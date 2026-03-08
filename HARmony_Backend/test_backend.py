#!/usr/bin/env python3
"""
Test script for HARmony Backend
"""
import requests
import json
import numpy as np

BASE_URL = "http://127.0.0.1:5000/api"

def test_endpoint(endpoint, method='GET', data=None):
    """Test a single endpoint"""
    url = f"{BASE_URL}/{endpoint}"
    print(f"\n🔍 Testing {method} {url}")
    
    try:
        if method == 'GET':
            response = requests.get(url)
        elif method == 'POST':
            headers = {'Content-Type': 'application/json'}
            response = requests.post(url, json=data, headers=headers)
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Success: {json.dumps(result, indent=2)[:200]}...")
            return True, result
        else:
            print(f"   ❌ Error: {response.text}")
            return False, response.text
            
    except requests.exceptions.ConnectionError:
        print(f"   ❌ Connection failed - Is the server running?")
        return False, None
    except Exception as e:
        print(f"   ❌ Exception: {e}")
        return False, None

def main():
    print("🧪 Testing HARmony Backend API")
    print("=" * 60)
    
    # 1. Test health endpoint
    test_endpoint("health")
    
    # 2. Test model info
    success, model_info = test_endpoint("model-info")
    
    if success:
        # Get feature count from model info
        feature_count = model_info.get('feature_count', 0)
        print(f"\n📊 Model expects {feature_count} features")
        
        # 3. Test activities endpoint
        test_endpoint("activities")
        
        # 4. Test debug endpoint
        test_endpoint("debug")
        
        # 5. Test with example features if we know the count
        if feature_count > 0:
            # Create dummy features
            dummy_features = list(np.random.randn(feature_count))
            
            test_data = {
                "features": dummy_features,
                "timestamp": "2024-01-18T10:30:00.000Z"
            }
            
            test_endpoint("predict", method='POST', data=test_data)
        
        # 6. Test the built-in test prediction
        test_endpoint("test-prediction")
        
        # 7. Get example features format
        test_endpoint("example-features")
    
    print("\n" + "=" * 60)
    print("✅ Testing complete!")

if __name__ == "__main__":
    main()
