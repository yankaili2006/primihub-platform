#!/usr/bin/env python3
"""
联邦学习完整测试 - 使用真实数据
"""
import requests
import json
import time
import csv
import os
from datetime import datetime

BASE_URL = "http://172.20.0.6:8080"
PROJECT_ID = 3  # 项目database ID
PROJECT_UUID = "16e44754-1b06-4db9-9399-d4c26e3195c5"  # 项目UUID

def login():
    """登录系统"""
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.post(f"{BASE_URL}/sys/user/login", data=data)
    result = response.json()
    if result.get('code') == 0:
        user_data = result['result']
        return user_data.get('token'), user_data.get('sysUser', {}).get('userId')
    return None, None

def create_training_data_files():
    """创建训练数据CSV文件"""
    print("\n" + "="*80)
    print("【步骤 1】创建训练数据文件")
    print("="*80)

    # 机构1的训练数据
    data1 = []
    for i in range(50):
        data1.append({
            'feature1': i * 0.1,
            'feature2': i * 0.2 + 1,
            'feature3': i * 0.15 - 2,
            'feature4': i * 0.05 + 0.5,
            'label': 1 if i % 2 == 0 else 0
        })

    # 机构2的训练数据
    data2 = []
    for i in range(50):
        data2.append({
            'feature1': i * 0.12 + 0.5,
            'feature2': i * 0.18,
            'feature3': i * 0.13 - 1,
            'feature4': i * 0.06 + 1,
            'label': 1 if i % 3 == 0 else 0
        })

    # 保存到临时文件
    file1 = '/tmp/fl_train_org1.csv'
    file2 = '/tmp/fl_train_org2.csv'

    with open(file1, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['feature1', 'feature2', 'feature3', 'feature4', 'label'])
        writer.writeheader()
        writer.writerows(data1)

    with open(file2, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['feature1', 'feature2', 'feature3', 'feature4', 'label'])
        writer.writeheader()
        writer.writerows(data2)

    print(f"✅ 创建训练数据文件:")
    print(f"   机构1: {file1} (50行 × 5列)")
    print(f"   机构2: {file2} (50行 × 5列)")

    return file1, file2

def upload_file_via_api(token, file_path, resource_name):
    """通过API上传文件并创建资源"""
    files = {
        'file': open(file_path, 'rb')
    }
    data = {
        'token': token,
        'timestamp': int(time.time() * 1000),
        'nonce': 123,
        'resourceName': resource_name,
        'resourceDesc': f'自动上传的训练数据 - {datetime.now().strftime("%Y%m%d_%H%M%S")}',
        'resourceAuthType': '0',  # 公开
        'fileContainsY': '1',  # 包含标签
        'yRows': 'label',  # 标签列
        'yRowsIndex': '4'  # 标签列索引
    }

    response = requests.post(
        f"{BASE_URL}/data/resource/saveDataResource",
        files=files,
        data=data
    )

    return response.json()

def upload_training_data(token):
    """上传训练数据"""
    print("\n" + "="*80)
    print("【步骤 2】上传训练数据到平台")
    print("="*80)

    file1, file2 = create_training_data_files()

    # 上传机构1数据
    print("\n📤 上传机构1数据...")
    result1 = upload_file_via_api(token, file1, "联邦学习训练数据_机构1_API上传")

    if result1.get('code') == 0:
        resource_id_1 = result1['result']['resourceId']
        fusion_id_1 = result1['result'].get('resourceFusionId')
        print(f"✅ 机构1数据上传成功")
        print(f"   资源ID: {resource_id_1}")
        print(f"   Fusion ID: {fusion_id_1}")
    else:
        print(f"❌ 机构1数据上传失败: {result1.get('msg')}")
        return None, None

    time.sleep(2)

    # 上传机构2数据
    print("\n📤 上传机构2数据...")
    result2 = upload_file_via_api(token, file2, "联邦学习训练数据_机构2_API上传")

    if result2.get('code') == 0:
        resource_id_2 = result2['result']['resourceId']
        fusion_id_2 = result2['result'].get('resourceFusionId')
        print(f"✅ 机构2数据上传成功")
        print(f"   资源ID: {resource_id_2}")
        print(f"   Fusion ID: {fusion_id_2}")
    else:
        print(f"❌ 机构2数据上传失败: {result2.get('msg')}")
        return resource_id_1, None

    # 等待文件注册到节点
    print("\n⏳ 等待数据文件注册到训练节点...")
    time.sleep(5)

    return (resource_id_1, fusion_id_1), (resource_id_2, fusion_id_2)

def create_and_run_model(token, user_id, resource1, resource2):
    """创建并运行联邦学习模型"""
    resource_id_1, fusion_id_1 = resource1
    resource_id_2, fusion_id_2 = resource2

    print("\n" + "="*80)
    print("【步骤 3】创建横向联邦逻辑回归模型")
    print("="*80)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    model_data = {
        "modelName": f"联邦LR模型_真实数据_{timestamp}",
        "modelDesc": "使用真实上传数据的横向联邦逻辑回归模型",
        "param": {
            "projectId": PROJECT_ID,
            "trainType": 1,  # 横向联邦
            "modelComponents": [
                {
                    "componentCode": "start",
                    "componentValues": [
                        {"key": "taskName", "val": f"联邦LR训练_真实数据_{timestamp}"}
                    ]
                },
                {
                    "componentCode": "dataSet",
                    "componentValues": [
                        {
                            "key": "selectData",
                            "val": json.dumps([
                                {
                                    "resourceId": str(resource_id_1),
                                    "resourceName": "联邦学习训练数据_机构1_API上传",
                                    "identity": 1,
                                    "organName": "API测试机构",
                                    "organIdentity": "000000000000000000000000test0001",
                                    "resourceColumnList": [
                                        {"key": "0", "val": "feature1"},
                                        {"key": "1", "val": "feature2"},
                                        {"key": "2", "val": "feature3"},
                                        {"key": "3", "val": "feature4"},
                                        {"key": "4", "val": "label"}
                                    ],
                                    "resourceYColumnsList": ["label"],
                                    "resourceYColumnsDataType": ["int"],
                                    "resourceYDataType": 1,
                                    "resourceYRows": "label",
                                    "resourceYRowsIndex": 4
                                },
                                {
                                    "resourceId": str(resource_id_2),
                                    "resourceName": "联邦学习训练数据_机构2_API上传",
                                    "identity": 2,
                                    "organName": "PSI协作机构",
                                    "organIdentity": "000000000000000000000000test0002",
                                    "resourceColumnList": [
                                        {"key": "0", "val": "feature1"},
                                        {"key": "1", "val": "feature2"},
                                        {"key": "2", "val": "feature3"},
                                        {"key": "3", "val": "feature4"},
                                        {"key": "4", "val": "label"}
                                    ],
                                    "resourceYColumnsList": ["label"],
                                    "resourceYColumnsDataType": ["int"],
                                    "resourceYDataType": 1,
                                    "resourceYRows": "label",
                                    "resourceYRowsIndex": 4
                                }
                            ], ensure_ascii=False)
                        }
                    ]
                },
                {
                    "componentCode": "model",
                    "componentValues": [
                        {"key": "modelType", "val": "3"},  # 横向LR
                        {"key": "learningRate", "val": "0.1"},
                        {"key": "alpha", "val": "0.0001"},
                        {"key": "encryption", "val": "Plaintext"},
                        {"key": "globalEpoch", "val": "10"},
                        {"key": "localEpoch", "val": "1"},
                        {"key": "batchSize", "val": "32"}
                    ]
                }
            ]
        }
    }

    headers = {
        'Content-Type': 'application/json',
        'userId': str(user_id)
    }

    params = {
        'token': token,
        'timestamp': int(time.time() * 1000),
        'nonce': 123
    }

    response = requests.post(
        f"{BASE_URL}/data/model/saveModelTask",
        json=model_data,
        headers=headers,
        params=params
    )

    result = response.json()

    if result.get('code') == 0:
        model_id = result['result']['modelId']
        task_id = result['result']['taskId']
        print(f"✅ 模型创建成功")
        print(f"   模型ID: {model_id}")
        print(f"   任务ID: {task_id}")
        print(f"   模型类型: 横向联邦逻辑回归")
        print(f"   训练参数:")
        print(f"     - Learning Rate: 0.1")
        print(f"     - Batch Size: 32")
        print(f"     - Global Epoch: 10")
        print(f"     - Encryption: Plaintext")
        return model_id, task_id
    else:
        print(f"❌ 模型创建失败: {result.get('msg')}")
        print(f"详细信息: {json.dumps(result, indent=2, ensure_ascii=False)}")
        return None, None

def monitor_task(token, task_id, timeout=120):
    """监控任务状态"""
    print("\n" + "="*80)
    print("【步骤 4】监控训练任务状态")
    print("="*80)

    start_time = time.time()
    check_count = 0

    while True:
        check_count += 1
        elapsed = time.time() - start_time

        if elapsed > timeout:
            print(f"\n⏰ 监控超时 ({timeout}秒)")
            print(f"   任务可能仍在运行，请稍后通过Web界面查看")
            return False

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

            print(f"\n📊 任务状态更新 (检查 #{check_count})")
            print(f"   状态: {status_text}")
            print(f"   时间: {datetime.now().strftime('%H:%M:%S')}")

            if task.get('taskErrorMsg'):
                print(f"   错误: {task.get('taskErrorMsg')}")

            if status == 3:  # 成功
                print(f"\n🎉 训练任务完成！")
                print(f"   开始时间: {task.get('taskStartDate')}")
                print(f"   结束时间: {task.get('taskEndDate')}")
                print(f"   耗时: {task.get('timeConsuming')}ms")
                return True
            elif status == 4:  # 失败
                print(f"\n❌ 训练任务失败")
                print(f"   错误信息: {task.get('taskErrorMsg')}")
                return False

        time.sleep(3)

def main():
    print("\n" + "#"*80)
    print("#" + " "*28 + "联邦学习完整测试 - 真实数据" + " "*28 + "#")
    print("#"*80)

    print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # 登录
    print("\n" + "="*80)
    print("【步骤 0】用户登录")
    print("="*80)
    token, user_id = login()
    if not token:
        print("❌ 登录失败")
        return
    print(f"✅ 登录成功 - 用户ID: {user_id}")

    # 上传训练数据
    result = upload_training_data(token)
    if not result or not result[0] or not result[1]:
        print("\n❌ 数据上传失败，测试终止")
        return

    resource1, resource2 = result

    # 创建并运行模型
    model_id, task_id = create_and_run_model(token, user_id, resource1, resource2)
    if not task_id:
        print("\n❌ 模型创建失败，测试终止")
        return

    # 监控任务
    success = monitor_task(token, task_id)

    # 总结
    print("\n" + "="*80)
    if success:
        print("🎉 联邦学习训练成功完成！")
        print("="*80)
        print(f"   任务ID: {task_id}")
        print(f"   模型ID: {model_id}")
        print(f"   项目ID: {PROJECT_ID}")
        print(f"\n💡 您可以通过以下方式查看结果:")
        print(f"   - Web界面: http://192.168.99.5:30811")
        print(f"   - API: GET /data/task/getTaskData?taskId={task_id}")
    else:
        print("⚠️  训练流程已启动，但未确认完成状态")
        print("="*80)
        print(f"   请稍后通过Web界面查看训练结果")

    print("\n" + "="*80)
    print(f"结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)

if __name__ == "__main__":
    main()
