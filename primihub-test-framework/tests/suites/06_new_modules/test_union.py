#!/usr/bin/env python3
"""联邦求并功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class UnionTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.task_id = None

    def run(self):
        print("\n" + "="*60)
        print("联邦求并功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_save_union()
            self.test_task_list()
            self.test_task_details()
            self.test_cancel_task()
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
        self.report.add_test_result("联邦求并", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_save_union(self):
        s = time.time()
        data = {
            "ownOrganId": 1, "ownResourceId": 1, "ownKeyword": "id",
            "otherOrganId": 2, "otherResourceId": 2, "otherKeyword": "uid",
            "resultName": f"求并测试_{int(time.time())}",
            "resultOrganIds": "1,2",
            "tag": 0,
            "remarks": "联邦求并自动化测试"
        }
        r = self.client.save_data_union(data)
        ok = r.get('code') == 0
        if ok:
            res = r.get('result', {})
            self.task_id = res if isinstance(res, (int, str)) else res.get('taskId')
        self.report.add_test_result("联邦求并", "创建求并任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建任务 (ID: {self.task_id})")

    def test_task_list(self):
        s = time.time()
        r = self.client.get_union_task_list()
        ok = r.get('code') == 0
        self.report.add_test_result("联邦求并", "任务列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 任务列表")

    def test_task_details(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.get_union_task_details(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦求并", "任务详情", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 任务详情")

    def test_cancel_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.cancel_union_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦求并", "取消任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 取消任务")

    def test_delete_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.del_union_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦求并", "删除任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 删除任务")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'union_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    UnionTest().run()
