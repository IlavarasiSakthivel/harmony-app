#!/usr/bin/env python3
"""
HARmony Backend - Alternative FastAPI Run Script
Use: python backend/run.py
"""
import uvicorn
import sys
import os

# Add parent directory to path so imports work
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

if __name__ == "__main__":
    print("=" * 60)
    print("HARmony Backend (FastAPI) - Via backend/run.py")
    print("=" * 60)
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
