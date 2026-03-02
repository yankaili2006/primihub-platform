#!/usr/bin/env python3
"""
节点连接修复脚本
问题：CLI工具在请求认证时使用了错误的公钥（本地公钥而非远程公钥）
解决：修复CLI工具，使其获取远程节点的公钥进行加密
"""

import sys
import re

def fix_cli_auth_request():
    """修复primihub-cli.py中的auth_request_partner函数"""

    cli_file = "primihub-cli.py"

    print("=" * 80)
    print("修复节点连接CLI工具")
    print("=" * 80)
    print()

    # 读取原文件
    print(f"[1/4] 读取 {cli_file}...")
    try:
        with open(cli_file, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"✗ 读取失败: {e}")
        return False

    # 备份原文件
    print(f"[2/4] 备份原文件到 {cli_file}.bak...")
    try:
        with open(f"{cli_file}.bak", 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ 备份成功")
    except Exception as e:
        print(f"✗ 备份失败: {e}")
        return False

    # 查找并替换auth_request_partner函数
    print(f"[3/4] 修复auth_request_partner函数...")

    # 原来的错误逻辑（获取本地公钥）
    old_pattern = r'''    def auth_request_partner\(self, gateway: str, public_key: str = None\) -> Optional\[Dict\]:
        """请求加入合作方（节点互相认证）"""
        self\._print_header\("请求节点认证"\)

        if not self\.token:
            self\._print_error\("请先登录"\)
            return None

        # 如果没有提供public_key，尝试从本地机构信息获取
        if not public_key:
            self\._print_warning\("未提供公钥，尝试获取本地公钥\.\.\."\)
            local_info = self\._request\("GET", "/sys/organ/getLocalOrganInfo", \{\}\)
            if local_info and local_info\.get\('code'\) == 0:
                organ_info = local_info\.get\('result', \{\}\)\.get\('sysLocalOrganInfo', \{\}\)
                public_key = organ_info\.get\('publicKey', ''\)
                if public_key:
                    self\._print_success\(f"使用本地公钥: \{public_key\[:50\]\}\.\.\."\)
                else:
                    self\._print_error\("无法获取本地公钥"\)
                    return None
            else:
                self\._print_error\("获取本地机构信息失败"\)
                return None'''

    # 新的正确逻辑（获取远程公钥）
    new_code = '''    def auth_request_partner(self, gateway: str, public_key: str = None) -> Optional[Dict]:
        """请求加入合作方（节点互相认证）"""
        self._print_header("请求节点认证")

        if not self.token:
            self._print_error("请先登录")
            return None

        # 如果没有提供public_key，尝试从远程机构信息获取
        if not public_key:
            self._print_warning("未提供公钥，尝试从远程节点获取公钥...")

            # 构建远程节点的API URL
            remote_url = gateway
            if not remote_url.endswith('/prod-api'):
                if remote_url.endswith('/'):
                    remote_url = remote_url.rstrip('/') + '/prod-api'
                else:
                    remote_url = remote_url + '/prod-api'

            # 临时创建一个客户端来访问远程节点
            import requests
            try:
                response = requests.get(
                    f"{remote_url}/sys/organ/getLocalOrganInfo",
                    params={"token": "temp"},
                    timeout=10
                )
                remote_info = response.json()

                if remote_info and remote_info.get('code') == 0:
                    organ_info = remote_info.get('result', {}).get('sysLocalOrganInfo', {})
                    public_key = organ_info.get('publicKey', '')
                    if public_key:
                        self._print_success(f"✓ 获取到远程节点公钥: {public_key[:50]}...")
                    else:
                        self._print_error("远程节点未配置公钥")
                        return None
                else:
                    self._print_error(f"获取远程机构信息失败: {remote_info.get('msg', '未知错误')}")
                    return None
            except Exception as e:
                self._print_error(f"连接远程节点失败: {e}")
                return None'''

    if old_pattern in content:
        content = content.replace(old_pattern, new_code)
        print("✓ 函数修复成功")
    else:
        print("✗ 未找到需要修复的代码模式")
        print("提示：可能文件已经被修改过，请手动检查")
        return False

    # 写入修复后的文件
    print(f"[4/4] 保存修复后的文件...")
    try:
        with open(cli_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ 保存成功")
    except Exception as e:
        print(f"✗ 保存失败: {e}")
        return False

    print()
    print("=" * 80)
    print("✓ 修复完成！")
    print("=" * 80)
    print()
    print("修复说明：")
    print("  原问题：CLI工具获取本地节点的公钥，导致加密解密密钥不匹配")
    print("  修复后：CLI工具获取远程节点的公钥，确保加密解密使用配对的密钥")
    print()
    print("测试命令：")
    print("  python3 primihub-cli.py --url http://100.64.0.23:30811/prod-api \\")
    print("    --user admin --password 123456 \\")
    print("    auth-request http://100.64.0.23:30812")
    print()

    return True

if __name__ == "__main__":
    success = fix_cli_auth_request()
    sys.exit(0 if success else 1)
