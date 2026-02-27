"""
Periodically measures HTTP latency to a target and exposes /metrics.
"""
import os
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import urlopen
from urllib.error import URLError

# Config from env
TARGET_HOST = os.environ.get("TARGET_HOST", "localhost")
TARGET_PORT = os.environ.get("TARGET_PORT", "8081")
METRICS_PORT = int(os.environ.get("METRICS_PORT", "8080"))
PROBE_INTERVAL_SEC = int(os.environ.get("PROBE_INTERVAL_SEC", "15"))

TARGET_URL = f"http://{TARGET_HOST}:{TARGET_PORT}/"

# In-memory metrics (single writer: probe thread; readers: HTTP handlers)
_lock = threading.Lock()
_latency_seconds = 0.0
_measurements_total = 0
_last_error = ""
_last_success_time = 0.0


def _probe():
    global _latency_seconds, _measurements_total, _last_error, _last_success_time
    try:
        start = time.perf_counter()
        with urlopen(TARGET_URL, timeout=5) as resp:
            elapsed = time.perf_counter() - start
            with _lock:
                _latency_seconds = elapsed
                _measurements_total += 1
                _last_error = ""
                _last_success_time = time.time()
                if resp.status not in (200, 404):
                    _last_error = f"status {resp.status}"
    except Exception as e:
        with _lock:
            _measurements_total += 1
            _latency_seconds = 0.0
            _last_error = str(e)


def _probe_loop():
    while True:
        _probe()
        time.sleep(PROBE_INTERVAL_SEC)


def _metrics_body():
    with _lock:
        s = (
            "# HELP latency_seconds HTTP round-trip latency to target\n"
            "# TYPE latency_seconds gauge\n"
            f"latency_seconds {_latency_seconds:.6f}\n"
            "# HELP latency_measurements_total Total number of measurements\n"
            "# TYPE latency_measurements_total counter\n"
            f"latency_measurements_total {_measurements_total}\n"
        )
        if _last_success_time > 0:
            s += (
                "# HELP latency_last_success_timestamp_seconds Unix time of last successful measurement\n"
                "# TYPE latency_last_success_timestamp_seconds gauge\n"
                f"latency_last_success_timestamp_seconds {int(_last_success_time)}\n"
            )
        if _last_error:
            s += (
                "# HELP latency_last_error Last error message\n"
                "# TYPE latency_last_error gauge\n"
                "latency_last_error 1\n"
            )
    return s.encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(_metrics_body())
        elif self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass


def main():
    threading.Thread(target=_probe_loop, daemon=True).start()
    server = HTTPServer(("", METRICS_PORT), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
