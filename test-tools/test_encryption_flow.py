#!/usr/bin/env python3
"""
测试节点间加密解密流程
"""

import requests
import json
import base64
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5
import sys

def get_local_organ_info(port):
    """获取节点的本地机构信息"""
    url = f"http://100.64.0.23:{port}/prod-api/sys/organ/getLocalOrganInfo"
    response = requests.get(url, params={"token": "temp"}, timeout=10)
    result = response.json()
    if result.get('code') == 0:
        return result.get('result', {}).get('sysLocalOrganInfo', {})
    return None

def rsa_encrypt(plaintext, public_key_base64):
    """使用RSA公钥加密（分段加密，每段117字节）"""
    try:
        # 解码Base64公钥
        public_key_pem = base64.b64decode(public_key_base64).decode('utf-8')

        # 导入公钥
        public_key = RSA.import_key(public_key_pem)
        cipher = PKCS1_v1_5.new(public_key)

        # 将明文转换为字节
        plaintext_bytes = plaintext.encode('utf-8')

        # 分段加密（每段117字节）
        chunk_size = 117
        encrypted_chunks = []

        for i in range(0, len(plaintext_bytes), chunk_size):
            chunk = plaintext_bytes[i:i+chunk_size]
            encrypted_chunk = cipher.encrypt(chunk)
            encrypted_chunks.append(encrypted_chunk)

        # 合并所有加密块
        encrypted_data = b''.join(encrypted_chunks)

        # Base64编码
        return base64.b64encode(encrypted_data).decode('utf-8')
    except Exception as e:
        print(f"加密失败: {e}")
        return None

def test_encryption_flow():
    """测试完整的加密解密流程"""

    print("=" * 80)
    print("节点间加密解密流程测试")
    print("=" * 80)
    print()

    # 步骤1: 获取两个节点的信息
    print("[1/5] 获取节点信息...")
    node1_info = get_local_organ_info(30811)
    node2_info = get_local_organ_info(30812)

    if not node1_info or not node2_info:
        print("✗ 获取节点信息失败")
        return False

    print(f"✓ 节点30811: {node1_info['organId']}")
    print(f"  公钥前50字符: {node1_info['publicKey'][:50]}...")
    print(f"✓ 节点30812: {node2_info['organId']}")
    print(f"  公钥前50字符: {node2_info['publicKey'][:50]}...")
    print()

    # 步骤2: 准备要发送的数据
    print("[2/5] 准备测试数据...")
    test_data = {
        'organId': node1_info['organId'],
        'organName': node1_info['organName'],
        'gateway': node1_info['gatewayAddress'],
        'publicKey': node1_info['publicKey'],
        'applyId': 'test_encryption_' + str(int(requests.get('http://worldtimeapi.org/api/timezone/Etc/UTC').json()['unixtime']))
    }
    plaintext = json.dumps(test_data)
    print(f"✓ 数据长度: {len(plaintext)} 字节")
    print()

    # 步骤3: 使用节点2的公钥加密数据
    print("[3/5] 使用节点30812的公钥加密数据...")
    encrypted_data = rsa_encrypt(plaintext, node2_info['publicKey'])

    if not encrypted_data:
        print("✗ 加密失败")
        return False

    print(f"✓ 加密成功")
    print(f"  加密后长度: {len(encrypted_data)} 字符")
    print(f"  加密数据前100字符: {encrypted_data[:100]}...")
    print()

    # 步骤4: 发送加密数据到节点2（不使用ignore参数）
    print("[4/5] 发送加密数据到节点30812...")
    url = "http://100.64.0.23:30812/prod-api/shareData/apply"

    try:
        response = requests.post(
            url,
            json=encrypted_data,  # 直接发送加密字符串
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        result = response.json()

        print(f"响应状态码: {response.status_code}")
        print(f"响应内容: {json.dumps(result, indent=2, ensure_ascii=False)}")

        if result.get('code') == 0:
            print("✓ 解密成功！节点30812成功解密并处理了数据")
            print()
            return True
        else:
            print(f"✗ 请求失败: {result.get('msg')}")
            print()
            return False

    except Exception as e:
        print(f"✗ 请求异常: {e}")
        print()
        return False

    # 步骤5: 对比测试 - 不加密直接发送
    print("[5/5] 对比测试 - 不加密直接发送...")
    url_ignore = "http://100.64.0.23:30812/prod-api/shareData/apply?ignore=ignore"

    try:
        response = requests.post(
            url_ignore,
            json=test_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        result = response.json()

        print(f"响应状态码: {response.status_code}")
        print(f"响应内容: {json.dumps(result, indent=2, ensure_ascii=False)}")

        if result.get('code') == 0:
            print("✓ 不加密方式成功")
        else:
            print(f"✗ 不加密方式也失败: {result.get('msg')}")

    except Exception as e:
        print(f"✗ 请求异常: {e}")

if __name__ == "__main__":
    try:
        success = test_encryption_flow()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n程序异常: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
