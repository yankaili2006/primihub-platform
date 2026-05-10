#!/usr/bin/env python3
"""接口管理功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class ApiManageTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.api_id = None
        self.auth_id = None

    def run(self):
        print("\n" + "="*60)
        print("接口管理功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_add_api()
            self.test_get_api_detail()
            self.test_toggle_api_status()
            self.test_add_api_auth()
            self.test_get_api_statistics()
            self.test_get_api_page()
            self.test_delete_api()
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
        self.report.add_test_result("接口管理", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_add_api(self):
        s = time.time()
        data = {"apiName": f"测试接口_{int(time.time())}", "apiPath": "/api/test/hello", "apiMethod": "GET",
                "description": "接口管理测试", "protocol": "REST"}
        r = self.client.add_api(data)
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "新增接口", "passed" if ok else "failed", time.time()-s)
        if ok:
            r2 = self.client.get_api_page(page=1, page_size=100)
            items = r2.get('result', {}).get('list', [])
            for item in items:
                if item.get('apiPath') == '/api/test/hello':
                    self.api_id = item.get('id')
                    break
        print(f"{'✅' if ok else '❌'} 新增接口 (ID: {self.api_id})")

    def test_get_api_detail(self):
        if not self.api_id: return
        s = time.time()
        r = self.client.get_api_detail(self.api_id)
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "查询详情", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 查询详情")

    def test_toggle_api_status(self):
        if not self.api_id: return
        s = time.time()
        r = self.client.toggle_api_status(self.api_id, 0)
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "禁用接口", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.toggle_api_status(self.api_id, 1)
        ok2 = r2.get('code') == 0
        self.report.add_test_result("接口管理", "启用接口", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 禁用/启用接口")

    def test_add_api_auth(self):
        if not self.api_id: return
        s = time.time()
        data = {"apiId": self.api_id, "authName": f"测试授权_{int(time.time())}",
                "authType": "APP_KEY", "description": "接口授权测试"}
        r = self.client.add_api_auth(data)
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "新增授权", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 新增授权")

    def test_get_api_statistics(self):
        s = time.time()
        r = self.client.get_api_statistics()
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "调用统计", "passed" if ok else "failed", time.time()-s)
        total = r.get('result', {}).get('totalCalls', 0)
        print(f"{'✅' if ok else '❌'} 调用统计 (总计:{total})")

    def test_get_api_page(self):
        s = time.time()
        r = self.client.get_api_page()
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "查询列表", "passed" if ok else "failed", time.time()-s)
        count = len(r.get('result', {}).get('list', []))
        print(f"{'✅' if ok else '❌'} 查询列表 ({count}条)")

    def test_delete_api(self):
        if not self.api_id: return
        s = time.time()
        r = self.client.delete_api(self.api_id)
        ok = r.get('code') == 0
        self.report.add_test_result("接口管理", "删除接口", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 删除接口")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'api_manage_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    ApiManageTest().run()
