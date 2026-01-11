#!/usr/bin/env python3
"""
为你的系统定制的资源创建工具
基于你的Token和API路径
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


def get_resource_list():
    """获取资源列表"""
    print("="*70)
    print("  查看现有资源")
    print("="*70)

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    url = f'{BASE_URL}/data/fusionResource/getResourceList'
    params = {
        'pageNo': 1,
        'pageSize': 20,
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

            print(f"\n✅ 系统中共有 {total} 个资源\n")

            if resources:
                for i, res in enumerate(resources, 1):
                    print(f"{i}. {res.get('resourceName')}")
                    print(f"   ID: {res.get('resourceId')}")
                    print(f"   来源: {res.get('resourceSource')}")
                    print(f"   行数: {res.get('resourceRowsCount', 0):,}")
                    print()
            else:
                print("⚠️  还没有资源，可以创建新资源\n")

            return total, resources
        else:
            print(f"❌ 获取失败: {result.get('msg')}\n")
            return 0, []

    except Exception as e:
        print(f"❌ 错误: {e}\n")
        return 0, []


def test_create_api():
    """测试创建资源API的不同格式"""
    print("="*70)
    print("  测试创建资源API")
    print("="*70)
    print("""
由于我无法找到正确的创建资源API格式，建议：

方法1（推荐）：使用Web界面创建
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. 浏览器访问: http://100.64.0.23:30811
  2. 登录后进入数据资源管理
  3. 点击"创建资源"或"添加资源"
  4. 填写资源信息并保存
  5. 创建成功后，运行此脚本查看资源列表

方法2：获取实际的API格式
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. 在Web界面中创建一个资源
  2. 同时打开浏览器开发者工具(F12)
  3. 切换到Network标签
  4. 创建资源时，找到创建请求
  5. 复制Request URL和Request Payload
  6. 将这些信息提供给我，我会更新脚本

示例：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Request URL:
  http://100.64.0.23:30811/prod-api/data/xxx/saveResource

  Request Payload:
  {
    "resourceName": "...",
    "resourceDesc": "...",
    ...
  }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")


def main():
    """主函数"""

    print("\n" + "="*70)
    print("  PrimiHub 资源管理工具")
    print(f"  节点: {BASE_URL}")
    print("="*70 + "\n")

    if len(sys.argv) > 1:
        command = sys.argv[1].lower()

        if command == 'list':
            # 查看资源列表
            get_resource_list()

        elif command == 'test':
            # 测试创建API
            test_create_api()

        elif command == 'help':
            print("""
使用方法:

  python3 your_system_tool.py list    # 查看资源列表
  python3 your_system_tool.py test    # 查看创建资源的建议
  python3 your_system_tool.py help    # 显示帮助

示例:
  python3 your_system_tool.py list
            """)

        else:
            print(f"未知命令: {command}")
            print("运行 'python3 your_system_tool.py help' 查看帮助")

    else:
        # 默认：查看资源列表
        total, resources = get_resource_list()

        if total == 0:
            print("="*70)
            print("  下一步建议")
            print("="*70)
            print("""
由于系统中还没有资源，建议：

1. 在Web界面中创建资源:
   浏览器访问 http://100.64.0.23:30811

2. 或者提供创建资源的API格式:
   python3 your_system_tool.py test
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
