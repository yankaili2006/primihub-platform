#!/usr/bin/env python3
"""
PrimiHub 任务创建和执行工具
用于通过 API 创建和执行联邦学习任务
"""

import requests
import json
import sys
import argparse
import time
from typing import Dict, Any, Optional

class PrimiHubTaskManager:
    """PrimiHub 任务管理器"""

    def __init__(self, base_url: str, token: str = None, user_id: str = None):
        """
        初始化任务管理器

        Args:
            base_url: API 基础URL，例如 http://100.64.0.23:30811/prod-api
            token: 认证 token
            user_id: 用户 ID
        """
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.user_id = user_id
        self.session = requests.Session()

        # 设置默认请求头
        if token:
            self.session.headers.update({'token': token})
        if user_id:
            self.session.headers.update({'userId': user_id})

    def _make_request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        """
        发送 HTTP 请求

        Args:
            method: HTTP 方法 (GET, POST)
            endpoint: API 端点
            **kwargs: 其他请求参数

        Returns:
            响应 JSON 数据
        """
        url = f"{self.base_url}{endpoint}"

        # 添加时间戳和随机数
        import random
        timestamp = int(time.time() * 1000)
        nonce = random.randint(1, 1000)

        if method.upper() == 'GET':
            params = kwargs.get('params', {})
            params.update({
                'timestamp': timestamp,
                'nonce': nonce,
                'token': self.token or ''
            })
            kwargs['params'] = params
        elif method.upper() == 'POST':
            if kwargs.get('json'):
                data = kwargs.get('json', {})
                data.update({
                    'timestamp': timestamp,
                    'nonce': nonce,
                    'token': self.token or ''
                })
                kwargs['json'] = data

        try:
            response = self.session.request(method, url, **kwargs)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ 请求失败: {e}", file=sys.stderr)
            sys.exit(1)

    def get_project_detail(self, project_id: int) -> Dict[str, Any]:
        """
        获取项目详情

        Args:
            project_id: 项目 ID

        Returns:
            项目详情数据
        """
        print(f"📋 获取项目详情 (ID: {project_id})...")
        result = self._make_request('GET', '/data/project/getProjectDetails',
                                    params={'projectId': project_id})

        if result.get('code') == 0:
            print(f"✓ 项目名称: {result['result'].get('projectName', 'N/A')}")
            return result['result']
        else:
            print(f"❌ 获取项目详情失败: {result.get('msg', '未知错误')}", file=sys.stderr)
            sys.exit(1)

    def get_model_components(self, project_id: int) -> list:
        """
        获取可用的模型组件列表

        Args:
            project_id: 项目 ID

        Returns:
            组件列表
        """
        print(f"🔧 获取模型组件列表...")
        result = self._make_request('GET', '/data/model/getModelComponent',
                                    params={'projectId': project_id})

        if result.get('code') == 0:
            components = result.get('result', [])
            print(f"✓ 找到 {len(components)} 个可用组件")
            return components
        else:
            print(f"❌ 获取组件列表失败: {result.get('msg', '未知错误')}", file=sys.stderr)
            return []

    def save_model_and_component(self, project_id: int, model_data: Dict[str, Any]) -> Optional[str]:
        """
        保存模型和组件配置

        Args:
            project_id: 项目 ID
            model_data: 模型配置数据

        Returns:
            模型 ID
        """
        print(f"💾 保存任务配置...")

        payload = {
            'param': {
                'projectId': project_id,
                'modelId': model_data.get('modelId', ''),
                'isDraft': 1,  # 1 表示正式保存，0 表示草稿
                'modelComponents': model_data.get('modelComponents', []),
                'modelPointComponents': model_data.get('modelPointComponents', [])
            }
        }

        result = self._make_request('POST', '/data/model/saveModelAndComponent',
                                    json=payload,
                                    headers={'Content-Type': 'application/json'})

        if result.get('code') == 0:
            model_id = result['result'].get('modelId')
            print(f"✓ 任务配置已保存 (Model ID: {model_id})")
            return model_id
        else:
            print(f"❌ 保存任务配置失败: {result.get('msg', '未知错误')}", file=sys.stderr)
            return None

    def run_task(self, model_id: str) -> Optional[str]:
        """
        执行任务

        Args:
            model_id: 模型 ID

        Returns:
            任务 ID
        """
        print(f"▶️  执行任务 (Model ID: {model_id})...")

        result = self._make_request('GET', '/data/model/runTaskModel',
                                    params={'modelId': model_id})

        if result.get('code') == 0:
            task_id = result['result'].get('taskId')
            print(f"✓ 任务已开始执行 (Task ID: {task_id})")
            return task_id
        elif result.get('code') == 1007:
            print(f"❌ 数据资源不可用: {result.get('msg', '未知错误')}", file=sys.stderr)
            return None
        else:
            print(f"❌ 执行任务失败: {result.get('msg', '未知错误')}", file=sys.stderr)
            return None

    def get_task_status(self, task_id: str) -> Dict[str, Any]:
        """
        获取任务状态

        Args:
            task_id: 任务 ID

        Returns:
            任务状态数据
        """
        result = self._make_request('GET', '/data/model/getTaskModelComponent',
                                    params={'taskId': task_id})

        if result.get('code') == 0:
            return result['result']
        else:
            print(f"❌ 获取任务状态失败: {result.get('msg', '未知错误')}", file=sys.stderr)
            return {}

    def monitor_task(self, task_id: str, interval: int = 5, max_wait: int = 300):
        """
        监控任务执行状态

        Args:
            task_id: 任务 ID
            interval: 轮询间隔（秒）
            max_wait: 最大等待时间（秒）
        """
        print(f"⏳ 监控任务执行状态...")

        start_time = time.time()
        status_map = {
            0: '等待中',
            1: '运行中',
            2: '成功',
            3: '失败',
            4: '已取消'
        }

        while True:
            elapsed = time.time() - start_time
            if elapsed > max_wait:
                print(f"⚠️  超过最大等待时间 ({max_wait}秒)，停止监控")
                break

            status_data = self.get_task_status(task_id)
            task_state = status_data.get('taskState')

            if task_state is not None:
                status_text = status_map.get(task_state, f'未知状态({task_state})')
                print(f"  状态: {status_text} | 已用时: {int(elapsed)}秒")

                # 任务完成（成功、失败或取消）
                if task_state in [2, 3, 4]:
                    if task_state == 2:
                        print(f"✅ 任务执行成功！")
                    elif task_state == 3:
                        print(f"❌ 任务执行失败")
                    else:
                        print(f"⚠️  任务已取消")
                    break

            time.sleep(interval)

    def create_simple_task(self, project_id: int, task_name: str,
                          model_type: str = "1") -> Optional[str]:
        """
        创建一个简单的任务（示例）

        Args:
            project_id: 项目 ID
            task_name: 任务名称
            model_type: 模型类型 (1=PSI, 3=LR, 4=XGBoost等)

        Returns:
            任务 ID
        """
        # 这是一个简化的示例，实际使用时需要根据具体需求构建完整的模型配置
        model_data = {
            'modelComponents': [
                {
                    'componentCode': 'start',
                    'componentName': '开始',
                    'componentValues': [
                        {'key': 'taskName', 'val': task_name},
                        {'key': 'taskDesc', 'val': f'通过API创建的任务: {task_name}'}
                    ],
                    'coordinateX': 100,
                    'coordinateY': 100,
                    'width': 180,
                    'height': 40
                }
            ],
            'modelPointComponents': []
        }

        # 保存任务配置
        model_id = self.save_model_and_component(project_id, model_data)
        if not model_id:
            return None

        # 执行任务
        task_id = self.run_task(model_id)
        return task_id


def main():
    parser = argparse.ArgumentParser(
        description='PrimiHub 任务创建和执行工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例用法:
  # 创建并执行任务
  %(prog)s --base-url http://100.64.0.23:30811/prod-api \\
           --token YOUR_TOKEN \\
           --user-id YOUR_USER_ID \\
           --project-id 7 \\
           --task-name "测试任务" \\
           --run

  # 仅保存任务配置（不执行）
  %(prog)s --base-url http://100.64.0.23:30811/prod-api \\
           --token YOUR_TOKEN \\
           --project-id 7 \\
           --task-name "测试任务"

  # 执行已保存的任务
  %(prog)s --base-url http://100.64.0.23:30811/prod-api \\
           --token YOUR_TOKEN \\
           --model-id MODEL_ID \\
           --run-only

  # 监控任务状态
  %(prog)s --base-url http://100.64.0.23:30811/prod-api \\
           --token YOUR_TOKEN \\
           --task-id TASK_ID \\
           --monitor
        """
    )

    parser.add_argument('--base-url', required=True,
                       help='API 基础URL (例如: http://100.64.0.23:30811/prod-api)')
    parser.add_argument('--token', help='认证 token')
    parser.add_argument('--user-id', help='用户 ID')
    parser.add_argument('--project-id', type=int, help='项目 ID')
    parser.add_argument('--task-name', help='任务名称')
    parser.add_argument('--model-id', help='模型 ID（用于执行已保存的任务）')
    parser.add_argument('--task-id', help='任务 ID（用于监控任务状态）')
    parser.add_argument('--model-type', default='1',
                       help='模型类型 (1=PSI, 3=LR, 4=XGBoost等)')
    parser.add_argument('--run', action='store_true',
                       help='创建后立即执行任务')
    parser.add_argument('--run-only', action='store_true',
                       help='仅执行已保存的任务（需要 --model-id）')
    parser.add_argument('--monitor', action='store_true',
                       help='监控任务执行状态（需要 --task-id）')
    parser.add_argument('--config', help='从 JSON 文件加载完整的任务配置')

    args = parser.parse_args()

    # 创建任务管理器
    manager = PrimiHubTaskManager(args.base_url, args.token, args.user_id)

    # 监控任务状态
    if args.monitor:
        if not args.task_id:
            print("❌ 监控任务需要提供 --task-id", file=sys.stderr)
            sys.exit(1)
        manager.monitor_task(args.task_id)
        return

    # 仅执行已保存的任务
    if args.run_only:
        if not args.model_id:
            print("❌ 执行任务需要提供 --model-id", file=sys.stderr)
            sys.exit(1)
        task_id = manager.run_task(args.model_id)
        if task_id:
            print(f"\n✅ 任务已提交执行")
            print(f"   Task ID: {task_id}")
            print(f"\n使用以下命令监控任务状态:")
            print(f"   {sys.argv[0]} --base-url {args.base_url} --token {args.token} --task-id {task_id} --monitor")
        return

    # 创建新任务
    if not args.project_id or not args.task_name:
        print("❌ 创建任务需要提供 --project-id 和 --task-name", file=sys.stderr)
        parser.print_help()
        sys.exit(1)

    # 获取项目详情
    project = manager.get_project_detail(args.project_id)

    # 加载任务配置
    if args.config:
        print(f"📄 从文件加载任务配置: {args.config}")
        with open(args.config, 'r', encoding='utf-8') as f:
            model_data = json.load(f)
    else:
        # 使用简单的默认配置
        print(f"⚠️  使用简化的默认配置（仅用于演示）")
        print(f"   实际使用时请通过 --config 参数提供完整的任务配置")
        model_data = None

    # 创建任务
    if model_data:
        model_id = manager.save_model_and_component(args.project_id, model_data)
    else:
        task_id = manager.create_simple_task(args.project_id, args.task_name, args.model_type)
        if task_id and args.run:
            manager.monitor_task(task_id)
        return

    if not model_id:
        sys.exit(1)

    print(f"\n✅ 任务配置已保存")
    print(f"   Model ID: {model_id}")

    # 执行任务
    if args.run:
        task_id = manager.run_task(model_id)
        if task_id:
            print(f"\n✅ 任务已提交执行")
            print(f"   Task ID: {task_id}")
            manager.monitor_task(task_id)


if __name__ == '__main__':
    main()
