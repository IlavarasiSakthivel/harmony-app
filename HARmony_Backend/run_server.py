import uvicorn
import os
import sys
from app.main import app

if __name__ == '__main__':
    print("="*60)
    print("HARmony FastAPI Backend Server Starting")
    print("="*60)
    print(f"Python: {sys.version}")
    print(f"Working Directory: {os.getcwd()}")
    print("\n🌐 API Documentation (Swagger UI): http://127.0.0.1:8000/docs")
    print("🌐 API Documentation (ReDoc):     http://127.0.0.1:8000/redoc")
    print("\n✅ Server starting... (Press Ctrl+C to stop)")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
