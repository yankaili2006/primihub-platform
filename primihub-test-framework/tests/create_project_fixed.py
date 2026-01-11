#!/usr/bin/env python3
"""
修正后的项目创建脚本 - 使用正确的API路径
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
        print(f"GET {url}")
        print(f"Params: {params}")
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN
        print(f"POST {url}")
        print(f"Data keys: {list(data.keys())}")
        response = requests.post(url, json=data, headers=headers, timeout=30)

    print(f"Status: {response.status_code}")
    print(f"Response length: {len(response.text)}")
    print(f"Response: {response.text[:500]}")

    if response.text:
        return response.json()
    else:
        return None

print("=" * 70)
print("  测试不同的API路径")
print("=" * 70)

# 尝试不同的路径组合
paths_to_try = [
    "/sys/organ/getOrganList",
    "/organ/getOrganList",
    "/sys/organ/list",
    "/organ/list"
]

organs = None
for path in paths_to_try:
    print(f"\n尝试路径: {path}")
    result = make_api_call(path)

    if result and result.get('code') == 0:
        organs = result.get('result', [])
        print(f"✅ 成功! 找到 {len(organs)} 个机构")
        working_path = path
        break
    elif result:
        print(f"❌ 失败: {result.get('msg')}")
    else:
        print(f"❌ 空响应")

if organs:
    print("\n" + "=" * 70)
    print("  创建项目")
    print("=" * 70)

    for i, organ in enumerate(organs[:5], 1):
        print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
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

    print(f"\n创建项目: {project_data['projectName']}")
    print(f"发起机构: {organs[0].get('organName')}")

    # 尝试不同的项目创建路径
    project_paths = [
        "/data/project/saveOrUpdateProject",
        "/project/saveOrUpdateProject"
    ]

    for path in project_paths:
        print(f"\n尝试路径: {path}")
        result = make_api_call(path, method="POST", data=project_data)

        if result and result.get('code') == 0:
            project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
            print(f"\n🎉 项目创建成功!")
            print(f"   项目ID: {project_id}")
            print(f"   项目名称: {project_data['projectName']}")
            break
        elif result:
            print(f"❌ 失败: {result.get('msg')}")
else:
    print("\n❌ 无法获取机构列表")

print("\n" + "=" * 70)
