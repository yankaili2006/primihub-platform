#!/usr/bin/env python3
"""
PrimiHub 完整 Web 界面测试工具
测试登录、菜单、API 端点等功能
"""

import requests
import json
import time
from datetime import datetime
from typing import Dict, List

class CompleteWebTester:
    """完整的 Web 测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456"):
        self.base_url = base_url.rstrip('/')
        self.api_url = f"{self.base_url}/prod-api"
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.token = None
        self.test_results = []

    def log_test(self, module: str, test_name: str, success: bool, message: str = "", duration: float = 0):
        """记录测试结果"""
        result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "module": module,
            "test": test_name,
            "success": success,
            "message": message,
            "duration": duration
        }
        self.test_results.append(result)

        status = "✅" if success else "❌"
        print(f"{status} [{module}] {test_name}: {message} ({duration:.2f}s)")

    def test_login(self):
        """测试用户登录"""
        print("\n=== 测试用户登录 ===")
        start = time.time()

        try:
            url = f"{self.api_url}/user/login"
            data = {
                "userAccount": self.username,
                "userPassword": self.password
            }

            response = self.session.post(url, data=data, timeout=10)
            duration = time.time() - start

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    self.token = result.get('result', {}).get('token', '')
                    self.log_test("登录", "用户登录", True, f"Token: {self.token[:30]}...", duration)
                    return True
                else:
                    self.log_test("登录", "用户登录", False, f"登录失败: {result.get('message')}", duration)
                    return False
            else:
                self.log_test("登录", "用户登录", False, f"状态码: {response.status_code}", duration)
                return False
        except Exception as e:
            duration = time.time() - start
            self.log_test("登录", "用户登录", False, f"异常: {str(e)}", duration)
            return False

    def test_menu_structure(self):
        """测试菜单结构"""
        print("\n=== 测试菜单结构 ===")

        if not self.token:
            self.log_test("菜单", "菜单结构", False, "未登录，无法测试菜单", 0)
            return False

        start = time.time()
        try:
            url = f"{self.api_url}/user/login"
            data = {
                "userAccount": self.username,
                "userPassword": self.password
            }

            response = self.session.post(url, data=data, timeout=10)
            duration = time.time() - start

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    auth_list = result.get('result', {}).get('grantAuthRootList', [])
                    menu_count = self.count_menus(auth_list)

                    self.log_test("菜单", "菜单数量", True, f"共 {menu_count} 个菜单项", duration)

                    # 提取菜单名称
                    menu_names = self.extract_menu_names(auth_list)
                    self.log_test("菜单", "菜单提取", True, f"提取到 {len(menu_names)} 个菜单名称", 0)

                    return True
                else:
                    self.log_test("菜单", "菜单结构", False, f"获取失败: {result.get('message')}", duration)
                    return False
            else:
                self.log_test("菜单", "菜单结构", False, f"状态码: {response.status_code}", duration)
                return False
        except Exception as e:
            duration = time.time() - start
            self.log_test("菜单", "菜单结构", False, f"异常: {str(e)}", duration)
            return False

    def count_menus(self, auth_list: List[Dict]) -> int:
        """递归统计菜单数量"""
        count = 0
        for auth in auth_list:
            count += 1
            if auth.get('children'):
                count += self.count_menus(auth['children'])
        return count

    def extract_menu_names(self, auth_list: List[Dict], level: int = 0) -> List[str]:
        """递归提取菜单名称"""
        names = []
        for auth in auth_list:
            name = auth.get('authName', '未命名')
            names.append(f"{'  ' * level}└─ {name}")
            if auth.get('children'):
                names.extend(self.extract_menu_names(auth['children'], level + 1))
        return names

    def test_homepage_access(self):
        """测试主页访问"""
        print("\n=== 测试主页访问 ===")
        start = time.time()

        try:
            response = self.session.get(f"{self.base_url}/", timeout=10)
            duration = time.time() - start

            if response.status_code == 200:
                self.log_test("主页", "页面访问", True, f"大小: {len(response.content)} bytes", duration)
                return True
            else:
                self.log_test("主页", "页面访问", False, f"状态码: {response.status_code}", duration)
                return False
        except Exception as e:
            duration = time.time() - start
            self.log_test("主页", "页面访问", False, f"异常: {str(e)}", duration)
            return False

    def run_all_tests(self):
        """运行所有测试"""
        print(f"\n{'='*60}")
        print(f"PrimiHub 完整 Web 界面测试")
        print(f"测试地址: {self.base_url}")
        print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*60}")

        # 运行测试
        self.test_homepage_access()
        self.test_login()
        self.test_menu_structure()

        # 生成报告
        self.generate_report()

    def generate_report(self):
        """生成测试报告"""
        print(f"\n{'='*60}")
        print("测试报告")
        print(f"{'='*60}")

        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r['success'])
        failed = total - passed

        print(f"\n总测试数: {total}")
        print(f"✅ 通过: {passed}")
        print(f"❌ 失败: {failed}")
        print(f"通过率: {passed/total*100:.1f}%")

        if failed > 0:
            print(f"\n失败的测试:")
            for r in self.test_results:
                if not r['success']:
                    print(f"  - [{r['module']}] {r['test']}: {r['message']}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="PrimiHub 完整 Web 界面测试工具")
    parser.add_argument("--url", default="http://192.168.99.5:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")

    args = parser.parse_args()

    tester = CompleteWebTester(args.url, args.username, args.password)
    tester.run_all_tests()
