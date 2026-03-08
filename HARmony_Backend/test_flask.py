#!/usr/bin/env python3
print("Testing Flask installation...")

try:
    from flask import Flask
    print("✅ Flask import successful")
    
    app = Flask(__name__)
    
    @app.route('/')
    def hello():
        return "Hello World!"
    
    print("✅ Flask app created successfully")
    print("🌐 Flask is ready to use!")
    
except ImportError as e:
    print(f"❌ Flask import failed: {e}")
    print("\nTo install Flask:")
    print("   source venv/bin/activate")
    print("   pip install Flask")
