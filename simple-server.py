#!/usr/bin/env python3
"""
Simple HTTP server that only serves the chat interface
"""

import http.server
import socketserver
import os
from urllib.parse import urlparse

class SecureChatHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        # Serve the chat interface
        if parsed_path.path in ['/', '/simple-frontend.html', '/index.html']:
            self.serve_chat_interface()
        # Serve Prism.js files for syntax highlighting
        elif parsed_path.path in ['/prism.min.js', '/prism-css.min.css', '/prism-python.min.js', '/prism-javascript.min.js', '/prism-java.min.js', '/prism-css.min.js', '/prism-bash.min.js', '/prism-go.min.js', '/prism-markup.min.js', '/prism-nginx.min.js', '/prism-fish.min.js', '/prism-jinja2.min.js']:
            self.serve_static_file(parsed_path.path)
        else:
            # Return 404 for any other requests
            self.send_error(404, "Not Found")
    
    def serve_chat_interface(self):
        try:
            with open('simple-frontend.html', 'r', encoding='utf-8') as f:
                content = f.read()
            
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(content.encode('utf-8'))))
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
        except FileNotFoundError:
            self.send_error(404, "Chat interface not found")
        except Exception as e:
            self.send_error(500, f"Server error: {str(e)}")
    
    def serve_static_file(self, file_path):
        try:
            # Remove leading slash
            filename = file_path[1:]
            
            # Determine content type
            if filename.endswith('.js'):
                content_type = 'application/javascript'
            elif filename.endswith('.css'):
                content_type = 'text/css'
            else:
                content_type = 'application/octet-stream'
            
            with open(filename, 'rb') as f:
                content = f.read()
            
            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404, f"File not found: {file_path}")
        except Exception as e:
            self.send_error(500, f"Server error: {str(e)}")

if __name__ == "__main__":
    PORT = 3000
    
    with socketserver.TCPServer(("", PORT), SecureChatHandler) as httpd:
        print(f"🚀 Chat server running on http://localhost:{PORT}")
        print("🔒 Serving chat interface and syntax highlighting files")
        print("🛑 Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped")