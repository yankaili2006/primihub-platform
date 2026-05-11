#!/usr/bin/env python3
"""存证管理功能测试"""
import sys, os, time, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class EvidenceTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.evidence_id = None

    def run(self):
        print("\n" + "="*60)
        print("存证管理功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_create_evidence()
            self.test_evidence_detail()
            self.test_verify_evidence()
            self.test_get_statistics()
            self.test_apply_timestamp()
            self.test_timestamp_page()
            self.test_evidence_config()
            self.test_chain_list()
            self.test_api_list_and_key()
            self.test_regenerate_api_key()
            self.test_get_evidence_page()
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
        self.report.add_test_result("存证管理", "登录", "passed" if ok else "failed", time.time()-s,
                                     "" if ok else str(r))
        print(f"{'✅' if ok else '❌'} 登录{'成功' if ok else '失败'}")

    def test_create_evidence(self):
        s = time.time()
        r = self.client.create_evidence({"data": "测试存证数据_" + str(int(time.time())), "evidenceType": "text"})
        ok = r.get('code') == 0
        if ok: self.evidence_id = r.get('result', {}).get('id')
        self.report.add_test_result("存证管理", "创建存证", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建存证 (ID: {self.evidence_id})")

    def test_evidence_detail(self):
        if not self.evidence_id: return
        s = time.time()
        r = self.client.get_evidence_detail(self.evidence_id)
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "存证详情", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 存证详情")

    def test_verify_evidence(self):
        if not self.evidence_id: return
        s = time.time()
        r = self.client.verify_evidence(self.evidence_id)
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "验证存证", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 验证存证")

    def test_get_statistics(self):
        s = time.time()
        r = self.client.get_evidence_statistics()
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "查询统计", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 查询统计 total={r.get('result',{}).get('total',0)}")

    def test_apply_timestamp(self):
        if not self.evidence_id: return
        s = time.time()
        r = self.client.apply_timestamp(self.evidence_id)
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "申请时间戳", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 申请时间戳")

    def test_timestamp_page(self):
        s = time.time()
        r = self.client.find_timestamp_page()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("存证管理", "时间戳列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 时间戳列表 ({count}条)")

    def test_evidence_config(self):
        s = time.time()
        r = self.client.get_evidence_config()
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "查询配置", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.save_evidence_config({"blockchain_type": "FABRIC"})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("存证管理", "保存配置", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 查询配置 | {'✅' if ok2 else '❌'} 保存配置")

    def test_chain_list(self):
        s = time.time()
        r = self.client.get_chain_list()
        ok = r.get('code') == 0
        chains = r.get('result', [])
        chain_names = [c.get('name', c.get('type', '')) for c in chains] if chains else []
        self.report.add_test_result("存证管理", "区块链列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 区块链列表 ({'/'.join(chain_names)})")

    def test_api_list_and_key(self):
        s = time.time()
        r = self.client.get_evidence_api_list()
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "API接口列表", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.get_evidence_api_key()
        ok2 = r2.get('code') == 0
        self.report.add_test_result("存证管理", "API密钥查询", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} API接口 | {'✅' if ok2 else '❌'} API密钥")

    def test_regenerate_api_key(self):
        s = time.time()
        r = self.client.regenerate_api_key("测试API密钥")
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "重新生成API密钥", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 重新生成API密钥")

    def test_get_evidence_page(self):
        s = time.time()
        r = self.client.get_evidence_page()
        ok = r.get('code') == 0
        self.report.add_test_result("存证管理", "查询列表", "passed" if ok else "failed", time.time()-s)
        count = len(r.get('result',{}).get('list',[]))
        print(f"{'✅' if ok else '❌'} 查询列表 ({count}条)")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'evidence_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    EvidenceTest().run()
