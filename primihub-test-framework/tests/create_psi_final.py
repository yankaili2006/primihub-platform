#!/usr/bin/env python3
"""
PSI任务创建 - 最终版本（逐步添加所有必需参数）
"""

import requests
import time
import json
from datetime import datetime

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"
USER_ID = 1

def make_api_call(endpoint, method="GET", params=None, data=None):
    """发送API请求"""
    url = f"{BASE_URL}{endpoint}"
    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    if method == "GET":
        if params is None:
            params = {}
        params.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})
        headers = {"token": TOKEN}
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if params is None:
            params = {}
        params.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})
        headers = {"token": TOKEN}
        response = requests.post(url, params=params, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  PSI任务创建和执行（最终版本）")
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

            print(f"✅ 项目信息:")
            print(f"   项目ID: {project_id}")
            print(f"   机构ID: {organ_id}")

            # 步骤2: 创建PSI任务
            print("\n步骤2: 创建PSI任务...")

            timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

            # 完整的PSI参数
            psi_params = {
                "taskName": f"PSI求交_{timestamp_str}",
                "taskDesc": "隐私求交测试",
                "projectId": project_id,
                "ownOrganId": organ_id,
                "ownResourceId": "2",
                "ownKeyword": "user_id",
                "otherOrganId": organ_id,
                "otherResourceId": "2",
                "otherKeyword": "user_id",
                "resultName": f"result_{timestamp_str}",
                "resultOrganIds": organ_id,
                "psiTag": "0",  # 添加psiTag参数
                "outputContent": "0",
                "outputNoRepeat": "1",
                "outputFilePathType": "0",
                "userId": str(USER_ID)
            }

            print(f"   任务名称: {psi_params['taskName']}")
            print(f"   匹配字段: {psi_params['ownKeyword']}")

            response = make_api_call("/data/psi/saveDataPsi", method="POST", params=psi_params)

            print(f"\nStatus: {response.status_code}")

            if response.text:
                result = response.json()
                print(f"\nResponse:")
                print(json.dumps(result, indent=2, ensure_ascii=False))

                if result.get('code') == 0:
                    psi_result = result.get('result', {})
                    task_id = psi_result.get('taskId') or psi_result.get('id')

                    print(f"\n🎉 PSI任务创建成功!")
                    print(f"   任务ID: {task_id}")

                    # 步骤3: 查询任务状态
                    print("\n步骤3: 查询任务状态...")
                    time.sleep(3)

                    response = make_api_call("/data/task/getTaskList")

                    if response.text:
                        result = response.json()
                        if result.get('code') == 0:
                            task_list = result.get('result', {})
                            tasks = task_list.get('list', []) if isinstance(task_list, dict) else []

                            print(f"✅ 系统中共有 {len(tasks)} 个任务")

                            if tasks:
                                task_state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}

                                for i, task in enumerate(tasks[:3], 1):
                                    state = task_state_map.get(task.get('taskState'), "未知")
                                    print(f"\n{i}. {task.get('taskName')}")
                                    print(f"   状态: {state}")
                                    print(f"   创建时间: {task.get('createDate')}")

                                print("\n" + "=" * 70)
                                print("  ✅ PSI任务创建并提交执行成功!")
                                print("=" * 70)
                else:
                    print(f"\n❌ 失败: {result.get('msg')}")
                    if "缺少参数" in result.get('msg', ''):
                        missing_param = result.get('msg').split(':')[1] if ':' in result.get('msg') else '未知'
                        print(f"   还需要参数: {missing_param}")

print("\n" + "=" * 70)
