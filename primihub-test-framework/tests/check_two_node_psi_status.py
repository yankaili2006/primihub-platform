#!/usr/bin/env python3
"""
查询两节点PSI任务状态
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
print("  两节点PSI任务状态查询")
print("=" * 70)

# 查询PSI任务列表
print("\n查询PSI任务列表...")
response = make_api_call("/data/psi/getPsiTaskList")

if response.text:
    result = response.json()
    if result.get('code') == 0:
        tasks = result.get('result', {}).get('data', [])
        total = result.get('result', {}).get('total', 0)

        print(f"✅ PSI任务总数: {total}")

        if tasks:
            task_state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败", 4: "取消"}

            for i, task in enumerate(tasks, 1):
                state = task.get('taskState')
                state_name = task_state_map.get(state, '未知')

                print(f"\n{'='*70}")
                print(f"任务 {i}: {task.get('taskName')}")
                print(f"{'='*70}")
                print(f"   任务ID: {task.get('taskId')}")
                print(f"   任务标识: {task.get('taskIdName')}")
                print(f"   PSI ID: {task.get('dataPsiId')}")
                print(f"   状态: {state_name} (code: {state})")
                print(f"   创建时间: {task.get('createDate')}")
                print(f"   耗时: {task.get('consuming')}ms")
                print(f"   结果名称: {task.get('resultName')}")
                print(f"   发起方机构: {task.get('ownOrganId', 'N/A')}")
                print(f"   协作方机构: {task.get('otherOrganId')}")
                print(f"   协作方机构名: {task.get('otherOrganName')}")

                # 如果是最新的任务（任务ID=2），显示详细信息
                if task.get('taskId') == 2:
                    print(f"\n   📊 这是刚创建的两节点PSI任务:")
                    print(f"   - 机构A: API测试机构 (资源3: U001-U010)")
                    print(f"   - 机构B: PSI协作机构 (资源4: U005-U015)")
                    print(f"   - 预期交集: U005-U010 (6条)")

                    if state == 0:
                        print(f"\n   ⏳ 任务正在等待执行...")
                    elif state == 1:
                        print(f"\n   🔄 任务正在执行中...")
                    elif state == 2:
                        print(f"\n   ✅ 任务执行成功!")
                    elif state == 3:
                        print(f"\n   ❌ 任务执行失败")

# 查询数据库中的PSI任务
print(f"\n{'='*70}")
print("数据库查询")
print(f"{'='*70}")

import subprocess

result = subprocess.run(
    ['docker', 'exec', 'mysql', 'mysql', '-uroot', '-proot', 'privacy1', '-e',
     'SELECT task_id, task_id_name, task_state, ascription, create_date FROM data_psi_task ORDER BY task_id DESC LIMIT 3;'],
    capture_output=True, text=True
)

if result.returncode == 0 and result.stdout:
    print("\n✅ PSI任务表 (data_psi_task):")
    print(result.stdout)
else:
    print("\n⚠️  无法查询数据库")

print("\n" + "=" * 70)
print("  状态分析")
print("=" * 70)

print("""
两节点PSI任务已成功创建！

任务配置:
- 机构A (API测试机构): 资源3 包含 U001-U010 (10条)
- 机构B (PSI协作机构): 资源4 包含 U005-U015 (11条)
- 匹配字段: user_id
- 预期交集: U005-U010 (6条记录)

如果任务状态为"待执行"或"失败":
可能原因:
1. 单节点环境 - PSI需要多个独立的计算节点
2. 节点通信 - 需要配置节点间的gRPC通信
3. 资源权限 - 需要配置资源的访问权限

在真实的多节点环境中:
- 每个机构运行在独立的节点上
- 节点间通过gRPC进行安全通信
- PSI计算在节点间协同完成
""")

print("=" * 70)
