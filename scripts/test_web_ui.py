#!/usr/bin/env python3

"""
PrimiHub 前端UI测试脚本（简化版）
功能: 测试前端页面可访问性和UI元素
用法: python3 test_web_ui.py
"""

import sys
import os
import time
import json
from datetime import datetime
from playwright.sync_api import sync_playwright

# 颜色定义
class Colors:
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

# 配置
BASE_URL = "http://localhost:8080"
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

def test_page_accessibility(page):
    """测试页面可访问性"""
    print_header("1. 页面可访问性测试")

    print_test("访问前端首页")
    try:
        response = page.goto(BASE_URL, wait_until="networkidle", timeout=15000)
        if response and response.status == 200:
            print_pass("前端首页可访问")
            print_info(f"状态码: {response.status}")
            print_info(f"URL: {page.url}")
        else:
            print_fail("前端首页响应异常", f"状态码: {response.status if response else 'None'}")
            return False
    except Exception as e:
        print_fail("无法访问前端首页", e)
        return False

    print_test("检查页面标题")
    try:
        title = page.title()
        print_pass(f"页面标题: {title}")
    except Exception as e:
        print_fail("获取页面标题失败", e)

    # 截图
    try:
        page.screenshot(path=f"{SCREENSHOTS_DIR}/01_homepage.png")
        print_info("截图已保存: 01_homepage.png")
    except Exception as e:
        print_info(f"截图保存失败: {e}")

    return True

def test_login_page_elements(page):
    """测试登录页面元素"""
    print_header("2. 登录页面UI元素测试")

    page.wait_for_load_state("networkidle")
    time.sleep(2)

    # 测试登录表单元素
    elements_to_check = [
        ("用户名输入框", ['input[type="text"]', 'input[placeholder*="用户"]', 'input[placeholder*="账号"]']),
        ("密码输入框", ['input[type="password"]']),
        ("登录按钮", ['button:has-text("登录")', 'button[type="submit"]']),
    ]

    for element_name, selectors in elements_to_check:
        print_test(f"检查{element_name}")
        found = False
        for selector in selectors:
            try:
                count = page.locator(selector).count()
                if count > 0:
                    print_pass(f"找到{element_name} (选择器: {selector}, 数量: {count})")
                    found = True
                    break
            except:
                continue

        if not found:
            print_fail(f"未找到{element_name}")

    # 检查可选元素
    optional_elements = [
        ("忘记密码链接", ['text="忘记密码"', 'a:has-text("忘记密码")']),
        ("注册链接", ['text="注册"', 'a:has-text("注册")', 'text="用户注册"']),
        ("验证码", ['input[placeholder*="验证码"]', '.captcha', '.verify-code']),
    ]

    print_info("\n检查可选UI元素:")
    for element_name, selectors in optional_elements:
        found = False
        for selector in selectors:
            try:
                if page.locator(selector).count() > 0:
                    print_info(f"  ✓ 找到{element_name}")
                    found = True
                    break
            except:
                continue

        if not found:
            print_info(f"  - 未找到{element_name}")

    # 截图
    try:
        page.screenshot(path=f"{SCREENSHOTS_DIR}/02_login_page.png", full_page=True)
        print_info("\n截图已保存: 02_login_page.png")
    except Exception as e:
        print_info(f"截图保存失败: {e}")

def test_page_responsiveness(page):
    """测试页面响应式设计"""
    print_header("3. 页面响应式测试")

    viewports = [
        ("桌面", 1920, 1080),
        ("平板", 768, 1024),
        ("手机", 375, 667)
    ]

    for viewport_name, width, height in viewports:
        print_test(f"测试{viewport_name}视图 ({width}x{height})")
        try:
            page.set_viewport_size({"width": width, "height": height})
            time.sleep(1)
            page.screenshot(path=f"{SCREENSHOTS_DIR}/03_{viewport_name}_{width}x{height}.png")
            print_pass(f"{viewport_name}视图渲染正常")
            print_info(f"截图已保存: 03_{viewport_name}_{width}x{height}.png")
        except Exception as e:
            print_fail(f"{viewport_name}视图测试失败", e)

    # 恢复默认视图
    page.set_viewport_size({"width": 1920, "height": 1080})

def test_page_performance(page):
    """测试页面性能"""
    print_header("4. 页面性能测试")

    print_test("测试页面加载时间")
    try:
        start_time = time.time()
        page.goto(BASE_URL, wait_until="networkidle", timeout=30000)
        end_time = time.time()
        load_time = (end_time - start_time) * 1000

        if load_time < 3000:
            print_pass(f"页面加载时间: {load_time:.0f}ms (优秀)")
        elif load_time < 5000:
            print_pass(f"页面加载时间: {load_time:.0f}ms (良好)")
        else:
            print_fail(f"页面加载时间: {load_time:.0f}ms (需优化)")
    except Exception as e:
        print_fail("页面加载时间测试失败", e)

def test_console_errors(page):
    """测试控制台错误"""
    print_header("5. 控制台错误检测")

    errors = []
    warnings = []

    def handle_console(msg):
        if msg.type == "error":
            errors.append(msg.text)
        elif msg.type == "warning":
            warnings.append(msg.text)

    page.on("console", handle_console)

    print_test("检测控制台错误和警告")
    try:
        page.goto(BASE_URL, wait_until="networkidle")
        time.sleep(3)

        if errors:
            print_fail(f"发现 {len(errors)} 个控制台错误")
            for i, error in enumerate(errors[:5], 1):
                print_info(f"  错误{i}: {error[:100]}")
            if len(errors) > 5:
                print_info(f"  ... 还有 {len(errors) - 5} 个错误")
        else:
            print_pass("未发现控制台错误")

        if warnings:
            print_info(f"发现 {len(warnings)} 个控制台警告")
            for i, warning in enumerate(warnings[:3], 1):
                print_info(f"  警告{i}: {warning[:100]}")
        else:
            print_info("未发现控制台警告")

    except Exception as e:
        print_fail("控制台错误检测失败", e)

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
    report_file = f"{RESULTS_DIR}/web_ui_test_report.json"
    os.makedirs(RESULTS_DIR, exist_ok=True)

    report = {
        "timestamp": datetime.now().isoformat(),
        "test_type": "Frontend UI Test",
        "statistics": {
            "total": test_stats["total"],
            "passed": test_stats["passed"],
            "failed": test_stats["failed"],
            "success_rate": success_rate
        },
        "tests": test_stats["tests"],
        "screenshots_dir": SCREENSHOTS_DIR
    }

    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print_info(f"详细报告已保存: {report_file}")

    # 生成文本报告
    text_report_file = f"{RESULTS_DIR}/web_ui_test_report.txt"
    with open(text_report_file, 'w', encoding='utf-8') as f:
        f.write("PrimiHub 前端UI测试报告\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"测试类型: 前端UI测试\n")
        f.write(f"前端URL: {BASE_URL}\n\n")
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
        f.write(f"截图目录: {SCREENSHOTS_DIR}\n")
        f.write(f"截图数量: {len([f for f in os.listdir(SCREENSHOTS_DIR) if f.endswith('.png')])}\n")

    print_info(f"文本报告已保存: {text_report_file}")
    print_info(f"截图目录: {SCREENSHOTS_DIR}")

    if test_stats["failed"] == 0:
        print(f"\n{Colors.GREEN}✓ 所有测试通过！{Colors.NC}\n")
        return 0
    else:
        print(f"\n{Colors.YELLOW}⚠ 部分测试失败（{test_stats['failed']}个）{Colors.NC}\n")
        return 1

def main():
    """主函数"""
    print_header("PrimiHub 前端UI自动化测试")

    print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"前端URL: {BASE_URL}")
    print(f"测试类型: 前端UI测试（不依赖后端）")
    print()

    # 创建截图和结果目录
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    os.makedirs(RESULTS_DIR, exist_ok=True)
    print_info(f"截图保存目录: {SCREENSHOTS_DIR}")
    print_info(f"结果保存目录: {RESULTS_DIR}")
    print_info("运行模式: 无头模式")

    # 启动浏览器
    with sync_playwright() as p:
        print_info("启动 Chromium 浏览器...\n")
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        try:
            # 运行测试
            if test_page_accessibility(page):
                test_login_page_elements(page)
                test_page_responsiveness(page)
                test_page_performance(page)
                test_console_errors(page)
            else:
                print(f"\n{Colors.RED}前端不可访问，终止测试{Colors.NC}\n")

        except Exception as e:
            print_fail("测试过程发生异常", e)
        finally:
            # 关闭浏览器
            browser.close()

    # 生成报告
    return generate_report()

if __name__ == "__main__":
    sys.exit(main())
