#!/usr/bin/env python3
"""
PrimiHub 完整登录流程测试 - 使用正确密码123456
"""

import sys
import time
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:8080"
USERNAME = "admin"
PASSWORD = "123456"  # 正确的密码

Colors_GREEN = '\033[0;32m'
Colors_RED = '\033[0;31m'
Colors_YELLOW = '\033[1;33m'
Colors_BLUE = '\033[0;34m'
Colors_NC = '\033[0m'

def main():
    print(f"\n{Colors_BLUE}{'=' * 60}{Colors_NC}")
    print(f"{Colors_BLUE}PrimiHub 客户端登录测试 - 密码123456{Colors_NC}")
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
        console_errors = []

        def handle_request(request):
            if "/user/login" in request.url:
                print(f"{Colors_YELLOW}→ 登录请求: {request.url}{Colors_NC}")

        def handle_response(response):
            nonlocal login_response
            if "/user/login" in response.url:
                login_response = response
                print(f"{Colors_YELLOW}← 登录响应: {response.status}{Colors_NC}")
                try:
                    body = response.json()
                    print(f"  响应: {body}")
                except:
                    pass

        # 监听控制台错误
        def handle_console(msg):
            if msg.type in ['error', 'warning']:
                console_errors.append(f"[{msg.type}] {msg.text}")
                print(f"  {Colors_RED}[Console] {msg.text}{Colors_NC}")

        page.on("request", handle_request)
        page.on("response", handle_response)
        page.on("console", handle_console)

        try:
            print(f"{Colors_BLUE}[1/6] 访问登录页面{Colors_NC}")
            page.goto(BASE_URL, wait_until="networkidle")
            print(f"  ✓ 页面加载完成\n")
            time.sleep(2)

            print(f"{Colors_BLUE}[2/6] 填写登录表单{Colors_NC}")
            page.locator('input[type="text"]').first.fill(USERNAME)
            page.locator('input[type="password"]').first.fill(PASSWORD)
            print(f"  ✓ 用户名: {USERNAME}")
            print(f"  ✓ 密码: {'*' * len(PASSWORD)}\n")

            # 截图登录前
            page.screenshot(path="/tmp/login-123456-before.png")

            print(f"{Colors_BLUE}[3/6] 点击登录{Colors_NC}")
            page.locator('button:has-text("登录")').first.click()
            print(f"  ✓ 已点击登录按钮\n")

            # 等待响应
            time.sleep(5)

            # 截图登录后
            page.screenshot(path="/tmp/login-123456-after.png")

            print(f"{Colors_BLUE}[4/6] 分析登录结果{Colors_NC}")

            current_url = page.url
            print(f"  当前URL: {current_url}")

            if login_response:
                try:
                    body = login_response.json()
                    if body.get('code') == 0:
                        print(f"  {Colors_GREEN}✓ 登录API返回成功！{Colors_NC}")
                    else:
                        print(f"  {Colors_RED}✗ 登录失败: {body.get('msg')}{Colors_NC}")
                        return 1
                except:
                    pass

            print(f"\n{Colors_BLUE}[5/6] 检查登录后状态{Colors_NC}")

            # 等待页面完全加载
            time.sleep(3)

            # 检查是否跳转
            if "login" not in current_url.lower():
                print(f"  {Colors_GREEN}✓ 已跳转到主页{Colors_NC}")

                # 截图主页
                page.screenshot(path="/tmp/login-success-homepage.png", full_page=True)

                # 检查页面标题
                title = page.title()
                print(f"  页面标题: {title}")

                # 检查是否有错误消息
                try:
                    error_count = page.locator('.el-message--error').count()
                    if error_count > 0:
                        print(f"  {Colors_RED}发现 {error_count} 个错误消息{Colors_NC}")
                        for i in range(min(error_count, 3)):
                            text = page.locator('.el-message--error').nth(i).text_content()
                            print(f"    - {text}")
                except:
                    pass

                print(f"\n{Colors_BLUE}[6/6] 控制台错误{Colors_NC}")
                if console_errors:
                    print(f"  发现 {len(console_errors)} 个控制台错误/警告:")
                    for err in console_errors[:10]:
                        print(f"    {err}")
                else:
                    print(f"  {Colors_GREEN}✓ 无控制台错误{Colors_NC}")

                print(f"\n  截图:")
                print(f"    - /tmp/login-123456-before.png")
                print(f"    - /tmp/login-123456-after.png")
                print(f"    - /tmp/login-success-homepage.png")

                return 0
            else:
                print(f"  {Colors_RED}✗ 仍在登录页面{Colors_NC}")
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
