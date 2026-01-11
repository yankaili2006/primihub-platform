#!/usr/bin/env python3
"""
验证PSI任务创建和状态
"""

import requests
import time
import json

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"

def make_api_call(endpoint, method="GET", params=None):
    """发送API请求"""
    url = f"{BASE_URL}{endpoint}"
    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    if params is None:
        params = {}
    params.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})
    headers = {"token": TOKEN}

    if method == "GET":
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        response = requests.post(url, params=params, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  验证PSI任务")
print("=" * 70)

# 查询PSI任务列表
print("\n查询PSI任务列表...")
response = make_api_call("/data/psi/getPsiTaskList")

if response.text:
    result = response.json()
    print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")

    if result.get('code') == 0:
        psi_list = result.get('result', {})
        if isinstance(psi_list, dict):
            psi_tasks = psi_list.get('list', [])
            total = psi_list.get('total', 0)
        else:
            psi_tasks = psi_list if isinstance(psi_list, list) else []
            total = len(psi_tasks)

        print(f"\n✅ PSI任务总数: {total}")

        if psi_tasks:
            print("\nPSI任务详情:")
            task_state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}

            for i, task in enumerate(psi_tasks, 1):
                state = task_state_map.get(task.get('taskState'), "未知")
                print(f"\n{i}. {task.get('taskName', 'N/A')}")
                print(f"   任务ID: {task.get('taskId')}")
                print(f"   PSI ID: {task.get('psiId')}")
                print(f"   状态: {state} ({task.get('taskState')})")
                print(f"   创建时间: {task.get('createDate')}")
                print(f"   发起方机构: {task.get('ownOrganId')}")
                print(f"   发起方资源: {task.get('ownResourceId')}")
                print(f"   匹配字段: {task.get('ownKeyword')}")
                print(f"   结果名称: {task.get('resultName')}")

            print("\n" + "=" * 70)
            print("  ✅ PSI任务验证成功!")
            print("=" * 70)
        else:
            print("\n⚠️  PSI任务列表为空")
    else:
        print(f"❌ 查询失败: {result.get('msg')}")

# 查询数据库中的PSI任务
print("\n查询数据库中的PSI任务...")
import subprocess
result = subprocess.run(
    ['docker', 'exec', 'mysql', 'mysql', '-uroot', '-proot', 'privacy1', '-e',
     'SELECT id, task_id_name, task_state, create_date FROM data_psi_task ORDER BY id DESC LIMIT 3;'],
    capture_output=True, text=True
)

if result.returncode == 0:
    print("✅ 数据库查询结果:")
    print(result.stdout)
else:
    print("❌ 数据库查询失败")

print("\n" + "=" * 70)
