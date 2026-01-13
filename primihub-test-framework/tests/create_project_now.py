#!/usr/bin/env python3
"""
使用有效token创建项目
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
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN
        response = requests.post(url, json=data, headers=headers, timeout=30)

    print(f"Status: {response.status_code}")
    print(f"Response length: {len(response.text)}")

    if response.text:
        return response.json()
    else:
        print("Empty response!")
        return None

print("=" * 70)
print("  创建项目测试")
print("=" * 70)

# 步骤1: 获取机构列表
print("\n步骤1: 获取机构列表...")
result = make_api_call("/sys/organ/getOrganList")

if result and result.get('code') == 0:
    organs = result.get('result', [])
    print(f"✅ 找到 {len(organs)} 个机构")

    for i, organ in enumerate(organs[:5], 1):
        print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

    if organs:
        # 步骤2: 创建项目
        print("\n步骤2: 创建项目...")

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
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

        print(f"   项目名称: {project_data['projectName']}")
        print(f"   发起机构: {organs[0].get('organName')}")

        result = make_api_call("/data/project/saveOrUpdateProject", method="POST", data=project_data)

        if result:
            print(f"\n响应:")
            print(json.dumps(result, indent=2, ensure_ascii=False))

            if result.get('code') == 0:
                project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
                print(f"\n🎉 项目创建成功!")
                print(f"   项目ID: {project_id}")
                print(f"   项目名称: {project_data['projectName']}")
            else:
                print(f"\n❌ 失败: {result.get('msg')}")
else:
    print(f"❌ 获取机构列表失败")
    if result:
        print(f"   错误: {result.get('msg')}")

print("\n" + "=" * 70)
