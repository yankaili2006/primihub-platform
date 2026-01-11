#!/usr/bin/env python3
"""
完整流程：创建机构 -> 创建项目
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
print("  完整流程：创建机构 -> 创建项目")
print("=" * 70)

# 步骤1: 创建机构
print("\n步骤1: 创建机构...")
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
organ_data = {
    "organName": f"测试机构_{timestamp}",
    "organDesc": f"通过API创建的测试机构 - {timestamp}"
}

print(f"   机构名称: {organ_data['organName']}")

response = make_api_call("/sys/organ/saveOrgan", method="POST", data=organ_data)
print(f"Status: {response.status_code}")

if response.text:
    result = response.json()
    print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")

    if result.get('code') == 0:
        organ_id = result.get('result')
        print(f"\n✅ 机构创建成功!")
        print(f"   机构ID: {organ_id}")

        # 步骤2: 获取机构列表验证
        print("\n步骤2: 验证机构列表...")
        response = make_api_call("/sys/organ/getOrganList")

        if response.text:
            result = response.json()
            if result.get('code') == 0:
                result_data = result.get('result', {})
                organs = result_data.get('data', []) if isinstance(result_data, dict) else []
                print(f"✅ 系统中现在有 {len(organs)} 个机构")

                if organs:
                    # 步骤3: 创建项目
                    print("\n步骤3: 创建项目...")
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

                    response = make_api_call("/data/project/saveOrUpdateProject", method="POST", data=project_data)
                    print(f"\nStatus: {response.status_code}")

                    if response.text:
                        result = response.json()
                        print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")

                        if result.get('code') == 0:
                            project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
                            print(f"\n🎉 项目创建成功!")
                            print(f"   项目ID: {project_id}")
                            print(f"   项目名称: {project_data['projectName']}")

                            # 步骤4: 验证项目
                            print("\n步骤4: 验证项目列表...")
                            response = make_api_call("/data/project/getProjectList")

                            if response.text:
                                list_result = response.json()
                                if list_result.get('code') == 0:
                                    list_data = list_result.get('result', {})
                                    projects = list_data.get('list', []) if isinstance(list_data, dict) else []
                                    print(f"✅ 系统中共有 {len(projects)} 个项目")

                                    for proj in projects:
                                        if proj.get('projectName') == project_data['projectName']:
                                            print(f"\n✅ 找到刚创建的项目:")
                                            print(f"   项目ID: {proj.get('projectId')}")
                                            print(f"   项目名称: {proj.get('projectName')}")
                                            print(f"   状态: {proj.get('projectState')}")
                                            break
                        else:
                            print(f"\n❌ 项目创建失败: {result.get('msg')}")
    else:
        print(f"\n❌ 机构创建失败: {result.get('msg')}")

print("\n" + "=" * 70)
