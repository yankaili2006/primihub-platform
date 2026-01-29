#!/usr/bin/env python3

"""
PrimiHub 登录网络请求分析脚本
捕获并分析登录过程中的所有网络请求
"""

import sys
import time
import json
from playwright.sync_api import sync_playwright

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

def analyze_login_network(page):
    """分析登录过程中的网络请求"""

    # 存储网络请求
    requests_log = []
    responses_log = []

    # 监听请求
    def handle_request(request):
        req_info = {
            "url": request.url,
            "method": request.method,
            "headers": dict(request.headers),
            "post_data": request.post_data if request.method == "POST" else None
        }
        requests_log.append(req_info)

        # 只打印登录相关请求
        if "login" in request.url.lower() or "captcha" in request.url.lower():
            print_info(f"→ 请求: {request.method} {request.url}")
            if request.post_data:
                print_info(f"  数据: {request.post_data[:200]}")

    # 监听响应
    def handle_response(response):
        resp_info = {
            "url": response.url,
            "status": response.status,
            "headers": dict(response.headers)
        }

        # 尝试获取响应体
        try:
            if response.status != 200:
                resp_info["body"] = response.text()
        except:
            pass

        responses_log.append(resp_info)

        # 打印登录相关响应
        if "login" in response.url.lower() or "captcha" in response.url.lower():
            print_info(f"← 响应: {response.status} {response.url}")

            # 如果是登录接口，尝试获取响应内容
            if "login" in response.url.lower():
                try:
                    body = response.json()
                    print_info(f"  响应体: {json.dumps(body, ensure_ascii=False)}")
                except:
                    try:
                        text = response.text()
                        print_info(f"  响应: {text[:200]}")
                    except:
                        pass

    page.on("request", handle_request)
    page.on("response", handle_response)

    print_step("1. 访问登录页面")
    page.goto(BASE_URL, wait_until="networkidle")
    print_success(f"页面加载完成")
    time.sleep(2)

    print_step("2. 填写登录信息")
    username_input = page.locator('input[type="text"]').first
    username_input.fill(USERNAME)
    print_success(f"已输入用户名: {USERNAME}")

    password_input = page.locator('input[type="password"]').first
    password_input.fill(PASSWORD)
    print_success(f"已输入密码: {'*' * len(PASSWORD)}")

    # 截图登录前
    page.screenshot(path="/tmp/login-before-click.png")

    print_step("3. 点击登录按钮并监控网络请求")
    print_info("正在监控网络请求...")

    login_button = page.locator('button:has-text("登录")').first
    login_button.click()

    # 等待网络请求
    time.sleep(5)

    # 截图登录后
    page.screenshot(path="/tmp/login-after-click.png")

    print_step("4. 分析网络请求")

    # 过滤登录相关请求
    login_requests = [r for r in requests_log if "login" in r["url"].lower()]
    captcha_requests = [r for r in requests_log if "captcha" in r["url"].lower()]

    print_info(f"总请求数: {len(requests_log)}")
    print_info(f"登录相关请求: {len(login_requests)}")
    print_info(f"验证码相关请求: {len(captcha_requests)}")

    # 详细分析登录请求
    if login_requests:
        print_info("\n登录请求详情:")
        for req in login_requests:
            print_info(f"  URL: {req['url']}")
            print_info(f"  Method: {req['method']}")
            if req['post_data']:
                print_info(f"  POST数据: {req['post_data']}")

    # 分析验证码请求
    if captcha_requests:
        print_info("\n验证码请求详情:")
        for req in captcha_requests:
            print_info(f"  URL: {req['url']}")
            print_info(f"  Method: {req['method']}")

    # 保存完整日志
    log_file = "/tmp/login_network_log.json"
    with open(log_file, 'w', encoding='utf-8') as f:
        json.dump({
            "requests": requests_log,
            "responses": responses_log,
            "login_requests": login_requests,
            "captcha_requests": captcha_requests
        }, f, indent=2, ensure_ascii=False)

    print_success(f"网络日志已保存: {log_file}")

    # 检查当前URL
    current_url = page.url
    print_info(f"\n最终URL: {current_url}")

    # 检查是否有错误消息
    try:
        error_msgs = page.locator('.el-message--error, .error-message').all()
        if error_msgs:
            print_info(f"\n页面错误消息:")
            for msg in error_msgs[:3]:
                text = msg.text_content()
                if text:
                    print_fail(f"  {text}")
    except:
        pass

    return {
        "requests_log": requests_log,
        "responses_log": responses_log,
        "login_requests": login_requests
    }

def main():
    print(f"\n{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}PrimiHub 登录网络请求分析{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        try:
            result = analyze_login_network(page)

            print(f"\n{Colors.GREEN}分析完成！{Colors.NC}\n")
            print("生成的文件:")
            print("  - /tmp/login-before-click.png  (点击前)")
            print("  - /tmp/login-after-click.png   (点击后)")
            print("  - /tmp/login_network_log.json  (网络日志)")
            print()

            return 0

        except Exception as e:
            print_fail(f"分析过程发生异常: {e}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
