#!/usr/bin/env python3
"""
创建基于OT（不经意传输）算法的PSI任务
"""
import requests
import time
import json
from datetime import datetime

BASE_URL = "http://172.20.0.6:8080"

def login():
    """登录获取token"""
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.post(f"{BASE_URL}/sys/user/login", data=data)
    result = response.json()
    if result.get('code') == 0:
        user_data = result['result']
        return user_data.get('token'), user_data.get('sysUser', {}).get('userId')
    return None, None

def create_psi_task(token, user_id):
    """创建基于KKRT(OT)算法的PSI任务"""
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    psi_params = {
        "taskName": f"PSI_KKRT不经意传输_{timestamp_str}",
        "taskDesc": "基于KKRT不经意传输(OT)算法的隐私集合求交",
        "projectId": "3",
        
        # 发起方（机构A）
        "ownOrganId": "000000000000000000000000test0001",
        "ownResourceId": "3",
        "ownKeyword": "user_id",
        
        # 协作方（机构B）
        "otherOrganId": "000000000000000000000000test0002",
        "otherResourceId": "4",
        "otherKeyword": "user_id",
        
        # TEE可信执行环境机构（使用发起方）
        "teeOrganId": "000000000000000000000000test0001",
        
        # 结果配置
        "resultName": f"psi_result_KKRT_OT_{timestamp_str}",
        "resultOrganIds": "000000000000000000000000test0001",
        "outputContent": "0",
        "outputNoRepeat": "1",
        "outputFilePathType": "0",
        
        # 用户信息
        "userId": str(user_id),
        
        # PSI算法类型: KKRT (OT)
        "tag": "0",
        "psiTag": "2",  # 2 = KKRT (不经意传输)
        
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }
    
    headers = {"token": token, "userId": str(user_id)}
    
    response = requests.post(
        f"{BASE_URL}/data/psi/saveDataPsi",
        params=psi_params,
        headers=headers
    )
    
    return response

print("=" * 80)
print("创建基于OT（不经意传输）算法的PSI任务")
print("=" * 80)

# 登录
print("\n【步骤1】登录系统")
token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)
print(f"✅ 登录成功 - 用户ID: {user_id}")

# 创建PSI任务
print("\n【步骤2】创建PSI任务")
print("算法类型: KKRT (Oblivious Transfer 不经意传输)")
print("算法特点: 基于OT协议，接收方无需透露其查询内容")
print("发起方: 机构A (test0001) - 资源3")
print("协作方: 机构B (test0002) - 资源4")
print("TEE机构: 机构A (test0001)")
print("匹配字段: user_id")

response = create_psi_task(token, user_id)

print(f"\nHTTP状态码: {response.status_code}")

if response.text:
    result = response.json()
    print("\nAPI响应:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    if result.get('code') == 0:
        psi_result = result.get('result', {})
        data_psi = psi_result.get('dataPsi', {})
        data_psi_task = psi_result.get('dataPsiTask', {})
        
        print("\n" + "=" * 80)
        print("🎉 PSI任务创建成功!")
        print("=" * 80)
        print(f"算法类型: KKRT (不经意传输 - OT)")
        print(f"PSI ID: {data_psi.get('id')}")
        print(f"任务ID: {data_psi_task.get('taskId')}")
        print(f"任务内部ID: {data_psi_task.get('taskIdName')}")
        print(f"任务状态: {data_psi_task.get('taskState')} (0=待执行)")
        print(f"结果名称: {data_psi.get('resultName')}")
        print(f"发起方资源: 机构A用户数据 (ID: 3)")
        print(f"协作方资源: 机构B用户数据 (ID: 4)")
        print("=" * 80)
    else:
        print(f"\n❌ PSI任务创建失败: {result.get('msg')}")
        print(f"错误码: {result.get('code')}")
else:
    print("❌ 无响应内容")

print("\n")
