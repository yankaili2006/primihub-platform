#!/usr/bin/env python3
"""联邦统计功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class FederatedStatsTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.task_id = None
        self.storage_config_id = None

    def run(self):
        print("\n" + "="*60)
        print("联邦统计功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_get_types()
            self.test_create_task()
            self.test_task_list()
            self.test_task_detail()
            self.test_run_task()
            self.test_stop_task()
            self.test_storage_config()
            self.test_logs()
            self.test_delete_task()
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
        self.report.add_test_result("联邦统计", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_get_types(self):
        s = time.time()
        r = self.client.get_stats_types()
        ok = r.get('code') == 0
        types = r.get('result', [])
        type_names = [t.get('name') for t in types] if types else []
        self.report.add_test_result("联邦统计", "统计类型列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 统计类型 ({'/'.join(type_names)})")

    def test_create_task(self):
        s = time.time()
        data = {
            "taskName": f"统计任务测试_{int(time.time())}",
            "statsType": "descriptive",
            "projectId": 1,
            "taskParam": {"columns": ["age", "score"], "filters": []}
        }
        r = self.client.create_stats_task(data)
        ok = r.get('code') == 0
        if ok:
            self.task_id = r.get('result', {}).get('taskId')
        self.report.add_test_result("联邦统计", "创建任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建任务 (ID: {self.task_id})")

    def test_task_list(self):
        s = time.time()
        r = self.client.get_stats_task_list()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("联邦统计", "任务列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 任务列表 ({count}条)")

    def test_task_detail(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.get_stats_task_detail(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦统计", "任务详情", "passed" if ok else "failed", time.time()-s)
        state = r.get('result', {}).get('taskStateName', 'N/A')
        print(f"{'✅' if ok else '❌'} 任务详情 (状态:{state})")

    def test_run_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.run_stats_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦统计", "执行任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 执行任务")

    def test_stop_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.stop_stats_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦统计", "停止任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 停止任务")

    def test_storage_config(self):
        s = time.time()
        r = self.client.get_stats_storage_config()
        ok = r.get('code') == 0
        self.report.add_test_result("联邦统计", "存储配置查询", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 存储配置")

        s2 = time.time()
        r2 = self.client.save_stats_storage_config({
            "configName": f"存储配置测试_{int(time.time())}",
            "storageType": "local",
            "storagePath": "/tmp/stats_results"
        })
        ok2 = r2.get('code') == 0
        self.report.add_test_result("联邦统计", "存储配置保存", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok2 else '❌'} 保存存储配置")

    def test_logs(self):
        s = time.time()
        r = self.client.get_stats_logs()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("联邦统计", "日志查询", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 日志查询 ({count}条)")

    def test_delete_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.delete_stats_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦统计", "删除任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 删除任务")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'federated_stats_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    FederatedStatsTest().run()
