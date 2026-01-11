#!/usr/bin/env python3
"""
PSI任务创建 - 尝试不同的参数传递方式
"""

import requests
import time
import json
from datetime import datetime

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"
USER_ID = 1

def make_api_call_debug(endpoint, method="GET", data=None, use_query_params=False):
    """发送API请求 - 调试版本"""
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

        # 添加基础参数到data
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN

        headers = {"Content-Type": "application/json", "token": TOKEN}

        if use_query_params:
            # 尝试将关键参数也放到URL中
            params = {
                "ownOrganId": data.get("ownOrganId"),
                "timestamp": timestamp,
                "nonce": nonce,
                "token": TOKEN
            }
            print(f"   使用查询参数: {params}")
            response = requests.post(url, json=data, params=params, headers=headers, timeout=30)
        else:
            print(f"   请求体数据: {json.dumps(data, ensure_ascii=False, indent=2)[:500]}")
            response = requests.post(url, json=data, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  PSI任务创建调试")
print("=" * 70)

# 获取项目信息
print("\n获取项目信息...")
response = requests.get(
    f"{BASE_URL}/data/project/getProjectList",
    params={"timestamp": int(time.time() * 1000), "nonce": 123, "token": TOKEN},
    headers={"token": TOKEN},
    timeout=30
)

if response.text:
    result = response.json()
    if result.get('code') == 0:
        projects = result.get('result', {}).get('data', [])
        if projects:
            project = projects[0]
            project_id = project.get('projectId')
            organ_id = project.get('organId')

            print(f"✅ 项目ID: {project_id}")
            print(f"✅ 机构ID: {organ_id}")

            timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

            # 方法1: 标准JSON body
            print("\n" + "=" * 70)
            print("方法1: 使用标准JSON body")
            print("=" * 70)

            psi_data = {
                "taskName": f"PSI测试1_{timestamp_str}",
                "projectId": project_id,
                "ownOrganId": organ_id,
                "ownResourceId": "2",
                "ownKeyword": "user_id",
                "otherOrganId": organ_id,
                "otherResourceId": "2",
                "otherKeyword": "user_id",
                "resultName": f"result1_{timestamp_str}",
                "userId": USER_ID
            }

            response = make_api_call_debug("/data/psi/saveDataPsi", method="POST", data=psi_data)
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:500]}")

            # 方法2: 使用查询参数
            print("\n" + "=" * 70)
            print("方法2: 关键参数放到URL查询参数中")
            print("=" * 70)

            psi_data2 = {
                "taskName": f"PSI测试2_{timestamp_str}",
                "projectId": project_id,
                "ownOrganId": organ_id,
                "ownResourceId": "2",
                "ownKeyword": "user_id",
                "otherOrganId": organ_id,
                "otherResourceId": "2",
                "otherKeyword": "user_id",
                "resultName": f"result2_{timestamp_str}",
                "userId": USER_ID
            }

            response = make_api_call_debug("/data/psi/saveDataPsi", method="POST", data=psi_data2, use_query_params=True)
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:500]}")

print("\n" + "=" * 70)
