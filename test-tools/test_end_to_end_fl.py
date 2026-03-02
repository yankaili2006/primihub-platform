#!/usr/bin/env python3
"""
使用真实上传数据的端到端联邦学习测试
资源ID: 7 (机构1), 8 (机构2)
"""
import requests
import json
import time
from datetime import datetime

BASE_URL = "http://172.20.0.6:8080"
PROJECT_DB_ID = 3
RESOURCE_ID_1 = 7
RESOURCE_ID_2 = 8

def login():
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.post(f"{BASE_URL}/user/login", data=data)
    result = response.json()
    if result.get('code') == 0:
        user_data = result['result']
        return user_data.get('token'), user_data.get('sysUser', {}).get('userId')
    return None, None

def create_and_run_training(token, user_id):
    print("\n" + "="*80)
    print("【创建横向联邦逻辑回归模型】")
    print("="*80)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    model_data = {
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "param": {
            "projectId": PROJECT_DB_ID,
            "modelId": None,
            "isDraft": 1,
            "trainType": 1,
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
                        {"key": "taskName", "val": f"端到端FL任务_{timestamp}"},
                        {"key": "taskDesc", "val": "使用真实上传数据的端到端测试"}
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
                            "val": json.dumps([
                                {
                                    "resourceId": str(RESOURCE_ID_1),
                                    "resourceName": "端到端测试_机构1_训练数据",
                                    "participationIdentity": 1,
                                    "organName": "API测试机构",
                                    "organId": "000000000000000000000000test0001",
                                    "resourceRowsCount": 50,
                                    "resourceColumnCount": 5,
                                    "resourceContainsY": 1,
                                    "auditStatus": 1
                                },
                                {
                                    "resourceId": str(RESOURCE_ID_2),
                                    "resourceName": "端到端测试_机构2_训练数据",
                                    "participationIdentity": 2,
                                    "organName": "PSI协作机构",
                                    "organId": "000000000000000000000000test0002",
                                    "resourceRowsCount": 50,
                                    "resourceColumnCount": 5,
                                    "resourceContainsY": 1,
                                    "auditStatus": 1
                                }
                            ], ensure_ascii=False)
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
                        {"key": "modelType", "val": "3"},
                        {"key": "modelName", "val": f"真实数据FL模型_{timestamp}"},
                        {"key": "modelDesc", "val": "使用真实上传数据的端到端测试"},
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

    headers = {
        'Content-Type': 'application/json',
        'userId': str(user_id)
    }

    # Step 1: Create model
    response = requests.post(
        f"{BASE_URL}/data/model/saveModelAndComponent",
        json=model_data,
        headers=headers
    )

    result = response.json()

    if result.get('code') == 0:
        model_id = result['result']['modelId']
        print(f"\n✅ 模型创建成功")
        print(f"   模型ID: {model_id}")

        # Step 2: Run training
        print(f"\n【启动训练任务】")
        run_params = {
            'token': token,
            'timestamp': int(time.time() * 1000),
            'nonce': 123,
            'modelId': model_id
        }

        run_response = requests.get(
            f"{BASE_URL}/data/model/runTaskModel",
            params=run_params,
            headers=headers
        )

        print(f"   响应状态码: {run_response.status_code}")
        print(f"   响应内容: {run_response.text[:200]}")

        if run_response.status_code != 200:
            print(f"❌ HTTP错误: {run_response.status_code}")
            return model_id, None

        try:
            run_result = run_response.json()
        except:
            print(f"❌ 无法解析JSON响应")
            print(f"   原始响应: {run_response.text}")
            return model_id, None

        if run_result.get('code') == 0:
            task_id = run_result['result']['taskId']
            print(f"✅ 训练任务已启动")
            print(f"   任务ID: {task_id}")
            return model_id, task_id
        else:
            print(f"❌ 启动训练失败")
            print(f"   错误: {run_result.get('msg')}")
            return model_id, None
    else:
        print(f"\n❌ 模型创建失败")
        print(f"   错误: {result.get('msg')}")
        print(f"   详细: {json.dumps(result, indent=2, ensure_ascii=False)[:1000]}")
        return None, None

def monitor_task(token, task_id):
    print("\n" + "="*80)
    print("【监控训练任务】")
    print("="*80)

    for i in range(40):  # 最多检查40次（2分钟）
        time.sleep(3)

        params = {
            'taskId': task_id,
            'token': token,
            'timestamp': int(time.time() * 1000),
            'nonce': 123
        }

        response = requests.get(f"{BASE_URL}/data/task/getTaskData", params=params)
        result = response.json()

        if result.get('code') == 0:
            task = result['result']
            status = task.get('taskState')
            status_map = {0: "初始化", 1: "等待中", 2: "运行中", 3: "成功", 4: "失败"}
            status_text = status_map.get(status, "未知")

            print(f"\r检查 #{i+1}: {status_text}  ", end='', flush=True)

            if status == 3:
                print(f"\n\n🎉 训练成功完成！")
                print(f"   开始: {task.get('taskStartDate')}")
                print(f"   结束: {task.get('taskEndDate')}")
                print(f"   耗时: {task.get('timeConsuming')}ms")
                if task.get('taskErrorMsg'):
                    print(f"   备注: {task.get('taskErrorMsg')}")
                return True
            elif status == 4:
                print(f"\n\n❌ 训练失败")
                print(f"   错误: {task.get('taskErrorMsg')}")
                return False

    print(f"\n\n⏰ 监控超时")
    return False

def main():
    print("\n" + "#"*80)
    print("#" + " "*24 + "端到端联邦学习测试 - 真实数据" + " "*24 + "#")
    print("#"*80)

    print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"使用资源: ID {RESOURCE_ID_1} (机构1), ID {RESOURCE_ID_2} (机构2)")

    # Login
    print("\n" + "="*80)
    print("【登录系统】")
    print("="*80)
    token, user_id = login()
    if not token:
        print("❌ 登录失败")
        return
    print(f"✅ 登录成功 - 用户ID: {user_id}")

    # Create and run
    model_id, task_id = create_and_run_training(token, user_id)
    if not task_id:
        return

    # Monitor
    success = monitor_task(token, task_id)

    # Summary
    print("\n" + "="*80)
    if success:
        print("✅ 端到端测试成功！")
    else:
        print("⚠️  端到端测试未完全成功")
    print("="*80)
    print(f"结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"\n查看详情: python3 ./view_results_fixed.py")

if __name__ == "__main__":
    main()
