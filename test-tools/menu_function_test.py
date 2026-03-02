#!/usr/bin/env python3
"""
PrimiHub 菜单功能测试工具
通过 API 模拟测试每个菜单的功能
"""

import requests
import json
import time
from datetime import datetime
from typing import Dict, List

class MenuFunctionTester:
    """菜单功能测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456"):
        self.base_url = base_url.rstrip('/')
        self.api_url = f"{self.base_url}/prod-api"
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.token = None
        self.menu_list = []
        self.test_results = []

    def log_test(self, menu_name: str, success: bool, message: str = ""):
        """记录测试结果"""
        result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "menu": menu_name,
            "success": success,
            "message": message
        }
        self.test_results.append(result)

        status = "✅" if success else "❌"
        print(f"{status} {menu_name}: {message}")

    def login(self):
        """登录获取 token"""
        print("\n=== 登录系统 ===")

        try:
            url = f"{self.api_url}/user/login"
            data = {
                "userAccount": self.username,
                "userPassword": self.password
            }

            response = self.session.post(url, data=data, timeout=10)

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    self.token = result.get('result', {}).get('token', '')
                    print(f"✓ 登录成功，Token: {self.token[:30]}...")
                    return True
                else:
                    print(f"✗ 登录失败: {result.get('message')}")
                    return False
            else:
                print(f"✗ 登录失败，状态码: {response.status_code}")
                return False
        except Exception as e:
            print(f"✗ 登录异常: {str(e)}")
            return False

    def get_menu_tree(self):
        """获取菜单树"""
        print("\n=== 获取菜单结构 ===")

        try:
            url = f"{self.api_url}/user/login"
            data = {
                "userAccount": self.username,
                "userPassword": self.password
            }

            response = self.session.post(url, data=data, timeout=10)

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    auth_list = result.get('result', {}).get('grantAuthRootList', [])
                    self.extract_menus(auth_list)
                    print(f"✓ 获取到 {len(self.menu_list)} 个菜单项")
                    return True
                else:
                    print(f"✗ 获取菜单失败: {result.get('message')}")
                    return False
            else:
                print(f"✗ 获取菜单失败，状态码: {response.status_code}")
                return False
        except Exception as e:
            print(f"✗ 获取菜单异常: {str(e)}")
            return False

    def extract_menus(self, auth_list: List[Dict], level: int = 0):
        """递归提取菜单"""
        for auth in auth_list:
            menu_info = {
                "name": auth.get('authName', '未命名'),
                "code": auth.get('authCode', ''),
                "url": auth.get('authUrl', ''),
                "level": level,
                "type": auth.get('authType', '')
            }
            self.menu_list.append(menu_info)

            if auth.get('children'):
                self.extract_menus(auth['children'], level + 1)

    def test_menu(self, menu: Dict):
        """测试单个菜单"""
        menu_name = menu['name']
        menu_url = menu.get('url', '')

        # 跳过没有 URL 的菜单（通常是父级菜单）
        if not menu_url or menu_url == '#':
            self.log_test(menu_name, True, "父级菜单（无需测试）")
            return True

        # 测试菜单对应的页面或 API
        try:
            # 尝试访问菜单 URL
            if menu_url.startswith('/'):
                test_url = f"{self.base_url}/#/{menu_url.lstrip('/')}"
            else:
                test_url = f"{self.base_url}/{menu_url}"

            response = self.session.get(test_url, timeout=5)

            if response.status_code in [200, 304]:
                self.log_test(menu_name, True, f"可访问 ({response.status_code})")
                return True
            else:
                self.log_test(menu_name, False, f"状态码: {response.status_code}")
                return False

        except Exception as e:
            self.log_test(menu_name, False, f"异常: {str(e)[:50]}")
            return False

    def test_all_menus(self):
        """测试所有菜单"""
        print(f"\n=== 开始测试 {len(self.menu_list)} 个菜单 ===\n")

        for i, menu in enumerate(self.menu_list, 1):
            indent = "  " * menu['level']
            print(f"[{i}/{len(self.menu_list)}] {indent}", end="")
            self.test_menu(menu)
            time.sleep(0.1)  # 避免请求过快

    def run_all_tests(self):
        """运行所有测试"""
        print(f"\n{'='*60}")
        print(f"PrimiHub 菜单功能测试")
        print(f"测试地址: {self.base_url}")
        print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*60}")

        # 登录
        if not self.login():
            print("登录失败，测试终止")
            return

        # 获取菜单
        if not self.get_menu_tree():
            print("获取菜单失败，测试终止")
            return

        # 测试所有菜单
        self.test_all_menus()

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

        print(f"\n总菜单数: {total}")
        print(f"✅ 通过: {passed}")
        print(f"❌ 失败: {failed}")
        if total > 0:
            print(f"通过率: {passed/total*100:.1f}%")

        if failed > 0:
            print(f"\n失败的菜单 (前10个):")
            failed_count = 0
            for r in self.test_results:
                if not r['success'] and failed_count < 10:
                    print(f"  - {r['menu']}: {r['message']}")
                    failed_count += 1

        # 保存详细报告
        report_file = "menu_test_report.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump({
                "test_time": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                "base_url": self.base_url,
                "total": total,
                "passed": passed,
                "failed": failed,
                "results": self.test_results
            }, f, ensure_ascii=False, indent=2)
        print(f"\n详细报告已保存到: {report_file}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="PrimiHub 菜单功能测试工具")
    parser.add_argument("--url", default="http://192.168.99.5:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")

    args = parser.parse_args()

    tester = MenuFunctionTester(args.url, args.username, args.password)
    tester.run_all_tests()
