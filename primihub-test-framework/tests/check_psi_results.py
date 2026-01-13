#!/usr/bin/env python3
"""
查看PSI任务执行结果和日志
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

    response = requests.get(url, params=params, headers=headers, timeout=30)
    return response

print("=" * 70)
print("  PSI任务执行结果分析")
print("=" * 70)

# 1. 查询PSI任务详情
print("\n1. 查询PSI任务详情...")
response = make_api_call("/data/psi/getPsiTaskList")

if response.text:
    result = response.json()
    if result.get('code') == 0:
        psi_tasks = result.get('result', {}).get('data', [])

        if psi_tasks:
            task = psi_tasks[0]
            task_id = task.get('taskId')
            task_id_name = task.get('taskIdName')
            task_state = task.get('taskState')

            task_state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败", 4: "取消"}
            state_name = task_state_map.get(task_state, "未知")

            print(f"\n任务信息:")
            print(f"   任务ID: {task_id}")
            print(f"   任务名称: {task.get('taskName')}")
            print(f"   任务标识: {task_id_name}")
            print(f"   状态: {state_name} (code: {task_state})")
            print(f"   创建时间: {task.get('createDate')}")
            print(f"   耗时: {task.get('consuming')}ms")

            # 2. 查询任务详细数据
            print(f"\n2. 查询任务详细数据...")
            response = make_api_call("/data/task/getTaskData", params={"taskId": task_id_name})

            if response.text:
                result = response.json()
                print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)[:1000]}")

                if result.get('code') == 0:
                    task_data = result.get('result', {})
                    print(f"\n任务详细信息:")
                    print(f"   任务类型: {task_data.get('taskType')}")
                    print(f"   任务状态: {task_data.get('taskState')}")

                    # 检查是否有错误信息
                    if task_data.get('taskErrorMsg'):
                        print(f"   ❌ 错误信息: {task_data.get('taskErrorMsg')}")

                    if task_data.get('taskMsg'):
                        print(f"   消息: {task_data.get('taskMsg')}")

# 3. 查询任务日志
print(f"\n3. 查询任务日志...")
response = make_api_call("/data/task/getTaskLogInfo", params={"taskId": task_id_name})

if response.text:
    result = response.json()
    if result.get('code') == 0:
        log_info = result.get('result', {})
        print(f"\n任务日志:")
        print(json.dumps(log_info, indent=2, ensure_ascii=False))
    else:
        print(f"   无法获取日志: {result.get('msg')}")

# 4. 检查数据库中的任务信息
print(f"\n4. 检查数据库中的任务状态...")
import subprocess

# 查询PSI任务表
result = subprocess.run(
    ['docker', 'exec', 'mysql', 'mysql', '-uroot', '-proot', 'privacy1', '-e',
     'SELECT task_id, task_id_name, task_state, ascription, create_date FROM data_psi_task WHERE id = 1;'],
    capture_output=True, text=True, stderr=subprocess.DEVNULL
)

if result.returncode == 0:
    print("✅ PSI任务表:")
    print(result.stdout)

# 查询通用任务表
result = subprocess.run(
    ['docker', 'exec', 'mysql', 'mysql', '-uroot', '-proot', 'privacy1', '-e',
     'SELECT task_id, task_name, task_type, task_state, task_error_msg FROM data_task WHERE task_id = "2010409034654031874";'],
    capture_output=True, text=True, stderr=subprocess.DEVNULL
)

if result.returncode == 0:
    print("\n✅ 通用任务表:")
    print(result.stdout)

print("\n" + "=" * 70)
print("  分析总结")
print("=" * 70)

print("""
PSI任务状态: 失败 (taskState: 3)

可能的失败原因:
1. 单方PSI配置问题 - 使用相同机构和资源作为双方可能不支持
2. 资源数据格式问题 - CSV文件格式或字段可能不符合要求
3. 节点通信问题 - PSI需要多方节点通信，单节点环境可能无法执行
4. 权限或配置问题 - 可能需要额外的配置或权限

建议:
1. 查看应用日志获取详细错误信息
2. 配置多方环境进行真正的PSI求交
3. 检查资源数据格式是否正确
4. 确认PSI节点服务是否正常运行
""")

print("=" * 70)
