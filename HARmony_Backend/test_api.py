#!/usr/bin/env python3
import requests
import json
import numpy as np

BASE_URL = "http://127.0.0.1:8000"

def test_endpoint(endpoint, method='GET', data=None):
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
            print(f"   ✅ Success")
            print(f"   Response: {json.dumps(result, indent=2)[:200]}...")
            return True, result
        else:
            print(f"   ❌ Error: {response.text}")
            return False, response.text
            
    except Exception as e:
        print(f"   ❌ Exception: {e}")
        return False, None

def main():
    print("🧪 Testing HARmony Backend")
    print("="*60)
    
    # Test basic endpoints
    test_endpoint("health")
    test_endpoint("model-info")
    test_endpoint("activities")
    test_endpoint("test")
    
    # Test prediction with dummy data (240 = 80 samples × 3 axes for WISDM CNN; 561 for sklearn fallback)
    print("\n🧪 Testing prediction endpoint...")
    dummy_features = np.random.randn(240).tolist()
    
    test_data = {
        "sensor_data": dummy_features,
        "user_id": "test_user"
    }
    
    success, result = test_endpoint("predict", method='POST', data=test_data)
    
    if success:
        print(f"\n🎉 Backend is working correctly!")
        print(f"   Activity: {result.get('activity', 'N/A')}")
        print(f"   Confidence: {result.get('confidence', 'N/A')}")
    else:
        print("\n❌ Backend test failed")
    
    print("\n" + "="*60)
    print("✅ Testing complete!")

if __name__ == "__main__":
    main()
