#!/usr/bin/env python3
"""
创建基于DH（密钥交换）算法的PSI任务
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

def create_psi_task(token, user_id, algorithm_type, psi_tag):
    """创建PSI任务
    algorithm_type: 0=DH, 1=ECDH, 2=KKRT(OT), 3=BC22(OT)
    psi_tag: PSI标签类型
    """
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    algorithm_names = {
        0: "DH密钥交换",
        1: "ECDH椭圆曲线",
        2: "KKRT不经意传输",
        3: "BC22不经意传输"
    }
    
    psi_params = {
        "taskName": f"PSI_{algorithm_names.get(algorithm_type, 'Unknown')}_{timestamp_str}",
        "taskDesc": f"基于{algorithm_names.get(algorithm_type)}算法的隐私集合求交",
        "projectId": "3",
        
        # 发起方（机构A）
        "ownOrganId": "000000000000000000000000test0001",
        "ownResourceId": "3",
        "ownKeyword": "user_id",
        
        # 协作方（机构B）
        "otherOrganId": "000000000000000000000000test0002",
        "otherResourceId": "4",
        "otherKeyword": "user_id",
        
        # 结果配置
        "resultName": f"psi_result_{algorithm_names.get(algorithm_type, 'unknown')}_{timestamp_str}",
        "resultOrganIds": "000000000000000000000000test0001",
        "outputContent": "0",
        "outputNoRepeat": "1",
        "outputFilePathType": "0",
        
        # 用户信息
        "userId": str(user_id),
        
        # PSI算法类型
        "tag": str(algorithm_type),
        "psiTag": str(psi_tag),
        
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
print("创建基于DH（密钥交换）算法的PSI任务")
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
print("算法类型: DH (Diffie-Hellman 密钥交换)")
print("发起方: 机构A (test0001) - 资源3")
print("协作方: 机构B (test0002) - 资源4")
print("匹配字段: user_id")

# psiTag: 0=DH, 1=ECDH, 2=KKRT, 3=BC22
response = create_psi_task(token, user_id, algorithm_type=0, psi_tag=0)

print(f"\nHTTP状态码: {response.status_code}")

if response.text:
    result = response.json()
    print("\nAPI响应:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    if result.get('code') == 0:
        psi_result = result.get('result', {})
        task_id = psi_result.get('taskId') or psi_result.get('id')
        
        print("\n" + "=" * 80)
        print("🎉 PSI任务创建成功!")
        print("=" * 80)
        print(f"算法类型: DH (密钥交换)")
        print(f"任务ID: {task_id}")
        print(f"发起方资源: 机构A用户数据 (ID: 3)")
        print(f"协作方资源: 机构B用户数据 (ID: 4)")
        print("=" * 80)
    else:
        print(f"\n❌ PSI任务创建失败: {result.get('msg')}")
        print(f"错误码: {result.get('code')}")
else:
    print("❌ 无响应内容")

print("\n")
