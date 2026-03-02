#!/usr/bin/env python3
"""
PrimiHub 高级自动化测试工具
支持完整业务流程测试、性能测试、并发测试
"""

import requests
import json
import time
import threading
from datetime import datetime
from typing import Dict, List, Optional, Callable
import urllib3
from concurrent.futures import ThreadPoolExecutor, as_completed

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class AdvancedPrimiHubTester:
    """PrimiHub 高级测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456"):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.token = None
        self.test_results = []
        self.performance_data = []

    def log_test(self, module: str, test_name: str, success: bool, message: str = "", response_time: float = 0, extra_data: Dict = None):
        """记录测试结果"""
        result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "module": module,
            "test": test_name,
            "success": success,
            "message": message,
            "response_time": response_time,
            "extra_data": extra_data or {}
        }
        self.test_results.append(result)

        status = "✅" if success else "❌"
        print(f"{status} [{module}] {test_name}: {message} ({response_time:.3f}s)")

    def login(self) -> bool:
        """登录"""
        try:
            url = f"{self.base_url}/prod-api/user/login"
            data = {"userAccount": self.username, "userPassword": self.password}
            response = self.session.post(url, data=data, verify=False, timeout=10)

            if response.status_code == 200:
                result = response.json()
                if result.get("code") == 0:
                    self.token = result.get("data", {}).get("token")
                    self.session.headers.update({"Authorization": f"Bearer {self.token}"})
                    return True
            return False
        except:
            return False

    def test_workflow_psi(self):
        """测试 PSI 隐私求交完整流程"""
        print("\n=== 测试 PSI 隐私求交流程 ===")

        # 1. 获取项目列表
        start = time.time()
        try:
            response = self.session.get(
                f"{self.base_url}/prod-api/data/project/list",
                params={"pageNum": 1, "pageSize": 10},
                verify=False, timeout=10
            )
            elapsed = time.time() - start
            success = response.status_code == 200 and response.json().get("code") == 0
            self.log_test("PSI流程", "步骤1: 获取项目列表", success, "", elapsed)
        except Exception as e:
            self.log_test("PSI流程", "步骤1: 获取项目列表", False, str(e), time.time() - start)

        # 2. 获取资源列表
        start = time.time()
        try:
            response = self.session.get(
                f"{self.base_url}/prod-api/data/resource/list",
                params={"pageNum": 1, "pageSize": 10},
                verify=False, timeout=10
            )
            elapsed = time.time() - start
            success = response.status_code == 200 and response.json().get("code") == 0
            self.log_test("PSI流程", "步骤2: 获取资源列表", success, "", elapsed)
        except Exception as e:
            self.log_test("PSI流程", "步骤2: 获取资源列表", False, str(e), time.time() - start)

        # 3. 获取 PSI 任务列表
        start = time.time()
        try:
            response = self.session.get(
                f"{self.base_url}/prod-api/psi/list",
                params={"pageNum": 1, "pageSize": 10},
                verify=False, timeout=10
            )
            elapsed = time.time() - start
            success = response.status_code == 200 and response.json().get("code") == 0
            self.log_test("PSI流程", "步骤3: 获取PSI任务列表", success, "", elapsed)
        except Exception as e:
            self.log_test("PSI流程", "步骤3: 获取PSI任务列表", False, str(e), time.time() - start)

    def test_workflow_federated_learning(self):
        """测试联邦学习完整流程"""
        print("\n=== 测试联邦学习流程 ===")

        workflows = [
            ("获取联邦建模列表", "/prod-api/data/federatedLearning/list"),
            ("获取联邦分析列表", "/prod-api/data/federatedAnalysis/list"),
            ("获取联邦统计列表", "/prod-api/data/federatedStatistics/list"),
        ]

        for name, endpoint in workflows:
            start = time.time()
            try:
                response = self.session.get(
                    f"{self.base_url}{endpoint}",
                    params={"pageNum": 1, "pageSize": 10},
                    verify=False, timeout=10
                )
                elapsed = time.time() - start
                success = response.status_code == 200 and response.json().get("code") == 0
                self.log_test("联邦学习流程", name, success, "", elapsed)
            except Exception as e:
                self.log_test("联邦学习流程", name, False, str(e), time.time() - start)

    def test_performance(self, endpoint: str, params: Dict = None, num_requests: int = 10):
        """性能测试"""
        print(f"\n=== 性能测试: {endpoint} (请求数: {num_requests}) ===")

        response_times = []
        success_count = 0

        for i in range(num_requests):
            start = time.time()
            try:
                response = self.session.get(
                    f"{self.base_url}{endpoint}",
                    params=params or {},
                    verify=False, timeout=10
                )
                elapsed = time.time() - start
                response_times.append(elapsed)

                if response.status_code == 200 and response.json().get("code") == 0:
                    success_count += 1

            except Exception as e:
                elapsed = time.time() - start
                response_times.append(elapsed)

        # 计算统计数据
        avg_time = sum(response_times) / len(response_times)
        min_time = min(response_times)
        max_time = max(response_times)
        success_rate = (success_count / num_requests) * 100

        perf_data = {
            "endpoint": endpoint,
            "requests": num_requests,
            "success_count": success_count,
            "success_rate": success_rate,
            "avg_time": avg_time,
            "min_time": min_time,
            "max_time": max_time
        }
        self.performance_data.append(perf_data)

        self.log_test(
            "性能测试",
            f"{endpoint}",
            success_rate >= 90,
            f"成功率: {success_rate:.1f}%, 平均: {avg_time:.3f}s, 最小: {min_time:.3f}s, 最大: {max_time:.3f}s",
            avg_time,
            perf_data
        )

    def test_concurrent(self, endpoint: str, params: Dict = None, num_threads: int = 5, requests_per_thread: int = 10):
        """并发测试"""
        print(f"\n=== 并发测试: {endpoint} (线程数: {num_threads}, 每线程请求数: {requests_per_thread}) ===")

        def worker():
            results = []
            for _ in range(requests_per_thread):
                start = time.time()
                try:
                    response = self.session.get(
                        f"{self.base_url}{endpoint}",
                        params=params or {},
                        verify=False, timeout=10
                    )
                    elapsed = time.time() - start
                    success = response.status_code == 200 and response.json().get("code") == 0
                    results.append({"success": success, "time": elapsed})
                except:
                    results.append({"success": False, "time": time.time() - start})
            return results

        start_time = time.time()
        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = [executor.submit(worker) for _ in range(num_threads)]
            all_results = []
            for future in as_completed(futures):
                all_results.extend(future.result())

        total_time = time.time() - start_time
        total_requests = len(all_results)
        success_count = sum(1 for r in all_results if r["success"])
        success_rate = (success_count / total_requests) * 100
        avg_time = sum(r["time"] for r in all_results) / total_requests
        qps = total_requests / total_time

        self.log_test(
            "并发测试",
            f"{endpoint}",
            success_rate >= 90,
            f"成功率: {success_rate:.1f}%, QPS: {qps:.2f}, 平均响应: {avg_time:.3f}s",
            avg_time,
            {
                "threads": num_threads,
                "total_requests": total_requests,
                "success_rate": success_rate,
                "qps": qps
            }
        )

    def test_all_new_features(self):
        """测试所有新功能"""
        print("\n=== 测试所有 1.8.1 新功能 ===")

        features = [
            ("白名单列表", "/prod-api/sys/whitelist/list"),
            ("白名单配置", "/prod-api/sys/whitelist/config"),
            ("租户列表", "/prod-api/sys/tenant/list"),
            ("存证查询", "/prod-api/sys/evidence/query"),
            ("监控信息", "/prod-api/sys/monitor/info"),
            ("接口列表", "/prod-api/sys/api/list"),
            ("接口授权", "/prod-api/sys/api/auth"),
            ("日志列表", "/prod-api/sys/log/list"),
            ("操作日志", "/prod-api/sys/log/operation"),
            ("调度日志", "/prod-api/sys/log/schedule"),
        ]

        for name, endpoint in features:
            start = time.time()
            try:
                response = self.session.get(
                    f"{self.base_url}{endpoint}",
                    params={"pageNum": 1, "pageSize": 10},
                    verify=False, timeout=10
                )
                elapsed = time.time() - start
                success = response.status_code == 200
                result = response.json() if success else {}
                code = result.get("code", -1)

                self.log_test(
                    "新功能",
                    name,
                    success and code == 0,
                    f"HTTP {response.status_code}, Code {code}",
                    elapsed
                )
            except Exception as e:
                self.log_test("新功能", name, False, str(e), time.time() - start)

    def generate_advanced_report(self, output_file: str = "advanced_test_report.html"):
        """生成高级测试报告"""
        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r["success"])
        failed = total - passed
        pass_rate = (passed / total * 100) if total > 0 else 0

        # 按模块统计
        modules = {}
        for result in self.test_results:
            module = result["module"]
            if module not in modules:
                modules[module] = {"total": 0, "passed": 0, "failed": 0}
            modules[module]["total"] += 1
            if result["success"]:
                modules[module]["passed"] += 1
            else:
                modules[module]["failed"] += 1

        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PrimiHub 高级测试报告</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }}
        .container {{ max-width: 1400px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); overflow: hidden; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; }}
        .header h1 {{ font-size: 36px; margin-bottom: 10px; }}
        .header p {{ opacity: 0.9; }}
        .content {{ padding: 40px; }}
        .summary {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 40px; }}
        .stat-card {{ padding: 25px; border-radius: 12px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.1); transition: transform 0.3s; }}
        .stat-card:hover {{ transform: translateY(-5px); }}
        .stat-card.total {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }}
        .stat-card.passed {{ background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; }}
        .stat-card.failed {{ background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%); color: white; }}
        .stat-card.rate {{ background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; }}
        .stat-card h2 {{ font-size: 48px; margin-bottom: 10px; }}
        .stat-card p {{ font-size: 16px; opacity: 0.9; }}
        .section {{ margin-bottom: 40px; }}
        .section h2 {{ color: #333; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 3px solid #667eea; }}
        .module-stats {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 15px; margin-bottom: 30px; }}
        .module-card {{ background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #667eea; }}
        .module-card h3 {{ color: #333; margin-bottom: 10px; }}
        .module-card .stats {{ display: flex; justify-content: space-between; font-size: 14px; }}
        .module-card .stats span {{ padding: 5px 10px; border-radius: 4px; }}
        .module-card .stats .pass {{ background: #d4edda; color: #155724; }}
        .module-card .stats .fail {{ background: #f8d7da; color: #721c24; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        th, td {{ padding: 15px; text-align: left; border-bottom: 1px solid #e0e0e0; }}
        th {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; font-weight: 600; }}
        tr:hover {{ background-color: #f5f5f5; }}
        .success {{ color: #28a745; font-weight: bold; }}
        .failure {{ color: #dc3545; font-weight: bold; }}
        .perf-table {{ margin-top: 20px; }}
        .perf-good {{ background: #d4edda; }}
        .perf-warning {{ background: #fff3cd; }}
        .perf-bad {{ background: #f8d7da; }}
        .footer {{ background: #f8f9fa; padding: 20px; text-align: center; color: #666; border-top: 1px solid #e0e0e0; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 PrimiHub 高级测试报告</h1>
            <p>生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
            <p>测试地址: {self.base_url}</p>
        </div>

        <div class="content">
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
                <div class="stat-card rate">
                    <h2>{pass_rate:.1f}%</h2>
                    <p>通过率</p>
                </div>
            </div>

            <div class="section">
                <h2>📊 模块统计</h2>
                <div class="module-stats">
"""

        for module, stats in modules.items():
            pass_rate_module = (stats["passed"] / stats["total"] * 100) if stats["total"] > 0 else 0
            html += f"""
                    <div class="module-card">
                        <h3>{module}</h3>
                        <div class="stats">
                            <span class="pass">✓ {stats["passed"]}</span>
                            <span class="fail">✗ {stats["failed"]}</span>
                            <span>{pass_rate_module:.0f}%</span>
                        </div>
                    </div>
"""

        html += """
                </div>
            </div>
"""

        # 性能测试结果
        if self.performance_data:
            html += """
            <div class="section">
                <h2>⚡ 性能测试结果</h2>
                <table class="perf-table">
                    <thead>
                        <tr>
                            <th>接口</th>
                            <th>请求数</th>
                            <th>成功率</th>
                            <th>平均响应时间</th>
                            <th>最小响应时间</th>
                            <th>最大响应时间</th>
                        </tr>
                    </thead>
                    <tbody>
"""
            for perf in self.performance_data:
                perf_class = "perf-good" if perf["avg_time"] < 1 else ("perf-warning" if perf["avg_time"] < 3 else "perf-bad")
                html += f"""
                        <tr class="{perf_class}">
                            <td>{perf["endpoint"]}</td>
                            <td>{perf["requests"]}</td>
                            <td>{perf["success_rate"]:.1f}%</td>
                            <td>{perf["avg_time"]:.3f}s</td>
                            <td>{perf["min_time"]:.3f}s</td>
                            <td>{perf["max_time"]:.3f}s</td>
                        </tr>
"""
            html += """
                    </tbody>
                </table>
            </div>
"""

        # 详细测试结果
        html += """
            <div class="section">
                <h2>📋 详细测试结果</h2>
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
                            <td>{result["response_time"]:.3f}s</td>
                        </tr>
"""

        html += f"""
                    </tbody>
                </table>
            </div>
        </div>

        <div class="footer">
            <p>PrimiHub 自动化测试工具 v2.0 | 生成于 {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        </div>
    </div>
</body>
</html>
"""

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html)

        print(f"\n📊 高级测试报告已生成: {output_file}")
        print(f"   总计: {total} | 通过: {passed} | 失败: {failed} | 通过率: {pass_rate:.1f}%")

    def run_comprehensive_tests(self):
        """运行综合测试"""
        print("=" * 80)
        print("🚀 开始 PrimiHub 综合自动化测试")
        print("=" * 80)

        # 登录
        print("\n[1/6] 登录测试...")
        if not self.login():
            print("❌ 登录失败，无法继续测试")
            return

        # 功能测试
        print("\n[2/6] 新功能测试...")
        self.test_all_new_features()

        # 业务流程测试
        print("\n[3/6] 业务流程测试...")
        self.test_workflow_psi()
        self.test_workflow_federated_learning()

        # 性能测试
        print("\n[4/6] 性能测试...")
        self.test_performance("/prod-api/sys/user/list", {"pageNum": 1, "pageSize": 10}, 20)
        self.test_performance("/prod-api/data/project/list", {"pageNum": 1, "pageSize": 10}, 20)

        # 并发测试
        print("\n[5/6] 并发测试...")
        self.test_concurrent("/prod-api/sys/user/list", {"pageNum": 1, "pageSize": 10}, 5, 10)

        # 生成报告
        print("\n[6/6] 生成测试报告...")
        self.generate_advanced_report()

        print("\n" + "=" * 80)
        print("✅ 测试完成")
        print("=" * 80)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="PrimiHub 高级自动化测试工具")
    parser.add_argument("--url", default="http://localhost:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")
    parser.add_argument("--output", default="advanced_test_report.html", help="报告输出文件")

    args = parser.parse_args()

    tester = AdvancedPrimiHubTester(args.url, args.username, args.password)
    tester.run_comprehensive_tests()


if __name__ == "__main__":
    main()
