# FastAPI app initialization
# The main FastAPI app is defined in app/main.py
# This module is kept for compatibility

from app.main import app

def create_app():
    """Return the FastAPI app for compatibility."""
    return app
