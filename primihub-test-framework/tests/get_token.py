#!/usr/bin/env python3
"""
Token管理工具
- 验证已有token
- 测试token有效性
- 刷新token（如果支持）
"""

import sys
import os
import json
import requests
import time
from datetime import datetime

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient


def test_token(node_url: str, token: str, node_name: str = ""):
    """
    测试token是否有效

    Args:
        node_url: 节点URL
        token: 要测试的token
        node_name: 节点名称

    Returns:
        (is_valid, user_info) - token是否有效和用户信息
    """

    display_name = node_name if node_name else node_url

    print(f"\n{'='*70}")
    print(f"  测试 {display_name} 的Token")
    print(f"{'='*70}")
    print(f"节点地址: {node_url}")
    print(f"Token: {token[:50]}..." if len(token) > 50 else f"Token: {token}")

    try:
        client = PrimiHubAPIClient(node_url)
        client.token = token

        # 测试token - 调用一个简单的API
        response = client.get_user_list(page=1, page_size=1)

        if response.get('code') == 0:
            print(f"\n✅ Token有效!")

            # 尝试获取用户信息
            user_info = {
                'valid': True,
                'url': node_url,
                'token': token,
                'tested_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

            # 如果响应中有用户信息，提取出来
            if response.get('result'):
                result = response['result']
                if isinstance(result, dict):
                    user_info['user_data'] = result

            print(f"   测试时间: {user_info['tested_at']}")

            return True, user_info
        else:
            print(f"\n❌ Token无效或已过期")
            print(f"   错误信息: {response.get('msg')}")
            print(f"   错误代码: {response.get('code')}")

            return False, None

    except requests.exceptions.ConnectionError:
        print(f"\n❌ 连接失败: 无法连接到 {node_url}")
        return False, None
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False, None


def print_help():
    """打印帮助信息"""
    print("""
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║                    PrimiHub Token 管理工具                    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

⚠️  重要说明
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

由于PrimiHub的安全设计,/sys/user/getPubKey 接口需要token认证,
这导致无法直接通过API从零开始获取token。

因此,你需要 **首次从浏览器获取token**,之后就可以一直使用API了。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📖 如何从浏览器获取Token
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 打开浏览器访问节点地址并登录
   Node0: http://172.20.0.12:8080  (admin/123456)
   Node1: http://172.20.0.2:8080   (admin/123456)

2. 按 F12 打开开发者工具

3. 切换到 Network(网络) 标签

4. 刷新页面或点击任意菜单

5. 点击任意API请求(如 getOrganList)

6. 在右侧 Headers → Request Headers 中找到 token 字段

7. 复制完整的token值

详细步骤请查看: 如何获取Token.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 本工具用法
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 测试单个token是否有效:
   python3 get_token.py test <url> <token>

   示例:
   python3 get_token.py test http://172.20.0.12:8080 "eyJhbG..."

2. 测试多个节点的token:
   python3 get_token.py test-all

   (需要先在脚本中配置各节点的token)

3. 保存token到配置文件:
   python3 get_token.py save <node_name> <token>

   示例:
   python3 get_token.py save node0 "eyJhbG..."

4. 从配置文件读取token:
   python3 get_token.py load <node_name>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 快速开始
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

步骤1: 从浏览器获取node0和node1的token(参考上面的说明)

步骤2: 测试token是否有效
  python3 get_token.py test http://172.20.0.12:8080 "你的token"

步骤3: 将token填入测试脚本使用
  vim suites/03_project_task/test_with_token.py
  # 修改 USER_TOKEN = "你的token"

步骤4: 或者用于创建资源
  python3 create_resources_interactive.py
  # 按提示粘贴token

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")


def main():
    """主函数"""

    if len(sys.argv) < 2 or sys.argv[1] in ['-h', '--help', 'help']:
        print_help()
        return

    command = sys.argv[1].lower()

    if command == 'test':
        # 测试单个token
        if len(sys.argv) < 4:
            print("❌ 参数不足")
            print("\n用法: python3 get_token.py test <url> <token>")
            print("\n示例: python3 get_token.py test http://172.20.0.12:8080 \"eyJhbG...\"")
            return

        node_url = sys.argv[2]
        token = sys.argv[3]

        is_valid, user_info = test_token(node_url, token)

        if is_valid:
            print("\n" + "="*70)
            print("  Token验证成功")
            print("="*70)
            print("\n✅ 这个token可以正常使用!")
            print(f"\n你可以将它填入测试脚本:")
            print(f"  USER_TOKEN = \"{token}\"")
            print(f"\n或者用于API调用:")
            print(f"  client = PrimiHubAPIClient(\"{node_url}\")")
            print(f"  client.token = \"{token}\"")
            print()
        else:
            print("\n" + "="*70)
            print("  Token验证失败")
            print("="*70)
            print("\n❌ 这个token无法使用,请重新从浏览器获取")
            print("\n查看获取方法:")
            print("  cat 如何获取Token.md")
            print()

    elif command == 'test-all':
        # 测试预配置的所有节点
        print("\n" + "="*70)
        print("  测试所有节点的Token")
        print("="*70)
        print("\n⚠️  请先编辑脚本,在 tokens 字典中配置各节点的token")
        print("\n示例:")
        print("  tokens = {")
        print("      'node0': {'url': 'http://172.20.0.12:8080', 'token': '你的token'},")
        print("      'node1': {'url': 'http://172.20.0.2:8080', 'token': '你的token'}")
        print("  }")
        print()

        # 这里可以配置你的tokens
        tokens = {
            # 'node0': {'url': 'http://172.20.0.12:8080', 'token': ''},
            # 'node1': {'url': 'http://172.20.0.2:8080', 'token': ''}
        }

        if not tokens or all(not v.get('token') for v in tokens.values()):
            print("❌ 未配置任何token")
            return

        results = {}
        for node_name, config in tokens.items():
            if config.get('token'):
                is_valid, user_info = test_token(
                    config['url'],
                    config['token'],
                    node_name
                )
                results[node_name] = is_valid

        # 总结
        print("\n" + "="*70)
        print("  测试结果总结")
        print("="*70)

        valid_count = sum(1 for v in results.values() if v)
        total_count = len(results)

        print(f"\n总共测试: {total_count} 个节点")
        print(f"有效token: {valid_count} 个")
        print(f"无效token: {total_count - valid_count} 个")

        for node_name, is_valid in results.items():
            status = "✅ 有效" if is_valid else "❌ 无效"
            print(f"  {node_name}: {status}")

        print()

    elif command == 'save':
        # 保存token到文件
        if len(sys.argv) < 4:
            print("❌ 参数不足")
            print("\n用法: python3 get_token.py save <node_name> <token>")
            return

        node_name = sys.argv[2]
        token = sys.argv[3]

        config_file = "tokens.json"

        # 读取现有配置
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            config = {}

        # 保存token
        config[node_name] = {
            'token': token,
            'saved_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)

        print(f"\n✅ Token已保存到 {config_file}")
        print(f"   节点: {node_name}")
        print(f"   时间: {config[node_name]['saved_at']}")
        print()

    elif command == 'load':
        # 从文件加载token
        if len(sys.argv) < 3:
            print("❌ 参数不足")
            print("\n用法: python3 get_token.py load <node_name>")
            return

        node_name = sys.argv[2]
        config_file = "tokens.json"

        if not os.path.exists(config_file):
            print(f"❌ 配置文件不存在: {config_file}")
            return

        with open(config_file, 'r') as f:
            config = json.load(f)

        if node_name not in config:
            print(f"❌ 未找到节点: {node_name}")
            print(f"\n可用的节点:")
            for name in config.keys():
                print(f"  - {name}")
            return

        token_info = config[node_name]
        print(f"\n节点: {node_name}")
        print(f"Token: {token_info['token']}")
        print(f"保存时间: {token_info.get('saved_at', '未知')}")
        print()

    else:
        print(f"❌ 未知命令: {command}")
        print("\n运行 'python3 get_token.py help' 查看用法")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
