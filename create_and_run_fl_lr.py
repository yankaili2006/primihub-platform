#!/usr/bin/env python3
"""
完全自动化的联邦学习LR模型创建和运行脚本
基于源代码分析实现的完整自动化方案
"""

import requests
import json
import time
from datetime import datetime

# 配置
BASE_URL = "http://172.20.0.12:8080"
ADMIN_USER = "admin"
ADMIN_PASSWORD = "123456"
PROJECT_ID = 3  # 联邦LR项目的数据库ID


class AutomatedFederatedLR:
    def __init__(self):
        self.base_url = BASE_URL
        self.session = requests.Session()
        self.token = None
        self.user_id = None
        self.model_id = None

    def _make_request(self, method, endpoint, data=None, use_json=False,
                     extra_headers=None, files=None):
        """发送HTTP请求"""
        url = f"{self.base_url}{endpoint}"

        if data is None:
            data = {}

        headers = {}
        if extra_headers:
            headers.update(extra_headers)

        try:
            if method.upper() == 'GET':
                params = dict(data)
                if self.token:
                    params['token'] = self.token
                params['timestamp'] = int(time.time() * 1000)
                params['nonce'] = int(time.time() * 1000) % 1000 + 1
                response = self.session.get(url, params=params, headers=headers, timeout=30)
            elif method.upper() == 'POST':
                if files:
                    response = self.session.post(url, data=data, files=files,
                                                headers=headers, timeout=60)
                elif use_json:
                    data['timestamp'] = int(time.time() * 1000)
                    data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    if self.token:
                        data['token'] = self.token
                    response = self.session.post(url, json=data,
                                                headers=headers, timeout=30)
                else:
                    data['timestamp'] = int(time.time() * 1000)
                    data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    if self.token:
                        data['token'] = self.token
                    response = self.session.post(url, data=data, headers=headers, timeout=30)

            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"请求失败: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"响应内容: {e.response.text[:500]}")
            return None

    def login(self):
        """登录"""
        print("\n" + "="*70)
        print("▶ 步骤 1: 用户登录")
        print("="*70)

        data = {
            "userAccount": ADMIN_USER,
            "userPassword": ADMIN_PASSWORD
        }

        result = self._make_request("POST", "/sys/user/login", data)

        if result and result.get('code') == 0:
            user_data = result.get('result', {})
            self.token = user_data.get('token')
            self.user_id = user_data.get('sysUser', {}).get('userId')
            user_name = user_data.get('sysUser', {}).get('userName')
            print(f"✅ 登录成功")
            print(f"   用户: {user_name}, ID: {self.user_id}")
            return True
        else:
            print(f"❌ 登录失败: {result}")
            return False

    def create_fl_lr_model(self):
        """创建完整的联邦学习LR模型配置"""
        print("\n" + "="*70)
        print("▶ 步骤 2: 创建联邦学习LR模型")
        print("="*70)

        # 构建模型组件配置
        model_components = [
            # 1. 开始组件
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
                    {"key": "taskName", "val": f"联邦LR训练_{datetime.now().strftime('%Y%m%d_%H%M%S')}"},
                    {"key": "taskDesc", "val": "自动化创建的横向联邦逻辑回归训练任务"}
                ],
                "input": [],
                "output": [{"componentCode": "dataSet"}]
            },
            # 2. 数据集组件
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
                    # 指定数据资源 - 正确的JSON格式
                    {"key": "selectData", "val": json.dumps([
                        {
                            "resourceId": "demo0org0001-de7f2cb1-ef24-11f0-bac8-463ab87cfb66",
                            "resourceName": "联邦LR训练数据_机构1_AUTO",
                            "resourceRowsCount": 50,
                            "resourceColumnCount": 5,
                            "resourceContainsY": 1,
                            "organId": "000000000000000000000000test0001",
                            "organName": "API测试机构",
                            "participationIdentity": 1,
                            "auditStatus": 1
                        },
                        {
                            "resourceId": "demo0org0001-e4fdfcf0-ef24-11f0-bac8-463ab87cfb66",
                            "resourceName": "联邦LR训练数据_机构2_AUTO",
                            "resourceRowsCount": 50,
                            "resourceColumnCount": 5,
                            "resourceContainsY": 1,
                            "organId": "000000000000000000000000test0002",
                            "organName": "PSI协作机构",
                            "participationIdentity": 2,
                            "auditStatus": 1
                        }
                    ], ensure_ascii=False)}
                ],
                "input": [{"componentCode": "start"}],
                "output": [{"componentCode": "model"}]
            },
            # 3. 模型组件 - 横向逻辑回归
            {
                "componentCode": "model",
                "componentName": "模型选择",
                "frontComponentId": "model_1",
                "coordinateX": 100,
                "coordinateY": 250,
                "width": 180,
                "height": 40,
                "shape": "model-node",
                "componentValues": [
                    {"key": "modelType", "val": "3"},  # 3 = 横向-逻辑回归
                    {"key": "modelName", "val": f"联邦LR模型_{datetime.now().strftime('%Y%m%d_%H%M%S')}"},
                    {"key": "modelDesc", "val": "横向联邦逻辑回归模型 - 自动创建"},
                    {"key": "encryption", "val": "Plaintext"},  # 明文训练
                    {"key": "learningRate", "val": "0.1"},
                    {"key": "alpha", "val": "0.0001"},
                    {"key": "batchSize", "val": "32"},
                    {"key": "globalEpoch", "val": "10"},
                    {"key": "localEpoch", "val": "1"}
                ],
                "input": [{"componentCode": "dataSet"}],
                "output": []
            }
        ]

        # 构建完整的模型请求
        model_request = {
            "param": {
                "projectId": PROJECT_ID,
                "modelId": None,
                "isDraft": 1,  # 非草稿，直接保存
                "trainType": 1,  # 横向训练
                "modelComponents": model_components,
                "modelPointComponents": []  # 前端拖拽组件的位置信息，API创建时可为空
            }
        }

        headers = {"userId": str(self.user_id)} if self.user_id else {}

        print("正在创建模型配置...")
        result = self._make_request("POST", "/data/model/saveModelAndComponent",
                                   model_request, use_json=True, extra_headers=headers)

        if result and result.get('code') == 0:
            self.model_id = result.get('result', {}).get('modelId')
            print(f"✅ 模型创建成功")
            print(f"   模型ID: {self.model_id}")
            print(f"   模型类型: 横向联邦逻辑回归")
            print(f"   训练参数:")
            print(f"     - Learning Rate: 0.1")
            print(f"     - Batch Size: 32")
            print(f"     - Global Epoch: 10")
            print(f"     - Local Epoch: 1")
            return True
        else:
            print(f"❌ 模型创建失败: {result}")
            return False

    def run_model(self):
        """运行模型训练"""
        print("\n" + "="*70)
        print("▶ 步骤 3: 运行联邦学习训练任务")
        print("="*70)

        if not self.model_id:
            print("❌ 没有可用的模型ID")
            return False

        headers = {"userId": str(self.user_id)} if self.user_id else {}

        print(f"正在启动模型训练（模型ID: {self.model_id}）...")
        result = self._make_request("GET", "/data/model/runTaskModel",
                                   {"modelId": self.model_id},
                                   extra_headers=headers)

        if result and result.get('code') == 0:
            task_data = result.get('result', {})
            task_id = task_data.get('taskId')
            print(f"✅ 训练任务已启动")
            print(f"   任务ID: {task_id}")
            print(f"   状态: 正在运行...")
            return task_id
        else:
            print(f"❌ 启动训练失败: {result}")
            return None

    def monitor_task(self, task_id, max_wait=300):
        """监控任务执行状态"""
        print("\n" + "="*70)
        print("▶ 步骤 4: 监控训练任务")
        print("="*70)

        start_time = time.time()
        last_status = None

        while time.time() - start_time < max_wait:
            result = self._make_request("GET", "/data/task/getTaskData",
                                       {"taskId": task_id})

            if result and result.get('code') == 0:
                task = result.get('result', {})
                status = task.get('taskState')

                if status != last_status:
                    status_map = {
                        1: "等待中",
                        2: "运行中",
                        3: "成功",
                        4: "失败"
                    }
                    print(f"\n任务状态: {status_map.get(status, '未知')} ({status})")
                    last_status = status

                # 状态 3 = 成功, 4 = 失败
                if status == 3:
                    print(f"\n✅ 训练任务完成！")
                    print(f"   开始时间: {task.get('taskStartDate')}")
                    print(f"   结束时间: {task.get('taskEndDate')}")
                    print(f"   耗时: {task.get('timeConsuming')}ms")
                    return task
                elif status == 4:
                    print(f"\n❌ 训练任务失败")
                    print(f"   错误信息: {task.get('taskErrorMsg')}")
                    return task

            time.sleep(5)  # 每5秒检查一次

        print(f"\n⚠️  超时：任务在{max_wait}秒内未完成")
        return None

    def get_task_results(self, task_id):
        """获取训练结果"""
        print("\n" + "="*70)
        print("▶ 步骤 5: 获取训练结果")
        print("="*70)

        headers = {"userId": str(self.user_id)} if self.user_id else {}

        # 获取任务组件详情
        result = self._make_request("GET", "/data/model/getTaskModelComponent",
                                   {"taskId": task_id},
                                   extra_headers=headers)

        if result and result.get('code') == 0:
            components = result.get('result', {})
            print("✅ 训练结果获取成功")
            print(f"\n模型组件详情:")
            print(json.dumps(components, indent=2, ensure_ascii=False))
            return components
        else:
            print(f"❌ 获取结果失败: {result}")
            return None


def main():
    print("\n" + "="*70)
    print("完全自动化联邦学习LR训练流程".center(70))
    print("="*70)
    print("\n基于源代码深度分析的完整自动化实现")
    print("无需Web界面，纯API完成所有操作\n")

    runner = AutomatedFederatedLR()

    # 1. 登录
    if not runner.login():
        return

    # 2. 创建模型
    if not runner.create_fl_lr_model():
        return

    # 3. 运行模型
    task_id = runner.run_model()
    if not task_id:
        return

    # 4. 监控任务
    task_result = runner.monitor_task(task_id)

    # 5. 获取结果
    if task_result and task_result.get('taskState') == 3:
        runner.get_task_results(task_id)

    print("\n" + "="*70)
    print("流程执行完成".center(70))
    print("="*70)


if __name__ == "__main__":
    main()
