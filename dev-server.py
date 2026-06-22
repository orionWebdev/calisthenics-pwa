#!/usr/bin/env python3
"""
Development Server for Calisthenics PWA
This server serves the app locally with proper cache control headers
to ensure changes are immediately visible without hard reload.
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8080

class NoCacheHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """
    Custom HTTP Request Handler that adds no-cache headers
    for all files to ensure immediate visibility of changes.
    """

    def end_headers(self):
        """Add cache-control headers before ending headers"""
        # Prevent caching for all files during development
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')

        # CORS headers for local development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

        super().end_headers()

    def log_message(self, format, *args):
        """Override to provide cleaner log messages"""
        # Only log non-asset requests to reduce noise
        if not any(ext in args[0] for ext in ['.css', '.js', '.png', '.jpg', '.svg', '.ico']):
            print(f"[{self.log_date_time_string()}] {format % args}")
        elif '--verbose' in sys.argv:
            print(f"[{self.log_date_time_string()}] {format % args}")

def main():
    # Change to the script's directory
    os.chdir(Path(__file__).parent)

    # Create server
    Handler = NoCacheHTTPRequestHandler

    try:
        # ThreadingHTTPServer: handle each request in its own thread so a hung
        # or keep-alive connection (e.g. from a headless browser) can't block the
        # accept loop and make the server "listen but refuse" new connections.
        with http.server.ThreadingHTTPServer(("", PORT), Handler) as httpd:
            print("=" * 60)
            print("🚀 Calisthenics Pro - Development Server")
            print("=" * 60)
            print(f"\n✅ Server running at:")
            print(f"   http://localhost:{PORT}")
            print(f"   http://127.0.0.1:{PORT}")
            print(f"\n📂 Serving from: {os.getcwd()}")
            print(f"\n⚙️  Features:")
            print(f"   • No caching (changes visible immediately)")
            print(f"   • Service Worker disabled on localhost")
            print(f"   • CORS enabled for local development")
            print(f"\n💡 Tip: Use Ctrl+C to stop the server")
            print(f"🔧 Add --verbose flag for detailed logging")
            print("=" * 60)
            print()

            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped by user")
        sys.exit(0)
    except OSError as e:
        if e.errno == 10048:  # Port already in use on Windows
            print(f"\n❌ Error: Port {PORT} is already in use!")
            print(f"   Try closing other applications or change the PORT in this script.")
        else:
            print(f"\n❌ Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
