#!/usr/bin/env python3
"""联邦查询功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class FederatedQueryTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.task_id = None

    def run(self):
        print("\n" + "="*60)
        print("联邦查询功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_get_algorithms()
            self.test_create_query()
            self.test_run_query()
            self.test_query_list()
            self.test_query_result()
            self.test_tools()
            self.generate_report()
        except Exception as e:
            print(f"\n错误: {e}")
            import traceback; traceback.print_exc()
        finally:
            try: self.client.logout()
            except: pass

    def test_login(self):
        s = time.time()
        r = self.client.login(ADMIN_USER, ADMIN_PASSWORD)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦查询", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_get_algorithms(self):
        s = time.time()
        r = self.client.get_supported_algorithms()
        ok = r.get('code') == 0
        algos = r.get('result', [])
        self.report.add_test_result("联邦查询", "获取算法列表", "passed" if ok else "failed", time.time()-s)
        names = [a.get('type') for a in algos] if algos else []
        print(f"{'✅' if ok else '❌'} 算法列表 ({'/'.join(names)})")

    def test_create_query(self):
        s = time.time()
        data = {"taskName": f"联邦查询测试_{int(time.time())}", "algorithm": "DH", "mode": "batch", "queryType": "psi"}
        r = self.client.create_federated_query(data)
        ok = r.get('code') == 0
        if ok: self.task_id = r.get('result', {}).get('taskId')
        self.report.add_test_result("联邦查询", "创建查询任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建查询 (ID: {self.task_id})")

    def test_run_query(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.run_query(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦查询", "执行查询", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 执行查询")

    def test_query_list(self):
        s = time.time()
        r = self.client.get_query_list()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("联邦查询", "查询任务列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 任务列表 ({count}条)")

    def test_query_result(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.get_query_result(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦查询", "查询结果", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 查询结果")

    def test_tools(self):
        for tool in ["payloadChunk", "dedup", "codec", "bucket", "outputFields"]:
            s = time.time()
            r = self.client.test_tool({"toolName": tool, "testInput": "1,2,3,4,5,1,2,3"})
            ok = r.get('code') == 0
            self.report.add_test_result("联邦查询", f"工具-{tool}", "passed" if ok else "failed", time.time()-s)
            print(f"{'  ✅' if ok else '  ❌'} 工具: {tool}")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'federated_query_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    FederatedQueryTest().run()
