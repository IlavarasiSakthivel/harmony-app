#!/usr/bin/env python3
"""
HARmony Backend - Main Run Script (FastAPI)
"""
import uvicorn
import os
import sys
import socket

def find_available_port(start_port=8000, max_attempts=10):
    """Find an available port starting from start_port."""
    for port in range(start_port, start_port + max_attempts):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('0.0.0.0', port))
            sock.close()
            return port
        except OSError:
            continue
    return start_port  # Fallback

if __name__ == '__main__':
    port = find_available_port(8000)

    print("=" * 60)
    print("🚀 HARmony Backend Server (FastAPI)")
    print("=" * 60)
    print(f"📁 Working directory: {os.getcwd()}")
    print(f"🐍 Python: {sys.version.split()[0]}")
    print("=" * 60)
    print("📊 Available endpoints:")
    print(f"   GET  http://localhost:{port}/health")
    print(f"   GET  http://localhost:{port}/model-info")
    print(f"   GET  http://localhost:{port}/activities")
    print(f"   POST http://localhost:{port}/predict")
    print("=" * 60)
    print("📚 Interactive API Documentation:")
    print(f"   Swagger UI: http://127.0.0.1:{port}/docs")
    print(f"   ReDoc:      http://127.0.0.1:{port}/redoc")
    print("=" * 60)
    print("✅ Server starting... (Press Ctrl+C to stop)\n")

    # Run the app
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        reload=True  # Enable auto-reload for development
    )
