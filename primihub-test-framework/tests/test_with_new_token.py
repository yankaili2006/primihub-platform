#!/usr/bin/env python3
"""
使用新Token测试资源创建API
修复配置后的最终测试
"""

import requests
import time
import json
from datetime import datetime

# ========== 配置区域 ==========
# 请从浏览器获取新的token后，粘贴到下面:
TOKEN = "YOUR_NEW_TOKEN_HERE"  # ← 在这里粘贴新token

BASE_URL = "http://100.64.0.23:30811/prod-api"
# =============================

def test_resource_creation():
    """测试资源创建"""
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

    # 最小化的资源数据
    resource_data = {
        'resourceName': f'用户特征数据_{timestamp_str}',
        'resourceDesc': '修复gRPC配置后的测试资源',
        'resourceAuthType': 1,
        'resourceSource': 1,
        'tags': ['测试', 'gRPC修复后'],
        'fileId': 4,  # 使用已上传的文件
        'fieldList': [
            {
                'fieldName': 'user_id',
                'fieldType': 'String',
                'fieldDesc': '用户ID',
                'relevance': 1,
                'grouping': 0,
                'protectionStatus': 0
            },
            {
                'fieldName': 'age',
                'fieldType': 'Integer',
                'fieldDesc': '年龄',
                'relevance': 0,
                'grouping': 0,
                'protectionStatus': 0
            },
            {
                'fieldName': 'score',
                'fieldType': 'Double',
                'fieldDesc': '评分',
                'relevance': 0,
                'grouping': 0,
                'protectionStatus': 0
            }
        ],
        'fusionOrganList': []
    }

    timestamp = int(time.time() * 1000)
    resource_data['timestamp'] = timestamp
    resource_data['nonce'] = timestamp % 1000 + 1
    resource_data['token'] = TOKEN

    headers = {'Content-Type': 'application/json', 'userId': '1'}
    url = f'{BASE_URL}/data/resource/saveorupdateresource'
    url += f'?timestamp={timestamp}&nonce={resource_data["nonce"]}&token={TOKEN}'

    print("="*70)
    print("  测试资源创建API (gRPC配置已修复)")
    print("="*70)
    print(f"\n发送请求到: {url}")
    print(f"\n资源名称: {resource_data['resourceName']}")
    print(f"文件ID: {resource_data['fileId']}")
    print(f"字段数量: {len(resource_data['fieldList'])}")

    try:
        print("\n⏳ 发送请求...")
        response = requests.post(url, json=resource_data, headers=headers, timeout=30)

        print(f"\n状态码: {response.status_code}")
        print(f"\n响应内容:")
        result = response.json()
        print(json.dumps(result, indent=2, ensure_ascii=False))

        # 分析结果
        print("\n" + "="*70)
        if result.get('code') == 0:
            print("✅ 资源创建成功!")
            resource_id = result.get('result', {}).get('resourceId')
            if resource_id:
                print(f"   资源ID: {resource_id}")
                print(f"\n🎉 恭喜！gRPC通信链已完全修复:")
                print(f"   Application → PrimiHub Node → Meta Service ✅")
        elif result.get('code') == 102:
            print("❌ Token已失效")
            print("   请从浏览器重新获取token并更新脚本")
        elif result.get('code') == -1:
            print("⚠️  请求异常")
            print("   说明: 可能仍然存在gRPC通信问题")
            print("   建议: 检查后端日志")
        else:
            print(f"❌ 失败: {result.get('msg')}")

        print("="*70)

        return result

    except Exception as e:
        print(f"\n❌ 请求失败: {e}")
        return None


def main():
    if TOKEN == "YOUR_NEW_TOKEN_HERE":
        print("\n" + "⚠️ "*35)
        print("请先从浏览器获取新的token!")
        print("\n步骤:")
        print("1. 访问 http://100.64.0.23:30811")
        print("2. 登录 (admin / 123456)")
        print("3. 按F12 → Console")
        print("4. 运行: localStorage.getItem('token')")
        print("5. 复制token（去掉引号）")
        print("6. 粘贴到本脚本第12行的TOKEN变量中")
        print("7. 重新运行此脚本")
        print("⚠️ "*35 + "\n")
        return

    test_resource_creation()


if __name__ == "__main__":
    main()
