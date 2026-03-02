#!/usr/bin/env python3
"""
PrimiHub 系统自动化测试工具
模拟前端用户操作，测试系统各项功能
"""

import requests
import json
import time
from datetime import datetime
from typing import Dict, List, Optional
import urllib3

# 禁用 SSL 警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class PrimiHubTester:
    """PrimiHub 系统测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456"):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.token = None
        self.test_results = []

    def log_test(self, module: str, test_name: str, success: bool, message: str = "", response_time: float = 0):
        """记录测试结果"""
        result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "module": module,
            "test": test_name,
            "success": success,
            "message": message,
            "response_time": f"{response_time:.3f}s"
        }
        self.test_results.append(result)

        status = "✅" if success else "❌"
        print(f"{status} [{module}] {test_name}: {message} ({response_time:.3f}s)")

    def test_login(self) -> bool:
        """测试登录功能"""
        print("\n=== 测试登录功能 ===")
        start_time = time.time()

        try:
            url = f"{self.base_url}/prod-api/user/login"
            data = {
                "userAccount": self.username,
                "userPassword": self.password
            }

            response = self.session.post(url, data=data, verify=False, timeout=10)
            elapsed = time.time() - start_time

            if response.status_code == 200:
                result = response.json()
                if result.get("code") == 0:
                    self.token = result.get("data", {}).get("token")
                    self.session.headers.update({"Authorization": f"Bearer {self.token}"})
                    self.log_test("登录", "用户登录", True, f"登录成功，获取 token", elapsed)
                    return True
                else:
                    self.log_test("登录", "用户登录", False, f"登录失败: {result.get('msg')}", elapsed)
                    return False
            else:
                self.log_test("登录", "用户登录", False, f"HTTP {response.status_code}", elapsed)
                return False

        except Exception as e:
            elapsed = time.time() - start_time
            self.log_test("登录", "用户登录", False, f"异常: {str(e)}", elapsed)
            return False

    def test_api(self, module: str, test_name: str, method: str, endpoint: str,
                 data: Optional[Dict] = None, expected_code: int = 0) -> bool:
        """通用 API 测试方法"""
        start_time = time.time()

        try:
            url = f"{self.base_url}{endpoint}"

            if method.upper() == "GET":
                response = self.session.get(url, params=data, verify=False, timeout=10)
            elif method.upper() == "POST":
                response = self.session.post(url, json=data, verify=False, timeout=10)
            else:
                response = self.session.request(method, url, json=data, verify=False, timeout=10)

            elapsed = time.time() - start_time

            if response.status_code == 200:
                result = response.json()
                if result.get("code") == expected_code:
                    self.log_test(module, test_name, True, "请求成功", elapsed)
                    return True
                else:
                    self.log_test(module, test_name, False,
                                f"返回码 {result.get('code')}: {result.get('msg')}", elapsed)
                    return False
            else:
                self.log_test(module, test_name, False, f"HTTP {response.status_code}", elapsed)
                return False

        except Exception as e:
            elapsed = time.time() - start_time
            self.log_test(module, test_name, False, f"异常: {str(e)}", elapsed)
            return False

    def test_menu_access(self):
        """测试菜单访问权限"""
        print("\n=== 测试菜单访问权限 ===")

        menus = [
            ("系统设置", "/prod-api/sys/user/list", {"pageNum": 1, "pageSize": 10}),
            ("白名单管理", "/prod-api/sys/whitelist/list", {"pageNum": 1, "pageSize": 10}),
            ("租户管理", "/prod-api/sys/tenant/list", {"pageNum": 1, "pageSize": 10}),
            ("存证管理", "/prod-api/sys/evidence/query", {"pageNum": 1, "pageSize": 10}),
            ("监控管理", "/prod-api/sys/monitor/info", {}),
            ("接口管理", "/prod-api/sys/api/list", {"pageNum": 1, "pageSize": 10}),
            ("日志管理", "/prod-api/sys/log/list", {"pageNum": 1, "pageSize": 10}),
        ]

        for menu_name, endpoint, params in menus:
            self.test_api(menu_name, f"访问{menu_name}", "GET", endpoint, params)

    def test_whitelist_features(self):
        """测试白名单管理功能"""
        print("\n=== 测试白名单管理功能 ===")

        # 测试白名单列表
        self.test_api("白名单", "获取白名单列表", "GET",
                     "/prod-api/sys/whitelist/list", {"pageNum": 1, "pageSize": 10})

        # 测试白名单配置
        self.test_api("白名单", "获取白名单配置", "GET",
                     "/prod-api/sys/whitelist/config", {})

    def test_tenant_features(self):
        """测试租户管理功能"""
        print("\n=== 测试租户管理功能 ===")

        self.test_api("租户", "获取租户列表", "GET",
                     "/prod-api/sys/tenant/list", {"pageNum": 1, "pageSize": 10})

    def test_evidence_features(self):
        """测试存证管理功能"""
        print("\n=== 测试存证管理功能 ===")

        self.test_api("存证", "存证查询", "GET",
                     "/prod-api/sys/evidence/query", {"pageNum": 1, "pageSize": 10})

    def test_project_features(self):
        """测试项目管理功能"""
        print("\n=== 测试项目管理功能 ===")

        self.test_api("项目", "获取项目列表", "GET",
                     "/prod-api/data/project/list", {"pageNum": 1, "pageSize": 10})

    def test_resource_features(self):
        """测试资源管理功能"""
        print("\n=== 测试资源管理功能 ===")

        self.test_api("资源", "获取资源列表", "GET",
                     "/prod-api/data/resource/list", {"pageNum": 1, "pageSize": 10})

    def generate_report(self, output_file: str = "test_report.html"):
        """生成测试报告"""
        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r["success"])
        failed = total - passed
        pass_rate = (passed / total * 100) if total > 0 else 0

        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PrimiHub 系统测试报告</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        h1 {{ color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }}
        .summary {{ display: flex; gap: 20px; margin: 20px 0; }}
        .stat-card {{ flex: 1; padding: 20px; border-radius: 8px; text-align: center; }}
        .stat-card.total {{ background: #2196F3; color: white; }}
        .stat-card.passed {{ background: #4CAF50; color: white; }}
        .stat-card.failed {{ background: #f44336; color: white; }}
        .stat-card h2 {{ margin: 0; font-size: 36px; }}
        .stat-card p {{ margin: 5px 0 0 0; font-size: 14px; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
        th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
        th {{ background-color: #4CAF50; color: white; }}
        tr:hover {{ background-color: #f5f5f5; }}
        .success {{ color: #4CAF50; font-weight: bold; }}
        .failure {{ color: #f44336; font-weight: bold; }}
        .timestamp {{ color: #666; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 PrimiHub 系统测试报告</h1>
        <p class="timestamp">生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        <p>测试地址: {self.base_url}</p>

        <div class="summary">
            <div class="stat-card total">
                <h2>{total}</h2>
                <p>总测试数</p>
            </div>
            <div class="stat-card passed">
                <h2>{passed}</h2>
                <p>通过</p>
            </div>
            <div class="stat-card failed">
                <h2>{failed}</h2>
                <p>失败</p>
            </div>
            <div class="stat-card" style="background: #FF9800; color: white;">
                <h2>{pass_rate:.1f}%</h2>
                <p>通过率</p>
            </div>
        </div>

        <h2>测试详情</h2>
        <table>
            <thead>
                <tr>
                    <th>时间</th>
                    <th>模块</th>
                    <th>测试项</th>
                    <th>结果</th>
                    <th>消息</th>
                    <th>响应时间</th>
                </tr>
            </thead>
            <tbody>
"""

        for result in self.test_results:
            status_class = "success" if result["success"] else "failure"
            status_text = "✅ 通过" if result["success"] else "❌ 失败"
            html += f"""
                <tr>
                    <td>{result["timestamp"]}</td>
                    <td>{result["module"]}</td>
                    <td>{result["test"]}</td>
                    <td class="{status_class}">{status_text}</td>
                    <td>{result["message"]}</td>
                    <td>{result["response_time"]}</td>
                </tr>
"""

        html += """
            </tbody>
        </table>
    </div>
</body>
</html>
"""

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html)

        print(f"\n📊 测试报告已生成: {output_file}")
        print(f"   总计: {total} | 通过: {passed} | 失败: {failed} | 通过率: {pass_rate:.1f}%")

    def run_all_tests(self):
        """运行所有测试"""
        print("=" * 60)
        print("🚀 开始 PrimiHub 系统自动化测试")
        print("=" * 60)

        # 登录测试
        if not self.test_login():
            print("\n❌ 登录失败，无法继续测试")
            return

        # 功能测试
        self.test_menu_access()
        self.test_whitelist_features()
        self.test_tenant_features()
        self.test_evidence_features()
        self.test_project_features()
        self.test_resource_features()

        # 生成报告
        print("\n" + "=" * 60)
        self.generate_report()
        print("=" * 60)


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="PrimiHub 系统自动化测试工具")
    parser.add_argument("--url", default="http://localhost:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")
    parser.add_argument("--output", default="test_report.html", help="报告输出文件")

    args = parser.parse_args()

    tester = PrimiHubTester(args.url, args.username, args.password)
    tester.run_all_tests()


if __name__ == "__main__":
    main()
