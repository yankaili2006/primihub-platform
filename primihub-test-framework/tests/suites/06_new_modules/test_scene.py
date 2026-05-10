#!/usr/bin/env python3
"""场景定制化功能测试 (警务数据融合 + 电子证件)"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://172.20.0.12:8080")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "Admin@123456")

class SceneTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.police_task_id = None
        self.police_key_id = None
        self.cert_task_id = None

    def run(self):
        print("\n" + "="*60)
        print("场景定制化功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_police_create_task()
            self.test_police_task_list()
            self.test_police_save_api()
            self.test_police_generate_key()
            self.test_police_encrypt_decrypt()
            self.test_cert_create_task()
            self.test_cert_api()
            self.test_cert_generate_key()
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
        self.report.add_test_result("场景定制化", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_police_create_task(self):
        s = time.time()
        r = self.client.create_police_task({"taskName": f"警务融合测试_{int(time.time())}", "taskType": "intersection"})
        ok = r.get('code') == 0
        if ok: self.police_task_id = r.get('result', {}).get('taskId')
        self.report.add_test_result("场景定制化", "警务-创建任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 警务-创建任务 (ID: {self.police_task_id})")

    def test_police_task_list(self):
        s = time.time()
        r = self.client.get_police_task_list()
        ok = r.get('code') == 0
        self.report.add_test_result("场景定制化", "警务-任务列表", "passed" if ok else "failed", time.time()-s)
        count = len(r.get('result', {}).get('list', []))
        print(f"{'✅' if ok else '❌'} 警务-任务列表 ({count}条)")

    def test_police_save_api(self):
        s = time.time()
        r = self.client.save_police_api({"apiName": f"测试警务API_{int(time.time())}", "apiUrl": "http://test.police/api/query"})
        ok = r.get('code') == 0
        self.report.add_test_result("场景定制化", "警务-保存API配置", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.get_police_api_list()
        ok2 = r2.get('code') == 0
        self.report.add_test_result("场景定制化", "警务-API配置列表", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 警务-API配置")

    def test_police_generate_key(self):
        s = time.time()
        r = self.client.generate_police_key({"keyName": f"警务测试密钥_{int(time.time())}", "scheme": "BFV", "keySize": 2048})
        ok = r.get('code') == 0
        if ok: self.police_key_id = r.get('result', {}).get('keyId')
        self.report.add_test_result("场景定制化", "警务-生成密钥", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 警务-生成密钥 (ID: {self.police_key_id})")

    def test_police_encrypt_decrypt(self):
        if not self.police_key_id: return
        s = time.time()
        r = self.client.encrypt_police_data(self.police_key_id, "测试敏感数据123")
        ok = r.get('code') == 0
        encrypted = r.get('result', {}).get('encryptedData', '')
        self.report.add_test_result("场景定制化", "警务-加密数据", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.decrypt_police_data(self.police_key_id, encrypted)
        ok2 = r2.get('code') == 0
        self.report.add_test_result("场景定制化", "警务-解密数据", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 警务-加密/解密")

    def test_cert_create_task(self):
        s = time.time()
        r = self.client.create_cert_task({"taskName": f"电子证件测试_{int(time.time())}", "taskType": "feature_convert"})
        ok = r.get('code') == 0
        if ok: self.cert_task_id = r.get('result', {}).get('taskId')
        self.report.add_test_result("场景定制化", "电子证件-创建任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 电子证件-创建任务 (ID: {self.cert_task_id})")

    def test_cert_api(self):
        s = time.time()
        r = self.client.get_cert_api_list()
        ok = r.get('code') == 0
        self.report.add_test_result("场景定制化", "电子证件-API列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 电子证件-API列表")

    def test_cert_generate_key(self):
        s = time.time()
        r = self.client.generate_cert_key({"keyName": f"证件测试密钥_{int(time.time())}", "scheme": "BFV", "keySize": 2048})
        ok = r.get('code') == 0
        self.report.add_test_result("场景定制化", "电子证件-生成密钥", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 电子证件-生成密钥")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'scene_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    SceneTest().run()
