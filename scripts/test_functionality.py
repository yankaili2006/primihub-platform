#!/usr/bin/env python3
"""
PrimiHub 平台功能测试 - 登录后基本功能验证
"""

import sys
import time
import json
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:8080"
USERNAME = "admin"
PASSWORD = "123456"

Colors_GREEN = '\033[0;32m'
Colors_RED = '\033[0;31m'
Colors_YELLOW = '\033[1;33m'
Colors_BLUE = '\033[0;34m'
Colors_NC = '\033[0m'

class FunctionalityTester:
    def __init__(self, page):
        self.page = page
        self.test_results = []

    def log_test(self, name, passed, message=""):
        status = f"{Colors_GREEN}✓" if passed else f"{Colors_RED}✗"
        self.test_results.append({'name': name, 'passed': passed, 'message': message})
        print(f"{status} {name}{Colors_NC}")
        if message:
            print(f"  {message}")

    def login(self):
        """执行登录"""
        print(f"{Colors_BLUE}[登录] 开始登录{Colors_NC}")
        self.page.goto(BASE_URL, wait_until="networkidle")
        time.sleep(2)

        self.page.locator('input[type="text"]').first.fill(USERNAME)
        self.page.locator('input[type="password"]').first.fill(PASSWORD)
        self.page.locator('button:has-text("登录")').first.click()

        # 等待URL改变（离开登录页）
        try:
            self.page.wait_for_url(lambda url: "login" not in url.lower(), timeout=20000)
            time.sleep(1)  # 等待页面稳定
        except Exception as e:
            print(f"  等待跳转超时: {e}")

        current_url = self.page.url
        success = "login" not in current_url.lower()
        self.log_test("用户登录", success, f"URL: {current_url}")
        return success

    def test_navigation_menu(self):
        """测试导航菜单"""
        print(f"\n{Colors_BLUE}[测试1/6] 导航菜单功能{Colors_NC}")

        # 检查主要导航项
        nav_items = {
            "项目管理": ["项目管理", "Project"],
            "模型管理": ["模型管理", "Model"],
            "隐匿查询": ["隐匿查询", "PrivateSearch"],  # 修改：使用正确的文本"隐匿查询"
            "隐私求交": ["隐私求交", "PSI"],
            "资源管理": ["我的资源", "Resource", "资源管理"]  # 修改：添加"我的资源"
        }

        found_count = 0
        for nav_name, search_terms in nav_items.items():
            found = False
            for term in search_terms:
                try:
                    if self.page.locator(f'text="{term}"').count() > 0:
                        found = True
                        break
                except:
                    pass

            if found:
                found_count += 1
                self.log_test(f"导航项: {nav_name}", True)
            else:
                self.log_test(f"导航项: {nav_name}", False, "未找到")

        self.page.screenshot(path="/tmp/test_navigation.png")
        return found_count >= 3

    def test_project_list(self):
        """测试项目列表页面"""
        print(f"\n{Colors_BLUE}[测试2/6] 项目列表功能{Colors_NC}")

        try:
            # 查找并点击项目管理
            project_links = self.page.locator('text="项目管理"')
            if project_links.count() > 0:
                project_links.first.click()
                time.sleep(3)

                # 检查是否到达项目列表页
                current_url = self.page.url
                is_project_page = "project" in current_url.lower()
                self.log_test("访问项目列表页", is_project_page, f"URL: {current_url}")

                # 检查页面元素
                has_table = self.page.locator('table, .el-table').count() > 0
                self.log_test("项目列表表格", has_table)

                # 检查是否有搜索框
                has_search = self.page.locator('input[placeholder*="搜索"], input[placeholder*="查询"]').count() > 0
                self.log_test("搜索功能", has_search)

                self.page.screenshot(path="/tmp/test_project_list.png")
                return is_project_page
            else:
                self.log_test("访问项目列表页", False, "未找到项目管理链接")
                return False
        except Exception as e:
            self.log_test("访问项目列表页", False, f"异常: {str(e)}")
            return False

    def test_resource_management(self):
        """测试资源管理功能"""
        print(f"\n{Colors_BLUE}[测试3/6] 资源管理功能{Colors_NC}")

        try:
            # 查找资源管理链接 - 修改：使用"我的资源"
            resource_links = self.page.locator('text="我的资源"')
            if resource_links.count() == 0:
                resource_links = self.page.locator('text="资源管理"')
            if resource_links.count() == 0:
                resource_links = self.page.locator('text="资源"')

            if resource_links.count() > 0:
                resource_links.first.click()
                time.sleep(3)

                current_url = self.page.url
                is_resource_page = "resource" in current_url.lower()
                self.log_test("访问资源管理页", is_resource_page, f"URL: {current_url}")

                # 检查页面内容
                has_content = self.page.locator('.el-table, .resource-list, table').count() > 0
                self.log_test("资源列表显示", has_content)

                self.page.screenshot(path="/tmp/test_resource_mgmt.png")
                return is_resource_page
            else:
                self.log_test("访问资源管理页", False, "未找到资源管理链接")
                return False
        except Exception as e:
            self.log_test("访问资源管理页", False, f"异常: {str(e)}")
            return False

    def test_psi_functionality(self):
        """测试隐私求交功能"""
        print(f"\n{Colors_BLUE}[测试4/6] 隐私求交(PSI)功能{Colors_NC}")

        try:
            # 查找PSI链接
            psi_links = self.page.locator('text="隐私求交"')
            if psi_links.count() == 0:
                psi_links = self.page.locator('text="PSI"')

            if psi_links.count() > 0:
                psi_links.first.click()
                time.sleep(3)

                current_url = self.page.url
                is_psi_page = "psi" in current_url.lower()
                self.log_test("访问PSI页面", is_psi_page, f"URL: {current_url}")

                # 检查PSI任务列表
                has_task_list = self.page.locator('.el-table, table, .task-list').count() > 0
                self.log_test("PSI任务列表", has_task_list)

                # 检查是否有新建按钮
                has_create_btn = self.page.locator('button:has-text("新建"), button:has-text("创建")').count() > 0
                self.log_test("新建PSI任务按钮", has_create_btn)

                self.page.screenshot(path="/tmp/test_psi.png")
                return is_psi_page
            else:
                self.log_test("访问PSI页面", False, "未找到PSI链接")
                return False
        except Exception as e:
            self.log_test("访问PSI页面", False, f"异常: {str(e)}")
            return False

    def test_model_management(self):
        """测试模型管理功能"""
        print(f"\n{Colors_BLUE}[测试5/6] 模型管理功能{Colors_NC}")

        try:
            # 查找模型管理链接
            model_links = self.page.locator('text="模型管理"')
            if model_links.count() == 0:
                model_links = self.page.locator('text="模型"')

            if model_links.count() > 0:
                model_links.first.click()
                time.sleep(3)

                current_url = self.page.url
                is_model_page = "model" in current_url.lower()
                self.log_test("访问模型管理页", is_model_page, f"URL: {current_url}")

                # 检查模型列表
                has_list = self.page.locator('.el-table, table, .model-list').count() > 0
                self.log_test("模型列表显示", has_list)

                self.page.screenshot(path="/tmp/test_model_mgmt.png")
                return is_model_page
            else:
                self.log_test("访问模型管理页", False, "未找到模型管理链接")
                return False
        except Exception as e:
            self.log_test("访问模型管理页", False, f"异常: {str(e)}")
            return False

    def test_user_profile(self):
        """测试用户信息功能"""
        print(f"\n{Colors_BLUE}[测试6/6] 用户信息功能{Colors_NC}")

        try:
            # 查找用户头像或用户名 - 修复CSS选择器
            user_elements = self.page.locator('.user-info, .avatar, .user-name')
            if user_elements.count() == 0:
                # 尝试查找包含admin文本的元素
                user_elements = self.page.locator(':text("admin")')

            has_user_info = user_elements.count() > 0
            self.log_test("用户信息显示", has_user_info)

            # 尝试查找退出登录按钮
            logout_selectors = ['text="退出"', 'text="登出"', 'text="Logout"']
            logout_exists = False
            for selector in logout_selectors:
                if self.page.locator(selector).count() > 0:
                    logout_exists = True
                    break

            self.log_test("退出登录功能", logout_exists)

            self.page.screenshot(path="/tmp/test_user_profile.png")
            return has_user_info
        except Exception as e:
            self.log_test("用户信息显示", False, f"异常: {str(e)}")
            return False

    def generate_report(self):
        """生成测试报告"""
        print(f"\n{Colors_BLUE}{'=' * 60}{Colors_NC}")
        print(f"{Colors_BLUE}测试报告{Colors_NC}")
        print(f"{Colors_BLUE}{'=' * 60}{Colors_NC}\n")

        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r['passed'])
        failed = total - passed

        print(f"总测试数: {total}")
        print(f"{Colors_GREEN}通过: {passed}{Colors_NC}")
        print(f"{Colors_RED}失败: {failed}{Colors_NC}")
        print(f"成功率: {(passed/total*100):.1f}%\n")

        if failed > 0:
            print(f"{Colors_YELLOW}失败的测试:{Colors_NC}")
            for r in self.test_results:
                if not r['passed']:
                    print(f"  - {r['name']}")
                    if r['message']:
                        print(f"    {r['message']}")
            print()

        print("生成的截图:")
        screenshots = [
            "/tmp/test_navigation.png",
            "/tmp/test_project_list.png",
            "/tmp/test_resource_mgmt.png",
            "/tmp/test_psi.png",
            "/tmp/test_model_mgmt.png",
            "/tmp/test_user_profile.png"
        ]
        for ss in screenshots:
            print(f"  - {ss}")

        return passed >= total * 0.6  # 60%通过率

def main():
    print(f"\n{Colors_BLUE}{'=' * 60}{Colors_NC}")
    print(f"{Colors_BLUE}PrimiHub 平台功能测试{Colors_NC}")
    print(f"{Colors_BLUE}{'=' * 60}{Colors_NC}\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        tester = FunctionalityTester(page)

        try:
            # 登录
            if not tester.login():
                print(f"{Colors_RED}登录失败，终止测试{Colors_NC}")
                return 1

            # 执行功能测试
            tester.test_navigation_menu()
            tester.test_project_list()
            tester.test_resource_management()
            tester.test_psi_functionality()
            tester.test_model_management()
            tester.test_user_profile()

            # 生成报告
            success = tester.generate_report()

            return 0 if success else 1

        except Exception as e:
            print(f"{Colors_RED}✗ 测试异常: {e}{Colors_NC}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
