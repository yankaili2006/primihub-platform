#!/usr/bin/env python3
import requests
import json
import time

# Login
login_url = "http://100.64.0.23:30811/prod-api/user/login"
login_data = {
    "userAccount": "admin",
    "userPassword": "123456"
}

response = requests.post(login_url, data=login_data)
result = response.json()
token = result['result']['token']
user_id = result['result']['sysUser']['userId']

print(f"Token: {token[:30]}...")
print(f"User ID: {user_id}")
print()

# Prepare common params
def make_params(token):
    return {
        "token": token,
        "timestamp": str(int(time.time() * 1000)),
        "nonce": "123"
    }

base_url = "http://100.64.0.23:30811/prod-api"

# Test different APIs
apis = [
    ("/sys/organ/getOrganList", {"pageNo": 1, "pageSize": 10}),
    ("/sys/organ/getLocalOrganInfo", {}),
    ("/sys/organ/getHomepage", {}),
]

for api_path, extra_params in apis:
    print("=" * 80)
    print(f"API: {api_path}")
    print("=" * 80)

    params = make_params(token)
    params.update(extra_params)

    try:
        response = requests.get(base_url + api_path, params=params)
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Error: {e}")

    print()
