#!/usr/bin/env python3
"""
Login first, then create project with fresh token
"""

import sys
import os
import json
import time
import requests

# Configuration
BASE_URL = "http://100.64.0.23:30811/prod-api"

def make_api_call(endpoint, method="GET", data=None, token=None, use_json=True):
    """Make API call with proper timestamp and nonce"""
    url = f"{BASE_URL}{endpoint}"

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    headers = {}

    if token:
        headers["token"] = token

    if method == "GET":
        headers["Content-Type"] = "application/json"
        params = {
            "timestamp": timestamp,
            "nonce": nonce
        }
        if token:
            params["token"] = token
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}

        # Add timestamp and nonce to data
        request_data = data.copy()
        request_data["timestamp"] = timestamp
        request_data["nonce"] = nonce
        if token:
            request_data["token"] = token

        if use_json:
            headers["Content-Type"] = "application/json"
            response = requests.post(url, json=request_data, headers=headers, timeout=30)
        else:
            # Use form data
            response = requests.post(url, data=request_data, headers=headers, timeout=30)

    print(f"URL: {url}")
    print(f"Method: {method}")
    print(f"Status: {response.status_code}")
    print(f"Response length: {len(response.text)}")
    if response.text:
        print(f"Response: {response.text[:1000]}")
    else:
        print("Response: (empty)")

    if response.text:
        return response.json()
    else:
        return {"code": -1, "msg": "Empty response"}

# Step 1: Login (try with form data first)
print("=" * 70)
print("Step 1: Login")
print("=" * 70)

try:
    login_data = {
        "userAccount": "admin",
        "userPassword": "Admin@123456"
    }

    # Try with JSON first
    print("\nAttempt 1: Login with JSON data")
    result = make_api_call("/sys/user/login", method="POST", data=login_data, use_json=True)

    if result.get('code') != 0:
        # Try with form data
        print("\nAttempt 2: Login with form data")
        result = make_api_call("/sys/user/login", method="POST", data=login_data, use_json=False)

    if result.get('code') == 0:
        token = result.get('result', {}).get('token')
        user_id = result.get('result', {}).get('userId')
        user_name = result.get('result', {}).get('userName')

        print(f"\n✅ Login successful!")
        print(f"   User: {user_name} (ID: {user_id})")
        print(f"   Token: {token[:50]}..." if token else "   Token: None")

        # Step 2: Get organ list
        print("\n" + "=" * 70)
        print("Step 2: Get Organ List")
        print("=" * 70)

        result = make_api_call("/sys/organ/getOrganList", token=token)

        if result.get('code') == 0:
            organs = result.get('result', [])
            print(f"\n✅ Found {len(organs)} organs")

            for i, organ in enumerate(organs[:5], 1):
                print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

            if organs:
                # Step 3: Create project
                print("\n" + "=" * 70)
                print("Step 3: Create Project")
                print("=" * 70)

                timestamp = int(time.time())
                project_data = {
                    "projectName": f"API测试项目_{timestamp}",
                    "projectDesc": f"通过API创建的测试项目 - {timestamp}",
                    "projectOrgans": [
                        {
                            "organId": organs[0].get('organId'),
                            "participationIdentity": 1,
                            "resourceIds": []
                        }
                    ]
                }

                print(f"Creating project: {project_data['projectName']}")
                print(f"Initiator organ: {organs[0].get('organName')}")

                result = make_api_call("/data/project/saveOrUpdateProject", method="POST", data=project_data, token=token, use_json=True)

                if result.get('code') == 0:
                    project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
                    print(f"\n🎉 Project created successfully!")
                    print(f"   Project ID: {project_id}")
                    print(f"   Project Name: {project_data['projectName']}")

                    # Step 4: Verify project was created
                    print("\n" + "=" * 70)
                    print("Step 4: Verify Project")
                    print("=" * 70)

                    list_result = make_api_call("/data/project/getProjectList", token=token)
                    if list_result.get('code') == 0:
                        projects = list_result.get('result', {}).get('list', [])
                        print(f"✅ Total projects in system: {len(projects)}")

                        # Find our project
                        for proj in projects:
                            if proj.get('projectName') == project_data['projectName']:
                                print(f"\n✅ Found created project:")
                                print(f"   ID: {proj.get('projectId')}")
                                print(f"   Name: {proj.get('projectName')}")
                                print(f"   Status: {proj.get('projectState')}")
                                break
                else:
                    print(f"\n❌ Failed to create project: {result.get('msg')}")
            else:
                print("\n⚠️  No organs found, cannot create project")
        else:
            print(f"\n❌ Failed to get organs: {result.get('msg')}")
    else:
        print(f"\n❌ Login failed: {result.get('msg')}")

except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
