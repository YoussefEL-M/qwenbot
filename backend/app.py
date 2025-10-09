#!/usr/bin/env python3
"""
Optimized Qwen 2.5 Backend for 12GB VRAM
Features:
- Memory-efficient model loading
- Streaming responses
- GPU memory management
- FastAPI with WebSocket support
"""

import os
import gc
import torch
import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from transformers import (
    AutoTokenizer, 
    AutoModelForCausalLM, 
    TextIteratorStreamer,
    GenerationConfig
)
from threading import Thread
import json
import asyncio
from typing import List, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration - Dynamic model loading
import json

def load_model_config():
    """Load model configuration from file or use default"""
    try:
        with open('model_config.json', 'r') as f:
            config = json.load(f)
            return config.get('model', 'Qwen/Qwen2.5-3B-Instruct')
    except FileNotFoundError:
        return 'Qwen/Qwen2.5-3B-Instruct'

MODEL_NAME = load_model_config()
MAX_MEMORY_GB = 12  # Minimal memory requirement
DEVICE = os.getenv("DEVICE", "cuda" if torch.cuda.is_available() else "cpu")

app = FastAPI(title="Qwen 2.5 Chat API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global model and tokenizer
model = None
tokenizer = None
current_model_name = None

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    max_tokens: Optional[int] = 2048
    temperature: Optional[float] = 0.7
    top_p: Optional[float] = 0.9
    stream: Optional[bool] = False

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

manager = ConnectionManager()

def optimize_gpu_memory():
    """Optimize GPU memory usage"""
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        gc.collect()
        # Set memory fraction
        torch.cuda.set_per_process_memory_fraction(0.9)
        logger.info(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory // 1024**3}GB total")

def unload_model():
    """Unload current model from memory"""
    global model, tokenizer, current_model_name
    
    if model is not None:
        logger.info("🔄 Unloading current model...")
        
        try:
            # Move model to CPU first to free GPU memory
            if hasattr(model, 'cpu'):
                model.cpu()
            
            # Delete model and tokenizer
            del model
            del tokenizer
            
            # Clear GPU cache
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                gc.collect()
            
            model = None
            tokenizer = None
            current_model_name = None
            
            logger.info("✅ Model unloaded successfully")
        except Exception as e:
            logger.warning(f"⚠️ Error during model unload: {e}")
            # Force cleanup even if there's an error
            model = None
            tokenizer = None
            current_model_name = None
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
                gc.collect()

def load_model_dynamic(model_name: str):
    """Load a specific model dynamically"""
    global model, tokenizer, current_model_name
    
    # Unload current model if different
    if current_model_name != model_name:
        unload_model()
    
    # Load new model
    logger.info(f"🔄 Loading model: {model_name}")
    
    try:
        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            trust_remote_code=True,
            cache_dir="./model_cache"
        )
        
        # Configure model loading based on device
        if DEVICE == "cpu":
            # CPU-only configuration
            model = AutoModelForCausalLM.from_pretrained(
                model_name,
                torch_dtype=torch.float32,  # Use FP32 for CPU
                trust_remote_code=True,
                cache_dir="./model_cache",
                low_cpu_mem_usage=True,
                use_safetensors=True,  # Use safetensors if available
            )
        else:
            # GPU configuration for 12GB VRAM with optimizations
            model = AutoModelForCausalLM.from_pretrained(
                model_name,
                torch_dtype=torch.float16,  # Use FP16 for memory efficiency
                device_map="auto",
                trust_remote_code=True,
                cache_dir="./model_cache",
                low_cpu_mem_usage=True,
                max_memory={0: "10GB"},  # Reserve memory for other processes
                # Add optimizations for faster loading
                use_safetensors=True,  # Use safetensors if available
            )
        
        # Move model to correct device
        model = model.to(DEVICE)
        
        # Optimize model for inference
        model.eval()
        
        # Disable gradient checkpointing for faster inference
        if hasattr(model, 'gradient_checkpointing_disable'):
            model.gradient_checkpointing_disable()
            
        # Enable inference optimizations
        torch.backends.cudnn.benchmark = True
        if torch.cuda.is_available():
            torch.backends.cuda.matmul.allow_tf32 = True
            torch.backends.cudnn.allow_tf32 = True
            
        # Skip torch compilation for compatibility
        logger.info("✅ Model loaded successfully without compilation")
            
        current_model_name = model_name
        logger.info(f"✅ Model {model_name} loaded successfully!")
        logger.info(f"Model device: {next(model.parameters()).device}")
        
        # Print memory usage
        if torch.cuda.is_available():
            memory_used = torch.cuda.memory_allocated() / 1024**3
            memory_reserved = torch.cuda.memory_reserved() / 1024**3
            logger.info(f"GPU Memory - Used: {memory_used:.2f}GB, Reserved: {memory_reserved:.2f}GB")
        
        return True
        
    except Exception as e:
        logger.error(f"Failed to load model {model_name}: {str(e)}")
        return False

def load_model():
    """Load model with memory optimizations"""
    global model, tokenizer, current_model_name
    
    if model is not None and current_model_name == MODEL_NAME:
        return model, tokenizer
    
    # Use dynamic loading
    success = load_model_dynamic(MODEL_NAME)
    if not success:
        raise HTTPException(status_code=500, detail=f"Model loading failed: {MODEL_NAME}")
    
    return model, tokenizer

def format_messages_for_qwen(messages: List[ChatMessage]) -> str:
    """Format messages for Qwen 2.5 chat template using tokenizer's chat template"""
    # Try to use the tokenizer's built-in chat template for better efficiency
    try:
        # Convert to the format expected by apply_chat_template
        formatted_messages = []
        for msg in messages:
            formatted_messages.append({"role": msg.role, "content": msg.content})
        
        # Use tokenizer's chat template if available
        if hasattr(tokenizer, 'apply_chat_template') and tokenizer.chat_template:
            return tokenizer.apply_chat_template(formatted_messages, tokenize=False, add_generation_prompt=True)
    except:
        pass
    
    # Fallback to manual formatting
    formatted = []
    for msg in messages:
        if msg.role == "system":
            formatted.append(f"<|im_start|>system\n{msg.content}<|im_end|>")
        elif msg.role == "user":
            formatted.append(f"<|im_start|>user\n{msg.content}<|im_end|>")
        elif msg.role == "assistant":
            formatted.append(f"<|im_start|>assistant\n{msg.content}<|im_end|>")
    
    formatted.append("<|im_start|>assistant\n")
    return "\n".join(formatted)

async def generate_response(messages: List[ChatMessage], max_tokens: int = 2048, temperature: float = 0.7, top_p: float = 0.9, stream: bool = False):
    """Generate response from Qwen 2.5"""
    global model, tokenizer
    
    if model is None or tokenizer is None:
        model, tokenizer = load_model()
    
    # Format input
    prompt = format_messages_for_qwen(messages)
    
    # Tokenize with shorter context for faster inference
    inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=2048)
    inputs = {k: v.to(DEVICE) for k, v in inputs.items()}
    
    # Generation config optimized for speed
    generation_config = GenerationConfig(
        max_new_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        do_sample=True,
        pad_token_id=tokenizer.pad_token_id or tokenizer.eos_token_id,
        eos_token_id=tokenizer.eos_token_id,
        # Add optimizations for faster generation
        use_cache=True,  # Enable KV cache for faster generation
        repetition_penalty=1.0,  # Disable repetition penalty for speed
        # Additional speed optimizations
        num_beams=1,  # Use greedy search (faster than beam search)
        early_stopping=False,  # Don't use early stopping for speed
    )
    
    if stream:
        # Streaming generation
        streamer = TextIteratorStreamer(tokenizer, timeout=5.0, skip_prompt=True, skip_special_tokens=True)
        generation_kwargs = {
            **inputs,
            **generation_config.to_dict(),
            "streamer": streamer,
        }
        
        thread = Thread(target=model.generate, kwargs=generation_kwargs)
        thread.start()
        
        for new_text in streamer:
            if new_text:
                yield new_text
                # Remove delay for faster streaming
                # await asyncio.sleep(0.01)
        
        thread.join()
    else:
        # Non-streaming generation
        with torch.no_grad():
            outputs = model.generate(**inputs, generation_config=generation_config)
            response = tokenizer.decode(outputs[0][inputs['input_ids'].shape[1]:], skip_special_tokens=True)
            yield response

@app.on_event("startup")
async def startup_event():
    """Initialize the application"""
    optimize_gpu_memory()
    logger.info("🚀 Starting Qwen 2.5 Chat Server...")
    
    # Load the model on startup
    logger.info(f"🔄 Loading initial model: {MODEL_NAME}")
    try:
        success = load_model_dynamic(MODEL_NAME)
        if success:
            logger.info(f"✅ Model {MODEL_NAME} loaded successfully on startup!")
        else:
            logger.warning(f"⚠️ Failed to load model {MODEL_NAME} on startup")
    except Exception as e:
        logger.error(f"❌ Error loading model on startup: {str(e)}")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "model": MODEL_NAME, "device": DEVICE}

@app.get("/health")
async def health_check():
    """Detailed health check"""
    gpu_info = {}
    if torch.cuda.is_available():
        gpu_info = {
            "gpu_available": True,
            "gpu_name": torch.cuda.get_device_name(0),
            "memory_allocated": f"{torch.cuda.memory_allocated() / 1024**3:.2f}GB",
            "memory_reserved": f"{torch.cuda.memory_reserved() / 1024**3:.2f}GB",
            "memory_total": f"{torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f}GB"
        }
    
    return {
        "status": "healthy",
        "model": MODEL_NAME,
        "current_model": current_model_name,
        "model_loaded": model is not None,
        **gpu_info
    }

@app.post("/config/model")
async def update_model_config(request: dict):
    """Update model configuration and load new model dynamically"""
    try:
        new_model = request.get("model")
        if not new_model:
            raise HTTPException(status_code=400, detail="Model name is required")
        
        # Save configuration to file
        config = {"model": new_model}
        with open('model_config.json', 'w') as f:
            json.dump(config, f)
        
        logger.info(f"Model configuration updated to: {new_model}")
        
        # Load new model dynamically
        logger.info("🔄 Switching to new model...")
        success = load_model_dynamic(new_model)
        
        if success:
            return {
                "status": "success", 
                "message": f"Model switched to {new_model} successfully!",
                "current_model": new_model
            }
        else:
            return {
                "status": "error", 
                "message": f"Failed to load model {new_model}. Please check logs.",
                "current_model": current_model_name
            }
    
    except Exception as e:
        logger.error(f"Failed to update model configuration: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat")
async def chat_completion(request: ChatRequest):
    """Chat completion endpoint"""
    try:
        if request.stream:
            # For streaming, use WebSocket instead
            return {"error": "Use WebSocket endpoint for streaming responses"}
        
        response_text = ""
        async for chunk in generate_response(
            request.messages, 
            request.max_tokens, 
            request.temperature, 
            request.top_p, 
            False
        ):
            response_text += chunk
        
        return {
            "choices": [{
                "message": {
                    "role": "assistant",
                    "content": response_text.strip()
                }
            }]
        }
    
    except Exception as e:
        logger.error(f"Chat completion error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for streaming chat"""
    await manager.connect(websocket)
    logger.info("WebSocket connection established")
    
    try:
        while True:
            # Receive message
            data = await websocket.receive_text()
            request_data = json.loads(data)
            
            # Parse request
            messages = [ChatMessage(**msg) for msg in request_data.get("messages", [])]
            max_tokens = request_data.get("max_tokens", 2048)
            temperature = request_data.get("temperature", 0.7)
            top_p = request_data.get("top_p", 0.9)
            
            # Generate and stream response
            await manager.send_personal_message(json.dumps({"type": "start"}), websocket)
            
            try:
                async for chunk in generate_response(messages, max_tokens, temperature, top_p, True):
                    if chunk:
                        await manager.send_personal_message(
                            json.dumps({"type": "token", "content": chunk}), 
                            websocket
                        )
                
                await manager.send_personal_message(json.dumps({"type": "end"}), websocket)
                
            except Exception as e:
                await manager.send_personal_message(
                    json.dumps({"type": "error", "content": str(e)}), 
                    websocket
                )
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("WebSocket connection closed")
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        manager.disconnect(websocket)

if __name__ == "__main__":
    # Create necessary directories
    os.makedirs("./model_cache", exist_ok=True)
    os.makedirs("./offload_cache", exist_ok=True)
    
    logger.info("🤖 Qwen 2.5 Chat Server")
    logger.info(f"🎯 Model: {MODEL_NAME}")
    logger.info(f"🚀 Device: {DEVICE}")
    
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000, 
        log_level="info",
        access_log=True
    )
