"""Minimal HTTP server on port 8081 for latency probe. Stdlib only; runs in distroless."""
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args):
        pass

HTTPServer(("", 8081), Handler).serve_forever()
