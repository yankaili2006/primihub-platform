#!/usr/bin/env python3
"""
检查登录后的404错误
"""

import sys
import time
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:8080"
USERNAME = "admin"
PASSWORD = "123456"

Colors_GREEN = '\033[0;32m'
Colors_RED = '\033[0;31m'
Colors_YELLOW = '\033[1;33m'
Colors_BLUE = '\033[0;34m'
Colors_NC = '\033[0m'

def main():
    print(f"\n{Colors_BLUE}检查登录后的404错误{Colors_NC}\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        # 收集所有失败的请求
        failed_requests = []

        def handle_response(response):
            if response.status >= 400:
                failed_requests.append({
                    'url': response.url,
                    'status': response.status,
                    'statusText': response.status_text
                })
                print(f"{Colors_RED}✗ {response.status} {response.url}{Colors_NC}")

        page.on("response", handle_response)

        try:
            # 登录
            page.goto(BASE_URL, wait_until="networkidle")
            page.locator('input[type="text"]').first.fill(USERNAME)
            page.locator('input[type="password"]').first.fill(PASSWORD)
            page.locator('button:has-text("登录")').first.click()

            # 等待登录完成
            time.sleep(8)

            print(f"\n{Colors_BLUE}失败的请求统计:{Colors_NC}")
            print(f"总计: {len(failed_requests)} 个失败请求\n")

            # 按状态码分组
            status_groups = {}
            for req in failed_requests:
                status = req['status']
                if status not in status_groups:
                    status_groups[status] = []
                status_groups[status].append(req['url'])

            for status, urls in sorted(status_groups.items()):
                print(f"{Colors_YELLOW}HTTP {status}:{Colors_NC}")
                for url in urls:
                    print(f"  - {url}")
                print()

            # 截图
            page.screenshot(path="/tmp/login-after-errors.png", full_page=True)
            print(f"截图已保存: /tmp/login-after-errors.png")

            return 0

        except Exception as e:
            print(f"{Colors_RED}✗ 异常: {e}{Colors_NC}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
