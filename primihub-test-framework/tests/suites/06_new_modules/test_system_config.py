#!/usr/bin/env python3
"""系统配置功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class SystemConfigTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()

    def run(self):
        print("\n" + "="*60)
        print("系统配置功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_network_config()
            self.test_time_config()
            self.test_login_restriction()
            self.test_personalization()
            self.test_ftp_config()
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
        self.report.add_test_result("系统配置", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_network_config(self):
        s = time.time()
        r = self.client.get_network_config()
        ok = r.get('code') == 0
        self.report.add_test_result("系统配置", "网络配置查询", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.save_network_config({"domain": "test.primihub.com", "request_timeout": "30000"})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("系统配置", "网络配置保存", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 网络配置")

    def test_time_config(self):
        s = time.time()
        r = self.client.get_time_config()
        ok = r.get('code') == 0
        self.report.add_test_result("系统配置", "时间配置查询", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.save_time_config({"timezone": "Asia/Shanghai", "ntp_enabled": 1, "ntp_server": "ntp.aliyun.com"})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("系统配置", "时间配置保存", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 时间配置")

    def test_login_restriction(self):
        s = time.time()
        r = self.client.get_login_restriction()
        ok = r.get('code') == 0
        self.report.add_test_result("系统配置", "登录限制查询", "passed" if ok else "failed", time.time()-s)
        data = r.get('result', {})
        s2 = time.time()
        r2 = self.client.save_login_restriction({"maxLoginAttempts": 5, "captchaEnabled": 1, "sessionTimeoutMinutes": 30})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("系统配置", "登录限制保存", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 登录限制 (尝试次数:{data.get('maxLoginAttempts','N/A')})")

    def test_personalization(self):
        s = time.time()
        r = self.client.get_personalization_config()
        ok = r.get('code') == 0
        self.report.add_test_result("系统配置", "个性化设置查询", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.save_personalization_config({"platformName": "PrimiHub", "logoUrl": "/logo.png", "footer": "PrimiHub v2.0"})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("系统配置", "个性化设置保存", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 个性化设置")

    def test_ftp_config(self):
        s = time.time()
        r = self.client.get_ftp_config()
        ok = r.get('code') == 0
        self.report.add_test_result("系统配置", "FTP配置查询", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.save_ftp_config({"host": "ftp.example.com", "port": 21, "username": "test", "password": "pass"})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("系统配置", "FTP配置保存", "passed" if ok2 else "failed", time.time()-s2)
        s3 = time.time()
        r3 = self.client.test_ftp_connection({"host": "ftp.example.com", "port": 21, "username": "test", "password": "pass"})
        ok3 = r3.get('code') == 0
        self.report.add_test_result("系统配置", "FTP连接测试", "passed" if ok3 else "failed", time.time()-s3)
        print(f"{'✅' if ok else '❌'} FTP配置")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'system_config_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    SystemConfigTest().run()
