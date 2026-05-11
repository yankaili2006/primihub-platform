#!/usr/bin/env python3
"""联邦查询计费功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class FederatedBillingTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.rule_id = None

    def run(self):
        print("\n" + "="*60)
        print("联邦查询计费功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_create_rule()
            self.test_rule_list()
            self.test_rule_detail()
            self.test_toggle_rule()
            self.test_update_rule()
            self.test_record_list()
            self.test_statistics()
            self.test_delete_rule()
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
        self.report.add_test_result("联邦计费", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_create_rule(self):
        s = time.time()
        data = {
            "ruleName": f"计费规则测试_{int(time.time())}",
            "billingType": "by_count",
            "baseFee": 100,
            "pricePerQuery": 10,
            "minCharge": 10,
            "isActive": 1,
            "effectiveFrom": "2025-01-01",
            "effectiveTo": "2025-12-31"
        }
        r = self.client.create_billing_rule(data)
        ok = r.get('code') == 0
        if ok:
            self.rule_id = r.get('result', {}).get('ruleId')
        self.report.add_test_result("联邦计费", "创建规则", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建规则 (ID: {self.rule_id})")

    def test_rule_list(self):
        s = time.time()
        r = self.client.get_billing_rule_list()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("联邦计费", "规则列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 规则列表 ({count}条)")

    def test_rule_detail(self):
        if not self.rule_id: return
        s = time.time()
        r = self.client.get_billing_rule_detail(self.rule_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦计费", "规则详情", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 规则详情")

    def test_toggle_rule(self):
        if not self.rule_id: return
        s = time.time()
        r = self.client.toggle_billing_rule(self.rule_id, 0)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦计费", "禁用规则", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.toggle_billing_rule(self.rule_id, 1)
        ok2 = r2.get('code') == 0
        self.report.add_test_result("联邦计费", "启用规则", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 禁用/启用规则")

    def test_update_rule(self):
        if not self.rule_id: return
        s = time.time()
        r = self.client.update_billing_rule({
            "id": self.rule_id,
            "ruleName": f"计费规则已更新_{int(time.time())}",
            "pricePerQuery": 15,
            "minCharge": 20
        })
        ok = r.get('code') == 0
        self.report.add_test_result("联邦计费", "更新规则", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 更新规则")

    def test_record_list(self):
        s = time.time()
        r = self.client.get_billing_record_list()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("联邦计费", "记录列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 记录列表 ({count}条)")

    def test_statistics(self):
        s = time.time()
        r = self.client.get_billing_statistics()
        ok = r.get('code') == 0
        self.report.add_test_result("联邦计费", "统计查询", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 统计查询")

    def test_delete_rule(self):
        if not self.rule_id: return
        s = time.time()
        r = self.client.delete_billing_rule(self.rule_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦计费", "删除规则", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 删除规则")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'federated_billing_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    FederatedBillingTest().run()
