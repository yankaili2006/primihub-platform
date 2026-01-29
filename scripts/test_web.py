#!/usr/bin/env python3

"""
PrimiHub Web UI 无头浏览器测试脚本
功能: 使用 Playwright 自动化测试前端网页功能
用法: python3 test_web.py [--headless] [--screenshots]
"""

import sys
import os
import time
import json
from datetime import datetime
from pathlib import Path
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

# 颜色定义
class Colors:
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

# 配置
BASE_URL = "http://localhost:8080"
BACKEND_URL = "http://localhost:8090"
USERNAME = "admin"
PASSWORD = "admin"
SCREENSHOTS_DIR = "/tmp/primihub-web-test-screenshots"
RESULTS_DIR = "/tmp/primihub-test-results"

# 测试统计
test_stats = {
    "total": 0,
    "passed": 0,
    "failed": 0,
    "tests": []
}

def print_header(msg):
    print(f"\n{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}{msg}{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

def print_test(msg):
    print(f"{Colors.YELLOW}[测试] {msg}{Colors.NC}")
    test_stats["total"] += 1

def print_pass(msg):
    print(f"{Colors.GREEN}✓ 通过: {msg}{Colors.NC}")
    test_stats["passed"] += 1
    test_stats["tests"].append({"name": msg, "status": "passed"})

def print_fail(msg, error=None):
    print(f"{Colors.RED}✗ 失败: {msg}{Colors.NC}")
    if error:
        print(f"  错误: {error}")
    test_stats["failed"] += 1
    test_stats["tests"].append({"name": msg, "status": "failed", "error": str(error) if error else ""})

def print_info(msg):
    print(f"  {msg}")

def test_frontend_accessibility(page):
    """测试前端可访问性"""
    print_header("1. 前端可访问性测试")

    print_test("访问前端首页")
    try:
        response = page.goto(BASE_URL, wait_until="networkidle", timeout=15000)
        if response and response.status == 200:
            print_pass("前端首页可访问")
            print_info(f"状态码: {response.status}")
        else:
            print_fail("前端首页响应异常", f"状态码: {response.status if response else 'None'}")
    except Exception as e:
        print_fail("无法访问前端首页", e)
        return False

    # 检查页面标题
    print_test("检查页面标题")
    try:
        title = page.title()
        print_pass(f"页面标题: {title}")
    except Exception as e:
        print_fail("获取页面标题失败", e)

    return True

def test_login(page, save_screenshot=False):
    """测试登录功能"""
    print_header("2. 登录功能测试")

    print_test("定位登录表单")
    try:
        # 等待页面加载
        page.wait_for_load_state("networkidle")
        time.sleep(2)

        # 查找用户名输入框
        username_input = None
        possible_selectors = [
            'input[type="text"]',
            'input[placeholder*="用户名"]',
            'input[placeholder*="账号"]',
            'input.el-input__inner',
            '#username',
            'input[name="username"]'
        ]

        for selector in possible_selectors:
            try:
                if page.locator(selector).count() > 0:
                    username_input = page.locator(selector).first
                    print_info(f"找到用户名输入框: {selector}")
                    break
            except:
                continue

        if not username_input:
            print_fail("未找到用户名输入框")
            if save_screenshot:
                page.screenshot(path=f"{SCREENSHOTS_DIR}/login_form_not_found.png")
            return False

        print_pass("找到登录表单")
    except Exception as e:
        print_fail("定位登录表单失败", e)
        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/login_form_error.png")
        return False

    print_test("输入登录凭据")
    try:
        # 输入用户名
        username_input.fill(USERNAME)
        print_info(f"用户名: {USERNAME}")

        # 查找密码输入框
        password_input = page.locator('input[type="password"]').first
        password_input.fill(PASSWORD)
        print_info(f"密码: {'*' * len(PASSWORD)}")

        print_pass("登录凭据输入完成")

        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/before_login.png")
    except Exception as e:
        print_fail("输入登录凭据失败", e)
        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/credential_input_error.png")
        return False

    print_test("点击登录按钮")
    try:
        # 查找登录按钮
        login_button = None
        button_selectors = [
            'button[type="submit"]',
            'button:has-text("登录")',
            'button:has-text("Login")',
            'button.el-button--primary',
            '.login-button'
        ]

        for selector in button_selectors:
            try:
                if page.locator(selector).count() > 0:
                    login_button = page.locator(selector).first
                    print_info(f"找到登录按钮: {selector}")
                    break
            except:
                continue

        if not login_button:
            print_fail("未找到登录按钮")
            if save_screenshot:
                page.screenshot(path=f"{SCREENSHOTS_DIR}/login_button_not_found.png")
            return False

        # 点击登录
        login_button.click()
        print_info("已点击登录按钮")

        # 等待导航或响应
        time.sleep(3)
        page.wait_for_load_state("networkidle", timeout=10000)

        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/after_login.png")

        print_pass("登录按钮点击成功")
    except Exception as e:
        print_fail("点击登录按钮失败", e)
        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/login_click_error.png")
        return False

    print_test("验证登录状态")
    try:
        # 检查是否跳转到主页（URL变化）
        current_url = page.url
        print_info(f"当前URL: {current_url}")

        # 检查是否有登录成功的标志
        # 可能的标志：用户信息、退出按钮、主导航栏等
        success_indicators = [
            'text="退出"',
            'text="登出"',
            'text="Logout"',
            '.user-info',
            '.avatar',
            'text="首页"'
        ]

        login_success = False
        for indicator in success_indicators:
            try:
                if page.locator(indicator).count() > 0:
                    print_info(f"发现登录成功标志: {indicator}")
                    login_success = True
                    break
            except:
                continue

        # 检查是否仍在登录页面（失败标志）
        if "login" in current_url.lower():
            # 检查是否有错误提示
            error_msg = None
            try:
                error_selectors = [
                    '.el-message--error',
                    '.error-message',
                    'text="用户名或密码错误"',
                    'text="登录失败"'
                ]
                for selector in error_selectors:
                    if page.locator(selector).count() > 0:
                        error_msg = page.locator(selector).first.text_content()
                        break
            except:
                pass

            if error_msg:
                print_fail("登录失败", error_msg)
            else:
                print_fail("登录后仍在登录页面")
            return False

        if login_success or current_url != BASE_URL + "/":
            print_pass("登录成功")
            return True
        else:
            print_fail("无法确认登录状态")
            return False

    except Exception as e:
        print_fail("验证登录状态失败", e)
        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/login_verify_error.png")
        return False

def test_navigation(page, save_screenshot=False):
    """测试页面导航"""
    print_header("3. 页面导航测试")

    # 主要导航项
    nav_items = [
        ("首页", ["首页", "Home", "Dashboard"]),
        ("数据管理", ["数据", "Data", "资源"]),
        ("项目管理", ["项目", "Project"]),
        ("任务中心", ["任务", "Task"])
    ]

    for nav_name, possible_texts in nav_items:
        print_test(f"导航到 {nav_name}")
        try:
            # 尝试点击导航项
            clicked = False
            for text in possible_texts:
                try:
                    nav_link = page.locator(f'text="{text}"').first
                    if nav_link.count() > 0:
                        nav_link.click()
                        time.sleep(2)
                        page.wait_for_load_state("networkidle", timeout=5000)
                        clicked = True
                        print_pass(f"成功导航到 {nav_name}")
                        print_info(f"当前URL: {page.url}")

                        if save_screenshot:
                            page.screenshot(path=f"{SCREENSHOTS_DIR}/nav_{nav_name}.png")
                        break
                except:
                    continue

            if not clicked:
                print_fail(f"未找到导航项: {nav_name}")
        except Exception as e:
            print_fail(f"导航到 {nav_name} 失败", e)

def test_api_connectivity(page):
    """测试API连接性"""
    print_header("4. API连接性测试")

    print_test("检查后端API可访问性")
    try:
        response = page.request.get(f"{BACKEND_URL}/actuator/health")
        if response.status == 200:
            data = response.json()
            print_pass("后端API可访问")
            print_info(f"健康状态: {data.get('status', 'unknown')}")
        else:
            print_fail("后端API响应异常", f"状态码: {response.status}")
    except Exception as e:
        print_fail("后端API不可访问", e)

def test_page_elements(page, save_screenshot=False):
    """测试页面关键元素"""
    print_header("5. 页面元素测试")

    print_test("检查页面布局")
    try:
        # 检查常见的页面元素
        elements = {
            "导航栏": ['.navbar', '.nav-bar', 'nav', '.el-menu'],
            "侧边栏": ['.sidebar', '.side-bar', 'aside', '.el-aside'],
            "主内容区": ['.main-content', '.content', 'main', '.el-main'],
            "底部": ['footer', '.footer']
        }

        for element_name, selectors in elements.items():
            found = False
            for selector in selectors:
                try:
                    if page.locator(selector).count() > 0:
                        print_pass(f"找到{element_name}: {selector}")
                        found = True
                        break
                except:
                    continue

            if not found:
                print_info(f"未找到{element_name}（可选）")

        if save_screenshot:
            page.screenshot(path=f"{SCREENSHOTS_DIR}/page_layout.png", full_page=True)
    except Exception as e:
        print_fail("检查页面布局失败", e)

def generate_report():
    """生成测试报告"""
    print_header("测试报告")

    success_rate = (test_stats["passed"] / test_stats["total"] * 100) if test_stats["total"] > 0 else 0

    print(f"总测试数: {Colors.BLUE}{test_stats['total']}{Colors.NC}")
    print(f"通过数: {Colors.GREEN}{test_stats['passed']}{Colors.NC}")
    print(f"失败数: {Colors.RED}{test_stats['failed']}{Colors.NC}")
    print(f"成功率: {Colors.BLUE}{success_rate:.1f}%{Colors.NC}")
    print()

    # 保存JSON报告
    report_file = f"{RESULTS_DIR}/web_test_report.json"
    os.makedirs(RESULTS_DIR, exist_ok=True)

    report = {
        "timestamp": datetime.now().isoformat(),
        "statistics": {
            "total": test_stats["total"],
            "passed": test_stats["passed"],
            "failed": test_stats["failed"],
            "success_rate": success_rate
        },
        "tests": test_stats["tests"]
    }

    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print_info(f"详细报告已保存: {report_file}")

    # 生成文本报告
    text_report_file = f"{RESULTS_DIR}/web_test_report.txt"
    with open(text_report_file, 'w', encoding='utf-8') as f:
        f.write("PrimiHub Web UI 测试报告\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("测试统计\n")
        f.write("-" * 60 + "\n")
        f.write(f"总测试数: {test_stats['total']}\n")
        f.write(f"通过数: {test_stats['passed']}\n")
        f.write(f"失败数: {test_stats['failed']}\n")
        f.write(f"成功率: {success_rate:.1f}%\n\n")
        f.write("测试详情\n")
        f.write("-" * 60 + "\n")
        for test in test_stats["tests"]:
            status_icon = "✓" if test["status"] == "passed" else "✗"
            f.write(f"{status_icon} {test['name']}\n")
            if test.get("error"):
                f.write(f"  错误: {test['error']}\n")
        f.write("\n")

    print_info(f"文本报告已保存: {text_report_file}")

    if test_stats["failed"] == 0:
        print(f"\n{Colors.GREEN}✓ 所有测试通过！{Colors.NC}\n")
        return 0
    else:
        print(f"\n{Colors.RED}✗ 部分测试失败{Colors.NC}\n")
        return 1

def main():
    """主函数"""
    print_header("PrimiHub Web UI 无头浏览器测试")

    print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"前端URL: {BASE_URL}")
    print(f"后端URL: {BACKEND_URL}")
    print(f"用户名: {USERNAME}")
    print()

    # 解析参数
    headless = True
    save_screenshots = True

    if "--no-headless" in sys.argv:
        headless = False
        print_info("运行模式: 有头模式（可见浏览器窗口）")
    else:
        print_info("运行模式: 无头模式")

    if "--no-screenshots" in sys.argv:
        save_screenshots = False
    else:
        # 创建截图目录
        os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
        print_info(f"截图保存目录: {SCREENSHOTS_DIR}")

    # 创建结果目录
    os.makedirs(RESULTS_DIR, exist_ok=True)

    # 启动浏览器
    with sync_playwright() as p:
        print_info("启动 Chromium 浏览器...")
        browser = p.chromium.launch(headless=headless)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        try:
            # 运行测试
            if not test_frontend_accessibility(page):
                print(f"\n{Colors.RED}前端不可访问，终止测试{Colors.NC}\n")
                browser.close()
                return 1

            login_success = test_login(page, save_screenshots)

            if login_success:
                test_navigation(page, save_screenshots)
                test_page_elements(page, save_screenshots)
            else:
                print(f"\n{Colors.YELLOW}登录失败，跳过后续测试{Colors.NC}\n")

            test_api_connectivity(page)

        except Exception as e:
            print_fail("测试过程发生异常", e)
        finally:
            # 关闭浏览器
            browser.close()

    # 生成报告
    return generate_report()

if __name__ == "__main__":
    sys.exit(main())
