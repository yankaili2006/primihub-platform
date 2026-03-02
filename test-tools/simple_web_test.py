#!/usr/bin/env python3
"""
PrimiHub Web 界面简化测试工具
使用 requests 库测试页面可访问性和基本功能
"""

import requests
import json
import time
from datetime import datetime
from typing import Dict, List

class SimpleWebTester:
    """简化的 Web 测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456"):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
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

    def test_homepage_access(self):
        """测试主页访问"""
        print("\n=== 测试主页访问 ===")
        start = time.time()

        try:
            response = self.session.get(f"{self.base_url}/", timeout=10)
            duration = time.time() - start

            if response.status_code == 200:
                self.log_test("主页", "页面访问", True, f"状态码: {response.status_code}", duration)
                return True
            else:
                self.log_test("主页", "页面访问", False, f"状态码: {response.status_code}", duration)
                return False
        except Exception as e:
            duration = time.time() - start
            self.log_test("主页", "页面访问", False, f"异常: {str(e)}", duration)
            return False

    def test_api_endpoints(self):
        """测试常用 API 端点"""
        print("\n=== 测试 API 端点 ===")

        endpoints = [
            ("/api/user/login", "登录接口"),
            ("/api/sys/dict/getDictItems/organ_type", "字典接口"),
            ("/api/sys/common/static-file-trigger/", "静态文件接口"),
        ]

        for endpoint, name in endpoints:
            start = time.time()
            try:
                url = f"{self.base_url}{endpoint}"
                response = self.session.get(url, timeout=5)
                duration = time.time() - start

                # 对于需要认证的接口，401/403 也算正常
                if response.status_code in [200, 401, 403, 404, 405]:
                    self.log_test("API", name, True, f"状态码: {response.status_code}", duration)
                else:
                    self.log_test("API", name, False, f"状态码: {response.status_code}", duration)
            except Exception as e:
                duration = time.time() - start
                self.log_test("API", name, False, f"异常: {str(e)}", duration)

    def test_static_resources(self):
        """测试静态资源加载"""
        print("\n=== 测试静态资源 ===")

        resources = [
            ("/index.html", "首页HTML"),
            ("/favicon.ico", "网站图标"),
        ]

        for resource, name in resources:
            start = time.time()
            try:
                url = f"{self.base_url}{resource}"
                response = self.session.get(url, timeout=5)
                duration = time.time() - start

                if response.status_code == 200:
                    self.log_test("静态资源", name, True, f"大小: {len(response.content)} bytes", duration)
                else:
                    self.log_test("静态资源", name, False, f"状态码: {response.status_code}", duration)
            except Exception as e:
                duration = time.time() - start
                self.log_test("静态资源", name, False, f"异常: {str(e)}", duration)

    def run_all_tests(self):
        """运行所有测试"""
        print(f"\n{'='*60}")
        print(f"PrimiHub Web 界面测试")
        print(f"测试地址: {self.base_url}")
        print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*60}")

        # 运行测试
        self.test_homepage_access()
        self.test_static_resources()
        self.test_api_endpoints()

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

    parser = argparse.ArgumentParser(description="PrimiHub Web 界面简化测试工具")
    parser.add_argument("--url", default="http://192.168.99.5:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")

    args = parser.parse_args()

    tester = SimpleWebTester(args.url, args.username, args.password)
    tester.run_all_tests()
