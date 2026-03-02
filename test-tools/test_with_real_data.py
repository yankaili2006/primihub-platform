#!/usr/bin/env python3
"""
使用真实上传数据进行端到端联邦学习测试
"""
import requests
import json
import time
from datetime import datetime

BASE_URL = "http://172.20.0.6:8080"
PROJECT_DB_ID = 3

# 使用我们上传的真实数据资源
RESOURCE_1 = {
    "resourceId": "demo0org0001-9a9a1424-d8a6-473d-b300-2f7f5538edaa",
    "resourceName": "端到端测试_机构1_训练数据",
    "resourceRowsCount": 50,
    "resourceColumnCount": 5,
    "resourceContainsY": 1,
    "organId": "000000000000000000000000test0001",
    "organName": "API测试机构",
    "participationIdentity": 1,
    "auditStatus": 1
}

RESOURCE_2 = {
    "resourceId": "demo0org0001-563831ec-aba5-458a-9611-6c365d237624",
    "resourceName": "端到端测试_机构2_训练数据",
    "resourceRowsCount": 50,
    "resourceColumnCount": 5,
    "resourceContainsY": 1,
    "organId": "000000000000000000000000test0002",
    "organName": "PSI协作机构",
    "participationIdentity": 2,
    "auditStatus": 1
}

class FederatedLearningTrainer:
    def __init__(self):
        self.base_url = BASE_URL
        self.session = requests.Session()
        self.token = None
        self.user_id = None
        self.model_id = None
        self.task_id = None
        
    def _request(self, method, endpoint, data=None, json_data=None, headers=None):
        """统一的HTTP请求方法"""
        url = f"{self.base_url}{endpoint}"
        
        req_headers = headers or {}
        if self.user_id:
            req_headers['userId'] = str(self.user_id)
        
        if data is None:
            data = {}
        
        # 添加通用参数
        data['timestamp'] = int(time.time() * 1000)
        data['nonce'] = int(time.time() * 1000) % 1000 + 1
        if self.token:
            data['token'] = self.token
        
        try:
            if method.upper() == 'GET':
                response = self.session.get(url, params=data, headers=req_headers, timeout=30)
            elif method.upper() == 'POST':
                if json_data:
                    json_data['timestamp'] = int(time.time() * 1000)
                    json_data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    if self.token:
                        json_data['token'] = self.token
                    response = self.session.post(url, json=json_data, headers=req_headers, timeout=30)
                else:
                    response = self.session.post(url, data=data, headers=req_headers, timeout=30)
            
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ 请求失败: {e}")
            if hasattr(e, 'response') and e.response is not None:
                try:
                    print(f"响应: {json.dumps(e.response.json(), indent=2, ensure_ascii=False)}")
                except:
                    print(f"响应: {e.response.text[:500]}")
            return None
    
    def login(self):
        """登录"""
        print("\n" + "="*70)
        print("【步骤 1】用户登录")
        print("="*70)
        
        result = self._request("POST", "/user/login", {
            "userAccount": "admin",
            "userPassword": "123456"
        })
        
        if result and result.get('code') == 0:
            user_data = result.get('result', {})
            self.token = user_data.get('token')
            self.user_id = user_data.get('sysUser', {}).get('userId')
            print(f"✅ 登录成功 - 用户ID: {self.user_id}")
            return True
        else:
            print(f"❌ 登录失败")
            return False
    
    def create_model(self):
        """创建联邦学习模型"""
        print("\n" + "="*70)
        print("【步骤 2】创建横向联邦逻辑回归模型 - 使用真实数据")
        print("="*70)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        model_data = {
            "param": {
                "projectId": PROJECT_DB_ID,
                "modelId": None,
                "isDraft": 1,
                "trainType": 1,  # 横向训练
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
                            {"key": "taskName", "val": f"真实数据FL训练_{timestamp}"},
                            {"key": "taskDesc", "val": "使用真实上传CSV数据的端到端联邦学习"}
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
                                "val": json.dumps([RESOURCE_1, RESOURCE_2], ensure_ascii=False)
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
                        "componentValues": [
                            {"key": "modelType", "val": "3"},  # 横向逻辑回归
                            {"key": "modelName", "val": f"真实数据FL模型_{timestamp}"},
                            {"key": "modelDesc", "val": "使用真实CSV数据的端到端联邦学习"},
                            {"key": "encryption", "val": "Plaintext"},
                            {"key": "learningRate", "val": "0.1"},
                            {"key": "alpha", "val": "0.0001"},
                            {"key": "batchSize", "val": "16"},
                            {"key": "globalEpoch", "val": "5"},
                            {"key": "localEpoch", "val": "1"}
                        ],
                        "input": [{"componentCode": "dataSet"}],
                        "output": []
                    }
                ]
            }
        }
        
        result = self._request("POST", "/data/model/saveModelAndComponent", 
                              json_data=model_data)
        
        if result and result.get('code') == 0:
            self.model_id = result.get('result', {}).get('modelId')
            print(f"✅ 模型创建成功")
            print(f"   模型ID: {self.model_id}")
            print(f"   数据资源1: {RESOURCE_1['resourceName']}")
            print(f"   数据资源2: {RESOURCE_2['resourceName']}")
            print(f"   训练参数: globalEpoch=5, batchSize=16, learningRate=0.1")
            return True
        else:
            print(f"❌ 模型创建失败")
            if result:
                print(f"   错误信息: {result.get('msg')}")
            return False
    
    def run_training(self):
        """启动训练任务"""
        print("\n" + "="*70)
        print("【步骤 3】启动联邦学习训练任务")
        print("="*70)
        
        if not self.model_id:
            print("❌ 没有可用的模型ID")
            return False
        
        result = self._request("GET", "/data/model/runTaskModel", {
            "modelId": self.model_id
        })
        
        if result and result.get('code') == 0:
            task_data = result.get('result', {})
            self.task_id = task_data.get('taskId')
            print(f"✅ 训练任务已启动")
            print(f"   任务ID: {self.task_id}")
            print(f"   状态: 正在运行...")
            return True
        else:
            print(f"❌ 启动训练失败")
            if result:
                print(f"   错误信息: {result.get('msg')}")
            else:
                print(f"   响应为空或无效")
            return False
    
    def monitor_training(self, max_wait=180):
        """监控训练任务"""
        print("\n" + "="*70)
        print("【步骤 4】监控训练任务状态")
        print("="*70)
        
        if not self.task_id:
            print("❌ 没有可用的任务ID")
            return None
        
        start_time = time.time()
        last_status = None
        check_count = 0
        
        status_map = {
            0: "初始化",
            1: "等待中",
            2: "运行中",
            3: "成功",
            4: "失败"
        }
        
        while time.time() - start_time < max_wait:
            check_count += 1
            result = self._request("GET", "/data/task/getTaskData", {
                "taskId": self.task_id
            })
            
            if result and result.get('code') == 0:
                task = result.get('result', {})
                status = task.get('taskState')
                
                if status != last_status:
                    status_text = status_map.get(status, f'未知({status})')
                    print(f"\n📊 任务状态更新 (检查 #{check_count})")
                    print(f"   状态: {status_text}")
                    print(f"   时间: {datetime.now().strftime('%H:%M:%S')}")
                    last_status = status
                else:
                    print(f"\r检查 #{check_count}: {status_map.get(status, '未知')}  ", end='', flush=True)
                
                # 状态 3 = 成功, 4 = 失败
                if status == 3:
                    print(f"\n\n🎉 训练任务完成！")
                    print(f"   开始时间: {task.get('taskStartDate')}")
                    print(f"   结束时间: {task.get('taskEndDate')}")
                    if task.get('timeConsuming'):
                        print(f"   耗时: {task.get('timeConsuming')}ms")
                    if task.get('taskErrorMsg'):
                        print(f"   备注: {task.get('taskErrorMsg')}")
                    return task
                elif status == 4:
                    print(f"\n\n❌ 训练任务失败")
                    if task.get('taskErrorMsg'):
                        print(f"   错误信息: {task.get('taskErrorMsg')}")
                    return task
            else:
                print(f"\r⚠️  获取任务状态失败 (尝试 #{check_count})  ", end='', flush=True)
            
            time.sleep(3)  # 每3秒检查一次
        
        print(f"\n\n⏰ 监控超时 ({max_wait}秒)")
        print(f"   任务可能仍在运行，请稍后通过Web界面查看")
        return None
    
    def run(self):
        """运行完整流程"""
        print("\n" + "#"*70)
        print("#" + " "*68 + "#")
        print("#" + " "*10 + "端到端联邦学习测试 - 使用真实CSV数据" + " "*15 + "#")
        print("#" + " "*68 + "#")
        print("#"*70)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # 1. 登录
        if not self.login():
            return False
        
        # 2. 创建模型
        if not self.create_model():
            return False
        
        # 3. 启动训练
        if not self.run_training():
            return False
        
        # 4. 监控训练
        result = self.monitor_training(max_wait=180)
        
        print("\n" + "="*70)
        if result and result.get('taskState') == 3:
            print("🎉 端到端联邦学习测试成功完成！")
            print("="*70)
            print(f"   任务ID: {self.task_id}")
            print(f"   模型ID: {self.model_id}")
            print(f"   项目ID: {PROJECT_DB_ID}")
            print("\n💡 您可以通过以下方式查看结果:")
            print(f"   - Web界面: http://192.168.99.5:30811")
            print(f"   - API: GET /data/task/getTaskData?taskId={self.task_id}")
            return True
        else:
            print("⚠️  训练流程已启动，但未确认完成状态")
            print("="*70)
            print("   请稍后通过Web界面查看训练结果")
            return False


if __name__ == "__main__":
    trainer = FederatedLearningTrainer()
    success = trainer.run()
    
    print("\n" + "="*70)
    print(f"结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*70)
