#!/usr/bin/env python3
"""
修复后的项目创建脚本 - 正确处理响应结构
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
        # GET请求：不设置Content-Type，参数放在query string中
        params = {
            "timestamp": timestamp,
            "nonce": nonce,
            "token": TOKEN
        }
        headers = {
            "token": TOKEN
        }
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        # POST请求：设置Content-Type为application/json，参数放在body中
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN

        headers = {
            "Content-Type": "application/json",
            "token": TOKEN
        }
        response = requests.post(url, json=data, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  通过API创建项目")
print("=" * 70)

# 步骤1: 获取机构列表
print("\n步骤1: 获取机构列表...")
response = make_api_call("/sys/organ/getOrganList")

print(f"Status: {response.status_code}")

if response.text:
    result = response.json()
    print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")

    if result.get('code') == 0:
        # 处理分页结构的响应
        result_data = result.get('result', {})
        if isinstance(result_data, dict):
            organs = result_data.get('data', [])
        else:
            organs = result_data if isinstance(result_data, list) else []

        if organs:
            print(f"\n✅ 找到 {len(organs)} 个机构")

            for i, organ in enumerate(organs[:5], 1):
                print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

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

                    # 步骤3: 验证项目
                    print("\n步骤3: 验证项目...")
                    response = make_api_call("/data/project/getProjectList")

                    if response.text:
                        list_result = response.json()
                        if list_result.get('code') == 0:
                            list_data = list_result.get('result', {})
                            if isinstance(list_data, dict):
                                projects = list_data.get('list', [])
                            else:
                                projects = list_data if isinstance(list_data, list) else []

                            print(f"✅ 系统中共有 {len(projects)} 个项目")

                            # 查找刚创建的项目
                            for proj in projects:
                                if proj.get('projectName') == project_data['projectName']:
                                    print(f"\n✅ 找到刚创建的项目:")
                                    print(f"   项目ID: {proj.get('projectId')}")
                                    print(f"   项目名称: {proj.get('projectName')}")
                                    print(f"   状态: {proj.get('projectState')}")
                                    print(f"   创建时间: {proj.get('createDate')}")
                                    break
                else:
                    print(f"\n❌ 项目创建失败: {result.get('msg')}")
        else:
            print("\n⚠️  系统中没有机构，无法创建项目")
            print("   请先创建机构后再创建项目")
    else:
        print(f"❌ 获取机构列表失败: {result.get('msg')}")
else:
    print("❌ 空响应")

print("\n" + "=" * 70)
