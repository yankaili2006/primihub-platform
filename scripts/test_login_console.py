#!/usr/bin/env python3
"""
PrimiHub 登录测试 - 捕获控制台错误和网络请求
"""

import sys
import time
import json
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
    print(f"{Colors_BLUE}PrimiHub 登录测试 - 完整日志{Colors_NC}")
    print(f"{Colors_BLUE}{'=' * 60}{Colors_NC}\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        # 收集日志
        console_logs = []
        network_requests = []
        network_responses = []

        # 监听控制台消息
        def handle_console(msg):
            log_entry = {
                'type': msg.type,
                'text': msg.text,
                'location': msg.location
            }
            console_logs.append(log_entry)
            if msg.type in ['error', 'warning']:
                print(f"  {Colors_YELLOW}[Console {msg.type}] {msg.text}{Colors_NC}")

        # 监听网络请求
        def handle_request(request):
            if 'login' in request.url.lower() or 'validate' in request.url.lower() or 'captcha' in request.url.lower():
                req_info = {
                    'url': request.url,
                    'method': request.method,
                    'postData': request.post_data if request.method == 'POST' else None
                }
                network_requests.append(req_info)
                print(f"  {Colors_BLUE}→ {request.method} {request.url}{Colors_NC}")
                if request.post_data:
                    print(f"    数据: {request.post_data[:200]}")

        # 监听网络响应
        def handle_response(response):
            if 'login' in response.url.lower() or 'validate' in response.url.lower() or 'captcha' in response.url.lower():
                resp_info = {
                    'url': response.url,
                    'status': response.status
                }
                network_responses.append(resp_info)
                print(f"  {Colors_GREEN}← {response.status} {response.url}{Colors_NC}")

                if response.status != 200:
                    try:
                        body = response.text()
                        print(f"    {Colors_RED}响应: {body[:200]}{Colors_NC}")
                    except:
                        pass

        page.on("console", handle_console)
        page.on("request", handle_request)
        page.on("response", handle_response)

        try:
            print(f"{Colors_BLUE}[1/5] 访问登录页面{Colors_NC}")
            page.goto(BASE_URL, wait_until="networkidle")
            print(f"  ✓ 页面加载完成\n")
            time.sleep(2)

            print(f"{Colors_BLUE}[2/5] 填写登录信息{Colors_NC}")
            page.locator('input[type="text"]').first.fill(USERNAME)
            page.locator('input[type="password"]').first.fill(PASSWORD)
            print(f"  ✓ 已填写用户名和密码\n")

            print(f"{Colors_BLUE}[3/5] 点击登录并监控{Colors_NC}")

            # 点击登录
            page.locator('button:has-text("登录")').first.click()
            print(f"  ✓ 已点击登录按钮")

            # 等待可能的网络请求
            time.sleep(5)

            print(f"\n{Colors_BLUE}[4/5] 分析结果{Colors_NC}")

            current_url = page.url
            print(f"  当前URL: {current_url}")
            print(f"  登录相关请求数: {len(network_requests)}")
            print(f"  控制台错误数: {len([l for l in console_logs if l['type'] == 'error'])}")

            # 保存完整日志
            log_data = {
                'console_logs': console_logs,
                'network_requests': network_requests,
                'network_responses': network_responses,
                'final_url': current_url
            }

            with open('/tmp/login_full_log.json', 'w', encoding='utf-8') as f:
                json.dump(log_data, f, indent=2, ensure_ascii=False)

            print(f"\n{Colors_BLUE}[5/5] 总结{Colors_NC}")

            if "login" not in current_url.lower():
                print(f"  {Colors_GREEN}✓ 登录成功 - 已跳转到主页{Colors_NC}")
                page.screenshot(path="/tmp/login-success-final.png")
                return 0
            else:
                print(f"  {Colors_RED}✗ 登录失败 - 仍在登录页面{Colors_NC}")

                if len(network_requests) == 0:
                    print(f"  {Colors_YELLOW}→ 未发送任何登录请求{Colors_NC}")
                    print(f"  {Colors_YELLOW}→ 可能原因: 表单验证失败或JavaScript错误{Colors_NC}")

                # 输出控制台错误
                errors = [l for l in console_logs if l['type'] == 'error']
                if errors:
                    print(f"\n  {Colors_RED}控制台错误:{Colors_NC}")
                    for err in errors[:5]:
                        print(f"    - {err['text']}")

                page.screenshot(path="/tmp/login-failed-final.png")
                print(f"\n  日志已保存: /tmp/login_full_log.json")
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
