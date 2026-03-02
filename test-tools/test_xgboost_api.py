#!/usr/bin/env python3
"""
PrimiHub XGBoost 联邦学习 API 测试脚本
用于测试通过前端API调用运行XGBoost联邦学习项目
"""

import requests
import json
import time
import sys
import os
import argparse
import ipaddress
from datetime import datetime
from urllib.parse import urlparse


def _make_session(base_url: str = '', proxy: str = None, no_proxy: bool = False) -> requests.Session:
    """
    创建代理感知的 requests.Session。
    - no_proxy=True 或目标为私有地址 → 强制直连
    - proxy 参数 → 使用指定代理，私有网段直连
    - 默认 → 系统代理（Clash 等），自动补全私有网段 no_proxy
    """
    _PRIVATE = ('localhost', '127.0.0.1', '::1',
                '172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/16', '100.64.0.0/10')

    def _is_private(url: str) -> bool:
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

    session = requests.Session()
    if no_proxy or _is_private(base_url):
        session.trust_env = False
        session.proxies = {'http': None, 'https': None}
    elif proxy:
        session.proxies = {'http': proxy, 'https': proxy,
                           'no_proxy': ','.join(_PRIVATE)}
    else:
        existing = os.environ.get('no_proxy') or os.environ.get('NO_PROXY') or ''
        needed = [s for s in _PRIVATE if s not in existing]
        if needed:
            os.environ['no_proxy'] = ','.join(filter(None, [existing] + list(needed)))
    return session


class PrimiHubAPIClient:
    """PrimiHub API 客户端"""

    def __init__(self, base_url="http://localhost:30811", username="admin", password="123456",
                 proxy: str = None, no_proxy: bool = False):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.token = None
        self.session = _make_session(base_url=self.base_url, proxy=proxy, no_proxy=no_proxy)

    def login(self):
        """登录系统获取token"""
        print(f"🔐 正在登录系统: {self.username}")

        url = f"{self.base_url}/prod-api/user/login"
        data = {
            "userAccount": self.username,
            "userPassword": self.password
        }

        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            result = response.json()

            if result.get('code') == 0:
                self.token = result.get('result', {}).get('token')
                if self.token:
                    self.session.headers.update({'Authorization': f'Bearer {self.token}'})
                    print(f"✅ 登录成功! Token: {self.token[:20]}...")
                    return True
                else:
                    print(f"❌ 登录失败: 未获取到token")
                    return False
            else:
                print(f"❌ 登录失败: {result.get('msg', '未知错误')}")
                return False

        except Exception as e:
            print(f"❌ 登录异常: {str(e)}")
            return False

    def get_projects(self):
        """获取项目列表"""
        print("\n📋 获取项目列表...")

        url = f"{self.base_url}/prod-api/project/getProjectList"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            result = response.json()

            if result.get('code') == 0:
                projects = result.get('result', {}).get('list', [])
                print(f"✅ 找到 {len(projects)} 个项目")
                for proj in projects:
                    print(f"   - {proj.get('projectName')} (ID: {proj.get('projectId')})")
                return projects
            else:
                print(f"❌ 获取项目失败: {result.get('msg')}")
                return []

        except Exception as e:
            print(f"❌ 获取项目异常: {str(e)}")
            return []

    def get_resources(self):
        """获取数据资源列表"""
        print("\n📊 获取数据资源列表...")

        url = f"{self.base_url}/prod-api/data/getDataList"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            result = response.json()

            if result.get('code') == 0:
                resources = result.get('result', {}).get('list', [])
                print(f"✅ 找到 {len(resources)} 个数据资源")
                for res in resources[:5]:  # 只显示前5个
                    print(f"   - {res.get('resourceName')} (ID: {res.get('resourceId')})")
                return resources
            else:
                print(f"❌ 获取资源失败: {result.get('msg')}")
                return []

        except Exception as e:
            print(f"❌ 获取资源异常: {str(e)}")
            return []

    def create_xgboost_model(self, project_id, model_name=None, model_desc=None,
                            max_depth=3, n_trees=10):
        """创建XGBoost联邦学习模型
        参数名与Nacos components.json保持一致: numTree, maxDepth, regLambda, minChildWeight
        """

        if not model_name:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            model_name = f"XGBoost模型_{timestamp}"

        if not model_desc:
            model_desc = "通过API创建的纵向XGBoost联邦学习模型"

        print(f"\n🚀 创建XGBoost模型: {model_name}")
        print(f"   项目ID: {project_id}")
        print(f"   参数: maxDepth={max_depth}, numTree={n_trees}, regLambda=1, minChildWeight=3")

        # 构建模型组件JSON
        component_json = {
            "isDraft": 1,
            "modelComponents": [
                {
                    "componentCode": "start",
                    "componentName": "开始",
                    "componentValues": [
                        {"key": "taskName", "val": f"XGBoost训练_{datetime.now().strftime('%Y%m%d_%H%M%S')}"},
                        {"key": "taskDesc", "val": "通过API创建的XGBoost训练任务"}
                    ],
                    "coordinateX": 100,
                    "coordinateY": 50,
                    "frontComponentId": "start_1",
                    "height": 40,
                    "input": [],
                    "output": [{"componentCode": "dataSet"}],
                    "shape": "start-node",
                    "width": 180
                },
                {
                    "componentCode": "dataSet",
                    "componentName": "选择数据集",
                    "componentValues": [
                        {"key": "selectData", "val": ""}
                    ],
                    "coordinateX": 100,
                    "coordinateY": 150,
                    "frontComponentId": "dataSet_1",
                    "height": 40,
                    "input": [{"componentCode": "start"}],
                    "output": [{"componentCode": "model"}],
                    "shape": "data-node",
                    "width": 180
                },
                {
                    "componentCode": "model",
                    "componentName": "模型选择",
                    "componentValues": [
                        {"key": "modelType", "val": "2"},  # 2 = 纵向-XGBoost
                        {"key": "modelName", "val": model_name},
                        {"key": "modelDesc", "val": model_desc},
                        {"key": "maxDepth", "val": str(max_depth)},
                        # numTree: 与Nacos components.json中XGBoost参数名一致（非nTrees）
                        {"key": "numTree", "val": str(n_trees)},
                        {"key": "regLambda", "val": "1"},
                        {"key": "minChildWeight", "val": "3"}
                        # XGBoost不使用learningRate（已移除），learningRate属于LR模型参数
                    ],
                    "coordinateX": 100,
                    "coordinateY": 250,
                    "frontComponentId": "model_1",
                    "height": 40,
                    "input": [{"componentCode": "dataSet"}],
                    "output": [],
                    "shape": "model-node",
                    "width": 180
                }
            ],
            "modelPointComponents": [],
            "projectId": project_id,
            "trainType": 1
        }

        url = f"{self.base_url}/prod-api/model/saveModel"
        data = {
            "projectId": project_id,
            "modelName": model_name,
            "modelDesc": model_desc,
            "modelType": 0,  # 0表示联邦学习模型
            "trainType": 1,  # 1表示训练类型
            "componentJson": json.dumps(component_json, ensure_ascii=False)
        }

        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            result = response.json()

            if result.get('code') == 0:
                model_id = result.get('result')
                print(f"✅ 模型创建成功! Model ID: {model_id}")
                return model_id
            else:
                print(f"❌ 模型创建失败: {result.get('msg')}")
                return None

        except Exception as e:
            print(f"❌ 模型创建异常: {str(e)}")
            return None

    def run_model_task(self, model_id):
        """运行模型训练任务"""
        print(f"\n▶️  启动模型训练任务: Model ID {model_id}")

        url = f"{self.base_url}/prod-api/model/runModel"
        data = {
            "modelId": model_id
        }

        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            result = response.json()

            if result.get('code') == 0:
                task_id = result.get('result')
                print(f"✅ 任务启动成功! Task ID: {task_id}")
                return task_id
            else:
                print(f"❌ 任务启动失败: {result.get('msg')}")
                return None

        except Exception as e:
            print(f"❌ 任务启动异常: {str(e)}")
            return None

    def get_task_status(self, task_id):
        """获取任务状态"""
        url = f"{self.base_url}/prod-api/task/getTaskDetail"
        params = {"taskId": task_id}

        try:
            response = self.session.get(url, params=params)
            response.raise_for_status()
            result = response.json()

            if result.get('code') == 0:
                task_info = result.get('result', {})
                return task_info
            else:
                return None

        except Exception as e:
            print(f"❌ 获取任务状态异常: {str(e)}")
            return None

    def monitor_task(self, task_id, timeout=300, interval=5):
        """监控任务执行状态"""
        print(f"\n👀 监控任务执行状态 (Task ID: {task_id})")
        print(f"   超时时间: {timeout}秒, 检查间隔: {interval}秒")

        start_time = time.time()

        while True:
            elapsed = time.time() - start_time

            if elapsed > timeout:
                print(f"\n⏰ 任务监控超时 ({timeout}秒)")
                return False

            task_info = self.get_task_status(task_id)

            if task_info:
                task_state = task_info.get('taskState', 0)
                task_state_name = {
                    0: "未运行",
                    1: "运行中",
                    2: "已完成",
                    3: "失败"
                }.get(task_state, "未知")

                print(f"   [{int(elapsed)}s] 任务状态: {task_state_name}")

                if task_state == 2:
                    print(f"\n✅ 任务执行成功!")
                    return True
                elif task_state == 3:
                    print(f"\n❌ 任务执行失败!")
                    return False

            time.sleep(interval)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='PrimiHub XGBoost 联邦学习 API 测试')
    parser.add_argument('--url', default='http://localhost:30811',
                        help='服务地址，支持 localhost/LAN/Tailscale IP (默认: http://localhost:30811)')
    parser.add_argument('--user', default='admin', help='用户名 (默认: admin)')
    parser.add_argument('--password', default='123456', help='密码 (默认: 123456)')
    parser.add_argument('--proxy', default=None,
                        help='HTTP 代理，如 http://127.0.0.1:17900')
    parser.add_argument('--no-proxy', action='store_true', default=False,
                        help='强制直连，忽略系统代理（适合直连 LAN/Tailscale）')
    args = parser.parse_args()

    print("=" * 70)
    print("  PrimiHub XGBoost 联邦学习 API 测试")
    print("=" * 70)

    # 创建API客户端
    client = PrimiHubAPIClient(
        base_url=args.url,
        username=args.user,
        password=args.password,
        proxy=args.proxy,
        no_proxy=args.no_proxy,
    )

    # 1. 登录
    if not client.login():
        print("\n❌ 登录失败，退出测试")
        sys.exit(1)

    # 2. 获取项目列表
    projects = client.get_projects()
    if not projects:
        print("\n⚠️  没有找到项目，请先在Web界面创建项目")
        sys.exit(1)

    # 使用第一个项目
    project_id = projects[0].get('projectId')
    project_name = projects[0].get('projectName')
    print(f"\n📌 使用项目: {project_name} (ID: {project_id})")

    # 3. 获取数据资源
    resources = client.get_resources()
    if not resources:
        print("\n⚠️  没有找到数据资源，请先在Web界面上传数据")

    # 4. 创建XGBoost模型
    model_id = client.create_xgboost_model(
        project_id=project_id,
        max_depth=3,
        n_trees=10
    )

    if not model_id:
        print("\n❌ 模型创建失败，退出测试")
        sys.exit(1)

    # 5. 运行模型训练任务
    task_id = client.run_model_task(model_id)

    if not task_id:
        print("\n❌ 任务启动失败，退出测试")
        sys.exit(1)

    # 6. 监控任务执行
    success = client.monitor_task(task_id, timeout=300, interval=5)

    # 7. 输出结果
    print("\n" + "=" * 70)
    if success:
        print("  ✅ XGBoost 联邦学习任务执行成功!")
    else:
        print("  ❌ XGBoost 联邦学习任务执行失败!")
    print("=" * 70)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
