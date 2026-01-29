#!/usr/bin/env python3
"""
PrimiHub 完整登录流程测试 - 改进版
使用Promise等待和更好的网络监控
"""

import sys
import time
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:8080"
USERNAME = "admin"
PASSWORD = "admin"

Colors_GREEN = '\033[0;32m'
Colors_RED = '\033[0;31m'
Colors_YELLOW = '\033[1;33m'
Colors_BLUE = '\033[0;34m'
Colors_NC = '\033[0m'

def main():
    print(f"\n{Colors_BLUE}{'=' * 60}{Colors_NC}")
    print(f"{Colors_BLUE}PrimiHub 客户端登录测试（改进版）{Colors_NC}")
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

        def handle_response(response):
            nonlocal login_response
            if "/user/login" in response.url or "/dev-api/sys/user/login" in response.url:
                login_response = response
                print(f"{Colors_YELLOW}捕获登录响应: {response.url}{Colors_NC}")
                print(f"  状态码: {response.status}")
                try:
                    body = response.json()
                    print(f"  响应: {body}")
                except:
                    print(f"  无法解析JSON响应")

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
            page.screenshot(path="/tmp/login-step-before.png")

            print(f"\n{Colors_BLUE}[3/5] 点击登录并等待响应{Colors_NC}")

            # 使用expect_response等待登录响应
            with page.expect_response(lambda response: "login" in response.url.lower() or True, timeout=10000) as response_info:
                page.locator('button:has-text("登录")').first.click()
                print(f"  ✓ 已点击登录按钮")

            # 等待更长时间以捕获响应
            page.wait_for_timeout(5000)

            # 截图登录后
            page.screenshot(path="/tmp/login-step-after.png")

            print(f"\n{Colors_BLUE}[4/5] 分析登录结果{Colors_NC}")

            current_url = page.url
            print(f"  当前URL: {current_url}")

            # 检查是否有错误消息
            error_texts = []
            error_selectors = [
                '.el-message--error',
                '.el-message__content',
                'text=/.*错误.*/',
                'text=/.*失败.*/'
            ]

            for selector in error_selectors:
                try:
                    elements = page.locator(selector).all()
                    for elem in elements:
                        text = elem.text_content()
                        if text and len(text) > 0:
                            error_texts.append(text)
                except:
                    pass

            if error_texts:
                print(f"  {Colors_RED}发现错误消息:{Colors_NC}")
                for text in set(error_texts):
                    print(f"    - {text}")

            # 检查登录响应
            if login_response:
                print(f"  {Colors_GREEN}已捕获登录响应{Colors_NC}")
            else:
                print(f"  {Colors_YELLOW}未捕获到登录响应{Colors_NC}")

            print(f"\n{Colors_BLUE}[5/5] 验证登录状态{Colors_NC}")

            # 检查是否仍在登录页面
            if "login" in current_url.lower():
                print(f"  {Colors_RED}✗ 仍在登录页面 - 登录失败{Colors_NC}")

                # 尝试获取更详细的错误信息
                page.screenshot(path="/tmp/login-final-state.png", full_page=True)

                return 1
            else:
                print(f"  {Colors_GREEN}✓ 已跳转到主页 - 登录成功！{Colors_NC}")

                # 截图成功页面
                page.screenshot(path="/tmp/login-success.png", full_page=True)

                return 0

        except Exception as e:
            print(f"{Colors_RED}✗ 测试异常: {e}{Colors_NC}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            print(f"\n生成的截图:")
            print(f"  - /tmp/login-step-before.png")
            print(f"  - /tmp/login-step-after.png")
            print(f"  - /tmp/login-final-state.png")
            print()
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
