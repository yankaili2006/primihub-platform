#!/usr/bin/env python3
"""
使用数据库连接方式创建资源 (resourceSource=2)
不需要预先上传文件
"""

import sys
import os
import json
import time
import requests
from datetime import datetime

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

# 你的配置
BASE_URL = "http://100.64.0.23:30811/prod-api"
TOKEN = "SU202601111503542F1167CD6FFFD38A270C80D9D96A928C"
USER_ID = 1  # 默认admin用户ID


def create_resource_via_database():
    """
    使用数据库连接方式创建资源

    resourceSource=2 不需要fileId，而是需要dataSource对象
    """

    print("="*70)
    print("  使用数据库连接方式创建资源")
    print("="*70)

    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

    # 准备资源数据 - 使用数据库连接方式
    resource_data = {
        "resourceName": f"用户特征数据_{timestamp_str}",
        "resourceDesc": "用户基本信息和行为特征数据集",
        "resourceAuthType": 1,  # 1=公开
        "resourceSource": 2,    # 2=数据库链接
        "tags": ["测试数据", "用户特征"],
        "fieldList": [
            {
                "fieldName": "user_id",
                "fieldType": "string",
                "fieldDesc": "用户ID",
                "relevance": 1,
                "grouping": 0,
                "protectionStatus": 0
            },
            {
                "fieldName": "age",
                "fieldType": "int",
                "fieldDesc": "年龄",
                "relevance": 0,
                "grouping": 0,
                "protectionStatus": 0
            },
            {
                "fieldName": "gender",
                "fieldType": "int",
                "fieldDesc": "性别(0:女,1:男)",
                "relevance": 0,
                "grouping": 1,
                "protectionStatus": 0
            },
            {
                "fieldName": "city",
                "fieldType": "string",
                "fieldDesc": "城市",
                "relevance": 0,
                "grouping": 1,
                "protectionStatus": 0
            },
            {
                "fieldName": "income",
                "fieldType": "float",
                "fieldDesc": "收入",
                "relevance": 0,
                "grouping": 0,
                "protectionStatus": 1
            },
            {
                "fieldName": "education",
                "fieldType": "int",
                "fieldDesc": "学历(1-5)",
                "relevance": 0,
                "grouping": 0,
                "protectionStatus": 0
            }
        ],
        # 数据库连接配置
        "dataSource": {
            "dbType": "mysql",
            "dbDriver": "com.mysql.jdbc.Driver",
            "dbUrl": "jdbc:mysql://localhost:3306/test_db",
            "dbName": "test_db",
            "dbTableName": "user_features",
            "dbUserName": "root",
            "dbPassword": "password"
        }
    }

    # API URL
    url = f'{BASE_URL}/data/resource/saveorupdateresource'

    # 添加timestamp、nonce和token
    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1
    url = f'{url}?timestamp={timestamp}&nonce={nonce}&token={TOKEN}'

    # 在请求体中也包含这些参数
    resource_data['timestamp'] = timestamp
    resource_data['nonce'] = nonce
    resource_data['token'] = TOKEN

    # Headers
    headers = {
        'Content-Type': 'application/json',
        'userId': str(USER_ID)
    }

    print(f"\nAPI URL: {url}")
    print(f"\nHeaders:")
    print(json.dumps(headers, indent=2))
    print(f"\n请求体:")
    print(json.dumps(resource_data, indent=2, ensure_ascii=False))

    try:
        print(f"\n▶ 发送创建请求...")
        start_time = time.time()

        response = requests.post(
            url,
            json=resource_data,
            headers=headers,
            timeout=30
        )

        duration = time.time() - start_time

        print(f"✅ 请求完成 (耗时: {duration:.2f}秒)")
        print(f"   状态码: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print(f"\n响应:")
            print(json.dumps(result, indent=2, ensure_ascii=False))

            if result.get('code') == 0:
                print(f"\n🎉 资源创建成功!")
                resource_id = result.get('result', {}).get('resourceId')
                if resource_id:
                    print(f"   资源ID: {resource_id}")
                print(f"   资源名称: {resource_data['resourceName']}")

                # 验证
                print(f"\n▶ 验证资源是否创建成功...")
                time.sleep(1)
                verify_resource_created()

                return True
            else:
                print(f"\n❌ 创建失败")
                print(f"   错误码: {result.get('code')}")
                print(f"   错误信息: {result.get('msg')}")
                return False
        else:
            print(f"\n❌ HTTP错误: {response.status_code}")
            print(f"   响应: {response.text}")
            return False

    except Exception as e:
        print(f"\n❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_resource_created():
    """验证资源是否创建成功"""

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    url = f'{BASE_URL}/data/fusionResource/getResourceList'
    params = {
        'pageNo': 1,
        'pageSize': 10,
        'resourceId': '',
        'resourceName': '',
        'tagName': '',
        'resourceSource': '',
        'organId': '',
        'fileContainsY': '',
        'timestamp': timestamp,
        'nonce': nonce,
        'token': TOKEN
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        result = response.json()

        if result.get('code') == 0:
            resource_result = result.get('result', {})
            total = resource_result.get('total', 0)
            resources = resource_result.get('data', [])

            print(f"✅ 验证成功! 系统中现在共有 {total} 个资源")

            if resources:
                print(f"\n   最新的资源:")
                for i, res in enumerate(resources[:3], 1):
                    print(f"   {i}. {res.get('resourceName')}")
                    print(f"      ID: {res.get('resourceId')}")
                    print(f"      来源: {res.get('resourceSource')}")
        else:
            print(f"⚠️  验证失败: {result.get('msg')}")

    except Exception as e:
        print(f"⚠️  验证异常: {e}")


def main():
    """主函数"""

    print("\n" + "="*70)
    print("  PrimiHub 资源创建工具 (数据库连接方式)")
    print(f"  节点: {BASE_URL}")
    print("="*70 + "\n")

    print("ℹ️  使用数据库连接方式 (resourceSource=2):")
    print("   - 不需要预先上传文件")
    print("   - 需要提供数据库连接信息")
    print()

    # 创建资源
    success = create_resource_via_database()

    if success:
        print("\n" + "="*70)
        print("  成功!")
        print("="*70)
        print("""
✅ 资源创建成功!

下一步你可以:
1. 查看更多资源:
   python3 your_system_tool.py list

2. 创建更多资源:
   再次运行此脚本

3. 在Web界面查看:
   http://100.64.0.23:30811
        """)
    else:
        print("\n" + "="*70)
        print("  创建失败")
        print("="*70)
        print("""
可能的原因:
1. 数据库连接信息不正确
2. 缺少必需字段
3. 权限不足

建议:
1. 检查上面的错误信息
2. 或使用Web界面创建资源
        """)

    print("="*70 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
