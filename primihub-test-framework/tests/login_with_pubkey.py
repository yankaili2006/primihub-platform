#!/usr/bin/env python3
"""
使用公钥登录获取token
"""

import sys
import os
import json
import base64
import requests
import time
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))


def rsa_encrypt(public_key_str: str, plain_text: str) -> str:
    """
    使用RSA公钥加密字符串

    Args:
        public_key_str: Base64格式的公钥字符串
        plain_text: 要加密的明文

    Returns:
        Base64编码的加密结果
    """
    # 将Base64公钥转换为PEM格式
    public_key_pem = f"-----BEGIN PUBLIC KEY-----\n{public_key_str}\n-----END PUBLIC KEY-----"

    # 导入公钥
    rsa_key = RSA.importKey(public_key_pem)
    cipher = PKCS1_v1_5.new(rsa_key)

    # 加密
    encrypted = cipher.encrypt(plain_text.encode('utf-8'))

    # Base64编码
    encrypted_b64 = base64.b64encode(encrypted).decode('utf-8')

    return encrypted_b64


def login_with_pubkey(node_url: str, username: str, password: str,
                      public_key: str, validate_key_name: str):
    """
    使用公钥加密密码后登录

    Args:
        node_url: 节点URL
        username: 用户名
        password: 密码
        public_key: 公钥（Base64格式）
        validate_key_name: 公钥名称

    Returns:
        token字符串，失败返回None
    """

    print(f"\n{'='*70}")
    print(f"  使用公钥登录获取Token")
    print(f"{'='*70}")
    print(f"节点地址: {node_url}")
    print(f"用户名: {username}")
    print(f"密码: {'*' * len(password)}")
    print(f"公钥名称: {validate_key_name}")

    try:
        # 步骤1: 加密密码
        print(f"\n▶ 步骤1: 使用RSA加密密码...")

        try:
            encrypted_password = rsa_encrypt(public_key, password)
            print(f"✅ 密码加密成功")
            print(f"   加密结果长度: {len(encrypted_password)} 字符")
        except Exception as e:
            print(f"❌ 密码加密失败: {e}")
            import traceback
            traceback.print_exc()
            return None

        # 步骤2: 登录
        print(f"\n▶ 步骤2: 发送登录请求...")

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

        response = requests.post(login_url, data=login_data, headers=headers, timeout=10)
        login_result = response.json()

        if login_result.get('code') != 0:
            print(f"❌ 登录失败: {login_result.get('msg')}")
            print(f"响应: {json.dumps(login_result, indent=2, ensure_ascii=False)}")
            return None

        # 获取token
        result = login_result.get('result', {})
        token = result.get('token')
        user_id = result.get('userId')
        user_name = result.get('userName')

        if not token:
            print(f"❌ 登录响应中没有token")
            print(f"响应: {json.dumps(login_result, indent=2, ensure_ascii=False)}")
            return None

        print(f"✅ 登录成功!")
        print(f"   用户名: {user_name}")
        print(f"   用户ID: {user_id}")
        print(f"   Token: {token[:50]}..." if len(token) > 50 else f"   Token: {token}")

        return token

    except requests.exceptions.ConnectionError:
        print(f"❌ 连接失败: 无法连接到 {node_url}")
        return None
    except requests.exceptions.Timeout:
        print(f"❌ 请求超时: {node_url}")
        return None
    except Exception as e:
        print(f"❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
        return None


def main():
    """主函数"""

    print("\n" + "="*70)
    print("  PrimiHub 使用公钥登录获取Token")
    print("="*70)

    # 从命令行参数或默认值获取配置
    if len(sys.argv) >= 2:
        # 从JSON文件读取公钥信息
        pubkey_file = sys.argv[1]
        with open(pubkey_file, 'r') as f:
            pubkey_info = json.load(f)

        public_key = pubkey_info.get('publicKey')
        validate_key_name = pubkey_info.get('publicKeyName')
        node_url = pubkey_info.get('nodeUrl', 'http://172.20.0.12:8080')
        username = pubkey_info.get('username', 'admin')
        password = pubkey_info.get('password', '123456')
    else:
        # 使用你提供的公钥
        public_key = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCjYPvVwpFvU10w2+j4Xyg39NjnriMx9aIQb6VjZpeH4E6fyAwkZUApB0ReR6olNp4FJ5qrWeqP/8YS0BkCafJtA452IiiupleeR1OZUZKZPHDH2tVbpwKbjJY8BMAvpDJtF/zvZiI6RNphqoNKeojUwv2y/CRkn1aEU3MUz9IChwIDAQAB"
        validate_key_name = "RK20260111150354000001"
        node_url = "http://172.20.0.12:8080"
        username = "admin"
        password = "123456"

    print(f"\n使用以下配置:")
    print(f"  节点: {node_url}")
    print(f"  用户: {username}")
    print(f"  公钥名称: {validate_key_name}")

    # 登录获取token
    token = login_with_pubkey(node_url, username, password, public_key, validate_key_name)

    if token:
        print("\n" + "="*70)
        print("  获取Token成功")
        print("="*70)

        print(f"\n✅ Token获取成功!")
        print(f"\n【完整Token】")
        print(token)

        print(f"\n【使用方法】")
        print(f"\n1. 填入测试脚本:")
        print(f"   vim suites/03_project_task/test_with_token.py")
        print(f"   USER_TOKEN = \"{token}\"")

        print(f"\n2. 用于创建资源:")
        print(f"   python3 create_resources_interactive.py")
        print(f"   # 粘贴上面的token")

        print(f"\n3. 保存到配置文件:")
        print(f"   python3 get_token.py save node0 \"{token}\"")

        # 保存到文件
        output_file = f"token_{int(time.time())}.txt"
        with open(output_file, 'w') as f:
            f.write(token)

        print(f"\n📄 Token已保存到: {output_file}")

        print("\n" + "="*70)
        print()

    else:
        print("\n" + "="*70)
        print("  获取Token失败")
        print("="*70)
        print("\n❌ 无法获取token，请检查:")
        print("  1. 公钥是否正确")
        print("  2. 公钥名称(validateKeyName)是否正确")
        print("  3. 用户名和密码是否正确")
        print("  4. 节点服务是否正常运行")
        print("\n" + "="*70)
        print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
