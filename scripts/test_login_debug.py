#!/usr/bin/env python3
"""
PrimiHub 登录调试测试 - 检查登录按钮状态和Vue数据
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
    print(f"{Colors_BLUE}PrimiHub 登录调试测试{Colors_NC}")
    print(f"{Colors_BLUE}{'=' * 60}{Colors_NC}\n")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            locale='zh-CN'
        )
        page = context.new_page()

        try:
            print(f"{Colors_BLUE}[1/6] 访问登录页面{Colors_NC}")
            page.goto(BASE_URL, wait_until="networkidle")
            print(f"  ✓ 页面加载完成")
            time.sleep(2)

            print(f"\n{Colors_BLUE}[2/6] 检查登录按钮状态{Colors_NC}")

            # 检查按钮是否禁用
            button = page.locator('button:has-text("登录")').first
            is_disabled = button.get_attribute("disabled")
            print(f"  登录按钮禁用状态: {is_disabled}")

            if is_disabled is not None:
                print(f"  {Colors_RED}✗ 登录按钮被禁用！{Colors_NC}")
            else:
                print(f"  {Colors_GREEN}✓ 登录按钮可点击{Colors_NC}")

            print(f"\n{Colors_BLUE}[3/6] 检查Vue组件数据{Colors_NC}")

            # 获取Vue实例数据
            public_key_data = page.evaluate("""
                () => {
                    const app = document.querySelector('#app').__vue__;
                    if (app && app.$children && app.$children[0]) {
                        const loginComponent = app.$children[0].$children[0];
                        if (loginComponent && loginComponent.publicKeyData) {
                            return {
                                publicKey: loginComponent.publicKeyData.publicKey || '',
                                publicKeyName: loginComponent.publicKeyData.publicKeyName || ''
                            };
                        }
                    }
                    return null;
                }
            """)

            if public_key_data:
                print(f"  publicKeyData: {public_key_data}")
                if not public_key_data['publicKey']:
                    print(f"  {Colors_RED}✗ publicKey为空 - 这就是按钮被禁用的原因！{Colors_NC}")
                else:
                    print(f"  {Colors_GREEN}✓ publicKey已获取{Colors_NC}")
            else:
                print(f"  {Colors_YELLOW}无法访问Vue组件数据{Colors_NC}")

            print(f"\n{Colors_BLUE}[4/6] 填写登录表单{Colors_NC}")
            page.locator('input[type="text"]').first.fill(USERNAME)
            print(f"  ✓ 用户名: {USERNAME}")

            page.locator('input[type="password"]').first.fill(PASSWORD)
            print(f"  ✓ 密码: {'*' * len(PASSWORD)}")

            print(f"\n{Colors_BLUE}[5/6] 测试手动调用getValidatePublicKey{Colors_NC}")

            # 手动调用getValidatePublicKey
            result = page.evaluate("""
                async () => {
                    const app = document.querySelector('#app').__vue__;
                    if (app && app.$children && app.$children[0]) {
                        const loginComponent = app.$children[0].$children[0];
                        if (loginComponent && loginComponent.getValidatePublicKey) {
                            await loginComponent.getValidatePublicKey();
                            return {
                                success: true,
                                publicKey: loginComponent.publicKeyData.publicKey || '',
                                publicKeyName: loginComponent.publicKeyData.publicKeyName || ''
                            };
                        }
                    }
                    return { success: false };
                }
            """)

            print(f"  调用结果: {result}")

            if result and result.get('success'):
                if result.get('publicKey'):
                    print(f"  {Colors_GREEN}✓ 成功获取publicKey{Colors_NC}")
                    print(f"  publicKeyName: {result.get('publicKeyName')}")

                    # 等待按钮状态更新
                    time.sleep(1)

                    # 再次检查按钮状态
                    is_disabled = button.get_attribute("disabled")
                    if is_disabled is None:
                        print(f"  {Colors_GREEN}✓ 登录按钮现在可以点击了！{Colors_NC}")
                    else:
                        print(f"  {Colors_YELLOW}登录按钮仍然被禁用{Colors_NC}")
                else:
                    print(f"  {Colors_RED}✗ publicKey仍为空{Colors_NC}")

            print(f"\n{Colors_BLUE}[6/6] 尝试登录{Colors_NC}")

            # 点击登录按钮
            button.click()
            print(f"  ✓ 已点击登录按钮")

            # 等待响应
            time.sleep(3)

            current_url = page.url
            print(f"  当前URL: {current_url}")

            if "login" in current_url.lower():
                print(f"  {Colors_RED}✗ 仍在登录页面{Colors_NC}")
            else:
                print(f"  {Colors_GREEN}✓ 已跳转 - 登录可能成功！{Colors_NC}")

            # 截图
            page.screenshot(path="/tmp/login-debug.png")
            print(f"\n  截图已保存: /tmp/login-debug.png")

            return 0

        except Exception as e:
            print(f"{Colors_RED}✗ 测试异常: {e}{Colors_NC}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            browser.close()

if __name__ == "__main__":
    sys.exit(main())
