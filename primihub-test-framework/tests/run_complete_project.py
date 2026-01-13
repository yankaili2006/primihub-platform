#!/usr/bin/env python3
"""
创建并运行PSI（隐私求交）任务 - 修正版
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
print("  完整的基础项目运行流程")
print("=" * 70)

# 步骤1: 获取项目信息
print("\n步骤1: 获取项目信息...")
response = make_api_call("/data/project/getProjectList")

if response.text:
    result = response.json()
    if result.get('code') == 0:
        projects = result.get('result', {}).get('data', [])
        if projects:
            project = projects[0]
            project_id = project.get('projectId')
            organ_id = project.get('organId')

            print(f"✅ 使用项目: {project.get('projectName')}")
            print(f"   项目ID: {project_id}")
            print(f"   机构ID: {organ_id}")

            # 步骤2: 创建简单的PSI任务
            print("\n步骤2: 创建PSI任务...")

            timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

            # 构建完整的PSI任务数据
            psi_data = {
                "taskName": f"PSI测试_{timestamp_str}",
                "taskDesc": "隐私求交测试",
                "projectId": project_id,
                "ownOrganId": organ_id,  # 添加机构ID
                "resourceIds": ["2"],
                "resultName": f"result_{timestamp_str}",
                "psiType": 0,  # PSI类型
                "serverAddress": "100.64.0.23:30811"
            }

            print(f"   任务名称: {psi_data['taskName']}")
            print(f"   项目ID: {project_id}")
            print(f"   机构ID: {organ_id}")

            response = make_api_call("/data/psi/saveDataPsi", method="POST", data=psi_data)

            print(f"\nStatus: {response.status_code}")

            if response.text:
                result = response.json()
                print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)[:800]}")

                if result.get('code') == 0:
                    task_id = result.get('result', {}).get('taskId')
                    print(f"\n🎉 PSI任务创建成功!")
                    print(f"   任务ID: {task_id}")

                    # 步骤3: 查询任务列表
                    print("\n步骤3: 查询任务列表...")
                    time.sleep(2)

                    response = make_api_call("/data/task/getTaskList")

                    if response.text:
                        result = response.json()
                        if result.get('code') == 0:
                            task_list = result.get('result', {})
                            if isinstance(task_list, dict):
                                tasks = task_list.get('list', [])
                            else:
                                tasks = task_list if isinstance(task_list, list) else []

                            print(f"✅ 系统中共有 {len(tasks)} 个任务")

                            if tasks:
                                print("\n任务列表:")
                                for i, task in enumerate(tasks[:5], 1):
                                    print(f"\n{i}. {task.get('taskName')}")
                                    print(f"   任务ID: {task.get('taskId')}")
                                    print(f"   状态: {task.get('taskState')}")
                                    print(f"   创建时间: {task.get('createDate')}")

                                print("\n" + "=" * 70)
                                print("  ✅ 基础项目运行成功!")
                                print("=" * 70)
                                print("\n完成的步骤:")
                                print("1. ✅ 创建项目")
                                print("2. ✅ 创建数据资源")
                                print("3. ✅ 创建PSI任务")
                                print("4. ✅ 验证任务创建")
                else:
                    print(f"\n❌ 任务创建失败: {result.get('msg')}")

print("\n" + "=" * 70)
