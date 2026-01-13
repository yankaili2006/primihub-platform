#!/usr/bin/env python3
"""
完整登录流程：获取公钥 → 加密密码 → 登录获取Token
由于getPubKey需要token，这个脚本仅在getPubKey不需要认证时可用
"""

import sys
import os
import json
import base64
import requests
import time
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5


def rsa_encrypt(public_key_str: str, plain_text: str) -> str:
    """使用RSA公钥加密字符串"""
    public_key_pem = f"-----BEGIN PUBLIC KEY-----\n{public_key_str}\n-----END PUBLIC KEY-----"
    rsa_key = RSA.importKey(public_key_pem)
    cipher = PKCS1_v1_5.new(rsa_key)
    encrypted = cipher.encrypt(plain_text.encode('utf-8'))
    encrypted_b64 = base64.b64encode(encrypted).decode('utf-8')
    return encrypted_b64


def get_pubkey_no_auth(node_url: str):
    """
    尝试不带认证获取公钥（可能失败）
    """
    print(f"\n▶ 尝试获取公钥...")

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    pubkey_url = f"{node_url}/sys/user/getPubKey"
    params = {
        'timestamp': timestamp,
        'nonce': nonce
    }

    try:
        response = requests.get(pubkey_url, params=params, timeout=10)
        result = response.json()

        if result.get('code') == 0:
            pubkey = result.get('result', {}).get('pubKey')
            validate_key_name = result.get('result', {}).get('validateKeyName')

            if pubkey and validate_key_name:
                print(f"✅ 获取公钥成功!")
                print(f"   validateKeyName: {validate_key_name}")
                return pubkey, validate_key_name

        print(f"❌ 获取公钥失败: {result.get('msg')}")
        return None, None

    except Exception as e:
        print(f"❌ 获取公钥异常: {e}")
        return None, None


def login_and_get_token(node_url: str, username: str, password: str):
    """
    完整登录流程
    """
    print(f"\n{'='*70}")
    print(f"  完整登录流程")
    print(f"{'='*70}")
    print(f"节点: {node_url}")
    print(f"用户: {username}")

    # 步骤1: 获取公钥
    public_key, validate_key_name = get_pubkey_no_auth(node_url)

    if not public_key or not validate_key_name:
        print("\n" + "⚠️ "*35)
        print("无法自动获取公钥（需要token认证）")
        print("\n请手动从浏览器获取公钥：")
        print("1. 打开浏览器开发者工具(F12)")
        print("2. 切换到Console标签")
        print("3. 粘贴以下代码并回车：")
        print(f"""
fetch('{node_url}/sys/user/getPubKey?timestamp='+Date.now()+'&nonce=1')
  .then(r => r.json())
  .then(d => console.log(JSON.stringify(d.result, null, 2)))
        """)
        print("4. 复制输出的JSON")
        print("5. 将JSON保存为 pubkey.json")
        print("6. 运行: python3 login_with_pubkey.py pubkey.json")
        print("⚠️ "*35)
        return None

    # 步骤2: 加密密码
    print(f"\n▶ 加密密码...")
    try:
        encrypted_password = rsa_encrypt(public_key, password)
        print(f"✅ 密码加密成功")
    except Exception as e:
        print(f"❌ 密码加密失败: {e}")
        return None

    # 步骤3: 登录
    print(f"\n▶ 登录获取token...")

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    login_url = f"{node_url}/sys/user/login"
    login_data = {
        'userAccount': username,
        'userPassword': encrypted_password,
        'validateKeyName': validate_key_name,
        'timestamp': timestamp,
        'nonce': nonce
    }

    headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
    }

    try:
        response = requests.post(login_url, data=login_data, headers=headers, timeout=10)
        login_result = response.json()

        if login_result.get('code') != 0:
            print(f"❌ 登录失败: {login_result.get('msg')}")
            return None

        token = login_result.get('result', {}).get('token')
        user_name = login_result.get('result', {}).get('userName')

        if token:
            print(f"✅ 登录成功!")
            print(f"   用户: {user_name}")
            print(f"   Token: {token[:50]}...")
            return token
        else:
            print(f"❌ 响应中没有token")
            return None

    except Exception as e:
        print(f"❌ 登录异常: {e}")
        return None


def main():
    print("\n" + "="*70)
    print("  PrimiHub 自动登录获取Token")
    print("="*70)

    # 配置
    node_url = "http://172.20.0.12:8080"
    username = "admin"
    password = "123456"

    # 尝试自动登录
    token = login_and_get_token(node_url, username, password)

    if token:
        print("\n" + "="*70)
        print("  Token获取成功")
        print("="*70)
        print(f"\n✅ 完整Token:")
        print(token)

        # 保存token
        output_file = f"token_{int(time.time())}.txt"
        with open(output_file, 'w') as f:
            f.write(token)

        print(f"\n📄 Token已保存到: {output_file}")

        print(f"\n【使用方法】")
        print(f"1. 测试脚本: vim suites/03_project_task/test_with_token.py")
        print(f"2. 创建资源: python3 create_resources_interactive.py")
        print(f"3. 保存配置: python3 get_token.py save node0 \"{token}\"")

        print("\n" + "="*70 + "\n")
    else:
        print("\n" + "="*70)
        print("  自动获取失败")
        print("="*70)
        print("\n由于PrimiHub的安全设计，getPubKey接口需要token认证。")
        print("请使用以下方法之一获取token：")
        print("\n【方法1】从浏览器直接获取token（推荐）")
        print("  详见: 如何获取Token.md")
        print("\n【方法2】从浏览器获取公钥后登录")
        print("  1. 浏览器访问: http://172.20.0.12:8080")
        print("  2. 按F12 → Console")
        print("  3. 运行以下代码：")
        print("""
fetch('http://172.20.0.12:8080/sys/user/getPubKey?timestamp='+Date.now()+'&nonce=1')
  .then(r => r.json())
  .then(d => {{
    console.log('公钥信息:');
    console.log(JSON.stringify(d.result, null, 2));
    // 立即使用此公钥登录
  }})
        """)
        print("  4. 复制输出并立即运行 login_with_pubkey.py")
        print("\n" + "="*70 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
