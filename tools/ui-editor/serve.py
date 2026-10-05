#!/usr/bin/env python3
"""Tiny static file server for the Human HUD Editor's auto-load feature.

Why this exists: the editor's "Auto-load from repo" button uses fetch() to
read _defines_alt.dm / os13.dmi / backgrounds.dmi straight from disk. Firefox
(and some Chrome configurations) block fetch() entirely for file:// pages,
so auto-load silently fails when you just double-click index.html. Serving
the repo over plain http:// instead sidesteps that restriction in every
browser.

Usage (from anywhere):
    python tools/ui-editor/serve.py [port]

Then open the printed http://localhost URL (default port 8000) instead of
opening index.html directly.
"""
import functools
import http.server
import os
import socketserver
import sys

DEFAULT_PORT = 8000
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=REPO_ROOT)
    # allow_reuse_address avoids "address already in use" when restarting quickly
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(('127.0.0.1', port), handler) as httpd:
        url = f"http://localhost:{port}/tools/ui-editor/index.html"
        print(f"Serving repo root: {REPO_ROOT}")
        print(f"Open this in your browser: {url}")
        print("Press Ctrl+C to stop.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")


if __name__ == '__main__':
    main()
