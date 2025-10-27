#!/usr/bin/env python3
"""
Simple HTTP server to receive and display logs from HttpLogger.
Usage: python log_receiver.py
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime


class LogHandler(BaseHTTPRequestHandler):
    """Handler for incoming log requests."""
    
    def do_POST(self):
        """Handle POST requests with log data."""
        try:
            # Read the content length and body
            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length)
            
            # Parse JSON data
            log_data = json.loads(body.decode('utf-8'))
            
            # Display the log
            self.display_log(log_data)
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'OK')
            
        except Exception as e:
            print(f"Error processing log: {e}")
            self.send_response(500)
            self.end_headers()
    
    def display_log(self, log_data):
        """Display log data in a formatted way."""
        print("\n" + "=" * 60)
        print("LOG RECEIVED")
        print("=" * 60)
        
        # Display timestamp
        timestamp = log_data.get('timestamp', 'N/A')
        print(f"Timestamp: {timestamp}")
        
        # Display level with color
        level = log_data.get('level', 'info').upper()
        level_colors = {
            'DEBUG': '\033[36m',    # Cyan
            'INFO': '\033[32m',     # Green
            'WARNING': '\033[33m',  # Yellow
            'ERROR': '\033[31m',    # Red
        }
        color = level_colors.get(level, '\033[0m')
        reset = '\033[0m'
        print(f"Level: {color}{level}{reset}")
        
        # Display label if present
        if 'label' in log_data:
            print(f"Label: {log_data['label']}")
        
        # Display message or value
        if 'message' in log_data:
            print(f"Message: {log_data['message']}")
        
        if 'value' in log_data:
            print(f"Value:\n{log_data['value']}")
        
        # Display any other fields
        other_fields = {k: v for k, v in log_data.items() 
                       if k not in ['timestamp', 'level', 'label', 'message', 'value']}
        if other_fields:
            print("\nAdditional fields:")
            for key, value in other_fields.items():
                print(f"  {key}: {value}")
        
        print("=" * 60 + "\n")
    
    def log_message(self, format, *args):
        """Suppress default HTTP logging."""
        pass


def main():
    """Start the log receiver server."""
    host = 'localhost'
    port = 8888
    
    server = HTTPServer((host, port), LogHandler)
    
    print(f"Log Receiver Server")
    print(f"==================")
    print(f"Listening on http://{host}:{port}")
    print(f"Press Ctrl+C to stop\n")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        server.shutdown()
        print("Server stopped.")


if __name__ == '__main__':
    main()
