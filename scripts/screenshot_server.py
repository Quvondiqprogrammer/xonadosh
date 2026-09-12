#!/usr/bin/env python3
"""Host helper: listen for shot requests from iOS Simulator integration test,
run `xcrun simctl io … screenshot` at full 1242×2688."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "dist" / "appstore_screenshots"
OUT.mkdir(parents=True, exist_ok=True)
DEVICE = os.environ.get("DEVICE_ID", "booted")
PORT = int(os.environ.get("SHOT_PORT", "8765"))


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:  # quieter
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _ok(self, data: dict, code: int = 200) -> None:
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_GET(self) -> None:
        u = urlparse(self.path)
        if u.path in ("/health", "/"):
            self._ok({"ok": True, "out": str(OUT)})
            return
        if u.path == "/shot":
            qs = parse_qs(u.query)
            name = (qs.get("name") or ["shot"])[0]
            name = "".join(c for c in name if c.isalnum() or c in ("_", "-"))[:80]
            dest = OUT / f"{name}.png"
            cmd = [
                "xcrun",
                "simctl",
                "io",
                DEVICE,
                "screenshot",
                "--type=png",
                str(dest),
            ]
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode != 0:
                self._ok({"ok": False, "error": r.stderr or r.stdout}, 500)
                return
            # verify size
            sips = subprocess.run(
                ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(dest)],
                capture_output=True,
                text=True,
            )
            print(f"✓ {dest.name}  {sips.stdout.replace(chr(10), ' ').strip()}")
            self._ok({"ok": True, "path": str(dest)})
            return
        if u.path == "/done":
            self._ok({"ok": True})
            # signal main to exit soon
            global SHOULD_STOP
            SHOULD_STOP = True
            return
        self._ok({"ok": False, "error": "not found"}, 404)


SHOULD_STOP = False


def main() -> int:
    # Prefer concrete device id if provided
    global DEVICE
    if DEVICE == "booted":
        DEVICE = os.environ.get("DEVICE_ID", "booted")

    httpd = HTTPServer(("0.0.0.0", PORT), Handler)
    httpd.timeout = 0.5
    print(f"Screenshot server on http://127.0.0.1:{PORT}  → {OUT}", flush=True)
    print(f"device={DEVICE}", flush=True)

    start = time.time()
    while time.time() - start < 600:
        httpd.handle_request()
        if SHOULD_STOP:
            break
    print("server stop", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
