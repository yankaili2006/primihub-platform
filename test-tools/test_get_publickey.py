#!/usr/bin/env python3
import requests
import json
import time

# 登录
login_url = "http://100.64.0.23:30811/prod-api/user/login"
login_data = {
    "userAccount": "admin",
    "userPassword": "123456",
    "timestamp": int(time.time() * 1000),
    "nonce": 123
}

response = requests.post(login_url, data=login_data)
result = response.json()

if result.get('code') == 0:
    token = result['result']['token']
    user_id = result['result']['sysUser']['userId']
    print(f"✓ 登录成功, Token: {token[:30]}...")
    
    # 查询本地机构信息（包含公钥）
    for port in [30811, 30812, 30813]:
        organ_url = f"http://100.64.0.23:{port}/prod-api/sys/organ/getLocalOrganInfo"
        params = {
            "token": token,
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }
        headers = {"userId": str(user_id)}
        
        response = requests.get(organ_url, params=params, headers=headers)
        data = response.json()
        
        print(f"\n{'='*70}")
        print(f"节点端口: {port}")
        print(f"{'='*70}")
        
        if data.get('code') == 0:
            organ_info = data.get('result', {}).get('sysLocalOrganInfo', {})
            print(f"机构ID: {organ_info.get('organId', 'N/A')}")
            print(f"机构名称: {organ_info.get('organName', 'N/A')}")
            print(f"网关地址: {organ_info.get('organGateway', 'N/A')}")
            
            public_key = organ_info.get('publicKey')
            if public_key:
                print(f"公钥 (前100字符): {public_key[:100]}...")
                print(f"公钥长度: {len(public_key)} 字符")
            else:
                print("公钥: NULL 或不存在")
        else:
            print(f"✗ API调用失败: {data.get('msg', '未知错误')}")
else:
    print(f"✗ 登录失败: {result.get('msg', '未知错误')}")
