#!/usr/bin/env python3
"""
联邦分析 API 访问测试脚本
通过 Python 模拟前端登录和访问流程
"""

import requests
import json
import time
import sys
from typing import Dict, Any, Tuple

# 配置
BASE_URL = "http://localhost:30811"
API_PREFIX = "/prod-api"
USERNAME = "admin"
PASSWORD = "primihub123"

# 颜色输出
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

def print_colored(text: str, color: str):
    print(f"{color}{text}{Colors.NC}")

def print_step(step: str):
    print_colored(f"\n📝 {step}", Colors.BLUE)

def print_success(text: str):
    print_colored(f"  ✓ {text}", Colors.GREEN)

def print_error(text: str):
    print_colored(f"  ❌ {text}", Colors.RED)

def print_warning(text: str):
    print_colored(f"  ⚠️  {text}", Colors.YELLOW)

def get_captcha() -> Tuple[bool, str]:
    """获取验证码密钥"""
    try:
        timestamp = int(time.time() * 1000)
        nonce = int(time.time() * 1000) % 10000

        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/sys/captcha/get",
            json={"timestamp": timestamp, "nonce": nonce},
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            if data.get('code') == 0:
                validate_key = data.get('result', {}).get('validateKeyName', '')
                if validate_key:
                    return True, validate_key
        return False, ""
    except Exception as e:
        print_error(f"获取验证码失败: {e}")
        return False, ""

def login() -> Tuple[bool, str, Dict[str, Any]]:
    """用户登录"""
    print_step("步骤1: 用户登录")

    # 获取验证码密钥
    print("  获取验证码密钥...")
    success, validate_key = get_captcha()

    if not success:
        print_warning("未获取到验证码密钥，尝试不带验证码登录...")
        validate_key = ""
    else:
        print_success(f"验证码密钥: {validate_key}")

    # 构建登录数据
    timestamp = int(time.time() * 1000)
    nonce = int(time.time() * 1000) % 10000

    login_data = {
        "userAccount": USERNAME,
        "userPassword": PASSWORD,
        "timestamp": timestamp,
        "nonce": nonce
    }

    if validate_key:
        login_data["validateKeyName"] = validate_key
        login_data["validateCode"] = ""  # 空验证码

    print(f"  发送登录请求...")

    try:
        response = requests.post(
            f"{BASE_URL}{API_PREFIX}/sys/user/login",
            data=login_data,
            timeout=10
        )

        print(f"  HTTP状态码: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            code = data.get('code', -1)

            if code == 0:
                print_success(f"登录成功 (code: {code})")

                result = data.get('result', {})
                token = result.get('token', '')
                permissions = result.get('grantAuthRootList', [])
                user_info = result.get('sysUser', {})

                if token:
                    print_success(f"Token已获取: {token[:30]}...")
                else:
                    print_warning("未找到token")

                if permissions:
                    print_success(f"权限数据已返回，共 {len(permissions)} 条权限")

                    # 查找联邦分析权限
                    fed_perms = [p for p in permissions if 'FederatedAnalysis' in p.get('authCode', '')]

                    if fed_perms:
                        print_success(f"包含联邦分析相关权限，共 {len(fed_perms)} 条:")
                        for p in fed_perms[:10]:  # 只显示前10个
                            print(f"    - {p.get('authCode')}: {p.get('authName', 'N/A')}")
                        if len(fed_perms) > 10:
                            print(f"    ... 还有 {len(fed_perms) - 10} 条权限")
                    else:
                        print_warning("未找到联邦分析相关权限")
                        print("  所有权限列表（前10条）:")
                        for p in permissions[:10]:
                            print(f"    - {p.get('authCode')}: {p.get('authName', 'N/A')}")
                        if len(permissions) > 10:
                            print(f"    ... 还有 {len(permissions) - 10} 条权限")
                else:
                    print_warning("权限数据为空")

                user_name = user_info.get('userName', '')
                if user_name:
                    print_success(f"用户名: {user_name}")

                return True, token, data
            else:
                msg = data.get('msg', 'Unknown error')
                print_error(f"登录失败 (code: {code}, msg: {msg})")
                return False, "", data
        else:
            print_error(f"登录请求失败 (HTTP {response.status_code})")
            print(f"  响应: {response.text[:200]}")
            return False, "", {}

    except Exception as e:
        print_error(f"登录异常: {e}")
        return False, "", {}

def test_federated_analysis_api(token: str) -> bool:
    """测试联邦分析列表 API"""
    print_step("步骤2: 访问联邦分析列表 API")

    timestamp = int(time.time() * 1000)
    nonce = int(time.time() * 1000) % 10000

    params = {
        "pageNum": 1,
        "pageSize": 10,
        "timestamp": timestamp,
        "nonce": nonce,
        "token": token
    }

    headers = {
        "token": token,
        "Content-Type": "application/json"
    }

    api_url = f"{BASE_URL}{API_PREFIX}/data/federatedAnalysis/list"
    print(f"  请求URL: {api_url}")

    try:
        response = requests.get(
            api_url,
            params=params,
            headers=headers,
            timeout=10
        )

        print(f"  HTTP状态码: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            code = data.get('code', -1)

            if code == 0:
                print_success(f"API调用成功 (code: {code})")

                if 'result' in data:
                    print_success("返回了结果数据")

                return True
            elif code == 103:
                print_error(f"权限被拒绝 (code: 103 - 暂无权限)")
                msg = data.get('msg', '')
                print(f"  消息: {msg}")
                print(f"  完整响应: {json.dumps(data, ensure_ascii=False)}")
                return False
            else:
                msg = data.get('msg', '')
                print_warning(f"API返回错误 (code: {code}, msg: {msg})")
                print(f"  完整响应: {json.dumps(data, ensure_ascii=False)}")
                return False
        else:
            print_error(f"API请求失败 (HTTP {response.status_code})")
            print(f"  响应: {response.text[:200]}")
            return False

    except Exception as e:
        print_error(f"API调用异常: {e}")
        return False

def main():
    print("=" * 60)
    print("联邦分析 API 本地测试")
    print("=" * 60)
    print()
    print("配置信息:")
    print(f"  - 基础URL: {BASE_URL}")
    print(f"  - API前缀: {API_PREFIX}")
    print(f"  - 用户名: {USERNAME}")
    print()

    # 测试结果
    results = {
        'login': False,
        'permission_loaded': False,
        'has_federated_analysis_perm': False,
        'api_access': False
    }

    # 步骤1: 登录
    login_success, token, login_data = login()
    results['login'] = login_success

    if login_success:
        permissions = login_data.get('result', {}).get('grantAuthRootList', [])
        results['permission_loaded'] = len(permissions) > 0
        results['has_federated_analysis_perm'] = any(
            'FederatedAnalysis' in p.get('authCode', '') for p in permissions
        )

    if not login_success:
        print_error("\n❌ 登录失败，无法继续测试")
        sys.exit(1)

    # 步骤2: 测试 API
    api_success = test_federated_analysis_api(token)
    results['api_access'] = api_success

    # 输出测试结果
    print()
    print("=" * 60)
    print("📊 测试结果汇总")
    print("=" * 60)

    status_login = f"{Colors.GREEN}成功{Colors.NC}" if results['login'] else f"{Colors.RED}失败{Colors.NC}"
    status_perm = f"{Colors.GREEN}成功{Colors.NC}" if results['permission_loaded'] else f"{Colors.RED}失败{Colors.NC}"
    status_fed_perm = f"{Colors.GREEN}存在{Colors.NC}" if results['has_federated_analysis_perm'] else f"{Colors.RED}不存在{Colors.NC}"
    status_api = f"{Colors.GREEN}成功{Colors.NC}" if results['api_access'] else f"{Colors.RED}失败{Colors.NC}"

    print(f"✅ 登录: {status_login}")
    print(f"✅ 权限加载: {status_perm}")
    print(f"✅ 联邦分析权限: {status_fed_perm}")
    print(f"✅ API访问: {status_api}")
    print("=" * 60)

    if all(results.values()):
        print_colored("\n🎉 所有测试通过！", Colors.GREEN)
        print("\n结论: 后端 API 权限验证正常，问题在前端路由生成逻辑。")
        print("建议: 检查前端代码修改是否已部署到容器中。")
        sys.exit(0)
    else:
        print_colored("\n⚠️  部分测试失败", Colors.YELLOW)
        print("\n分析建议:")

        if not results['login']:
            print("  - 检查用户名和密码是否正确")
            print("  - 检查后端服务是否正常运行")

        if not results['permission_loaded']:
            print("  - 检查用户是否有权限")
            print("  - 检查数据库中的权限配置")

        if not results['has_federated_analysis_perm']:
            print("  - 用户没有联邦分析权限，需要在数据库中配置")
            print("  - 运行权限初始化脚本: ~/primihub-platform/init_permissions.sql")

        if not results['api_access']:
            print("  - 检查后端权限验证逻辑")
            print("  - 检查 token 是否正确传递")
            print("  - 查看后端日志: docker logs application0")

        sys.exit(1)

if __name__ == "__main__":
    main()
