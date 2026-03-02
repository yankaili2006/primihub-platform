#!/usr/bin/env python3
"""
PrimiHub CLI - 客户端命令行工具
用于测试和管理 PrimiHub 平台接口

使用示例:
  python primihub-cli.py --help
  python primihub-cli.py login --user admin --password primihub123
  python primihub-cli.py test-all
  python primihub-cli.py organs list
  python primihub-cli.py projects list
"""

import requests
import json
import time
import sys
import os
import subprocess
from datetime import datetime
from typing import Optional, Dict, Any
import argparse
from urllib.parse import urljoin

# 私有/本地网络段 - 这些地址应该绕过代理直连
_PRIVATE_NO_PROXY = (
    'localhost',
    '127.0.0.1',
    '::1',
    '172.16.0.0/12',   # Docker 桥接网络
    '10.0.0.0/8',      # 内网
    '192.168.0.0/16',  # 局域网
    '100.64.0.0/10',   # Tailscale VPN 网络
)


def _is_private_url(url: str) -> bool:
    """判断URL是否指向私有/本地网络，应跳过代理"""
    import ipaddress
    from urllib.parse import urlparse
    try:
        host = urlparse(url).hostname or ''
        if host in ('localhost', '127.0.0.1', '::1'):
            return True
        addr = ipaddress.ip_address(host)
        for cidr in ('172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/16', '100.64.0.0/10'):
            if addr in ipaddress.ip_network(cidr):
                return True
    except ValueError:
        pass
    return False


def make_session(proxy: str = None, no_proxy: bool = False, base_url: str = '') -> requests.Session:
    """
    创建配置好代理的 requests.Session。

    优先级（高→低）:
      1. no_proxy=True  → 强制直连，忽略所有代理环境变量
      2. proxy 参数     → 使用指定代理
      3. 环境变量       → 沿用系统 http_proxy/https_proxy（Clash 等）
                          并为私有网段自动追加 no_proxy 条目

    Tailscale 支持: 私有段 100.64.0.0/10 始终在 no_proxy 中，
    无论通过 Clash 还是直连均可访问 Tailscale IP。
    """
    session = requests.Session()

    if no_proxy or _is_private_url(base_url):
        # 强制直连：不使用任何代理
        session.trust_env = False
        session.proxies = {'http': None, 'https': None}
        return session

    if proxy:
        # 使用指定代理，同时为私有网段设置直连
        no_proxy_list = ','.join(_PRIVATE_NO_PROXY)
        session.proxies = {
            'http': proxy,
            'https': proxy,
            'no_proxy': no_proxy_list,
        }
        return session

    # 使用系统代理（如 Clash）：为私有网段补全 no_proxy
    existing_no_proxy = os.environ.get('no_proxy') or os.environ.get('NO_PROXY') or ''
    needed = [s for s in _PRIVATE_NO_PROXY if s not in existing_no_proxy]
    if needed:
        combined = ','.join(filter(None, [existing_no_proxy] + needed))
        # 仅对本次 session 生效，不修改全局环境变量
        os.environ['no_proxy'] = combined

    return session

# ANSI 颜色代码
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class PrimiHubCLI:
    """PrimiHub 客户端 CLI 类"""

    def __init__(self, base_url: str = "http://localhost:30811/prod-api",
                 proxy: str = None, no_proxy: bool = False):
        self.base_url = base_url.rstrip('/')
        self.session = make_session(proxy=proxy, no_proxy=no_proxy, base_url=self.base_url)
        self.token = None
        self.user_id = None
        self.user_name = None

    def _query_database(self, database: str, query: str) -> Optional[list]:
        """直接查询数据库（当API失败时的备用方案）"""
        try:
            cmd = [
                "docker", "exec", "mysql", "mysql",
                "-uprimihub", "-pprimihub@123", database,
                "-e", query, "--batch", "--skip-column-names"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                rows = []
                for line in lines:
                    if line and not line.startswith('mysql:'):
                        rows.append(line.split('\t'))
                return rows
            return None
        except Exception as e:
            return None

    def _print_header(self, text: str):
        """打印标题"""
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*70}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{text}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{'='*70}{Colors.ENDC}")

    def _print_success(self, text: str):
        """打印成功信息"""
        print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

    def _print_error(self, text: str):
        """打印错误信息"""
        print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

    def _print_info(self, text: str):
        """打印信息"""
        print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")

    def _print_warning(self, text: str):
        """打印警告"""
        print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None,
                 json_data: Optional[Dict] = None, headers: Optional[Dict] = None) -> Optional[Dict]:
        """统一的HTTP请求方法"""
        # 正确拼接 URL，处理 endpoint 以 / 开头的情况
        if endpoint.startswith('/'):
            endpoint = endpoint[1:]
        url = f"{self.base_url}/{endpoint}"

        req_headers = headers or {}
        if self.user_id:
            req_headers['userId'] = str(self.user_id)

        if data is None:
            data = {}

        # 添加通用参数
        if self.token:
            if json_data:
                json_data['token'] = self.token
            else:
                data['token'] = self.token

        data['timestamp'] = int(time.time() * 1000)
        data['nonce'] = int(time.time() * 1000) % 1000 + 1

        try:
            if method.upper() == 'GET':
                response = self.session.get(url, params=data, headers=req_headers, timeout=30)
            elif method.upper() == 'POST':
                if json_data:
                    json_data['timestamp'] = int(time.time() * 1000)
                    json_data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    response = self.session.post(url, json=json_data, headers=req_headers, timeout=30)
                else:
                    response = self.session.post(url, data=data, headers=req_headers, timeout=30)

            return response.json()
        except requests.exceptions.ConnectionError:
            self._print_error(f"连接失败: 无法连接到 {url}")
            return None
        except requests.exceptions.Timeout:
            self._print_error(f"请求超时: {url}")
            return None
        except Exception as e:
            self._print_error(f"请求失败: {str(e)}")
            return None

    def login(self, username: str = "admin", password: str = "primihub123") -> bool:
        """登录系统"""
        self._print_header("用户登录")

        result = self._request("POST", "/user/login", {
            "userAccount": username,
            "userPassword": password
        })

        if result and result.get('code') == 0:
            user_data = result.get('result', {})
            self.token = user_data.get('token')
            sys_user = user_data.get('sysUser', {})
            self.user_id = sys_user.get('userId')
            self.user_name = sys_user.get('userName')

            self._print_success("登录成功")
            self._print_info(f"用户: {self.user_name}")
            self._print_info(f"用户ID: {self.user_id}")
            self._print_info(f"Token: {self.token[:30]}...")
            return True
        else:
            self._print_error(f"登录失败: {result.get('msg') if result else '无响应'}")
            return False

    def health_check(self) -> bool:
        """健康检查"""
        self._print_header("健康检查")

        # 测试根路径
        try:
            response = requests.get(f"{self.base_url}/healthConnection", timeout=5)
            if response.status_code == 200:
                self._print_success(f"服务可访问: {self.base_url}")
                return True
            else:
                self._print_warning(f"服务响应异常: HTTP {response.status_code}")
                return False
        except Exception as e:
            self._print_error(f"服务不可访问: {str(e)}")
            return False

    def get_organs(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取机构列表"""
        self._print_header("机构列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/sys/organ/getOrganList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            organs = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个机构")
            print(f"\n{'机构ID':<35} {'机构名称':<20} {'网关地址':<30} {'状态':<10}")
            print("-" * 95)

            for organ in organs:
                organ_id = organ.get('organId', 'N/A')
                organ_name = organ.get('organName', 'N/A')
                gateway_raw = organ.get('organGateway', 'N/A')
                gateway = (gateway_raw if gateway_raw else 'N/A')[:29]
                enable = organ.get('enable', 0)
                status = "启用" if enable == 1 else "禁用"
                print(f"{organ_id:<35} {organ_name:<20} {gateway:<30} {status:<10}")

            return result
        else:
            # 如果API失败，自动尝试数据库查询
            self._print_error(f"API获取失败: {result.get('msg') if result else '无响应'}")
            self._print_warning("尝试使用数据库直接查询...")

            query = "SELECT organ_id, organ_name, organ_gateway, enable FROM sys_organ WHERE is_del=0"
            rows = self._query_database("privacy", query)

            if rows:
                self._print_success(f"从数据库找到 {len(rows)} 个机构")
                print(f"\n{'机构ID':<35} {'机构名称':<20} {'网关地址':<30} {'状态':<10}")
                print("-" * 95)

                for row in rows:
                    if len(row) >= 4:
                        organ_id = row[0]
                        organ_name = row[1]
                        gateway = row[2][:29] if row[2] else 'N/A'
                        enable = int(row[3]) if row[3] else 0
                        status = "启用" if enable == 1 else "禁用"
                        print(f"{organ_id:<35} {organ_name:<20} {gateway:<30} {status:<10}")

                return {"code": 0, "result": {"data": rows, "total": len(rows)}, "source": "database"}
            else:
                self._print_error("数据库查询也失败了")
                print("\n请手动运行以下命令:")
                print("  docker exec mysql mysql -uprimihub -pprimihub@123 privacy \\")
                print("    -e \"SELECT organ_id, organ_name, organ_gateway, enable FROM sys_organ WHERE is_del=0;\"")
                return None

    def auth_request_partner(self, gateway: str, public_key: str = None) -> Optional[Dict]:
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

            # 访问远程节点获取其公钥
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
                return None

        print(f"\n请求参数:")
        print(f"  目标网关: {gateway}")
        print(f"  公钥: {public_key[:50]}..." if len(public_key) > 50 else f"  公钥: {public_key}")

        result = self._request("GET", "/sys/organ/joiningPartners", {
            "gateway": gateway,
            "publicKey": public_key
        })

        if result and result.get('code') == 0:
            self._print_success("认证请求已发送")
            print("\n提示:")
            print("  1. 请等待对方机构管理员审核")
            print("  2. 使用 'auth-list' 命令查看认证状态")
            print("  3. 对方管理员可使用 'auth-approve' 命令批准")
            return result
        else:
            self._print_error(f"请求失败: {result.get('msg') if result else '无响应'}")
            return None

    def auth_list_requests(self, page: int = 1, page_size: int = 20, status: str = None) -> Optional[Dict]:
        """列出机构认证请求和状态"""
        self._print_header("节点认证状态")

        if not self.token:
            self._print_error("请先登录")
            return None

        params = {
            "pageNo": page,
            "pageSize": page_size
        }

        # 如果指定了状态筛选
        if status:
            params['examineState'] = status

        result = self._request("GET", "/sys/organ/getOrganList", params)

        if result and result.get('code') == 0:
            organs = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个机构")

            # 按认证状态分组显示
            pending = [o for o in organs if o.get('examineState') == 0]
            approved = [o for o in organs if o.get('examineState') == 1]
            rejected = [o for o in organs if o.get('examineState') == 2]

            # 显示待审核的请求
            if pending:
                print(f"\n待审核 ({len(pending)} 个)")
                print(f"{'ID':<8} {'机构名称':<20} {'网关地址':<35} {'申请时间':<20}")
                print("-" * 85)
                for organ in pending:
                    org_id = str(organ.get('id', 'N/A'))
                    org_name = organ.get('organName', 'N/A')[:19]
                    gateway_raw = organ.get('organGateway', 'N/A')
                    gateway = (gateway_raw if gateway_raw else 'N/A')[:34]
                    create_time = organ.get('createDate', 'N/A')[:19]
                    print(f"{org_id:<8} {org_name:<20} {gateway:<35} {create_time:<20}")

            # 显示已批准的合作方
            if approved:
                print(f"\n已认证 ({len(approved)} 个)")
                print(f"{'机构ID':<35} {'机构名称':<20} {'网关地址':<35} {'状态':<10}")
                print("-" * 102)
                for organ in approved:
                    org_id = organ.get('organId', 'N/A')
                    org_name = organ.get('organName', 'N/A')[:19]
                    gateway_raw = organ.get('organGateway', 'N/A')
                    gateway = (gateway_raw if gateway_raw else 'N/A')[:34]
                    enable = organ.get('enable', 0)
                    status_text = "✓ 启用" if enable == 1 else "✗ 禁用"
                    print(f"{org_id:<35} {org_name:<20} {gateway:<35} {status_text:<10}")

            # 显示被拒绝的请求
            if rejected:
                print(f"\n已拒绝 ({len(rejected)} 个)")
                print(f"{'ID':<8} {'机构名称':<20} {'拒绝原因':<40} {'处理时间':<20}")
                print("-" * 90)
                for organ in rejected:
                    org_id = str(organ.get('id', 'N/A'))
                    org_name = organ.get('organName', 'N/A')[:19]
                    reason = organ.get('examineMsg', 'N/A')[:39]
                    update_time = organ.get('updateDate', 'N/A')[:19]
                    print(f"{org_id:<8} {org_name:<20} {reason:<40} {update_time:<20}")

            print(f"\n命令提示:")
            print(f"  批准认证: python primihub-cli.py auth-approve <ID>")
            print(f"  拒绝认证: python primihub-cli.py auth-reject <ID> [原因]")
            print(f"  启用机构: python primihub-cli.py auth-enable <ID>")
            print(f"  禁用机构: python primihub-cli.py auth-disable <ID>")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def auth_examine_request(self, request_id: int, action: str, reason: str = None) -> Optional[Dict]:
        """审核认证请求（批准或拒绝）"""
        action_map = {
            'approve': (1, "批准"),
            'reject': (2, "拒绝"),
            'reapply': (0, "重新申请")
        }

        if action not in action_map:
            self._print_error(f"无效的操作: {action}，支持: approve, reject")
            return None

        examine_state, action_text = action_map[action]
        self._print_header(f"{action_text}认证请求")

        if not self.token:
            self._print_error("请先登录")
            return None

        params = {
            "id": request_id,
            "examineState": examine_state
        }

        if reason:
            params['examineMsg'] = reason

        print(f"\n操作:")
        print(f"  请求ID: {request_id}")
        print(f"  操作: {action_text}")
        if reason:
            print(f"  原因: {reason}")

        result = self._request("GET", "/sys/organ/examineJoining", params)

        if result and result.get('code') == 0:
            self._print_success(f"{action_text}成功")
            if action == 'approve':
                print("\n提示:")
                print("  1. 对方机构已添加为合作方")
                print("  2. 使用 'auth-list' 查看认证状态")
                print("  3. 现在可以与该机构进行联合计算")
            return result
        else:
            self._print_error(f"{action_text}失败: {result.get('msg') if result else '无响应'}")
            return None

    def auth_enable_disable(self, organ_id: int, enable: bool) -> Optional[Dict]:
        """启用或禁用合作机构"""
        action = "启用" if enable else "禁用"
        self._print_header(f"{action}合作机构")

        if not self.token:
            self._print_error("请先登录")
            return None

        status = 1 if enable else 0

        print(f"\n操作:")
        print(f"  机构ID: {organ_id}")
        print(f"  操作: {action}")

        result = self._request("GET", "/sys/organ/enableStatus", {
            "id": organ_id,
            "status": status
        })

        if result and result.get('code') == 0:
            self._print_success(f"{action}成功")
            print("\n提示:")
            print("  使用 'auth-list' 查看更新后的状态")
            return result
        else:
            self._print_error(f"{action}失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_projects(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取项目列表"""
        self._print_header("项目列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/project/getProjectList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            projects = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个项目")
            print(f"\n{'项目名称':<30} {'类型':<15} {'状态':<10} {'创建时间':<20}")
            print("-" * 70)

            type_map = {1: "PIR", 2: "联邦学习", 3: "PSI"}

            for project in projects:
                name = project.get('projectName', 'N/A')
                proj_type = type_map.get(project.get('projectType'), 'Unknown')
                status = "正常" if project.get('status') == 1 else "禁用"
                create_time = project.get('createDate', 'N/A')[:19]
                print(f"{name:<30} {proj_type:<15} {status:<10} {create_time:<20}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_resources(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取资源列表"""
        self._print_header("资源列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/resource/getdataresourcelist", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            resources = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个资源")
            print(f"\n{'资源名称':<30} {'文件类型':<10} {'行数':<10} {'列数':<10}")
            print("-" * 70)

            for resource in resources:
                name = resource.get('resourceName', 'N/A')
                file_type = resource.get('fileType', 'N/A')
                rows = resource.get('resourceRowsCount', 0)
                cols = resource.get('resourceColumnCount', 0)
                print(f"{name:<30} {file_type:<10} {rows:<10} {cols:<10}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_tasks(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取任务列表"""
        self._print_header("任务列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/task/getTaskList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            tasks = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个任务")
            print(f"\n{'任务ID':<15} {'任务名称':<25} {'状态':<10} {'创建时间':<20}")
            print("-" * 70)

            status_map = {0: "未开始", 1: "等待中", 2: "运行中", 3: "成功", 4: "失败"}

            for task in tasks:
                task_id = str(task.get('taskIdName', 'N/A'))[:14]
                task_name = task.get('taskName', 'N/A')[:24]
                state = status_map.get(task.get('taskState'), 'Unknown')
                create_time = task.get('createDate', 'N/A')[:19]
                print(f"{task_id:<15} {task_name:<25} {state:<10} {create_time:<20}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_models(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取模型列表"""
        self._print_header("模型列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/model/getModelList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            models = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个模型")
            print(f"\n{'模型ID':<10} {'模型名称':<30} {'项目名称':<20}")
            print("-" * 70)

            for model in models:
                model_id = str(model.get('id', 'N/A'))
                model_name = model.get('modelName', 'N/A')[:29]
                project_name = model.get('projectName', 'N/A')[:19]
                print(f"{model_id:<10} {model_name:<30} {project_name:<20}")

            return result
        else:
            self._print_error(f"API获取失败: {result.get('msg') if result else '无响应'}")
            self._print_warning("已知问题: 模型列表接口不存在（HTTP 404）")
            self._print_info("当前系统中模型数量: 0")
            print("\n说明: 该接口可能已废弃或路径变更")
            return None

    def get_users(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取用户列表"""
        self._print_header("用户列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/sys/user/findUserPage", {
            "pageNum": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            users = result.get('result', {}).get('sysUserList', [])
            page_param = result.get('result', {}).get('pageParam', {})
            total = page_param.get('itemTotalCount', 0)

            self._print_success(f"找到 {total} 个用户")
            print(f"\n{'用户ID':<10} {'账号':<20} {'用户名':<20} {'角色':<10} {'状态':<10}")
            print("-" * 70)

            for user in users:
                user_id = str(user.get('userId', 'N/A'))
                account = user.get('userAccount', 'N/A')
                name = user.get('userName', 'N/A')
                role = user.get('roleIdList', 'N/A')
                is_forbid = user.get('isForbid', 0)
                status = "禁用" if is_forbid == 1 else "正常"
                print(f"{user_id:<10} {account:<20} {name:<20} {role:<10} {status:<10}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_datasets(self, page: int = 1, page_size: int = 10,
                     resource_name: str = None, tags: str = None) -> Optional[Dict]:
        """获取数据集列表"""
        self._print_header("数据集列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        params = {
            "pageNo": page,
            "pageSize": page_size
        }

        if resource_name:
            params["resourceName"] = resource_name
        if tags:
            params["tags"] = tags

        result = self._request("GET", "/data/resource/getdataresourcelist", params)

        if result and result.get('code') == 0:
            datasets = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个数据集")
            print(f"\n{'资源ID':<15} {'资源名称':<30} {'标签':<20} {'状态':<10} {'创建时间':<20}")
            print("-" * 95)

            for dataset in datasets:
                resource_id = str(dataset.get('resourceId', 'N/A'))
                resource_name = dataset.get('resourceName', 'N/A')[:29]
                tags = dataset.get('resourceTagsName', 'N/A')[:19]
                state_name = dataset.get('resourceStateName', 'N/A')
                create_time = dataset.get('createDate', 'N/A')[:19] if dataset.get('createDate') else 'N/A'
                print(f"{resource_id:<15} {resource_name:<30} {tags:<20} {state_name:<10} {create_time:<20}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_dataset_detail(self, resource_id: str) -> Optional[Dict]:
        """获取数据集详情"""
        self._print_header(f"数据集详情 (ID: {resource_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/resource/getdataresource", {
            "resourceId": resource_id
        })

        if result and result.get('code') == 0:
            result_data = result.get('result', {})
            # 正确解析嵌套的resource对象
            dataset = result_data.get('resource', {}) if isinstance(result_data, dict) else {}

            self._print_success("获取成功")
            print(f"\n基本信息:")
            print(f"  资源ID: {dataset.get('resourceId', 'N/A')}")
            print(f"  资源名称: {dataset.get('resourceName', 'N/A')}")
            print(f"  资源描述: {dataset.get('resourceDesc', 'N/A')}")
            print(f"  文件行数: {dataset.get('fileRows', 'N/A')}")
            print(f"  文件列数: {dataset.get('fileColumns', 'N/A')}")
            print(f"  文件大小: {dataset.get('fileSize', 'N/A')} bytes")
            print(f"  创建时间: {dataset.get('createDate', 'N/A')}")

            # 显示字段信息
            field_list = result_data.get('fieldList', [])
            if field_list:
                print(f"\n字段信息 (共{len(field_list)}个字段):")
                print(f"  {'字段名':<20} {'类型':<15} {'描述':<30}")
                print(f"  {'-'*65}")
                for field in field_list[:10]:  # 只显示前10个字段
                    field_name = field.get('fieldName', 'N/A')
                    field_type = field.get('fieldType', 'N/A')
                    field_desc = field.get('fieldDesc', 'N/A')[:29]
                    print(f"  {field_name:<20} {field_type:<15} {field_desc:<30}")
                if len(field_list) > 10:
                    print(f"  ... 还有 {len(field_list) - 10} 个字段")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_dataset_fields(self, resource_id: int, page: int = 1, page_size: int = 20) -> Optional[Dict]:
        """获取数据集字段信息"""
        self._print_header(f"数据集字段 (资源ID: {resource_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/resource/getDataResourceFieldPage", {
            "resourceId": resource_id,
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            fields = result.get('result', {}).get('list', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个字段")
            print(f"\n{'字段ID':<10} {'字段名称':<25} {'字段类型':<15} {'字段描述':<30}")
            print("-" * 80)

            for field in fields:
                field_id = str(field.get('fieldId', 'N/A'))
                field_name = field.get('fieldName', 'N/A')[:24]
                field_type = field.get('fieldType', 'N/A')[:14]
                field_desc = field.get('fieldDesc', 'N/A')[:29]
                print(f"{field_id:<10} {field_name:<25} {field_type:<15} {field_desc:<30}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_dataset_tags(self) -> Optional[Dict]:
        """获取数据集标签列表"""
        self._print_header("数据集标签")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/resource/getResourceTags", {})

        if result and result.get('code') == 0:
            tags = result.get('result', [])

            self._print_success(f"找到 {len(tags)} 个标签")
            print(f"\n{'序号':<10} {'标签名称':<30}")
            print("-" * 40)

            for idx, tag in enumerate(tags, 1):
                # 处理标签数据，可能是字符串或字典
                if isinstance(tag, str):
                    tag_name = tag
                elif isinstance(tag, dict):
                    tag_name = tag.get('tagName', tag.get('name', str(tag)))
                else:
                    tag_name = str(tag)

                print(f"{idx:<10} {tag_name:<30}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def preview_dataset(self, resource_id: str = None, file_id: int = None) -> Optional[Dict]:
        """预览数据集内容"""
        self._print_header("数据集预览")

        if not self.token:
            self._print_error("请先登录")
            return None

        if not resource_id and not file_id:
            self._print_error("需要提供 resource_id 或 file_id")
            return None

        params = {}
        if resource_id:
            params["resourceId"] = resource_id
        if file_id:
            params["fileId"] = file_id

        result = self._request("GET", "/data/resource/resourceFilePreview", params)

        if result and result.get('code') == 0:
            preview_data = result.get('result', {})

            self._print_success("预览成功")

            # 显示头部信息
            headers = preview_data.get('head', [])
            if headers:
                print(f"\n列名: {', '.join(headers)}")

            # 显示数据行
            rows = preview_data.get('data', [])
            if rows:
                print(f"\n预览数据 (前 {len(rows)} 行):")
                print("-" * 100)
                for i, row in enumerate(rows[:10], 1):  # 只显示前10行
                    print(f"{i}. {row}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_psi_tasks(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取PSI任务列表"""
        self._print_header("PSI任务列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/psi/getPsiTaskList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            tasks = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个PSI任务")
            print(f"\n{'任务ID':<20} {'任务名称':<30} {'状态':<15} {'创建时间':<20}")
            print("-" * 85)

            for task in tasks:
                task_id = str(task.get('taskId', 'N/A'))
                task_name = task.get('taskName', 'N/A')[:29]
                task_state = task.get('taskStateName', 'N/A')
                create_time = task.get('createDate', 'N/A')[:19] if task.get('createDate') else 'N/A'
                print(f"{task_id:<20} {task_name:<30} {task_state:<15} {create_time:<20}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_psi_task_detail(self, task_id: str) -> Optional[Dict]:
        """获取PSI任务详情"""
        self._print_header(f"PSI任务详情 (ID: {task_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/psi/getPsiTaskDetails", {
            "taskId": task_id
        })

        if result and result.get('code') == 0:
            task = result.get('result', {})

            self._print_success("获取成功")
            print(f"\n基本信息:")
            print(f"  任务ID: {task.get('taskId', 'N/A')}")
            print(f"  任务名称: {task.get('taskName', 'N/A')}")
            print(f"  任务描述: {task.get('taskDesc', 'N/A')}")
            print(f"  任务状态: {task.get('taskStateName', 'N/A')}")
            print(f"  创建时间: {task.get('createDate', 'N/A')}")
            print(f"  开始时间: {task.get('startDate', 'N/A')}")
            print(f"  结束时间: {task.get('endDate', 'N/A')}")

            # 参与方信息
            if 'organDtos' in task and task['organDtos']:
                print(f"\n参与方信息:")
                for organ in task['organDtos']:
                    print(f"  - {organ.get('organName', 'N/A')} (ID: {organ.get('organId', 'N/A')})")

            # 结果统计
            if 'resultCount' in task:
                print(f"\n结果统计:")
                print(f"  交集数量: {task.get('resultCount', 'N/A')}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_pir_tasks(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取PIR任务列表"""
        self._print_header("PIR任务列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/pir/getPirTaskList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            tasks = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个PIR任务")
            print(f"\n{'任务ID':<20} {'任务名称':<30} {'状态':<15} {'创建时间':<20}")
            print("-" * 85)

            for task in tasks:
                task_id = str(task.get('taskId', 'N/A'))
                task_name = task.get('taskName', 'N/A')[:29]
                task_state = task.get('taskStateName', 'N/A')
                create_time = task.get('createDate', 'N/A')[:19] if task.get('createDate') else 'N/A'
                print(f"{task_id:<20} {task_name:<30} {task_state:<15} {create_time:<20}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_pir_task_detail(self, task_id: str) -> Optional[Dict]:
        """获取PIR任务详情"""
        self._print_header(f"PIR任务详情 (ID: {task_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/pir/getPirTaskDetail", {
            "taskId": task_id
        })

        if result and result.get('code') == 0:
            task = result.get('result', {})

            self._print_success("获取成功")
            print(f"\n基本信息:")
            print(f"  任务ID: {task.get('taskId', 'N/A')}")
            print(f"  任务名称: {task.get('taskName', 'N/A')}")
            print(f"  任务描述: {task.get('taskDesc', 'N/A')}")
            print(f"  任务状态: {task.get('taskStateName', 'N/A')}")
            print(f"  创建时间: {task.get('createDate', 'N/A')}")
            print(f"  开始时间: {task.get('startDate', 'N/A')}")
            print(f"  结束时间: {task.get('endDate', 'N/A')}")

            # 参与方信息
            if 'organDtos' in task and task['organDtos']:
                print(f"\n参与方信息:")
                for organ in task['organDtos']:
                    print(f"  - {organ.get('organName', 'N/A')} (ID: {organ.get('organId', 'N/A')})")

            # 查询信息
            if 'queryParam' in task:
                print(f"\n查询参数:")
                print(f"  {task.get('queryParam', 'N/A')}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_fl_tasks(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取联邦学习任务列表"""
        self._print_header("联邦学习任务列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/federatedLearning/getTaskList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            tasks = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个联邦学习任务")
            print(f"\n{'任务ID':<20} {'任务名称':<30} {'状态':<15} {'创建时间':<20}")
            print("-" * 85)

            for task in tasks:
                task_id = str(task.get('taskId', 'N/A'))
                task_name = task.get('taskName', 'N/A')[:29]
                task_state = task.get('taskStateName', 'N/A')
                create_time = task.get('createDate', 'N/A')[:19] if task.get('createDate') else 'N/A'
                print(f"{task_id:<20} {task_name:<30} {task_state:<15} {create_time:<20}")

            return result
        else:
            self._print_error(f"API获取失败: {result.get('msg') if result else '无响应'}")
            self._print_warning("已知问题: 联邦学习接口查询失败（数据库映射问题）")
            self._print_info("临时方案: 使用通用任务列表查看FL任务")
            print("\n请运行以下命令:")
            print("  python3 primihub-cli.py --url http://localhost:30811/prod-api \\")
            print("    --user admin --password 123456 tasks")
            return None

    def get_fl_task_detail(self, task_id: str) -> Optional[Dict]:
        """获取联邦学习任务详情"""
        self._print_header(f"联邦学习任务详情 (ID: {task_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/federatedLearning/getTaskDetails", {
            "taskId": task_id
        })

        if result and result.get('code') == 0:
            task = result.get('result', {})

            self._print_success("获取成功")
            print(f"\n基本信息:")
            print(f"  任务ID: {task.get('taskId', 'N/A')}")
            print(f"  任务名称: {task.get('taskName', 'N/A')}")
            print(f"  任务描述: {task.get('taskDesc', 'N/A')}")
            print(f"  任务状态: {task.get('taskStateName', 'N/A')}")
            print(f"  算法类型: {task.get('algorithmName', 'N/A')}")
            print(f"  创建时间: {task.get('createDate', 'N/A')}")
            print(f"  开始时间: {task.get('startDate', 'N/A')}")
            print(f"  结束时间: {task.get('endDate', 'N/A')}")

            # 参与方信息
            if 'organDtos' in task and task['organDtos']:
                print(f"\n参与方信息:")
                for organ in task['organDtos']:
                    print(f"  - {organ.get('organName', 'N/A')} (ID: {organ.get('organId', 'N/A')})")

            # 模型信息
            if 'modelId' in task:
                print(f"\n模型信息:")
                print(f"  模型ID: {task.get('modelId', 'N/A')}")
                print(f"  模型名称: {task.get('modelName', 'N/A')}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_fl_models(self, page: int = 1, page_size: int = 10) -> Optional[Dict]:
        """获取联邦学习模型列表"""
        self._print_header("联邦学习模型列表")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/federatedLearning/getModelList", {
            "pageNo": page,
            "pageSize": page_size
        })

        if result and result.get('code') == 0:
            models = result.get('result', {}).get('data', [])
            total = result.get('result', {}).get('total', 0)

            self._print_success(f"找到 {total} 个模型")
            print(f"\n{'模型ID':<20} {'模型名称':<30} {'算法':<15} {'创建时间':<20}")
            print("-" * 85)

            for model in models:
                model_id = str(model.get('modelId', 'N/A'))
                model_name = model.get('modelName', 'N/A')[:29]
                algorithm = model.get('algorithmName', 'N/A')[:14]
                create_time = model.get('createDate', 'N/A')[:19] if model.get('createDate') else 'N/A'
                print(f"{model_id:<20} {model_name:<30} {algorithm:<15} {create_time:<20}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def get_fl_training_progress(self, task_id: str) -> Optional[Dict]:
        """获取联邦学习训练进度"""
        self._print_header(f"训练进度 (任务ID: {task_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/federatedLearning/getTrainingProgress", {
            "taskId": task_id
        })

        if result and result.get('code') == 0:
            progress = result.get('result', {})

            self._print_success("获取成功")
            print(f"\n训练进度:")
            print(f"  当前轮次: {progress.get('currentEpoch', 'N/A')}/{progress.get('totalEpoch', 'N/A')}")
            print(f"  完成进度: {progress.get('progress', 'N/A')}%")
            print(f"  当前状态: {progress.get('status', 'N/A')}")

            # 训练指标
            if 'metrics' in progress:
                metrics = progress['metrics']
                print(f"\n训练指标:")
                if 'loss' in metrics:
                    print(f"  损失值: {metrics['loss']}")
                if 'accuracy' in metrics:
                    print(f"  准确率: {metrics['accuracy']}")
                if 'auc' in metrics:
                    print(f"  AUC: {metrics['auc']}")

            return result
        else:
            self._print_error(f"获取失败: {result.get('msg') if result else '无响应'}")
            return None

    def create_project(self, project_name: str, project_type: int,
                      project_desc: str = None, organ_ids: list = None,
                      project_mode: int = 1) -> Optional[Dict]:
        """创建项目（通用方法）

        Args:
            project_name: 项目名称
            project_type: 项目类型 (1=PIR, 2=联邦学习, 3=PSI)
            project_desc: 项目描述
            organ_ids: 参与机构ID列表
            project_mode: 项目模式 (1=横向, 2=纵向，仅FL使用)
        """
        type_names = {1: "PIR", 2: "联邦学习", 3: "PSI"}
        type_name = type_names.get(project_type, "未知")

        self._print_header(f"创建{type_name}项目")

        if not self.token:
            self._print_error("请先登录")
            return None

        if not organ_ids:
            self._print_error("需要指定参与机构ID列表")
            return None

        # 构建机构参与信息
        project_organs = []
        for idx, organ_id in enumerate(organ_ids):
            project_organs.append({
                "organId": organ_id,
                "participationIdentity": 1 if idx == 0 else 2  # 第一个为发起方，其他为协作方
            })

        project_data = {
            "projectName": project_name,
            "projectDesc": project_desc or f"{type_name}项目 - {project_name}",
            "projectType": project_type,
            "serverOrganId": organ_ids[0] if organ_ids else None,
            "projectOrgans": project_organs
        }

        # 仅联邦学习需要 projectMode
        if project_type == 2:
            project_data["projectMode"] = project_mode

        result = self._request("POST", "/data/project/saveOrUpdateProject",
                              json_data=project_data)

        if result and result.get('code') == 0:
            project = result.get('result', {})
            self._print_success("项目创建成功")
            print(f"\n项目信息:")
            print(f"  项目ID: {project.get('id', 'N/A')}")
            print(f"  项目名称: {project.get('projectName', 'N/A')}")
            print(f"  项目类型: {type_name}")
            print(f"  参与机构数: {len(organ_ids)}")
            return result
        else:
            self._print_error(f"创建失败: {result.get('msg') if result else '无响应'}")
            return None

    def create_fl_project(self, project_name: str, project_desc: str = None,
                         organ_ids: list = None, project_mode: int = 1) -> Optional[Dict]:
        """创建联邦学习项目"""
        return self.create_project(project_name, 2, project_desc, organ_ids, project_mode)

    def create_psi_project(self, project_name: str, project_desc: str = None,
                          organ_ids: list = None) -> Optional[Dict]:
        """创建PSI项目"""
        return self.create_project(project_name, 3, project_desc, organ_ids)

    def create_pir_project(self, project_name: str, project_desc: str = None,
                          organ_ids: list = None) -> Optional[Dict]:
        """创建PIR项目"""
        return self.create_project(project_name, 1, project_desc, organ_ids)

    def create_fl_model(self, project_id: int, model_name: str,
                       resources: list, model_type: int = 3,
                       learning_rate: float = 0.1, batch_size: int = 32,
                       global_epoch: int = 10, local_epoch: int = 1,
                       encryption: str = "Plaintext",
                       num_tree: int = 5, max_depth: int = 5,
                       reg_lambda: float = 1.0, min_child_weight: int = 3) -> Optional[Dict]:
        """创建联邦学习模型

        Args:
            project_id: 项目ID (数据库中的id)
            model_name: 模型名称
            resources: 资源列表，每个资源包含 resourceId, organId 等信息
            model_type: 模型类型 (2=纵向XGBoost, 3=横向逻辑回归, 5=纵向逻辑回归等)
            learning_rate: 学习率 (LR类模型使用)
            batch_size: 批次大小 (LR类模型使用)
            global_epoch: 全局迭代次数 (LR类模型使用)
            local_epoch: 本地迭代次数 (LR类模型使用)
            encryption: 加密方式 (Plaintext, CKKS, Paillier)
            num_tree: 树的数量 (XGBoost使用, 对应Nacos组件参数numTree)
            max_depth: 树的最大深度 (XGBoost使用, 对应Nacos组件参数maxDepth)
            reg_lambda: 正则化系数 (XGBoost使用, 对应Nacos组件参数regLambda)
            min_child_weight: 最小子节点样本权重 (XGBoost使用, 对应Nacos组件参数minChildWeight)
        """
        self._print_header("创建联邦学习模型")

        if not self.token:
            self._print_error("请先登录")
            return None

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        task_name = f"FL_训练_{model_name}_{timestamp}"

        # 根据模型类型决定model组件参数，与Nacos components.json保持一致
        # model_type=2: 纵向XGBoost  model_type=3: 横向逻辑回归  model_type=5: 纵向逻辑回归
        XGBOOST_MODEL_TYPES = {2}  # 使用numTree/maxDepth/regLambda/minChildWeight的模型
        if model_type in XGBOOST_MODEL_TYPES:
            # XGBoost参数 - 参数名严格对应Nacos components.json中的type_code
            model_component_values = [
                {"key": "modelType", "val": str(model_type)},
                {"key": "modelName", "val": model_name},
                {"key": "modelDesc", "val": f"联邦学习模型 - {model_name}"},
                {"key": "numTree", "val": str(num_tree)},
                {"key": "maxDepth", "val": str(max_depth)},
                {"key": "regLambda", "val": str(int(reg_lambda))},
                {"key": "minChildWeight", "val": str(min_child_weight)}
            ]
            train_type = 0  # 纵向训练
        else:
            # LR/NN类模型参数
            model_component_values = [
                {"key": "modelType", "val": str(model_type)},
                {"key": "modelName", "val": model_name},
                {"key": "modelDesc", "val": f"联邦学习模型 - {model_name}"},
                {"key": "encryption", "val": encryption},
                {"key": "learningRate", "val": str(learning_rate)},
                {"key": "alpha", "val": "0.0001"},
                {"key": "batchSize", "val": str(batch_size)},
                {"key": "globalEpoch", "val": str(global_epoch)},
                {"key": "localEpoch", "val": str(local_epoch)}
            ]
            train_type = 1  # 横向训练

        model_data = {
            "param": {
                "projectId": project_id,
                "modelId": None,
                "isDraft": 1,
                "trainType": train_type,
                "modelComponents": [
                    {
                        "componentCode": "start",
                        "componentName": "开始",
                        "frontComponentId": "start_1",
                        "coordinateX": 100,
                        "coordinateY": 50,
                        "width": 180,
                        "height": 40,
                        "shape": "start-node",
                        "componentValues": [
                            {"key": "taskName", "val": task_name},
                            {"key": "taskDesc", "val": f"联邦学习训练任务 - {model_name}"}
                        ],
                        "input": [],
                        "output": [{"componentCode": "dataSet"}]
                    },
                    {
                        "componentCode": "dataSet",
                        "componentName": "选择数据集",
                        "frontComponentId": "dataSet_1",
                        "coordinateX": 100,
                        "coordinateY": 150,
                        "width": 180,
                        "height": 40,
                        "shape": "data-node",
                        "componentValues": [
                            {
                                "key": "selectData",
                                "val": json.dumps(resources, ensure_ascii=False)
                            }
                        ],
                        "input": [{"componentCode": "start"}],
                        "output": [{"componentCode": "model"}]
                    },
                    {
                        "componentCode": "model",
                        "componentName": "模型选择",
                        "frontComponentId": "model_1",
                        "coordinateX": 100,
                        "coordinateY": 250,
                        "width": 180,
                        "height": 40,
                        "shape": "model-node",
                        "componentValues": model_component_values,
                        "input": [{"componentCode": "dataSet"}],
                        "output": []
                    }
                ]
            }
        }

        result = self._request("POST", "/data/model/saveModelAndComponent",
                              json_data=model_data)

        if result and result.get('code') == 0:
            model_id = result.get('result', {}).get('modelId')
            type_names = {
                2: "纵向-XGBoost", 3: "横向-逻辑回归", 4: "MPC-逻辑回归",
                5: "纵向-逻辑回归", 6: "横向-NN(分类)", 7: "横向-NN(回归)",
                8: "横向-线性回归", 9: "纵向-线性回归"
            }
            self._print_success("模型创建成功")
            print(f"\n模型信息:")
            print(f"  模型ID: {model_id}")
            print(f"  模型名称: {model_name}")
            print(f"  模型类型: {type_names.get(model_type, f'类型{model_type}')}")
            print(f"\n训练参数:")
            if model_type in XGBOOST_MODEL_TYPES:
                print(f"  numTree: {num_tree}")
                print(f"  maxDepth: {max_depth}")
                print(f"  regLambda: {int(reg_lambda)}")
                print(f"  minChildWeight: {min_child_weight}")
            else:
                print(f"  学习率: {learning_rate}")
                print(f"  批次大小: {batch_size}")
                print(f"  全局迭代: {global_epoch}")
                print(f"  本地迭代: {local_epoch}")
                print(f"  加密方式: {encryption}")
            print(f"\n参与方数量: {len(resources)}")
            return result
        else:
            self._print_error(f"创建失败: {result.get('msg') if result else '无响应'}")
            return None

    def run_fl_model(self, model_id: int) -> Optional[Dict]:
        """启动联邦学习模型训练"""
        self._print_header(f"启动训练任务 (模型ID: {model_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        result = self._request("GET", "/data/model/runTaskModel", {
            "modelId": model_id
        })

        if result and result.get('code') == 0:
            task_data = result.get('result', {})
            task_id = task_data.get('taskId')
            self._print_success("训练任务已启动")
            print(f"\n任务信息:")
            print(f"  任务ID: {task_id}")
            print(f"  状态: 正在运行")
            return result
        else:
            self._print_error(f"启动失败: {result.get('msg') if result else '无响应'}")
            return None

    def monitor_fl_task(self, task_id: str, max_wait: int = 300,
                       check_interval: int = 5) -> Optional[Dict]:
        """监控联邦学习任务状态

        Args:
            task_id: 任务ID
            max_wait: 最大等待时间（秒）
            check_interval: 检查间隔（秒）
        """
        self._print_header(f"监控训练任务 (任务ID: {task_id})")

        if not self.token:
            self._print_error("请先登录")
            return None

        status_map = {
            0: "未开始",
            1: "等待中",
            2: "运行中",
            3: "成功",
            4: "失败"
        }

        start_time = time.time()
        last_status = None
        check_count = 0

        self._print_info(f"开始监控任务，最大等待时间: {max_wait}秒")

        while time.time() - start_time < max_wait:
            check_count += 1
            result = self._request("GET", "/data/task/getTaskData", {
                "taskId": task_id
            })

            if result and result.get('code') == 0:
                task = result.get('result', {})
                status = task.get('taskState')

                if status != last_status:
                    status_text = status_map.get(status, f'未知({status})')
                    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] 状态更新 (检查 #{check_count}): {status_text}")
                    last_status = status

                # 任务完成
                if status == 3:
                    self._print_success("训练任务完成！")
                    print(f"\n任务详情:")
                    print(f"  任务ID: {task.get('taskIdName', 'N/A')}")
                    print(f"  任务名称: {task.get('taskName', 'N/A')}")
                    print(f"  开始时间: {task.get('taskStartDate', 'N/A')}")
                    print(f"  结束时间: {task.get('taskEndDate', 'N/A')}")
                    if task.get('timeConsuming'):
                        print(f"  耗时: {task.get('timeConsuming')}ms")
                    return result
                elif status == 4:
                    self._print_error("训练任务失败")
                    if task.get('taskErrorMsg'):
                        print(f"  错误信息: {task.get('taskErrorMsg')}")
                    return result
            else:
                self._print_warning(f"获取任务状态失败 (尝试 #{check_count})")

            time.sleep(check_interval)

        self._print_warning(f"监控超时 ({max_wait}秒)")
        self._print_info("任务可能仍在运行，请稍后通过 fl-task-detail 命令查看")
        return None

    def create_psi_task(self, project_id: str, task_name: str,
                       own_organ_id: str, own_resource_id: str, own_keyword: str,
                       other_organ_id: str, other_resource_id: str, other_keyword: str,
                       result_organ_ids: str = None, algorithm: int = 0,
                       output_content: int = 0, output_no_repeat: int = 1) -> Optional[Dict]:
        """创建PSI（隐私集合求交）任务

        Args:
            project_id: 项目ID
            task_name: 任务名称
            own_organ_id: 发起方机构ID
            own_resource_id: 发起方资源ID
            own_keyword: 发起方匹配字段
            other_organ_id: 协作方机构ID
            other_resource_id: 协作方资源ID
            other_keyword: 协作方匹配字段
            result_organ_ids: 结果接收方机构ID（默认为发起方）
            algorithm: PSI算法类型 (0=DH, 1=ECDH, 2=KKRT, 3=BC22)
            output_content: 输出内容 (0=仅ID, 1=完整数据)
            output_no_repeat: 是否去重 (0=否, 1=是)
        """
        self._print_header("创建PSI任务")

        if not self.token:
            self._print_error("请先登录")
            return None

        timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
        algorithm_names = {
            0: "DH",
            1: "ECDH",
            2: "KKRT",
            3: "BC22"
        }

        if result_organ_ids is None:
            result_organ_ids = own_organ_id

        psi_params = {
            "taskName": task_name or f"PSI_{algorithm_names.get(algorithm)}_{timestamp_str}",
            "taskDesc": f"PSI任务 - {algorithm_names.get(algorithm)}算法",
            "projectId": str(project_id),
            "ownOrganId": own_organ_id,
            "ownResourceId": str(own_resource_id),
            "ownKeyword": own_keyword,
            "otherOrganId": other_organ_id,
            "otherResourceId": str(other_resource_id),
            "otherKeyword": other_keyword,
            "resultName": f"psi_result_{timestamp_str}",
            "resultOrganIds": result_organ_ids,
            "outputContent": str(output_content),
            "outputNoRepeat": str(output_no_repeat),
            "outputFilePathType": "0",
            # tag: 固定"0"（库类型标识），psiTag决定具体算法(0=DH,1=ECDH,2=KKRT,3=BC22)
            "tag": "0",
            "psiTag": str(algorithm)
        }

        result = self._request("POST", "/psi/saveDataPsi", data=psi_params)

        if result and result.get('code') == 0:
            task_data = result.get('result', {})
            task_id = task_data.get('taskId') or task_data.get('id')

            self._print_success("PSI任务创建成功")
            print(f"\n任务信息:")
            print(f"  任务ID: {task_id}")
            print(f"  任务名称: {psi_params['taskName']}")
            print(f"  算法类型: {algorithm_names.get(algorithm)}")
            print(f"  发起方: {own_organ_id}")
            print(f"  协作方: {other_organ_id}")
            print(f"  匹配字段: {own_keyword}")
            return result
        else:
            self._print_error(f"创建失败: {result.get('msg') if result else '无响应'}")
            return None

    def create_pir_task(self, project_id: str, task_name: str,
                       server_organ_id: str, server_resource_id: str,
                       client_organ_id: str, query_param: str,
                       result_organ_ids: str = None) -> Optional[Dict]:
        """创建PIR（隐私信息检索）任务

        Args:
            project_id: 项目ID
            task_name: 任务名称
            server_organ_id: 服务方机构ID
            server_resource_id: 服务方资源ID
            client_organ_id: 查询方机构ID
            query_param: 查询参数
            result_organ_ids: 结果接收方机构ID（默认为查询方）
        """
        self._print_header("创建PIR任务")

        if not self.token:
            self._print_error("请先登录")
            return None

        timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

        if result_organ_ids is None:
            result_organ_ids = client_organ_id

        pir_params = {
            "taskName": task_name or f"PIR_{timestamp_str}",
            "taskDesc": f"PIR任务 - 隐私信息检索",
            "projectId": str(project_id),
            "serverOrganId": server_organ_id,
            "serverResourceId": str(server_resource_id),
            "clientOrganId": client_organ_id,
            "queryParam": query_param,
            "resultName": f"pir_result_{timestamp_str}",
            "resultOrganIds": result_organ_ids
        }

        result = self._request("POST", "/data/pir/savePirTask", data=pir_params)

        if result and result.get('code') == 0:
            task_data = result.get('result', {})
            task_id = task_data.get('taskId') or task_data.get('id')

            self._print_success("PIR任务创建成功")
            print(f"\n任务信息:")
            print(f"  任务ID: {task_id}")
            print(f"  任务名称: {pir_params['taskName']}")
            print(f"  服务方: {server_organ_id}")
            print(f"  查询方: {client_organ_id}")
            print(f"  查询参数: {query_param}")
            return result
        else:
            self._print_error(f"创建失败: {result.get('msg') if result else '无响应'}")
            return None

    def test_all_apis(self) -> Dict[str, bool]:
        """测试所有关键接口"""
        self._print_header("接口可用性测试")

        results = {}

        # 1. 健康检查
        self._print_info("测试 1/7: 健康检查接口")
        results['health'] = self.health_check()

        # 2. 登录接口
        self._print_info("\n测试 2/7: 登录接口")
        results['login'] = self.login()

        if not results['login']:
            self._print_error("登录失败，跳过后续测试")
            return results

        # 3. 机构列表
        self._print_info("\n测试 3/7: 机构列表接口")
        organ_result = self.get_organs()
        results['organs'] = organ_result is not None

        # 4. 项目列表
        self._print_info("\n测试 4/7: 项目列表接口")
        project_result = self.get_projects()
        results['projects'] = project_result is not None

        # 5. 资源列表
        self._print_info("\n测试 5/7: 资源列表接口")
        resource_result = self.get_resources()
        results['resources'] = resource_result is not None

        # 6. 任务列表
        self._print_info("\n测试 6/7: 任务列表接口")
        task_result = self.get_tasks()
        results['tasks'] = task_result is not None

        # 7. 模型列表
        self._print_info("\n测试 7/7: 模型列表接口")
        model_result = self.get_models()
        results['models'] = model_result is not None

        # 汇总结果
        self._print_header("测试结果汇总")

        total = len(results)
        passed = sum(1 for v in results.values() if v)
        failed = total - passed

        print(f"\n总计: {total} 个接口")
        print(f"{Colors.OKGREEN}通过: {passed}{Colors.ENDC}")
        print(f"{Colors.FAIL}失败: {failed}{Colors.ENDC}")

        print(f"\n{'接口':<20} {'状态':<10}")
        print("-" * 30)
        for api, status in results.items():
            status_str = f"{Colors.OKGREEN}✓ 通过{Colors.ENDC}" if status else f"{Colors.FAIL}✗ 失败{Colors.ENDC}"
            print(f"{api:<20} {status_str}")

        return results


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='PrimiHub CLI - PrimiHub 平台客户端命令行工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 健康检查
  python primihub-cli.py health

  # 登录
  python primihub-cli.py login --user admin --password 123456

  # 测试所有接口
  python primihub-cli.py test-all

  # 查看机构列表
  python primihub-cli.py organs

  # 查看项目列表
  python primihub-cli.py projects

  # 查看资源列表
  python primihub-cli.py resources

  # 查看任务列表
  python primihub-cli.py tasks

  # 查看模型列表
  python primihub-cli.py models

  # 查看用户列表
  python primihub-cli.py users

  # 查看数据集列表
  python primihub-cli.py datasets

  # 按名称搜索数据集
  python primihub-cli.py datasets --name "测试"

  # 查看数据集详情
  python primihub-cli.py dataset-detail <资源ID>

  # 查看数据集字段
  python primihub-cli.py dataset-fields <资源ID>

  # 查看数据集标签
  python primihub-cli.py dataset-tags

  # 预览数据集
  python primihub-cli.py dataset-preview --resource-id <资源ID>

  # ===== 节点认证相关命令 =====
  # 查看节点认证状态
  python primihub-cli.py auth-list

  # 请求与其他节点建立认证关系
  python primihub-cli.py auth-request http://192.168.1.100:8080

  # 批准节点认证请求
  python primihub-cli.py auth-approve <请求ID>

  # 拒绝节点认证请求（带原因）
  python primihub-cli.py auth-reject <请求ID> --reason "不符合条件"

  # 启用合作机构
  python primihub-cli.py auth-enable <机构ID>

  # 禁用合作机构
  python primihub-cli.py auth-disable <机构ID>

  # 查看PSI任务列表
  python primihub-cli.py psi-tasks

  # 查看PSI任务详情
  python primihub-cli.py psi-task-detail <任务ID>

  # 查看PIR任务列表
  python primihub-cli.py pir-tasks

  # 查看PIR任务详情
  python primihub-cli.py pir-task-detail <任务ID>

  # 查看联邦学习任务列表
  python primihub-cli.py fl-tasks

  # 查看联邦学习任务详情
  python primihub-cli.py fl-task-detail <任务ID>

  # 查看联邦学习模型列表
  python primihub-cli.py fl-models

  # 查看训练进度
  python primihub-cli.py fl-training-progress <任务ID>

  # 指定服务器地址
  python primihub-cli.py --url http://172.19.0.14:8080 --password 123456 login
        """
    )

    parser.add_argument('--url', type=str, default='http://localhost:30811/prod-api',
                        help='PrimiHub 服务器地址，支持 localhost/LAN/Tailscale IP '
                             '(默认: http://localhost:30811/prod-api)')
    parser.add_argument('--user', type=str, default='admin',
                        help='用户名 (默认: admin)')
    parser.add_argument('--password', type=str, default='123456',
                        help='密码 (默认: 123456)')
    parser.add_argument('--proxy', type=str, default=None,
                        help='HTTP 代理地址，如 http://127.0.0.1:17900 (默认: 使用系统代理)')
    parser.add_argument('--no-proxy', action='store_true', default=False,
                        help='强制直连，忽略系统代理环境变量（适合直连 LAN/Tailscale）')

    subparsers = parser.add_subparsers(dest='command', help='可用命令')

    # health 命令
    subparsers.add_parser('health', help='健康检查')

    # login 命令
    subparsers.add_parser('login', help='登录系统')

    # test-all 命令
    subparsers.add_parser('test-all', help='测试所有接口')

    # organs 命令
    organs_parser = subparsers.add_parser('organs', help='查看机构列表')
    organs_parser.add_argument('--page', type=int, default=1, help='页码')
    organs_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # auth-request 命令 - 请求节点认证
    auth_request_parser = subparsers.add_parser('auth-request', help='请求与其他节点建立认证关系')
    auth_request_parser.add_argument('gateway', type=str, help='目标节点的网关地址')
    auth_request_parser.add_argument('--public-key', type=str, help='本地公钥（不提供则自动获取）')

    # auth-list 命令 - 列出认证状态
    auth_list_parser = subparsers.add_parser('auth-list', help='查看节点认证状态')
    auth_list_parser.add_argument('--page', type=int, default=1, help='页码')
    auth_list_parser.add_argument('--size', type=int, default=20, help='每页数量')
    auth_list_parser.add_argument('--status', type=str, choices=['0', '1', '2'],
                                  help='筛选状态 (0=待审核, 1=已批准, 2=已拒绝)')

    # auth-approve 命令 - 批准认证请求
    auth_approve_parser = subparsers.add_parser('auth-approve', help='批准节点认证请求')
    auth_approve_parser.add_argument('request_id', type=int, help='认证请求ID')
    auth_approve_parser.add_argument('--reason', type=str, help='批准说明')

    # auth-reject 命令 - 拒绝认证请求
    auth_reject_parser = subparsers.add_parser('auth-reject', help='拒绝节点认证请求')
    auth_reject_parser.add_argument('request_id', type=int, help='认证请求ID')
    auth_reject_parser.add_argument('--reason', type=str, help='拒绝原因')

    # auth-enable 命令 - 启用合作机构
    auth_enable_parser = subparsers.add_parser('auth-enable', help='启用合作机构')
    auth_enable_parser.add_argument('organ_id', type=int, help='机构ID')

    # auth-disable 命令 - 禁用合作机构
    auth_disable_parser = subparsers.add_parser('auth-disable', help='禁用合作机构')
    auth_disable_parser.add_argument('organ_id', type=int, help='机构ID')

    # projects 命令
    projects_parser = subparsers.add_parser('projects', help='查看项目列表')
    projects_parser.add_argument('--page', type=int, default=1, help='页码')
    projects_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # resources 命令
    resources_parser = subparsers.add_parser('resources', help='查看资源列表')
    resources_parser.add_argument('--page', type=int, default=1, help='页码')
    resources_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # tasks 命令
    tasks_parser = subparsers.add_parser('tasks', help='查看任务列表')
    tasks_parser.add_argument('--page', type=int, default=1, help='页码')
    tasks_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # models 命令
    models_parser = subparsers.add_parser('models', help='查看模型列表')
    models_parser.add_argument('--page', type=int, default=1, help='页码')
    models_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # users 命令
    users_parser = subparsers.add_parser('users', help='查看用户列表')
    users_parser.add_argument('--page', type=int, default=1, help='页码')
    users_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # datasets 命令
    datasets_parser = subparsers.add_parser('datasets', help='查看数据集列表')
    datasets_parser.add_argument('--page', type=int, default=1, help='页码')
    datasets_parser.add_argument('--size', type=int, default=10, help='每页数量')
    datasets_parser.add_argument('--name', type=str, help='资源名称（模糊搜索）')
    datasets_parser.add_argument('--tags', type=str, help='标签筛选')

    # dataset-detail 命令
    dataset_detail_parser = subparsers.add_parser('dataset-detail', help='查看数据集详情')
    dataset_detail_parser.add_argument('resource_id', type=str, help='资源ID')

    # dataset-fields 命令
    dataset_fields_parser = subparsers.add_parser('dataset-fields', help='查看数据集字段')
    dataset_fields_parser.add_argument('resource_id', type=int, help='资源ID')
    dataset_fields_parser.add_argument('--page', type=int, default=1, help='页码')
    dataset_fields_parser.add_argument('--size', type=int, default=20, help='每页数量')

    # dataset-tags 命令
    subparsers.add_parser('dataset-tags', help='查看数据集标签列表')

    # dataset-preview 命令
    dataset_preview_parser = subparsers.add_parser('dataset-preview', help='预览数据集内容')
    dataset_preview_parser.add_argument('--resource-id', type=str, help='资源ID')
    dataset_preview_parser.add_argument('--file-id', type=int, help='文件ID')

    # psi-tasks 命令
    psi_tasks_parser = subparsers.add_parser('psi-tasks', help='查看PSI任务列表')
    psi_tasks_parser.add_argument('--page', type=int, default=1, help='页码')
    psi_tasks_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # psi-task-detail 命令
    psi_task_detail_parser = subparsers.add_parser('psi-task-detail', help='查看PSI任务详情')
    psi_task_detail_parser.add_argument('task_id', type=str, help='任务ID')

    # pir-tasks 命令
    pir_tasks_parser = subparsers.add_parser('pir-tasks', help='查看PIR任务列表')
    pir_tasks_parser.add_argument('--page', type=int, default=1, help='页码')
    pir_tasks_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # pir-task-detail 命令
    pir_task_detail_parser = subparsers.add_parser('pir-task-detail', help='查看PIR任务详情')
    pir_task_detail_parser.add_argument('task_id', type=str, help='任务ID')

    # fl-tasks 命令
    fl_tasks_parser = subparsers.add_parser('fl-tasks', help='查看联邦学习任务列表')
    fl_tasks_parser.add_argument('--page', type=int, default=1, help='页码')
    fl_tasks_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # fl-task-detail 命令
    fl_task_detail_parser = subparsers.add_parser('fl-task-detail', help='查看联邦学习任务详情')
    fl_task_detail_parser.add_argument('task_id', type=str, help='任务ID')

    # fl-models 命令
    fl_models_parser = subparsers.add_parser('fl-models', help='查看联邦学习模型列表')
    fl_models_parser.add_argument('--page', type=int, default=1, help='页码')
    fl_models_parser.add_argument('--size', type=int, default=10, help='每页数量')

    # fl-training-progress 命令
    fl_progress_parser = subparsers.add_parser('fl-training-progress', help='查看训练进度')
    fl_progress_parser.add_argument('task_id', type=str, help='任务ID')

    # fl-create-project 命令
    fl_create_project_parser = subparsers.add_parser('fl-create-project', help='创建联邦学习项目')
    fl_create_project_parser.add_argument('project_name', type=str, help='项目名称')
    fl_create_project_parser.add_argument('--desc', type=str, help='项目描述')
    fl_create_project_parser.add_argument('--organs', type=str, required=True,
                                         help='参与机构ID列表，逗号分隔')
    fl_create_project_parser.add_argument('--mode', type=int, default=1,
                                         choices=[1, 2],
                                         help='项目模式 (1=横向, 2=纵向, 默认: 1)')

    # psi-create-project 命令
    psi_create_project_parser = subparsers.add_parser('psi-create-project', help='创建PSI项目')
    psi_create_project_parser.add_argument('project_name', type=str, help='项目名称')
    psi_create_project_parser.add_argument('--desc', type=str, help='项目描述')
    psi_create_project_parser.add_argument('--organs', type=str, required=True,
                                           help='参与机构ID列表，逗号分隔')

    # pir-create-project 命令
    pir_create_project_parser = subparsers.add_parser('pir-create-project', help='创建PIR项目')
    pir_create_project_parser.add_argument('project_name', type=str, help='项目名称')
    pir_create_project_parser.add_argument('--desc', type=str, help='项目描述')
    pir_create_project_parser.add_argument('--organs', type=str, required=True,
                                           help='参与机构ID列表，逗号分隔')

    # fl-create-model 命令
    fl_create_model_parser = subparsers.add_parser('fl-create-model', help='创建联邦学习模型')
    fl_create_model_parser.add_argument('project_id', type=int, help='项目ID')
    fl_create_model_parser.add_argument('model_name', type=str, help='模型名称')
    fl_create_model_parser.add_argument('--resources', type=str, required=True,
                                       help='资源配置JSON文件路径')
    fl_create_model_parser.add_argument('--model-type', type=int, default=3,
                                       help='模型类型 (2=纵向XGBoost, 3=横向逻辑回归, 5=纵向逻辑回归, 默认: 3)')
    # LR/NN类模型参数
    fl_create_model_parser.add_argument('--learning-rate', type=float, default=0.1,
                                       help='学习率 - LR/NN模型使用 (默认: 0.1)')
    fl_create_model_parser.add_argument('--batch-size', type=int, default=32,
                                       help='批次大小 - LR/NN模型使用 (默认: 32)')
    fl_create_model_parser.add_argument('--global-epoch', type=int, default=10,
                                       help='全局迭代次数 - LR/NN模型使用 (默认: 10)')
    fl_create_model_parser.add_argument('--local-epoch', type=int, default=1,
                                       help='本地迭代次数 - LR/NN模型使用 (默认: 1)')
    fl_create_model_parser.add_argument('--encryption', type=str, default='Plaintext',
                                       choices=['Plaintext', 'CKKS', 'Paillier'],
                                       help='加密方式 - LR/NN模型使用 (默认: Plaintext)')
    # XGBoost专用参数（与Nacos components.json中的type_code保持一致）
    fl_create_model_parser.add_argument('--num-tree', type=int, default=5,
                                       help='树的数量 - XGBoost(model-type=2)使用, 对应numTree (默认: 5)')
    fl_create_model_parser.add_argument('--max-depth', type=int, default=5,
                                       help='树最大深度 - XGBoost(model-type=2)使用, 对应maxDepth (默认: 5)')
    fl_create_model_parser.add_argument('--reg-lambda', type=float, default=1.0,
                                       help='正则化系数 - XGBoost(model-type=2)使用, 对应regLambda (默认: 1.0)')
    fl_create_model_parser.add_argument('--min-child-weight', type=int, default=3,
                                       help='最小子节点权重 - XGBoost(model-type=2)使用, 对应minChildWeight (默认: 3)')

    # fl-run-model 命令
    fl_run_model_parser = subparsers.add_parser('fl-run-model', help='启动联邦学习模型训练')
    fl_run_model_parser.add_argument('model_id', type=int, help='模型ID')

    # fl-monitor-task 命令
    fl_monitor_task_parser = subparsers.add_parser('fl-monitor-task', help='监控联邦学习任务')
    fl_monitor_task_parser.add_argument('task_id', type=str, help='任务ID')
    fl_monitor_task_parser.add_argument('--max-wait', type=int, default=300,
                                       help='最大等待时间（秒，默认: 300）')
    fl_monitor_task_parser.add_argument('--interval', type=int, default=5,
                                       help='检查间隔（秒，默认: 5）')

    # psi-create 命令
    psi_create_parser = subparsers.add_parser('psi-create', help='创建PSI隐私集合求交任务')
    psi_create_parser.add_argument('project_id', type=str, help='项目ID')
    psi_create_parser.add_argument('task_name', type=str, help='任务名称')
    psi_create_parser.add_argument('--own-organ', type=str, required=True,
                                   help='发起方机构ID')
    psi_create_parser.add_argument('--own-resource', type=str, required=True,
                                   help='发起方资源ID')
    psi_create_parser.add_argument('--own-keyword', type=str, required=True,
                                   help='发起方匹配字段')
    psi_create_parser.add_argument('--other-organ', type=str, required=True,
                                   help='协作方机构ID')
    psi_create_parser.add_argument('--other-resource', type=str, required=True,
                                   help='协作方资源ID')
    psi_create_parser.add_argument('--other-keyword', type=str, required=True,
                                   help='协作方匹配字段')
    psi_create_parser.add_argument('--result-organs', type=str,
                                   help='结果接收方机构ID（默认为发起方）')
    psi_create_parser.add_argument('--algorithm', type=int, default=0,
                                   choices=[0, 1, 2, 3],
                                   help='PSI算法 (0=DH, 1=ECDH, 2=KKRT, 3=BC22, 默认: 0)')
    psi_create_parser.add_argument('--output-content', type=int, default=0,
                                   choices=[0, 1],
                                   help='输出内容 (0=仅ID, 1=完整数据, 默认: 0)')
    psi_create_parser.add_argument('--no-repeat', type=int, default=1,
                                   choices=[0, 1],
                                   help='是否去重 (0=否, 1=是, 默认: 1)')

    # pir-create 命令
    pir_create_parser = subparsers.add_parser('pir-create', help='创建PIR隐私信息检索任务')
    pir_create_parser.add_argument('project_id', type=str, help='项目ID')
    pir_create_parser.add_argument('task_name', type=str, help='任务名称')
    pir_create_parser.add_argument('--server-organ', type=str, required=True,
                                   help='服务方机构ID')
    pir_create_parser.add_argument('--server-resource', type=str, required=True,
                                   help='服务方资源ID')
    pir_create_parser.add_argument('--client-organ', type=str, required=True,
                                   help='查询方机构ID')
    pir_create_parser.add_argument('--query-param', type=str, required=True,
                                   help='查询参数')
    pir_create_parser.add_argument('--result-organs', type=str,
                                   help='结果接收方机构ID（默认为查询方）')

    args = parser.parse_args()

    # 创建 CLI 实例
    cli = PrimiHubCLI(
        base_url=args.url,
        proxy=args.proxy,
        no_proxy=args.no_proxy,
    )

    # 如果没有指定命令，显示帮助
    if not args.command:
        parser.print_help()
        return

    # 执行命令
    if args.command == 'health':
        cli.health_check()

    elif args.command == 'login':
        cli.login(username=args.user, password=args.password)

    elif args.command == 'test-all':
        results = cli.test_all_apis()
        # 如果有失败的测试，返回非零退出码
        if not all(results.values()):
            sys.exit(1)

    elif args.command == 'organs':
        if cli.login(username=args.user, password=args.password):
            cli.get_organs(page=args.page, page_size=args.size)

    elif args.command == 'auth-request':
        if cli.login(username=args.user, password=args.password):
            public_key = getattr(args, 'public_key', None)
            cli.auth_request_partner(gateway=args.gateway, public_key=public_key)

    elif args.command == 'auth-list':
        if cli.login(username=args.user, password=args.password):
            status = getattr(args, 'status', None)
            cli.auth_list_requests(page=args.page, page_size=args.size, status=status)

    elif args.command == 'auth-approve':
        if cli.login(username=args.user, password=args.password):
            reason = getattr(args, 'reason', None)
            cli.auth_examine_request(request_id=args.request_id, action='approve', reason=reason)

    elif args.command == 'auth-reject':
        if cli.login(username=args.user, password=args.password):
            reason = getattr(args, 'reason', None)
            cli.auth_examine_request(request_id=args.request_id, action='reject', reason=reason)

    elif args.command == 'auth-enable':
        if cli.login(username=args.user, password=args.password):
            cli.auth_enable_disable(organ_id=args.organ_id, enable=True)

    elif args.command == 'auth-disable':
        if cli.login(username=args.user, password=args.password):
            cli.auth_enable_disable(organ_id=args.organ_id, enable=False)

    elif args.command == 'projects':
        if cli.login(username=args.user, password=args.password):
            cli.get_projects(page=args.page, page_size=args.size)

    elif args.command == 'resources':
        if cli.login(username=args.user, password=args.password):
            cli.get_resources(page=args.page, page_size=args.size)

    elif args.command == 'tasks':
        if cli.login(username=args.user, password=args.password):
            cli.get_tasks(page=args.page, page_size=args.size)

    elif args.command == 'models':
        if cli.login(username=args.user, password=args.password):
            cli.get_models(page=args.page, page_size=args.size)

    elif args.command == 'users':
        if cli.login(username=args.user, password=args.password):
            cli.get_users(page=args.page, page_size=args.size)

    elif args.command == 'datasets':
        if cli.login(username=args.user, password=args.password):
            cli.get_datasets(page=args.page, page_size=args.size,
                            resource_name=args.name, tags=args.tags)

    elif args.command == 'dataset-detail':
        if cli.login(username=args.user, password=args.password):
            cli.get_dataset_detail(resource_id=args.resource_id)

    elif args.command == 'dataset-fields':
        if cli.login(username=args.user, password=args.password):
            cli.get_dataset_fields(resource_id=args.resource_id,
                                  page=args.page, page_size=args.size)

    elif args.command == 'dataset-tags':
        if cli.login(username=args.user, password=args.password):
            cli.get_dataset_tags()

    elif args.command == 'dataset-preview':
        if cli.login(username=args.user, password=args.password):
            cli.preview_dataset(resource_id=args.resource_id, file_id=args.file_id)

    elif args.command == 'psi-tasks':
        if cli.login(username=args.user, password=args.password):
            cli.get_psi_tasks(page=args.page, page_size=args.size)

    elif args.command == 'psi-task-detail':
        if cli.login(username=args.user, password=args.password):
            cli.get_psi_task_detail(task_id=args.task_id)

    elif args.command == 'pir-tasks':
        if cli.login(username=args.user, password=args.password):
            cli.get_pir_tasks(page=args.page, page_size=args.size)

    elif args.command == 'pir-task-detail':
        if cli.login(username=args.user, password=args.password):
            cli.get_pir_task_detail(task_id=args.task_id)

    elif args.command == 'fl-tasks':
        if cli.login(username=args.user, password=args.password):
            cli.get_fl_tasks(page=args.page, page_size=args.size)

    elif args.command == 'fl-task-detail':
        if cli.login(username=args.user, password=args.password):
            cli.get_fl_task_detail(task_id=args.task_id)

    elif args.command == 'fl-models':
        if cli.login(username=args.user, password=args.password):
            cli.get_fl_models(page=args.page, page_size=args.size)

    elif args.command == 'fl-training-progress':
        if cli.login(username=args.user, password=args.password):
            cli.get_fl_training_progress(task_id=args.task_id)

    elif args.command == 'fl-create-project':
        if cli.login(username=args.user, password=args.password):
            organ_ids = [oid.strip() for oid in args.organs.split(',')]
            result = cli.create_fl_project(
                project_name=args.project_name,
                project_desc=args.desc,
                organ_ids=organ_ids,
                project_mode=args.mode
            )
            if result:
                project_id = result.get('result', {}).get('id')
                if project_id:
                    print(f"\n提示: 项目ID为 {project_id}，可用于创建模型")

    elif args.command == 'psi-create-project':
        if cli.login(username=args.user, password=args.password):
            organ_ids = [oid.strip() for oid in args.organs.split(',')]
            result = cli.create_psi_project(
                project_name=args.project_name,
                project_desc=args.desc,
                organ_ids=organ_ids
            )
            if result:
                project_id = result.get('result', {}).get('id')
                if project_id:
                    print(f"\n提示: 项目ID为 {project_id}，可用于创建PSI任务")
                    print(f"  python primihub-cli.py psi-create {project_id} <任务名> ...")

    elif args.command == 'pir-create-project':
        if cli.login(username=args.user, password=args.password):
            organ_ids = [oid.strip() for oid in args.organs.split(',')]
            result = cli.create_pir_project(
                project_name=args.project_name,
                project_desc=args.desc,
                organ_ids=organ_ids
            )
            if result:
                project_id = result.get('result', {}).get('id')
                if project_id:
                    print(f"\n提示: 项目ID为 {project_id}，可用于创建PIR任务")
                    print(f"  python primihub-cli.py pir-create {project_id} <任务名> ...")

    elif args.command == 'fl-create-model':
        if cli.login(username=args.user, password=args.password):
            # 读取资源配置文件
            try:
                with open(args.resources, 'r', encoding='utf-8') as f:
                    resources = json.load(f)

                result = cli.create_fl_model(
                    project_id=args.project_id,
                    model_name=args.model_name,
                    resources=resources,
                    model_type=args.model_type,
                    learning_rate=args.learning_rate,
                    batch_size=args.batch_size,
                    global_epoch=args.global_epoch,
                    local_epoch=args.local_epoch,
                    encryption=args.encryption,
                    num_tree=args.num_tree,
                    max_depth=args.max_depth,
                    reg_lambda=args.reg_lambda,
                    min_child_weight=args.min_child_weight
                )

                if result:
                    model_id = result.get('result', {}).get('modelId')
                    print(f"\n提示: 使用以下命令启动训练:")
                    print(f"  python primihub-cli.py fl-run-model {model_id}")
            except FileNotFoundError:
                print(f"错误: 找不到资源配置文件: {args.resources}")
            except json.JSONDecodeError as e:
                print(f"错误: 资源配置文件格式错误: {e}")

    elif args.command == 'fl-run-model':
        if cli.login(username=args.user, password=args.password):
            result = cli.run_fl_model(model_id=args.model_id)
            if result:
                task_id = result.get('result', {}).get('taskId')
                print(f"\n提示: 使用以下命令监控任务:")
                print(f"  python primihub-cli.py fl-monitor-task {task_id}")

    elif args.command == 'fl-monitor-task':
        if cli.login(username=args.user, password=args.password):
            cli.monitor_fl_task(
                task_id=args.task_id,
                max_wait=args.max_wait,
                check_interval=args.interval
            )

    elif args.command == 'psi-create':
        if cli.login(username=args.user, password=args.password):
            result = cli.create_psi_task(
                project_id=args.project_id,
                task_name=args.task_name,
                own_organ_id=args.own_organ,
                own_resource_id=args.own_resource,
                own_keyword=args.own_keyword,
                other_organ_id=args.other_organ,
                other_resource_id=args.other_resource,
                other_keyword=args.other_keyword,
                result_organ_ids=args.result_organs,
                algorithm=args.algorithm,
                output_content=args.output_content,
                output_no_repeat=args.no_repeat
            )
            if result:
                task_id = result.get('result', {}).get('taskId') or result.get('result', {}).get('id')
                if task_id:
                    print(f"\n提示: 使用以下命令查看任务详情:")
                    print(f"  python primihub-cli.py psi-task-detail {task_id}")

    elif args.command == 'pir-create':
        if cli.login(username=args.user, password=args.password):
            result = cli.create_pir_task(
                project_id=args.project_id,
                task_name=args.task_name,
                server_organ_id=args.server_organ,
                server_resource_id=args.server_resource,
                client_organ_id=args.client_organ,
                query_param=args.query_param,
                result_organ_ids=args.result_organs
            )
            if result:
                task_id = result.get('result', {}).get('taskId') or result.get('result', {}).get('id')
                if task_id:
                    print(f"\n提示: 使用以下命令查看任务详情:")
                    print(f"  python primihub-cli.py pir-task-detail {task_id}")


if __name__ == "__main__":
    main()
