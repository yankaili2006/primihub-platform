#!/usr/bin/env python3
"""
测试 PrimiHub 用户列表 API 接口
完整测试流程：登录 -> 获取用户列表
"""

import requests
import json
import time
from datetime import datetime

# 颜色输出
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*70}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*70}{Colors.ENDC}\n")

def print_success(text):
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")

def print_warning(text):
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

def test_with_gateway(base_url):
    """测试使用 Gateway 地址"""
    print_header(f"测试服务器: {base_url}")

    # 1. 测试登录
    print_info("步骤 1/3: 测试登录接口")
    login_url = f"{base_url}/user/login"
    login_data = {
        "userAccount": "admin",
        "userPassword": "primihub123",
        "timestamp": int(time.time() * 1000),
        "nonce": int(time.time() * 1000) % 1000 + 1
    }

    try:
        login_response = requests.post(login_url, data=login_data, timeout=10)
        print(f"  HTTP状态码: {login_response.status_code}")

        if login_response.status_code == 200:
            login_result = login_response.json()
            print(f"  响应代码: {login_result.get('code')}")
            print(f"  响应消息: {login_result.get('msg')}")

            if login_result.get('code') == 0:
                print_success("登录成功")
                token = login_result.get('result', {}).get('token')
                user_id = login_result.get('result', {}).get('sysUser', {}).get('userId')
                print(f"  Token: {token[:30]}..." if token else "  Token: None")
                print(f"  用户ID: {user_id}")

                # 2. 测试获取用户列表
                print_info("\n步骤 2/3: 测试获取用户列表接口")
                user_list_url = f"{base_url}/sys/user/getUserList"
                user_list_params = {
                    "pageNo": 1,
                    "pageSize": 10,
                    "token": token,
                    "timestamp": int(time.time() * 1000),
                    "nonce": int(time.time() * 1000) % 1000 + 1
                }
                headers = {
                    "userId": str(user_id)
                }

                user_response = requests.get(user_list_url, params=user_list_params,
                                            headers=headers, timeout=10)
                print(f"  HTTP状态码: {user_response.status_code}")

                if user_response.status_code == 200:
                    user_result = user_response.json()
                    print(f"  响应代码: {user_result.get('code')}")
                    print(f"  响应消息: {user_result.get('msg')}")

                    if user_result.get('code') == 0:
                        print_success("获取用户列表成功")

                        users = user_result.get('result', {}).get('data', [])
                        total = user_result.get('result', {}).get('total', 0)

                        print(f"\n  找到 {total} 个用户:")
                        print(f"  {'用户ID':<10} {'账号':<20} {'用户名':<20} {'角色':<10} {'状态':<10}")
                        print(f"  {'-'*70}")

                        for user in users:
                            user_id_str = str(user.get('userId', 'N/A'))
                            account = user.get('userAccount', 'N/A')
                            name = user.get('userName', 'N/A')
                            role = user.get('roleIdList', 'N/A')
                            is_forbid = user.get('isForbid', 0)
                            status = "禁用" if is_forbid == 1 else "正常"
                            print(f"  {user_id_str:<10} {account:<20} {name:<20} {role:<10} {status:<10}")

                        return True
                    else:
                        print_error(f"获取用户列表失败: {user_result.get('msg')}")
                        print(f"  完整响应: {json.dumps(user_result, indent=2, ensure_ascii=False)}")
                else:
                    print_error(f"HTTP请求失败: {user_response.status_code}")
                    print(f"  响应内容: {user_response.text[:500]}")

            else:
                print_error(f"登录失败: {login_result.get('msg')}")
                print(f"  完整响应: {json.dumps(login_result, indent=2, ensure_ascii=False)}")
        else:
            print_error(f"HTTP请求失败: {login_response.status_code}")
            print(f"  响应内容: {login_response.text[:500]}")

    except requests.exceptions.ConnectionError as e:
        print_error(f"连接失败: 无法连接到 {base_url}")
    except requests.exceptions.Timeout:
        print_error(f"请求超时: {base_url}")
    except Exception as e:
        print_error(f"请求异常: {str(e)}")

    return False

def test_all_servers():
    """测试所有服务器"""
    print_header("PrimiHub 用户列表 API 接口测试")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    servers = [
        ("机构0 - Docker内部Gateway", "http://172.19.0.14:8080"),
        ("机构0 - 外部访问", "http://10.12.0.12:30811/gateway"),
        ("机构1 - 外部访问", "http://10.12.0.12:30812/gateway"),
        ("机构2 - 外部访问", "http://10.12.0.12:30813/gateway"),
    ]

    results = {}

    for name, url in servers:
        success = test_with_gateway(url)
        results[name] = success
        if success:
            break  # 如果成功就不测试其他了

    # 汇总结果
    print_header("测试结果汇总")

    success_count = sum(1 for v in results.values() if v)
    fail_count = len(results) - success_count

    print(f"总测试数: {len(results)}")
    print(f"{Colors.OKGREEN}成功: {success_count}{Colors.ENDC}")
    print(f"{Colors.FAIL}失败: {fail_count}{Colors.ENDC}\n")

    print(f"{'服务器':<40} {'状态':<10}")
    print("-" * 50)
    for name, success in results.items():
        status = f"{Colors.OKGREEN}✓ 通过{Colors.ENDC}" if success else f"{Colors.FAIL}✗ 失败{Colors.ENDC}"
        print(f"{name:<40} {status}")

    print()

    if success_count == 0:
        print_warning("所有API测试失败，尝试数据库直接查询...")
        print("\n建议使用数据库查询脚本:")
        print("  bash query-users.sh")
        return False

    return True

def direct_database_query():
    """提示如何使用数据库直接查询"""
    print_header("数据库直接查询方法")

    print("由于API接口可能存在问题，您可以使用以下方法直接查询数据库:\n")

    print(f"{Colors.OKGREEN}方法 1: 使用查询脚本（推荐）{Colors.ENDC}")
    print("  bash query-users.sh\n")

    print(f"{Colors.OKGREEN}方法 2: 直接使用 MySQL 命令{Colors.ENDC}")
    print("  docker exec mysql mysql -uprimihub -pprimihub@123 privacy1 \\")
    print("    -e \"SELECT * FROM sys_user WHERE is_del=0;\"\n")

    print(f"{Colors.OKGREEN}方法 3: 查看文档{Colors.ENDC}")
    print("  cat QUERY_USERS_GUIDE.md\n")

if __name__ == "__main__":
    import sys

    # 允许指定服务器URL
    if len(sys.argv) > 1:
        custom_url = sys.argv[1]
        print_header("自定义服务器测试")
        test_with_gateway(custom_url)
    else:
        # 测试所有服务器
        success = test_all_servers()

        if not success:
            direct_database_query()
            sys.exit(1)
