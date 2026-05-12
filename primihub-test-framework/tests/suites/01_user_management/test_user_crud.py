import pytest
import time
import logging
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

logger = logging.getLogger(__name__)


class UserManagementTest:
    def __init__(self, base_url, admin_user, admin_password):
        self.client = PrimiHubAPIClient(base_url)
        self.admin_user = admin_user
        self.admin_password = admin_password
        self.report = TestReport()
        self.created_user_ids = []

    def run(self):
        print("\n" + "=" * 60)
        print("用户管理功能测试".center(60))
        print("=" * 60)
        try:
            self.test_login()
            self.test_get_user_list()
            self.test_create_user()
            self.test_get_user_by_account()
            self.test_update_user()
            self.test_freeze_unfreeze()
            self.test_delete_user()
            self.test_role_apis()
            self.generate_report()
        except Exception as e:
            print(f"\n错误: {e}")
            import traceback; traceback.print_exc()
        finally:
            self.cleanup()
            try: self.client.logout()
            except: pass

    def cleanup(self):
        for uid in self.created_user_ids:
            try:
                self.client.delete_user([uid])
                print(f"  清理: 删除用户 {uid}")
            except Exception:
                pass

    def test_login(self):
        s = time.time()
        r = self.client.login(self.admin_user, self.admin_password)
        ok = r.get("code") == 0
        self.report.add_test_result("用户管理", "登录", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 登录 ({'成功' if ok else r.get(\"msg\", \"失败\")})")

    def test_get_user_list(self):
        s = time.time()
        r = self.client.get_user_list(page=1, page_size=10)
        ok = r.get("code") == 0
        cnt = 0
        result = r.get("result", {})
        if isinstance(result, dict):
            cnt = len(result.get("list", []))
        elif isinstance(result, list):
            cnt = len(result)
        self.report.add_test_result("用户管理", "获取用户列表", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 获取用户列表 (共{cnt}个用户)")

    def test_create_user(self):
        ts = int(time.time())
        user = {
            "userAccount": f"tuser_{ts}",
            "userName": f"测试_{ts}",
            "userPassword": "Test@123456",
            "userPhone": f"138{ts % 10000000000:010d}"[:11],
            "userEmail": f"tuser_{ts}@example.com",
        }
        s = time.time()
        r = self.client.create_user(user)
        ok = r.get("code") == 0
        uid = r.get("result", {}).get("userId")
        if uid:
            self.created_user_ids.append(uid)
        self.report.add_test_result("用户管理", "创建用户", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 创建用户 {user['userAccount']} ({'成功' if ok else r.get('msg', '失败')})")

    def test_get_user_by_account(self):
        s = time.time()
        r = self.client.get_user_by_account("admin")
        ok = r.get("code") == 0 and r.get("result", {}).get("userAccount") == "admin"
        self.report.add_test_result("用户管理", "查询用户", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 查询用户 admin ({'找到' if ok else '失败'})")

    def test_update_user(self):
        if not self.created_user_ids:
            print("⚠️ 跳过修改用户：无已创建用户")
            self.report.add_test_result("用户管理", "修改用户", "skipped", 0, "无已创建用户")
            return
        uid = self.created_user_ids[0]
        update = {"userId": uid, "userName": f"已修改_{int(time.time())}"}
        s = time.time()
        r = self.client.update_user(update)
        ok = r.get("code") == 0
        self.report.add_test_result("用户管理", "修改用户", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 修改用户 ID={uid}")

    def test_freeze_unfreeze(self):
        if not self.created_user_ids:
            print("⚠️ 跳过冻结/解冻：无已创建用户")
            self.report.add_test_result("用户管理", "冻结用户", "skipped", 0, "无已创建用户")
            self.report.add_test_result("用户管理", "解冻用户", "skipped", 0, "无已创建用户")
            return
        uid = self.created_user_ids[0]
        s = time.time()
        r1 = self.client.freeze_user(uid)
        ok1 = r1.get("code") == 0
        self.report.add_test_result("用户管理", "冻结用户", "passed" if ok1 else "failed", time.time() - s)
        print(f"{'✅' if ok1 else '❌'} 冻结用户 ID={uid}")
        s = time.time()
        r2 = self.client.unfreeze_user(uid)
        ok2 = r2.get("code") == 0
        self.report.add_test_result("用户管理", "解冻用户", "passed" if ok2 else "failed", time.time() - s)
        print(f"{'✅' if ok2 else '❌'} 解冻用户 ID={uid}")

    def test_delete_user(self):
        if len(self.created_user_ids) < 1:
            print("⚠️ 跳过删除用户：无已创建用户")
            self.report.add_test_result("用户管理", "删除用户", "skipped", 0, "无已创建用户")
            return
        uid = self.created_user_ids.pop()
        s = time.time()
        r = self.client.delete_user([uid])
        ok = r.get("code") == 0
        self.report.add_test_result("用户管理", "删除用户", "passed" if ok else "failed", time.time() - s)
        print(f"{'✅' if ok else '❌'} 删除用户 ID={uid}")

    def test_role_apis(self):
        apis = [
            ("获取角色列表", lambda: self.client._make_request("GET", "/sys/role/findRolePage", params={"pageNum": 1, "pageSize": 10})),
        ]
        for name, fn in apis:
            s = time.time()
            try:
                r = fn()
                ok = r.get("code") == 0
                self.report.add_test_result("用户管理", name, "passed" if ok else "failed", time.time() - s)
                print(f"{'✅' if ok else '❌'} {name}")
            except Exception as e:
                self.report.add_test_result("用户管理", name, "error", time.time() - s, str(e))
                print(f"❌ {name}: {e}")

    def generate_report(self):
        report_dir = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(report_dir, exist_ok=True)
        ts = time.strftime("%Y%m%d_%H%M%S")
        self.report.generate_html_report(os.path.join(report_dir, f"user_management_{ts}.html"))
        self.report.generate_json_report(os.path.join(report_dir, f"user_management_{ts}.json"))
        self.report.print_summary()


if __name__ == "__main__":
    import logging
    logging.basicConfig(level=logging.INFO)
    base_url = os.environ.get("API_BASE_URL", "http://localhost:8080")
    admin_user = os.environ.get("ADMIN_USER", "admin")
    admin_pwd = os.environ.get("ADMIN_PASSWORD", "123456")
    test = UserManagementTest(base_url, admin_user, admin_pwd)
    test.run()
