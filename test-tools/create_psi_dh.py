#!/usr/bin/env python3
"""
创建基于DH（密钥交换）算法的PSI任务
"""
import requests
import time
import json
import os
import sys
import argparse
import ipaddress
from datetime import datetime
from urllib.parse import urlparse


def _make_session(base_url: str = '') -> requests.Session:
    """代理感知的 Session：私有/本地/Tailscale 地址强制直连"""
    _PRIVATE = ('localhost', '127.0.0.1', '::1',
                '172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/16', '100.64.0.0/10')
    session = requests.Session()
    try:
        host = urlparse(base_url).hostname or ''
        addr = ipaddress.ip_address(host)
        for cidr in ('172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/16', '100.64.0.0/10'):
            if addr in ipaddress.ip_network(cidr):
                session.trust_env = False
                return session
    except ValueError:
        pass
    if urlparse(base_url).hostname in ('localhost', '127.0.0.1', '::1'):
        session.trust_env = False
        return session
    # 外部地址使用系统代理，但补全私有网段 no_proxy
    existing = os.environ.get('no_proxy') or os.environ.get('NO_PROXY') or ''
    needed = [s for s in _PRIVATE if s not in existing]
    if needed:
        os.environ['no_proxy'] = ','.join(filter(None, [existing] + list(needed)))
    return session


_parser = argparse.ArgumentParser(description='创建DH PSI任务', add_help=False)
_parser.add_argument('--url', default=os.environ.get('PRIMIHUB_URL', 'http://172.23.0.15:8080'),
                     help='网关地址 (默认: http://172.23.0.15:8080，可用 PRIMIHUB_URL 环境变量覆盖)')
_args, _ = _parser.parse_known_args()

BASE_URL = _args.url

# 代理感知的全局 session（私有/Tailscale 地址强制直连）
_session = _make_session(BASE_URL)


def login():
    """登录获取token"""
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = _session.post(f"{BASE_URL}/user/login", data=data)
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
        
        # 发起方（机构0，node0上的psi_client_data）
        "ownOrganId": "550e8400-e29b-41d4-a716-446655440000",
        "ownResourceId": "10",
        "ownKeyword": "id",

        # 协作方（同机构，node1上的psi_server_data，触发本地查询路径）
        "otherOrganId": "550e8400-e29b-41d4-a716-446655440000",
        "otherResourceId": "11",
        "otherKeyword": "id",

        # 结果配置
        "resultName": f"psi_result_{algorithm_names.get(algorithm_type, 'unknown')}_{timestamp_str}",
        "resultOrganIds": "550e8400-e29b-41d4-a716-446655440000",
        "outputContent": "0",
        "outputNoRepeat": "1",
        "outputFilePathType": "0",
        
        # 用户信息
        "userId": str(user_id),
        
        # PSI算法类型
        # tag: 固定为"0"（库类型标识，由psiTag决定具体算法）
        # psiTag: 具体算法 0=DH, 1=ECDH, 2=KKRT, 3=BC22
        "tag": "0",
        "psiTag": str(psi_tag),
        
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }
    
    headers = {"token": token, "userId": str(user_id)}
    
    response = _session.post(
        f"{BASE_URL}/psi/saveDataPsi",
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
print("发起方: 机构0 (node0, psi_client_data) - 资源10")
print("协作方: 机构0 (node1, psi_server_data) - 资源11")
print("匹配字段: id")

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
        print(f"发起方资源: psi_client_data/node0 (ID: 10)")
        print(f"协作方资源: psi_server_data/node1 (ID: 11)")
        print("=" * 80)
    else:
        print(f"\n❌ PSI任务创建失败: {result.get('msg')}")
        print(f"错误码: {result.get('code')}")
else:
    print("❌ 无响应内容")

print("\n")
