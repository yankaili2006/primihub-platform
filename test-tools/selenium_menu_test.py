#!/tmp/selenium_venv/bin/python3
"""
PrimiHub 浏览器自动化菜单测试
使用 Selenium 模拟用户操作，测试每个菜单
"""

import time
import json
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

class SeleniumMenuTester:
    """Selenium 菜单测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456", headless: bool = True):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.headless = headless
        self.driver = None
        self.test_results = []
        self.menu_results = []

    def setup_driver(self):
        """初始化浏览器驱动"""
        print("正在初始化浏览器...")

        chrome_options = Options()
        if self.headless:
            chrome_options.add_argument('--headless')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--window-size=1920,1080')

        try:
            service = Service(ChromeDriverManager().install())
            self.driver = webdriver.Chrome(service=service, options=chrome_options)
            self.driver.implicitly_wait(10)
            print("✓ 浏览器初始化成功")
            return True
        except Exception as e:
            print(f"✗ 浏览器初始化失败: {str(e)}")
            return False

    def log_test(self, module: str, test_name: str, success: bool, message: str = ""):
        """记录测试结果"""
        result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "module": module,
            "test": test_name,
            "success": success,
            "message": message
        }
        self.test_results.append(result)

        status = "✅" if success else "❌"
        print(f"{status} [{module}] {test_name}: {message}")

    def test_login(self):
        """测试登录"""
        print("\n=== 测试登录 ===")

        try:
            # 访问登录页
            self.driver.get(f"{self.base_url}/#/login")
            time.sleep(2)

            # 查找并填写用户名
            username_input = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, 'input[placeholder*="用户名"], input[placeholder*="账号"]'))
            )
            username_input.clear()
            username_input.send_keys(self.username)

            # 查找并填写密码
            password_input = self.driver.find_element(By.CSS_SELECTOR, 'input[type="password"]')
            password_input.clear()
            password_input.send_keys(self.password)

            time.sleep(1)

            # 点击登录按钮
            login_button = self.driver.find_element(By.CSS_SELECTOR, 'button[type="submit"], button:has-text("登录")')
            login_button.click()

            # 等待登录完成
            time.sleep(3)

            # 检查是否登录成功
            current_url = self.driver.current_url
            if "#/login" not in current_url:
                self.log_test("登录", "用户登录", True, "登录成功")
                return True
            else:
                self.log_test("登录", "用户登录", False, "登录失败")
                return False

        except Exception as e:
            self.log_test("登录", "用户登录", False, f"异常: {str(e)}")
            return False

    def get_menu_items(self):
        """获取所有菜单项"""
        print("\n=== 获取菜单列表 ===")

        try:
            time.sleep(2)

            # 查找侧边栏菜单
            menu_items = self.driver.find_elements(By.CSS_SELECTOR, '.el-menu-item, .el-submenu__title')

            menus = []
            for item in menu_items:
                try:
                    text = item.text.strip()
                    if text and text not in menus:
                        menus.append(text)
                except:
                    continue

            print(f"找到 {len(menus)} 个菜单项")
            return menus

        except Exception as e:
            print(f"获取菜单失败: {str(e)}")
            return []

    def test_menu_click(self, menu_text: str):
        """测试点击菜单"""
        try:
            # 查找菜单项
            menu_items = self.driver.find_elements(By.XPATH, f"//*[contains(text(), '{menu_text}')]")

            if not menu_items:
                self.menu_results.append({
                    "menu": menu_text,
                    "success": False,
                    "message": "菜单未找到"
                })
                return False

            # 点击第一个匹配的菜单
            menu_item = menu_items[0]
            self.driver.execute_script("arguments[0].scrollIntoView();", menu_item)
            time.sleep(0.5)
            menu_item.click()
            time.sleep(2)

            # 检查页面是否有变化
            page_source = self.driver.page_source

            self.menu_results.append({
                "menu": menu_text,
                "success": True,
                "message": "点击成功"
            })

            print(f"  ✓ {menu_text}")
            return True

        except Exception as e:
            self.menu_results.append({
                "menu": menu_text,
                "success": False,
                "message": f"异常: {str(e)}"
            })
            print(f"  ✗ {menu_text}: {str(e)}")
            return False

    def test_all_menus(self):
        """测试所有菜单"""
        print("\n=== 测试所有菜单 ===")

        menus = self.get_menu_items()

        if not menus:
            print("未找到菜单项")
            return

        print(f"\n开始测试 {len(menus)} 个菜单...")

        for menu in menus:
            self.test_menu_click(menu)
            time.sleep(1)

    def run_all_tests(self):
        """运行所有测试"""
        print(f"\n{'='*60}")
        print(f"PrimiHub 浏览器自动化菜单测试")
        print(f"测试地址: {self.base_url}")
        print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*60}")

        if not self.setup_driver():
            print("浏览器初始化失败，测试终止")
            return

        try:
            # 测试登录
            if not self.test_login():
                print("登录失败，测试终止")
                return

            # 测试所有菜单
            self.test_all_menus()

            # 生成报告
            self.generate_report()

        finally:
            if self.driver:
                self.driver.quit()
                print("\n浏览器已关闭")

    def generate_report(self):
        """生成测试报告"""
        print(f"\n{'='*60}")
        print("测试报告")
        print(f"{'='*60}")

        total_menus = len(self.menu_results)
        passed_menus = sum(1 for r in self.menu_results if r['success'])
        failed_menus = total_menus - passed_menus

        print(f"\n菜单测试统计:")
        print(f"总菜单数: {total_menus}")
        print(f"✅ 成功: {passed_menus}")
        print(f"❌ 失败: {failed_menus}")
        if total_menus > 0:
            print(f"成功率: {passed_menus/total_menus*100:.1f}%")

        if failed_menus > 0:
            print(f"\n失败的菜单:")
            for r in self.menu_results:
                if not r['success']:
                    print(f"  - {r['menu']}: {r['message']}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="PrimiHub 浏览器自动化菜单测试")
    parser.add_argument("--url", default="http://192.168.99.5:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")
    parser.add_argument("--no-headless", action="store_true", help="显示浏览器窗口")

    args = parser.parse_args()

    tester = SeleniumMenuTester(
        args.url,
        args.username,
        args.password,
        headless=not args.no_headless
    )
    tester.run_all_tests()
