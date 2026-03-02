#!/usr/bin/env python3
"""Test if encryption works with the fixed public keys"""

import requests
import time

def test_health_check(from_port, to_port):
    """Test health check from one node to another"""
    url = f'http://100.64.0.23:{to_port}/prod-api/share/shareData/healthConnection'
    data = {'time': int(time.time() * 1000)}
    
    try:
        response = requests.post(url, json=data, headers={'Content-Type': 'application/json'}, timeout=5)
        result = response.json()
        
        if result.get('code') == 0:
            services = result.get('result', [])
            return True, services
        else:
            return False, result.get('msg', 'Unknown error')
    except Exception as e:
        return False, str(e)

print("Testing health checks with fixed database...")
print("=" * 70)
print()

tests = [
    (30812, 30811, "Node 30812 → Node 30811"),
    (30813, 30811, "Node 30813 → Node 30811"),
]

for from_port, to_port, desc in tests:
    success, result = test_health_check(from_port, to_port)
    if success:
        print(f"✓ {desc}: SUCCESS - Services: {result}")
    else:
        print(f"✗ {desc}: FAILED - {result}")

print()
print("=" * 70)
