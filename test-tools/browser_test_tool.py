#!/usr/bin/env python3
"""
PrimiHub 浏览器自动化测试工具
使用 Playwright 模拟真实用户操作
"""

import asyncio
import time
from datetime import datetime
from pathlib import Path
from typing import List, Dict
from playwright.async_api import async_playwright, Page, Browser


class BrowserTester:
    """浏览器测试类"""

    def __init__(self, base_url: str, username: str = "admin", password: str = "123456",
                 headless: bool = False, slow_mo: int = 0):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.headless = headless
        self.slow_mo = slow_mo
        self.test_results = []
        self.screenshot_dir = Path("screenshots")
        self.screenshot_dir.mkdir(exist_ok=True)

    def log_test(self, module: str, test_name: str, success: bool, message: str = "", duration: float = 0):
        """记录测试结果"""
        result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "module": module,
            "test": test_name,
            "success": success,
            "message": message,
            "duration": duration
        }
        self.test_results.append(result)

        status = "✅" if success else "❌"
        print(f"{status} [{module}] {test_name}: {message} ({duration:.2f}s)")

    async def take_screenshot(self, page: Page, name: str):
        """截图"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = self.screenshot_dir / f"{name}_{timestamp}.png"
        await page.screenshot(path=str(filename))
        return str(filename)

    async def test_login(self, page: Page) -> bool:
        """测试登录功能"""
        print("\n=== 测试登录功能 ===")
        start = time.time()

        try:
            # 访问登录页
            await page.goto(f"{self.base_url}/#/login", wait_until="networkidle")
            await page.wait_for_timeout(1000)

            # 检查登录页面元素
            username_input = await page.query_selector('input[placeholder*="用户名"], input[placeholder*="账号"]')
            password_input = await page.query_selector('input[type="password"]')
            login_button = await page.query_selector('button[type="submit"], button:has-text("登录")')

            if not all([username_input, password_input, login_button]):
                await self.take_screenshot(page, "login_page_error")
                self.log_test("登录", "页面元素检查", False, "登录页面元素不完整", time.time() - start)
                return False

            self.log_test("登录", "页面元素检查", True, "登录页面元素完整", time.time() - start)

            # 输入用户名密码
            await username_input.fill(self.username)
            await password_input.fill(self.password)
            await page.wait_for_timeout(500)

            # 点击登录
            await login_button.click()
            await page.wait_for_timeout(2000)

            # 检查是否登录成功（URL 变化或出现主页元素）
            current_url = page.url
            if "#/login" not in current_url:
                await self.take_screenshot(page, "login_success")
                self.log_test("登录", "用户登录", True, "登录成功", time.time() - start)
                return True
            else:
                await self.take_screenshot(page, "login_failed")
                self.log_test("登录", "用户登录", False, "登录失败", time.time() - start)
                return False

        except Exception as e:
            await self.take_screenshot(page, "login_exception")
            self.log_test("登录", "用户登录", False, f"异常: {str(e)}", time.time() - start)
            return False

    async def test_homepage(self, page: Page):
        """测试主页加载"""
        print("\n=== 测试主页加载 ===")
        start = time.time()

        try:
            # 等待主页加载
            await page.wait_for_timeout(2000)

            # 检查主页元素
            elements_to_check = [
                ('侧边栏', '.sidebar, .el-aside, aside'),
                ('顶部导航', '.navbar, .el-header, header'),
                ('主内容区', '.main-container, .el-main, main'),
            ]

            all_found = True
            for name, selector in elements_to_check:
                element = await page.query_selector(selector)
                if element:
                    self.log_test("主页", f"检查{name}", True, f"{name}存在", 0)
                else:
                    self.log_test("主页", f"检查{name}", False, f"{name}不存在", 0)
                    all_found = False

            await self.take_screenshot(page, "homepage")
            duration = time.time() - start
            self.log_test("主页", "主页加载", all_found, "主页加载完成" if all_found else "主页元素不完整", duration)

        except Exception as e:
            await self.take_screenshot(page, "homepage_error")
            self.log_test("主页", "主页加载", False, f"异常: {str(e)}", time.time() - start)

    async def test_menu_navigation(self, page: Page):
        """测试菜单导航"""
        print("\n=== 测试菜单导航 ===")

        menus = [
            ("项目管理", "项目"),
            ("资源管理", "资源"),
            ("白名单管理", "白名单"),
            ("租户管理", "租户"),
            ("存证管理", "存证"),
            ("监控管理", "监控"),
            ("接口管理", "接口"),
            ("日志管理", "日志"),
            ("系统设置", "系统"),
        ]

        for menu_name, keyword in menus:
            start = time.time()
            try:
                # 查找菜单项
                menu_item = await page.query_selector(f'text="{keyword}"')

                if menu_item:
                    # 点击菜单
                    await menu_item.click()
                    await page.wait_for_timeout(1500)

                    # 截图
                    await self.take_screenshot(page, f"menu_{keyword}")

                    # 检查页面是否加载
                    content = await page.content()
                    if keyword in content or menu_name in content:
                        self.log_test("菜单导航", menu_name, True, "菜单访问成功", time.time() - start)
                    else:
                        self.log_test("菜单导航", menu_name, False, "页面内容未加载", time.time() - start)
                else:
                    self.log_test("菜单导航", menu_name, False, "菜单项不存在", time.time() - start)

            except Exception as e:
                await self.take_screenshot(page, f"menu_{keyword}_error")
                self.log_test("菜单导航", menu_name, False, f"异常: {str(e)}", time.time() - start)

    async def test_whitelist_page(self, page: Page):
        """测试白名单管理页面"""
        print("\n=== 测试白名单管理页面 ===")
        start = time.time()

        try:
            # 导航到白名单页面
            await page.goto(f"{self.base_url}/#/whitelist/list", wait_until="networkidle")
            await page.wait_for_timeout(2000)

            # 检查页面元素
            elements = [
                ('表格', '.el-table, table'),
                ('搜索框', 'input[placeholder*="搜索"], input[placeholder*="查询"]'),
                ('按钮组', '.el-button, button'),
            ]

            all_found = True
            for name, selector in elements:
                element = await page.query_selector(selector)
                if element:
                    self.log_test("白名单页面", f"检查{name}", True, f"{name}存在", 0)
                else:
                    self.log_test("白名单页面", f"检查{name}", False, f"{name}不存在", 0)
                    all_found = False

            await self.take_screenshot(page, "whitelist_page")
            self.log_test("白名单页面", "页面加载", all_found, "页面加载完成", time.time() - start)

        except Exception as e:
            await self.take_screenshot(page, "whitelist_error")
            self.log_test("白名单页面", "页面加载", False, f"异常: {str(e)}", time.time() - start)

    async def test_tenant_page(self, page: Page):
        """测试租户管理页面"""
        print("\n=== 测试租户管理页面 ===")
        start = time.time()

        try:
            await page.goto(f"{self.base_url}/#/tenant/list", wait_until="networkidle")
            await page.wait_for_timeout(2000)

            # 检查表格是否存在
            table = await page.query_selector('.el-table, table')
            if table:
                await self.take_screenshot(page, "tenant_page")
                self.log_test("租户页面", "页面加载", True, "页面加载成功", time.time() - start)
            else:
                await self.take_screenshot(page, "tenant_error")
                self.log_test("租户页面", "页面加载", False, "表格不存在", time.time() - start)

        except Exception as e:
            await self.take_screenshot(page, "tenant_exception")
            self.log_test("租户页面", "页面加载", False, f"异常: {str(e)}", time.time() - start)

    async def test_responsive_design(self, page: Page):
        """测试响应式设计"""
        print("\n=== 测试响应式设计 ===")

        viewports = [
            ("桌面", 1920, 1080),
            ("平板", 768, 1024),
            ("手机", 375, 667),
        ]

        for name, width, height in viewports:
            start = time.time()
            try:
                await page.set_viewport_size({"width": width, "height": height})
                await page.wait_for_timeout(1000)

                await self.take_screenshot(page, f"responsive_{name}")
                self.log_test("响应式", f"{name}视图", True, f"{width}x{height}", time.time() - start)

            except Exception as e:
                self.log_test("响应式", f"{name}视图", False, f"异常: {str(e)}", time.time() - start)

        # 恢复默认视口
        await page.set_viewport_size({"width": 1920, "height": 1080})

    def generate_report(self, output_file: str = "browser_test_report.html"):
        """生成测试报告"""
        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r["success"])
        failed = total - passed
        pass_rate = (passed / total * 100) if total > 0 else 0

        # 按模块统计
        modules = {}
        for result in self.test_results:
            module = result["module"]
            if module not in modules:
                modules[module] = {"total": 0, "passed": 0}
            modules[module]["total"] += 1
            if result["success"]:
                modules[module]["passed"] += 1

        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PrimiHub 浏览器测试报告</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #f0f2f5; padding: 20px; }}
        .container {{ max-width: 1400px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; border-radius: 12px 12px 0 0; }}
        .header h1 {{ font-size: 32px; margin-bottom: 10px; }}
        .content {{ padding: 40px; }}
        .summary {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 40px; }}
        .stat-card {{ padding: 25px; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        .stat-card.total {{ background: #667eea; color: white; }}
        .stat-card.passed {{ background: #10b981; color: white; }}
        .stat-card.failed {{ background: #ef4444; color: white; }}
        .stat-card.rate {{ background: #f59e0b; color: white; }}
        .stat-card h2 {{ font-size: 42px; margin-bottom: 8px; }}
        .stat-card p {{ font-size: 14px; opacity: 0.9; }}
        .module-stats {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 15px; margin: 30px 0; }}
        .module-card {{ background: #f9fafb; padding: 20px; border-radius: 8px; border-left: 4px solid #667eea; }}
        .module-card h3 {{ color: #333; margin-bottom: 10px; font-size: 16px; }}
        .module-card .progress {{ height: 8px; background: #e5e7eb; border-radius: 4px; overflow: hidden; }}
        .module-card .progress-bar {{ height: 100%; background: #10b981; transition: width 0.3s; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
        th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #e5e7eb; }}
        th {{ background: #f9fafb; color: #374151; font-weight: 600; }}
        tr:hover {{ background: #f9fafb; }}
        .success {{ color: #10b981; font-weight: bold; }}
        .failure {{ color: #ef4444; font-weight: bold; }}
        .section {{ margin-bottom: 40px; }}
        .section h2 {{ color: #1f2937; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #667eea; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌐 PrimiHub 浏览器测试报告</h1>
            <p>生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
            <p>测试地址: {self.base_url}</p>
        </div>

        <div class="content">
            <div class="summary">
                <div class="stat-card total">
                    <h2>{total}</h2>
                    <p>总测试数</p>
                </div>
                <div class="stat-card passed">
                    <h2>{passed}</h2>
                    <p>通过</p>
                </div>
                <div class="stat-card failed">
                    <h2>{failed}</h2>
                    <p>失败</p>
                </div>
                <div class="stat-card rate">
                    <h2>{pass_rate:.1f}%</h2>
                    <p>通过率</p>
                </div>
            </div>

            <div class="section">
                <h2>📊 模块统计</h2>
                <div class="module-stats">
"""

        for module, stats in modules.items():
            module_pass_rate = (stats["passed"] / stats["total"] * 100) if stats["total"] > 0 else 0
            html += f"""
                    <div class="module-card">
                        <h3>{module}</h3>
                        <p style="color: #6b7280; font-size: 14px; margin-bottom: 8px;">
                            {stats["passed"]}/{stats["total"]} 通过
                        </p>
                        <div class="progress">
                            <div class="progress-bar" style="width: {module_pass_rate}%"></div>
                        </div>
                    </div>
"""

        html += """
                </div>
            </div>

            <div class="section">
                <h2>📋 详细测试结果</h2>
                <table>
                    <thead>
                        <tr>
                            <th>时间</th>
                            <th>模块</th>
                            <th>测试项</th>
                            <th>结果</th>
                            <th>消息</th>
                            <th>耗时</th>
                        </tr>
                    </thead>
                    <tbody>
"""

        for result in self.test_results:
            status_class = "success" if result["success"] else "failure"
            status_text = "✅ 通过" if result["success"] else "❌ 失败"
            html += f"""
                        <tr>
                            <td>{result["timestamp"]}</td>
                            <td>{result["module"]}</td>
                            <td>{result["test"]}</td>
                            <td class="{status_class}">{status_text}</td>
                            <td>{result["message"]}</td>
                            <td>{result["duration"]:.2f}s</td>
                        </tr>
"""

        html += f"""
                    </tbody>
                </table>
            </div>

            <div class="section">
                <h2>📸 截图目录</h2>
                <p>测试截图保存在: <code>{self.screenshot_dir.absolute()}</code></p>
            </div>
        </div>
    </div>
</body>
</html>
"""

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html)

        print(f"\n📊 浏览器测试报告已生成: {output_file}")
        print(f"   总计: {total} | 通过: {passed} | 失败: {failed} | 通过率: {pass_rate:.1f}%")
        print(f"   截图目录: {self.screenshot_dir.absolute()}")

    async def run_all_tests(self):
        """运行所有测试"""
        print("=" * 80)
        print("🌐 开始 PrimiHub 浏览器自动化测试")
        print("=" * 80)

        async with async_playwright() as p:
            # 启动浏览器
            browser = await p.chromium.launch(
                headless=self.headless,
                slow_mo=self.slow_mo
            )

            # 创建上下文和页面
            context = await browser.new_context(
                viewport={"width": 1920, "height": 1080},
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            )
            page = await context.new_page()

            try:
                # 登录测试
                if not await self.test_login(page):
                    print("\n❌ 登录失败，无法继续测试")
                    return

                # 主页测试
                await self.test_homepage(page)

                # 菜单导航测试
                await self.test_menu_navigation(page)

                # 功能页面测试
                await self.test_whitelist_page(page)
                await self.test_tenant_page(page)

                # 响应式测试
                await self.test_responsive_design(page)

            finally:
                await browser.close()

        # 生成报告
        self.generate_report()

        print("\n" + "=" * 80)
        print("✅ 浏览器测试完成")
        print("=" * 80)


async def main():
    import argparse

    parser = argparse.ArgumentParser(description="PrimiHub 浏览器自动化测试工具")
    parser.add_argument("--url", default="http://localhost:30811", help="系统地址")
    parser.add_argument("--username", default="admin", help="用户名")
    parser.add_argument("--password", default="123456", help="密码")
    parser.add_argument("--headless", action="store_true", help="无头模式")
    parser.add_argument("--slow-mo", type=int, default=0, help="慢速模式（毫秒）")

    args = parser.parse_args()

    tester = BrowserTester(
        args.url,
        args.username,
        args.password,
        args.headless,
        args.slow_mo
    )
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main())
