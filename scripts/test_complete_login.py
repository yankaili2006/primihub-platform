#!/usr/bin/env python3
"""
PrimiHub 完整登录流程测试 - 使用正确的密码
"""

import sys
import time
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:8080"
USERNAME = "admin"
PASSWORD = "primihub"  # 使用默认密码 (8个字符)

Colors_GREEN = '\033[0;32m'
Colors_RED = '\033[0;31m'
Colors_YELLOW = '\033[1;33m'
Colors_BLUE = '\033[0;34m'
Colors_NC = '\033[0m'

def main():
    print(f"\n{Colors_BLUE}{'=' * 60}{Colors_NC}")
    print(f"{Colors_BLUE}PrimiHub 客户端登录测试 - 正确密码{Colors_NC}")
    print(f"{Colors_BLUE}{'=' * 60}{Colors_NC}\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        # 网络请求监控
        login_response = None
        login_request = None

        def handle_request(request):
            nonlocal login_request
            if "/user/login" in request.url or "/sys/user/login" in request.url:
                login_request = request
                print(f"{Colors_YELLOW}捕获登录请求: {request.url}{Colors_NC}")
                print(f"  方法: {request.method}")
                if request.post_data:
                    print(f"  数据: {request.post_data[:100]}...")

        def handle_response(response):
            nonlocal login_response
            if "/user/login" in response.url or "/sys/user/login" in response.url:
                login_response = response
                print(f"{Colors_YELLOW}捕获登录响应: {response.url}{Colors_NC}")
                print(f"  状态码: {response.status}")
                try:
                    body = response.json()
                    print(f"  响应: {body}")
                except:
                    try:
                        text = response.text()
                        print(f"  响应: {text[:200]}")
                    except:
                        pass

        page.on("request", handle_request)
        page.on("response", handle_response)

        try:
            print(f"{Colors_BLUE}[1/5] 访问登录页面{Colors_NC}")
            page.goto(BASE_URL, wait_until="networkidle")
            print(f"  ✓ 页面加载完成")
            time.sleep(2)

            print(f"\n{Colors_BLUE}[2/5] 填写登录表单{Colors_NC}")
            page.locator('input[type="text"]').first.fill(USERNAME)
            print(f"  ✓ 用户名: {USERNAME}")

            page.locator('input[type="password"]').first.fill(PASSWORD)
            print(f"  ✓ 密码: {'*' * len(PASSWORD)}")

            # 截图登录前
            page.screenshot(path="/tmp/login-correct-pwd-before.png")

            print(f"\n{Colors_BLUE}[3/5] 点击登录{Colors_NC}")
            page.locator('button:has-text("登录")').first.click()
            print(f"  ✓ 已点击登录按钮")

            # 等待响应
            time.sleep(5)

            # 截图登录后
            page.screenshot(path="/tmp/login-correct-pwd-after.png")

            print(f"\n{Colors_BLUE}[4/5] 分析登录结果{Colors_NC}")

            current_url = page.url
            print(f"  当前URL: {current_url}")

            # 检查是否有登录请求
            if login_request:
                print(f"  {Colors_GREEN}✓ 已发送登录请求{Colors_NC}")
            else:
                print(f"  {Colors_RED}✗ 未发送登录请求{Colors_NC}")

            # 检查是否有登录响应
            if login_response:
                print(f"  {Colors_GREEN}✓ 已收到登录响应{Colors_NC}")
            else:
                print(f"  {Colors_YELLOW}未收到登录响应{Colors_NC}")

            print(f"\n{Colors_BLUE}[5/5] 验证登录状态{Colors_NC}")

            # 检查是否跳转
            if "login" not in current_url.lower():
                print(f"  {Colors_GREEN}✓ 已跳转到主页 - 登录成功！{Colors_NC}")
                page.screenshot(path="/tmp/login-success-page.png", full_page=True)
                print(f"\n  截图:")
                print(f"    - /tmp/login-correct-pwd-before.png")
                print(f"    - /tmp/login-correct-pwd-after.png")
                print(f"    - /tmp/login-success-page.png")
                return 0
            else:
                print(f"  {Colors_RED}✗ 仍在登录页面{Colors_NC}")

                # 检查错误消息
                try:
                    error_msg = page.locator('.el-message--error').first.text_content(timeout=2000)
                    print(f"  错误消息: {error_msg}")
                except:
                    pass

                page.screenshot(path="/tmp/login-failed-page.png", full_page=True)
                print(f"\n  截图:")
                print(f"    - /tmp/login-correct-pwd-before.png")
                print(f"    - /tmp/login-correct-pwd-after.png")
                print(f"    - /tmp/login-failed-page.png")
                return 1

        except Exception as e:
            print(f"{Colors_RED}✗ 测试异常: {e}{Colors_NC}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
