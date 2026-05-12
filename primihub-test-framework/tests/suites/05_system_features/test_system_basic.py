import pytest
import time
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport


class SystemFeaturesTest:
    def __init__(self, base_url, admin_user, admin_password):
        self.client = PrimiHubAPIClient(base_url)
        self.admin_user = admin_user
        self.admin_password = admin_password
        self.report = TestReport()

    def run(self):
        print("\n" + "=" * 60)
        print("系统功能测试".center(60))
        print("=" * 60)
        try:
            self.test_login()
            self.test_homepage()
            self.test_health()
            self.test_system_config()
            self.test_organ_management()
            self.test_role_management()
            self.test_auth_list()
            self.test_swagger()
            self.generate_report()
        except Exception as e:
            print(f"\n错误: {e}")
            import traceback; traceback.print_exc()
        finally:
            try: self.client.logout()
            except: pass

    def test_login(self):
        s = time.time()
        r = self.client.login(self.admin_user, self.admin_password)
        ok = r.get("code") == 0
        self.report.add_test_result("系统功能", "登录", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_homepage(self):
        s = time.time()
        r = self.client._make_request("GET", "/sys/organ/getHomepage")
        ok = r.get("code") == 0
        self.report.add_test_result("系统功能", "首页配置", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 首页配置")

    def test_health(self):
        s = time.time()
        r = self.client._make_request("GET", "/test/healthConnection")
        ok = r.get("code") == 0
        elapsed = time.time() - s
        self.report.add_test_result("系统功能", "健康检查", "passed" if ok else "failed", elapsed)
        print(f"{'✅' if ok else '❌'} 健康检查 ({elapsed:.2f}s)")

    def test_system_config(self):
        apis = [
            ("网络配置", lambda: self.client._make_request("GET", "/systemConfig/getNetworkConfig")),
            ("登录限制", lambda: self.client._make_request("GET", "/systemConfig/getLoginRestriction")),
            ("个性化配置", lambda: self.client._make_request("GET", "/systemConfig/getPersonalizationConfig")),
            ("FTP配置", lambda: self.client._make_request("GET", "/systemConfig/getFtpConfig")),
            ("时间配置", lambda: self.client._make_request("GET", "/systemConfig/getTimeConfig")),
        ]
        for name, fn in apis:
            s = time.time()
            try:
                r = fn()
                ok = r.get("code") == 0
                self.report.add_test_result("系统功能", name, "passed" if ok else "failed", time.time() - s)
                print(f"{'✅' if ok else '❌'} {name}")
            except Exception as e:
                self.report.add_test_result("系统功能", name, "error", time.time() - s, str(e))
                print(f"❌ {name}: {e}")

    def test_organ_management(self):
        s = time.time()
        r = self.client.get_organ_list()
        ok = r.get("code") == 0
        organs = r.get("result", [])
        self.report.add_test_result("系统功能", "机构列表", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 机构列表 ({len(organs)}个)")

    def test_role_management(self):
        s = time.time()
        r = self.client._make_request("GET", "/sys/role/findRolePage", params={"pageNum": 1, "pageSize": 10})
        ok = r.get("code") == 0
        self.report.add_test_result("系统功能", "角色列表", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 角色列表")

    def test_auth_list(self):
        s = time.time()
        r = self.client._make_request("GET", "/sys/oauth/getAuthList")
        ok = r.get("code") == 0
        auths = r.get("result", [])
        self.report.add_test_result("系统功能", "认证列表", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 认证列表 ({len(auths)}项)")

    def test_swagger(self):
        s = time.time()
        try:
            r = self.client._make_request("GET", "/v2/api-docs")
            ok = r.get("code") == 0 or "swagger" in str(r).lower()
            self.report.add_test_result("系统功能", "Swagger文档", "passed" if ok else "failed", time.time() - s)
            print(f"{'✅' if ok else '❌'} Swagger文档")
        except Exception as e:
            self.report.add_test_result("系统功能", "Swagger文档", "error", time.time() - s, str(e))
            print(f"❌ Swagger文档: {e}")

    def generate_report(self):
        report_dir = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(report_dir, exist_ok=True)
        ts = time.strftime("%Y%m%d_%H%M%S")
        self.report.generate_html_report(os.path.join(report_dir, f"system_features_{ts}.html"))
        self.report.generate_json_report(os.path.join(report_dir, f"system_features_{ts}.json"))
        self.report.print_summary()


if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.INFO)
    base_url = os.environ.get("API_BASE_URL", "http://localhost:8080")
    admin_user = os.environ.get("ADMIN_USER", "admin")
    admin_pwd = os.environ.get("ADMIN_PASSWORD", "123456")
    test = SystemFeaturesTest(base_url, admin_user, admin_pwd)
    test.run()
