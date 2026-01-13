#!/usr/bin/env python3
"""
测试资源创建API - 验证Gateway修复
使用方法: python3 test_resource_api.py <your_token>
"""

import sys
import json
import time
import requests
from datetime import datetime

BASE_URL = "http://100.64.0.23:30811/prod-api"

def test_resource_creation(token):
    """测试资源创建API"""

    print("="*70)
    print("  测试资源创建API (验证Gateway JSON解析修复)")
    print("="*70)

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    # 构造资源数据
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    resource_data = {
        'resourceName': f'测试资源_{timestamp_str}',
        'resourceDesc': '验证Gateway修复后的资源创建',
        'resourceAuthType': 1,
        'resourceSource': 1,
        'tags': ['测试', 'Gateway修复'],
        'fileId': 4,  # 使用已存在的文件ID
        'fieldList': [
            {
                'fieldName': 'id',
                'fieldType': 'String',
                'fieldDesc': 'ID',
                'relevance': 1,
                'grouping': 0,
                'protectionStatus': 0
            },
            {
                'fieldName': 'value',
                'fieldType': 'Integer',
                'fieldDesc': '数值',
                'relevance': 0,
                'grouping': 0,
                'protectionStatus': 0
            }
        ],
        'fusionOrganList': [],
        'timestamp': timestamp,
        'nonce': nonce,
        'token': token
    }

    headers = {
        'Content-Type': 'application/json',
        'userId': '1'
    }

    url = f'{BASE_URL}/data/resource/saveorupdateresource'
    url += f'?timestamp={timestamp}&nonce={nonce}&token={token}'

    print(f"\n📤 发送请求:")
    print(f"   URL: {url}")
    print(f"   资源名称: {resource_data['resourceName']}")
    print(f"   字段数量: {len(resource_data['fieldList'])}")

    try:
        print("\n⏳ 正在发送请求...")
        response = requests.post(url, json=resource_data, headers=headers, timeout=30)

        print(f"\n📥 响应:")
        print(f"   状态码: {response.status_code}")

        result = response.json()
        print(f"\n   响应内容:")
        print(json.dumps(result, indent=2, ensure_ascii=False))

        # 分析结果
        print("\n" + "="*70)
        code = result.get('code')

        if code == 0:
            print("✅ 成功! 资源创建成功")
            resource_id = result.get('result', {}).get('resourceId')
            if resource_id:
                print(f"   资源ID: {resource_id}")
            print("\n🎉 Gateway JSON解析修复验证通过!")
            print("   Application → Gateway → Backend 通信正常 ✅")
            return True

        elif code == 102:
            print("❌ Token已失效")
            print("   请重新从浏览器获取token")
            return False

        elif code == -1:
            msg = result.get('msg', '')
            print(f"⚠️  请求失败: {msg}")
            if 'JSON' in msg or '解析' in msg:
                print("   可能是Gateway JSON解析问题")
            return False

        else:
            print(f"❌ 失败: {result.get('msg')}")
            return False

    except requests.exceptions.Timeout:
        print("\n❌ 请求超时")
        print("   可能是后端服务响应慢或网络问题")
        return False

    except Exception as e:
        print(f"\n❌ 请求异常: {e}")
        return False

    finally:
        print("="*70)


def main():
    print("\n" + "="*70)
    print("  PrimiHub 资源创建API测试")
    print("="*70)

    if len(sys.argv) < 2:
        print("\n使用方法:")
        print(f"  python3 {sys.argv[0]} <token>")
        print("\n获取Token:")
        print("  1. 浏览器访问: http://100.64.0.23:30811")
        print("  2. 登录 (admin / 123456)")
        print("  3. 按F12打开开发者工具 → Console")
        print("  4. 运行: localStorage.getItem('token')")
        print("  5. 复制token (去掉引号)")
        print(f"  6. 运行: python3 {sys.argv[0]} <复制的token>")
        print("\n" + "="*70 + "\n")
        sys.exit(1)

    token = sys.argv[1]
    print(f"\n使用Token: {token[:20]}...{token[-10:]}")

    success = test_resource_creation(token)

    if success:
        print("\n✅ 测试通过!")
    else:
        print("\n❌ 测试失败")

    print()


if __name__ == "__main__":
    main()
