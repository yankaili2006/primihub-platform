#!/usr/bin/env python3
"""监控管理功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class MonitorTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()

    def run(self):
        print("\n" + "="*60)
        print("监控管理功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_system_monitor()
            self.test_cpu_monitor()
            self.test_memory_monitor()
            self.test_disk_monitor()
            self.test_jvm_monitor()
            self.test_alert_config()
            self.test_alert_history()
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
        self.report.add_test_result("监控管理", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_system_monitor(self):
        s = time.time()
        r = self.client.get_system_monitor()
        ok = r.get('code') == 0 and r.get('result', {}).get('cpuUsage') is not None
        self.report.add_test_result("监控管理", "系统监控", "passed" if ok else "failed", time.time()-s)
        cpu = r.get('result', {}).get('cpuUsage', 'N/A')
        mem = r.get('result', {}).get('memoryUsage', 'N/A')
        print(f"{'✅' if ok else '❌'} 系统监控 (CPU:{cpu}% 内存:{mem}%)")

    def test_cpu_monitor(self):
        s = time.time()
        r = self.client.get_cpu_monitor()
        ok = r.get('code') == 0
        self.report.add_test_result("监控管理", "CPU监控", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} CPU监控")

    def test_memory_monitor(self):
        s = time.time()
        r = self.client.get_memory_monitor()
        ok = r.get('code') == 0
        self.report.add_test_result("监控管理", "内存监控", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 内存监控")

    def test_disk_monitor(self):
        s = time.time()
        r = self.client.get_disk_monitor()
        ok = r.get('code') == 0
        self.report.add_test_result("监控管理", "磁盘监控", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 磁盘监控")

    def test_jvm_monitor(self):
        s = time.time()
        r = self.client.get_jvm_monitor()
        ok = r.get('code') == 0
        self.report.add_test_result("监控管理", "JVM监控", "passed" if ok else "failed", time.time()-s)
        heap = r.get('result', {}).get('heapUsage', 'N/A')
        print(f"{'✅' if ok else '❌'} JVM监控 (堆:{heap}%)")

    def test_alert_config(self):
        s = time.time()
        r = self.client.get_alert_config()
        ok = r.get('code') == 0
        self.report.add_test_result("监控管理", "告警配置查询", "passed" if ok else "failed", time.time()-s)
        s2 = time.time()
        r2 = self.client.save_alert_config({"type": "CPU", "threshold": 85, "duration": 300, "enabled": 1})
        ok2 = r2.get('code') == 0
        self.report.add_test_result("监控管理", "告警配置保存", "passed" if ok2 else "failed", time.time()-s2)
        print(f"{'✅' if ok else '❌'} 告警配置")

    def test_alert_history(self):
        s = time.time()
        r = self.client.get_alert_history()
        ok = r.get('code') == 0
        self.report.add_test_result("监控管理", "告警历史", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 告警历史")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'monitor_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    MonitorTest().run()
