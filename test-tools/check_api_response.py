#!/usr/bin/env python3
"""Check actual API response"""

import requests
import time
import json

url = 'http://100.64.0.23:30811/prod-api/share/shareData/healthConnection'
data = {'time': int(time.time() * 1000)}

print("Testing health check API directly...")
print(f"URL: {url}")
print(f"Data: {data}")
print()

try:
    response = requests.post(url, json=data, headers={'Content-Type': 'application/json'}, timeout=5)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    print()
    
    try:
        result = response.json()
        print(f"Parsed JSON: {json.dumps(result, indent=2, ensure_ascii=False)}")
    except:
        print("Could not parse as JSON")
except Exception as e:
    print(f"Error: {e}")
