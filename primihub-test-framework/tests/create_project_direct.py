#!/usr/bin/env python3
"""
直接尝试创建项目，跳过获取机构列表
"""

import requests
import time
import json
from datetime import datetime

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"

def make_api_call(endpoint, method="GET", data=None):
    """发送API请求"""
    url = f"{BASE_URL}{endpoint}"
    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    if method == "GET":
        params = {"timestamp": timestamp, "nonce": nonce, "token": TOKEN}
        headers = {"token": TOKEN}
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN
        headers = {"Content-Type": "application/json", "token": TOKEN}
        response = requests.post(url, json=data, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  直接通过API创建项目（使用已知的organ_id）")
print("=" * 70)

# 直接使用我们创建的organ_id
organ_id = "000000000000000000000000test0001"
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

project_data = {
    "projectName": f"API测试项目_{timestamp}",
    "projectDesc": f"通过API创建的测试项目 - {timestamp}",
    "projectOrgans": [
        {
            "organId": organ_id,
            "participationIdentity": 1,
            "resourceIds": []
        }
    ]
}

print(f"\n创建项目:")
print(f"   项目名称: {project_data['projectName']}")
print(f"   机构ID: {organ_id}")

response = make_api_call("/data/project/saveOrUpdateProject", method="POST", data=project_data)

print(f"\nStatus: {response.status_code}")
print(f"Response: {response.text[:1000]}")

if response.text:
    result = response.json()

    if result.get('code') == 0:
        project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
        print(f"\n🎉 项目创建成功!")
        print(f"   项目ID: {project_id}")
        print(f"   项目名称: {project_data['projectName']}")

        # 验证项目
        print("\n验证项目列表...")
        response = make_api_call("/data/project/getProjectList")

        if response.text:
            list_result = response.json()
            print(f"Response: {json.dumps(list_result, indent=2, ensure_ascii=False)}")
    else:
        print(f"\n❌ 项目创建失败: {result.get('msg')}")

print("\n" + "=" * 70)
