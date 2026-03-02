#!/usr/bin/env python3
"""
查看PSI任务状态
"""
import requests
import time
import json

BASE_URL = "http://172.20.0.6:8080"

def login():
    """登录获取token"""
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.post(f"{BASE_URL}/user/login", data=data)
    result = response.json()
    if result.get('code') == 0:
        user_data = result['result']
        return user_data.get('token'), user_data.get('sysUser', {}).get('userId')
    return None, None

def check_psi_tasks(token, user_id):
    """查看PSI任务列表"""
    params = {
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    
    headers = {"token": token, "userId": str(user_id)}
    
    response = requests.get(
        f"{BASE_URL}/psi/getPsiTaskList",
        params=params,
        headers=headers
    )
    
    if response.status_code == 200:
        result = response.json()
        if result.get('code') == 0:
            return result.get('result', {})
    return None

print("=" * 80)
print("PSI任务状态查询")
print("=" * 80)

# 登录
token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)

print(f"\n✅ 登录成功 - 用户ID: {user_id}")

# 查询PSI任务
print("\n查询PSI任务列表...")
psi_data = check_psi_tasks(token, user_id)

if psi_data:
    psi_list = psi_data.get('list', []) if isinstance(psi_data, dict) else psi_data
    
    print(f"\n找到 {len(psi_list)} 个PSI任务\n")
    
    status_map = {
        0: "待执行",
        1: "执行中", 
        2: "成功",
        3: "失败"
    }
    
    algorithm_map = {
        0: "DH (密钥交换)",
        1: "ECDH (椭圆曲线)",
        2: "KKRT (不经意传输)",
        3: "BC22/HE (全同态加密)"
    }
    
    # 只显示最新创建的3个任务（ID 3, 4, 5）
    target_tasks = [t for t in psi_list if t.get('psiId') in [3, 4, 5]]
    
    if target_tasks:
        print("=" * 80)
        print("最新创建的PSI任务（DH、OT、HE算法）")
        print("=" * 80)
        
        for task in sorted(target_tasks, key=lambda x: x.get('psiId', 0)):
            psi_id = task.get('psiId')
            task_name = task.get('taskName', 'N/A')
            task_state = task.get('taskState', 0)
            tag = task.get('tag', 0)
            result_name = task.get('resultName', 'N/A')
            create_date = task.get('createDate', 'N/A')
            
            print(f"\n【PSI ID: {psi_id}】")
            print(f"任务名称: {task_name}")
            print(f"算法类型: {algorithm_map.get(tag, '未知')}")
            print(f"任务状态: {status_map.get(task_state, '未知')} ({task_state})")
            print(f"结果名称: {result_name}")
            print(f"创建时间: {create_date}")
            
            if task_state == 2:
                print("✅ 任务已完成！")
            elif task_state == 0:
                print("⏳ 任务待执行")
            elif task_state == 1:
                print("🔄 任务执行中...")
            elif task_state == 3:
                print("❌ 任务执行失败")
        
        print("\n" + "=" * 80)
    else:
        print("⚠️  未找到目标PSI任务（ID 3, 4, 5）")
else:
    print("❌ 获取PSI任务列表失败")

print("\n")
