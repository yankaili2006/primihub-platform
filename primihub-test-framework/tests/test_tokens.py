#!/usr/bin/env python3
"""
Test which token is valid
"""

import time
import requests
import json

BASE_URL = "http://100.64.0.23:30811/prod-api"

# Different tokens found in test files
TOKENS = [
    ("Token 1", "SU202601111503542F1167CD6FFFD38A270C80D9D96A928C"),
    ("Token 2", "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"),
    ("Token 3", "SU2026011119425868F77BF514722324D1A684973415FB86"),
]

def test_token(token_name, token):
    """Test if a token is valid by calling the organ list API"""
    url = f"{BASE_URL}/sys/organ/getOrganList"

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    params = {
        "timestamp": timestamp,
        "nonce": nonce,
        "token": token
    }

    headers = {
        "Content-Type": "application/json",
        "token": token
    }

    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)

        if response.text:
            result = response.json()
            if result.get('code') == 0:
                organs = result.get('result', [])
                print(f"✅ {token_name}: VALID - Found {len(organs)} organs")
                return token, organs
            else:
                print(f"❌ {token_name}: INVALID - {result.get('msg')}")
        else:
            print(f"❌ {token_name}: Empty response")
    except Exception as e:
        print(f"❌ {token_name}: Error - {e}")

    return None, None

print("=" * 70)
print("Testing Tokens")
print("=" * 70)

valid_token = None
organs = None

for token_name, token in TOKENS:
    print(f"\nTesting {token_name}...")
    print(f"Token: {token[:30]}...")
    result_token, result_organs = test_token(token_name, token)

    if result_token:
        valid_token = result_token
        organs = result_organs
        break

if valid_token:
    print("\n" + "=" * 70)
    print("Creating Project with Valid Token")
    print("=" * 70)

    # Create project
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
        ],
        "timestamp": int(time.time() * 1000),
        "nonce": int(time.time() * 1000) % 1000 + 1,
        "token": valid_token
    }

    url = f"{BASE_URL}/data/project/saveOrUpdateProject"
    headers = {
        "Content-Type": "application/json",
        "token": valid_token
    }

    print(f"\nCreating project: {project_data['projectName']}")
    print(f"Initiator organ: {organs[0].get('organName')}")

    try:
        response = requests.post(url, json=project_data, headers=headers, timeout=30)
        result = response.json()

        print(f"\nResponse:")
        print(json.dumps(result, indent=2, ensure_ascii=False))

        if result.get('code') == 0:
            project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
            print(f"\n🎉 Project created successfully!")
            print(f"   Project ID: {project_id}")
            print(f"   Project Name: {project_data['projectName']}")
        else:
            print(f"\n❌ Failed: {result.get('msg')}")
    except Exception as e:
        print(f"\n❌ Error: {e}")
else:
    print("\n❌ No valid token found. Please login through the web interface to get a new token.")
