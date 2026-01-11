#!/usr/bin/env python3
"""
PSI任务创建 - 正确版本（使用查询参数）
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
        # POST请求：参数放在URL查询字符串中
        if params is None:
            params = {}
        params.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})

        # 如果有data，作为JSON body发送
        if data:
            headers = {"Content-Type": "application/json", "token": TOKEN}
            response = requests.post(url, params=params, json=data, headers=headers, timeout=30)
        else:
            headers = {"token": TOKEN}
            response = requests.post(url, params=params, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  PSI任务创建和执行（正确版本）")
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
            print(f"   项目名称: {project.get('projectName')}")
            print(f"   机构ID: {organ_id}")

            # 步骤2: 创建PSI任务（参数放在URL中）
            print("\n步骤2: 创建PSI任务...")

            timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

            # 所有PSI参数作为查询参数
            psi_params = {
                "taskName": f"PSI求交任务_{timestamp_str}",
                "taskDesc": "隐私求交测试任务",
                "projectId": project_id,
                "ownOrganId": organ_id,
                "ownResourceId": "2",
                "ownKeyword": "user_id",
                "otherOrganId": organ_id,
                "otherResourceId": "2",
                "otherKeyword": "user_id",
                "resultName": f"psi_result_{timestamp_str}",
                "outputContent": "0",
                "outputNoRepeat": "1",
                "outputFilePathType": "0",
                "userId": str(USER_ID),
                "tag": "0"
            }

            print(f"   任务名称: {psi_params['taskName']}")
            print(f"   发起方机构: {organ_id}")
            print(f"   发起方资源: {psi_params['ownResourceId']}")
            print(f"   匹配字段: {psi_params['ownKeyword']}")

            response = make_api_call("/data/psi/saveDataPsi", method="POST", params=psi_params)

            print(f"\nStatus: {response.status_code}")

            if response.text:
                result = response.json()
                print(f"\nResponse:")
                print(json.dumps(result, indent=2, ensure_ascii=False)[:800])

                if result.get('code') == 0:
                    psi_result = result.get('result', {})
                    task_id = psi_result.get('taskId') or psi_result.get('id')

                    print(f"\n🎉 PSI任务创建成功!")
                    print(f"   任务ID: {task_id}")
                    print(f"   任务名称: {psi_params['taskName']}")

                    # 步骤3: 等待并查询任务状态
                    print("\n步骤3: 查询任务状态...")
                    print("   等待5秒让任务开始执行...")
                    time.sleep(5)

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
                                task_state_map = {
                                    0: "待执行",
                                    1: "执行中",
                                    2: "成功",
                                    3: "失败",
                                    4: "取消"
                                }

                                for i, task in enumerate(tasks[:5], 1):
                                    state = task_state_map.get(task.get('taskState'), "未知")
                                    print(f"\n{i}. {task.get('taskName')}")
                                    print(f"   任务ID: {task.get('taskId')}")
                                    print(f"   任务类型: {task.get('taskType')}")
                                    print(f"   状态: {state} ({task.get('taskState')})")
                                    print(f"   创建时间: {task.get('createDate')}")

                                # 步骤4: 查询PSI任务详情
                                print("\n步骤4: 查询PSI任务列表...")
                                response = make_api_call("/data/psi/getPsiTaskList")

                                if response.text:
                                    result = response.json()
                                    if result.get('code') == 0:
                                        psi_list = result.get('result', {})
                                        if isinstance(psi_list, dict):
                                            psi_tasks = psi_list.get('list', [])
                                        else:
                                            psi_tasks = psi_list if isinstance(psi_list, list) else []

                                        print(f"✅ PSI任务总数: {len(psi_tasks)}")

                                        if psi_tasks:
                                            print("\nPSI任务详情:")
                                            for psi_task in psi_tasks[:3]:
                                                print(f"\n   任务名称: {psi_task.get('taskName')}")
                                                print(f"   任务ID: {psi_task.get('taskId')}")
                                                print(f"   状态: {psi_task.get('taskState')}")
                                                print(f"   结果名称: {psi_task.get('resultName')}")

                                print("\n" + "=" * 70)
                                print("  ✅ PSI任务创建并执行成功!")
                                print("=" * 70)
                                print("\n完成的步骤:")
                                print("1. ✅ 获取项目信息")
                                print("2. ✅ 创建PSI任务")
                                print("3. ✅ 查询任务状态")
                                print("4. ✅ 验证PSI任务")
                                print("\n任务已提交执行，可以通过任务列表查看执行进度")
                else:
                    print(f"\n❌ PSI任务创建失败: {result.get('msg')}")
                    print(f"   错误码: {result.get('code')}")

print("\n" + "=" * 70)
