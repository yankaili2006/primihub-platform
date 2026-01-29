#!/usr/bin/env python3

"""
PrimiHub 完整登录测试脚本
通过无头浏览器模拟真实用户登录流程
"""

import sys
import time
from playwright.sync_api import sync_playwright

# 配置
BASE_URL = "http://localhost:8080"
USERNAME = "admin"
PASSWORD = "admin"

# 颜色定义
class Colors:
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

def print_step(msg):
    print(f"{Colors.BLUE}[步骤] {msg}{Colors.NC}")

def print_success(msg):
    print(f"{Colors.GREEN}✓ {msg}{Colors.NC}")

def print_fail(msg):
    print(f"{Colors.RED}✗ {msg}{Colors.NC}")

def print_info(msg):
    print(f"  {msg}")

def complete_login(page):
    """完成登录流程"""

    print_step("1. 访问登录页面")
    page.goto(BASE_URL, wait_until="networkidle")
    print_success(f"页面加载完成: {page.url}")
    print_info(f"页面标题: {page.title()}")

    # 等待页面完全加载
    time.sleep(2)

    print_step("2. 填写登录信息")

    # 输入用户名
    try:
        username_input = page.locator('input[type="text"]').first
        username_input.fill(USERNAME)
        print_success(f"已输入用户名: {USERNAME}")
    except Exception as e:
        print_fail(f"输入用户名失败: {e}")
        return False

    # 输入密码
    try:
        password_input = page.locator('input[type="password"]').first
        password_input.fill(PASSWORD)
        print_success(f"已输入密码: {'*' * len(PASSWORD)}")
    except Exception as e:
        print_fail(f"输入密码失败: {e}")
        return False

    # 检查是否需要验证码
    print_step("3. 检查验证码要求")

    # 尝试查找验证码相关元素
    captcha_exists = False
    try:
        # 查找验证码图片或滑块
        captcha_selectors = [
            '.captcha',
            '.verify-code',
            'img[alt*="验证"]',
            'canvas',
            '.slider-verify'
        ]

        for selector in captcha_selectors:
            if page.locator(selector).count() > 0:
                captcha_exists = True
                print_info(f"发现验证码元素: {selector}")
                break

        if not captcha_exists:
            print_info("未发现验证码元素")
    except Exception as e:
        print_info(f"验证码检测异常: {e}")

    # 截图登录前状态
    try:
        page.screenshot(path="/tmp/primihub-login-before.png")
        print_info("截图已保存: /tmp/primihub-login-before.png")
    except:
        pass

    print_step("4. 点击登录按钮")

    try:
        login_button = page.locator('button:has-text("登录")').first
        login_button.click()
        print_success("已点击登录按钮")
    except Exception as e:
        print_fail(f"点击登录按钮失败: {e}")
        return False

    # 等待响应
    time.sleep(3)

    print_step("5. 检查登录结果")

    # 检查URL变化
    current_url = page.url
    print_info(f"当前URL: {current_url}")

    # 检查是否有错误消息
    error_selectors = [
        '.el-message--error',
        '.error-message',
        'text="用户名或密码错误"',
        'text="登录失败"',
        'text="验证码"',
        'text="密码错误"'
    ]

    error_found = False
    error_message = ""

    for selector in error_selectors:
        try:
            if page.locator(selector).count() > 0:
                error_message = page.locator(selector).first.text_content()
                error_found = True
                print_info(f"发现错误提示: {error_message}")
                break
        except:
            continue

    # 截图登录后状态
    try:
        page.screenshot(path="/tmp/primihub-login-after.png")
        print_info("截图已保存: /tmp/primihub-login-after.png")
    except:
        pass

    # 判断登录是否成功
    print_step("6. 验证登录状态")

    # 成功标志
    success_indicators = [
        'text="退出"',
        'text="登出"',
        'text="个人中心"',
        '.user-info',
        '.avatar'
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

    # 检查URL是否跳转到主页
    if "login" not in current_url.lower() and not error_found:
        login_success = True

    if login_success:
        print_success("登录成功！")
        print_info(f"当前页面: {page.title()}")

        # 尝试获取用户信息
        try:
            user_info = page.locator('.user-info, .username').first.text_content()
            print_info(f"用户信息: {user_info}")
        except:
            pass

        return True
    else:
        print_fail("登录失败")
        if error_message:
            print_info(f"错误原因: {error_message}")
        else:
            print_info("可能原因: 需要验证码或密码错误")
        return False

def test_after_login(page):
    """测试登录后的功能"""

    print_step("7. 测试登录后功能")

    # 等待页面加载
    time.sleep(2)
    page.wait_for_load_state("networkidle")

    # 截图主页
    try:
        page.screenshot(path="/tmp/primihub-homepage-loggedin.png", full_page=True)
        print_success("主页截图已保存")
    except:
        pass

    # 检查导航栏
    nav_items = [
        ("首页", ["首页", "Home", "Dashboard"]),
        ("数据管理", ["数据", "Data"]),
        ("项目管理", ["项目", "Project"]),
        ("任务中心", ["任务", "Task"])
    ]

    found_items = []
    for nav_name, possible_texts in nav_items:
        for text in possible_texts:
            try:
                if page.locator(f'text="{text}"').count() > 0:
                    found_items.append(nav_name)
                    print_info(f"✓ 找到导航项: {nav_name}")
                    break
            except:
                continue

    if found_items:
        print_success(f"发现 {len(found_items)} 个导航项")
        return True
    else:
        print_info("未发现导航项（可能页面还在加载）")
        return False

def main():
    """主函数"""
    print(f"\n{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}PrimiHub 客户端登录测试{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    print(f"开始时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"前端URL: {BASE_URL}")
    print(f"用户名: {USERNAME}")
    print()

    with sync_playwright() as p:
        # 启动浏览器（有头模式，可以看到过程）
        print_info("启动浏览器（无头模式）...")
        browser = p.chromium.launch(
            headless=True,  # 改为False可以看到浏览器操作
            slow_mo=100  # 放慢操作速度，便于观察
        )

        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )

        page = context.new_page()

        # 启用控制台日志监听
        def handle_console(msg):
            if msg.type in ["error", "warning"]:
                print_info(f"浏览器{msg.type}: {msg.text[:100]}")

        page.on("console", handle_console)

        try:
            # 执行登录
            login_result = complete_login(page)

            if login_result:
                # 测试登录后功能
                test_after_login(page)

                print(f"\n{Colors.GREEN}✓ 登录流程测试完成{Colors.NC}\n")
                print("截图文件:")
                print("  - /tmp/primihub-login-before.png  (登录前)")
                print("  - /tmp/primihub-login-after.png   (登录后)")
                print("  - /tmp/primihub-homepage-loggedin.png (主页)")
                print()

                return 0
            else:
                print(f"\n{Colors.YELLOW}⚠ 登录失败，请检查截图和错误信息{Colors.NC}\n")
                print("截图文件:")
                print("  - /tmp/primihub-login-before.png")
                print("  - /tmp/primihub-login-after.png")
                print()

                return 1

        except Exception as e:
            print_fail(f"测试过程发生异常: {e}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            # 关闭浏览器
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
