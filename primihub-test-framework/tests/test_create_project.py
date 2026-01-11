#!/usr/bin/env python3
"""
Simple project creation test
"""

import sys
import os
import json
import time
import requests

# Configuration
BASE_URL = "http://100.64.0.23:30811/prod-api"
TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"

def make_api_call(endpoint, method="GET", data=None):
    """Make API call with proper timestamp and nonce"""
    url = f"{BASE_URL}{endpoint}"

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    headers = {
        "Content-Type": "application/json",
        "token": TOKEN
    }

    if method == "GET":
        params = {
            "timestamp": timestamp,
            "nonce": nonce,
            "token": TOKEN
        }
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN
        response = requests.post(url, json=data, headers=headers, timeout=30)

    print(f"Status: {response.status_code}")
    print(f"Response: {response.text[:500]}")

    return response.json()

# Test 1: Get organ list
print("=" * 70)
print("Test 1: Get Organ List")
print("=" * 70)
try:
    result = make_api_call("/sys/organ/getOrganList")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result.get('code') == 0:
        organs = result.get('result', [])
        print(f"\n✅ Found {len(organs)} organs")

        if organs:
            # Test 2: Create project
            print("\n" + "=" * 70)
            print("Test 2: Create Project")
            print("=" * 70)

            timestamp = int(time.time())
            project_data = {
                "projectName": f"API测试项目_{timestamp}",
                "projectDesc": f"通过API创建 - {timestamp}",
                "projectOrgans": [
                    {
                        "organId": organs[0].get('organId'),
                        "participationIdentity": 1,
                        "resourceIds": []
                    }
                ]
            }

            print(f"Creating project: {project_data['projectName']}")
            result = make_api_call("/data/project/saveOrUpdateProject", method="POST", data=project_data)
            print(json.dumps(result, indent=2, ensure_ascii=False))

            if result.get('code') == 0:
                print("\n🎉 Project created successfully!")
            else:
                print(f"\n❌ Failed: {result.get('msg')}")
    else:
        print(f"❌ Failed to get organs: {result.get('msg')}")

except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
