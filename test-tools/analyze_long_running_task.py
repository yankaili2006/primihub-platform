#!/usr/bin/env python3
"""
分析联邦学习任务运行时间过长的原因
"""
import requests
import json
import time
from datetime import datetime

BASE_URL = "http://172.20.0.6:8080"

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
        return user_data.get('token')
    return None

def check_all_tasks(token):
    """检查所有任务状态"""
    params = {
        'pageNo': 1,
        'pageSize': 20,
        'token': token,
        'timestamp': int(time.time() * 1000),
        'nonce': 123
    }
    response = requests.get(f"{BASE_URL}/data/task/getTaskList", params=params)
    return response.json()

def check_task_detail(token, task_id):
    """检查特定任务详情"""
    params = {
        'taskId': task_id,
        'token': token,
        'timestamp': int(time.time() * 1000),
        'nonce': 123
    }
    response = requests.get(f"{BASE_URL}/data/task/getTaskData", params=params)
    return response.json()

print("\n" + "="*100)
print(" "*30 + "任务运行时间过长原因分析")
print("="*100)

token = login()
if not token:
    print("❌ 登录失败")
    exit(1)

print(f"\n✅ 已连接到系统")
print(f"分析时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

# 1. 检查所有任务
print("="*100)
print("【1】检查系统中所有任务状态")
print("="*100)

all_tasks_result = check_all_tasks(token)
if all_tasks_result.get('code') == 0:
    tasks = all_tasks_result.get('result', {}).get('data', [])
    
    status_map = {0: "初始化", 1: "等待中", 2: "运行中", 3: "成功", 4: "失败"}
    
    running_tasks = []
    completed_tasks = []
    failed_tasks = []
    
    for task in tasks:
        status = task.get('taskState', 0)
        if status == 2:
            running_tasks.append(task)
        elif status == 3:
            completed_tasks.append(task)
        elif status == 4:
            failed_tasks.append(task)
    
    print(f"\n📊 任务统计:")
    print(f"   总任务数: {len(tasks)}")
    print(f"   ✅ 已完成: {len(completed_tasks)}")
    print(f"   ⏳ 运行中: {len(running_tasks)}")
    print(f"   ❌ 失败: {len(failed_tasks)}")
    
    if len(running_tasks) > 0:
        print(f"\n⚠️  发现 {len(running_tasks)} 个运行中的任务:\n")
        for idx, task in enumerate(running_tasks, 1):
            print(f"{idx}. 任务ID: {task.get('taskId')}")
            print(f"   名称: {task.get('taskName')}")
            print(f"   开始时间: {task.get('taskStartDate')}")
            
            # 计算运行时长
            if task.get('taskStartDate'):
                try:
                    start_time = datetime.strptime(task.get('taskStartDate'), '%Y-%m-%d %H:%M:%S')
                    duration_minutes = (datetime.now() - start_time).total_seconds() / 60
                    print(f"   运行时长: {duration_minutes:.1f} 分钟")
                    
                    if duration_minutes > 30:
                        print(f"   ⚠️  异常: 运行时间过长！")
                except:
                    pass
            print()

# 2. 详细分析问题
print("="*100)
print("【2】可能的原因分析")
print("="*100)

print("""
🔍 联邦学习任务运行时间过长的常见原因:

1. ⚠️  多个任务并发运行
   • 问题: 发现多个任务同时处于"运行中"状态
   • 影响: 资源竞争导致每个任务都运行缓慢
   • 建议: 停止旧任务，只保留最新的任务

2. 🔧 系统资源不足
   • CPU/内存不足导致训练缓慢
   • 建议检查: docker stats

3. 🌐 网络通信问题
   • 节点间通信延迟
   • 数据传输速度慢
   • 建议检查: 节点日志和网络状态

4. 📊 数据或参数配置问题
   • 数据集过大
   • 迭代次数过多 (当前: globalEpoch=10)
   • 批次大小设置不当

5. 💥 任务卡住/死锁
   • 任务实际已失败但状态未更新
   • 建议: 查看节点错误日志
""")

# 3. 提供解决方案
print("="*100)
print("【3】建议的解决方案")
print("="*100)

if len(running_tasks) > 1:
    print(f"""
⚠️  检测到{len(running_tasks)}个任务同时运行，这很可能是主要原因！

🔧 解决步骤:

1. 停止旧任务 (通过Web界面或数据库)
   • 访问: http://192.168.99.5:30811
   • 路径: 模型管理 → 模型列表 → 停止旧任务
   
2. 或手动更新数据库状态:
   docker exec mysql mysql -uprimihub -pprimihub@123 privacy1 -e "
   UPDATE data_task SET task_state=4, task_error_msg='手动停止' 
   WHERE task_id IN ({','.join([str(t.get('taskId')) for t in running_tasks[:-1]])}) 
   AND task_state=2;"

3. 重启相关服务:
   docker compose restart application0 primihub-node0 primihub-node1 primihub-node2

4. 重新创建一个新的训练任务
""")
else:
    print("""
📋 当前只有1个任务在运行，可能的原因:

1. 检查系统资源:
   docker stats --no-stream

2. 查看节点日志:
   docker logs primihub-node0 --tail=100
   docker logs primihub-node1 --tail=100
   docker logs application0 --tail=100 | grep -i error

3. 如果任务确实卡住:
   • 通过Web界面停止任务
   • 或使用: python3 ./run_fl_training_full.py 重新创建
""")

print("\n" + "="*100)
print("分析完成")
print("="*100 + "\n")
