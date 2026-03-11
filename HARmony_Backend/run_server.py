import uvicorn
import os
import sys
from app.main import app

if __name__ == '__main__':
    port = 8000
    host = "0.0.0.0"
    print("="*60)
    print("HARmony FastAPI Backend Server Starting")
    print("="*60)
    print(f"Python: {sys.version}")
    print(f"Working Directory: {os.getcwd()}")
    print(f"\n🌐 Server listening on: http://0.0.0.0:{port}")
    print(f"🌐 API Documentation (Swagger UI): http://127.0.0.1:{port}/docs")
    print(f"🌐 API Documentation (ReDoc):     http://127.0.0.1:{port}/redoc")
    print("\n✅ Server starting... (Press Ctrl+C to stop)")
    uvicorn.run(app, host=host, port=port)
