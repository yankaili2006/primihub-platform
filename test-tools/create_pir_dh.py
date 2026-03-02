#!/usr/bin/env python3
"""
创建基于DH（密钥交换）算法的实时联邦查询（PIR）任务
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
    response = requests.post(f"{BASE_URL}/user/login", data=data)
    result = response.json()
    if result.get('code') == 0:
        user_data = result['result']
        return user_data.get('token'), user_data.get('sysUser', {}).get('userId')
    return None, None

def create_pir_task(token, user_id, resource_id, pir_param, task_name):
    """创建PIR任务"""
    params = {
        "resourceId": resource_id,
        "pirParam": pir_param,
        "taskName": task_name,
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }

    headers = {"token": token, "userId": str(user_id)}

    response = requests.post(
        f"{BASE_URL}/data/pir/pirSubmitTask",
        params=params,
        headers=headers
    )

    return response

print("=" * 80)
print("创建基于DH（密钥交换）算法的实时联邦查询（PIR）任务")
print("=" * 80)

# 登录
print("\n【步骤1】登录系统")
token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)
print(f"✅ 登录成功 - 用户ID: {user_id}")

# 创建PIR任务
print("\n【步骤2】创建PIR任务")
timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

print("算法类型: DH (Diffie-Hellman 密钥交换)")
print("目标资源: PIR测试资源_SQL插入")
print("资源ID: demo0org0001a1b2c3d4e5f6g7h8")
print("查询条件: user_id=U001")

# PIR参数：查询user_id为U001的记录
pir_param = json.dumps({
    "algorithm": "DH",
    "query_field": "user_id",
    "query_value": "U001"
})

task_name = f"PIR_DH密钥交换_{timestamp_str}"

response = create_pir_task(token, user_id, "demo0org0001a1b2c3d4e5f6g7h8", pir_param, task_name)

print(f"\nHTTP状态码: {response.status_code}")

if response.text:
    try:
        result = response.json()
        print("\nAPI响应:")
        print(json.dumps(result, indent=2, ensure_ascii=False))

        if result.get('code') == 0:
            task_result = result.get('result', {})
            print("\n" + "=" * 80)
            print("🎉 PIR任务创建成功!")
            print("=" * 80)
            print(f"算法类型: DH (密钥交换)")
            print(f"任务名称: {task_name}")
            print(f"资源ID: 3")
            print(f"查询条件: user_id=U001")
            if isinstance(task_result, dict):
                print(f"任务ID: {task_result.get('taskId', 'N/A')}")
            print("=" * 80)
        else:
            print(f"\n⚠️  PIR任务创建失败: {result.get('msg')}")
    except Exception as e:
        print(f"\n响应内容: {response.text[:500]}")
        print(f"解析错误: {str(e)}")

print("\n")
