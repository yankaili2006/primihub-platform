#!/usr/bin/env python3
"""
综合查询联邦学习训练结果
"""
import requests
import json
import time
from datetime import datetime

BASE_URL = "http://172.20.0.6:8080"
TASK_ID = 4

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

def api_call(method, endpoint, token, user_id=None, params=None):
    """统一API调用"""
    if params is None:
        params = {}
    params['token'] = token
    params['timestamp'] = int(time.time() * 1000)
    params['nonce'] = int(time.time() * 1000) % 1000 + 1
    
    headers = {}
    if user_id:
        headers['userId'] = str(user_id)
    
    if method == 'GET':
        response = requests.get(f"{BASE_URL}{endpoint}", params=params, headers=headers)
    else:
        response = requests.post(f"{BASE_URL}{endpoint}", data=params, headers=headers)
    
    return response.json()

print("\n" + "="*100)
print(" "*35 + "联邦学习训练完整结果报告")
print("="*100)

# 登录
token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)

print(f"\n✅ 系统连接成功")
print(f"   查询时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"   任务ID: {TASK_ID}")
print(f"   用户ID: {user_id}")

# 1. 任务基本信息
print("\n" + "="*100)
print("【1】任务基本信息")
print("="*100)

task_result = api_call('GET', '/data/task/getTaskData', token, params={'taskId': TASK_ID})
if task_result.get('code') == 0:
    task = task_result['result']
    
    status_map = {0: "初始化", 1: "等待中", 2: "运行中", 3: "成功", 4: "失败"}
    status = task.get('taskState', 0)
    status_text = status_map.get(status, f"未知({status})")
    
    print(f"""
📋 基本信息:
   任务名称: {task.get('taskName')}
   任务ID: {task.get('taskId')}
   任务ID名: {task.get('taskIdName')}
   任务类型: {'联邦学习' if task.get('taskType') == 1 else f"类型{task.get('taskType')}"}
   任务描述: {task.get('taskDesc')}
   
⏱️  执行状态:
   当前状态: {status_text}
   开始时间: {task.get('taskStartDate')}
   结束时间: {task.get('taskEndDate') or '尚未结束'}
   已运行时长: {(time.time() - time.mktime(time.strptime(task.get('taskStartDate'), '%Y-%m-%d %H:%M:%S')))/60:.1f} 分钟
""")
    
    if task.get('timeConsuming') and task.get('timeConsuming') > 0:
        print(f"   实际耗时: {task.get('timeConsuming')/1000:.2f}秒")
    
    if status == 3:
        print("\n🎉 状态: 训练已成功完成！")
    elif status == 2:
        print("\n⏳ 状态: 训练仍在进行中...")
    elif status == 4:
        print(f"\n❌ 状态: 训练失败")
        if task.get('taskErrorMsg'):
            print(f"   错误: {task.get('taskErrorMsg')}")
else:
    print(f"❌ 获取任务状态失败: {task_result.get('msg')}")
    exit(1)

# 2. 获取模型列表
print("\n" + "="*100)
print("【2】查询项目中的所有模型")
print("="*100)

model_list_result = api_call('GET', '/data/model/getmodellist', token, params={
    'projectId': 3,
    'pageNo': 1,
    'pageSize': 20
})

if model_list_result.get('code') == 0:
    models = model_list_result.get('result', {}).get('data', [])
    print(f"\n找到 {len(models)} 个模型:\n")
    for idx, model in enumerate(models, 1):
        print(f"{idx}. {model.get('modelName')}")
        print(f"   模型ID: {model.get('modelId')}")
        print(f"   创建时间: {model.get('createDate')}")
        if model.get('taskState'):
            print(f"   最近任务状态: {status_map.get(model.get('taskState'), model.get('taskState'))}")
        print()

# 3. 获取所有任务列表
print("=" * 100)
print("【3】查询项目中的所有任务")
print("="*100)

task_list_result = api_call('GET', '/data/task/getTaskList', token, params={
    'pageNo': 1,
    'pageSize': 20
})

if task_list_result.get('code') == 0:
    tasks = task_list_result.get('result', {}).get('data', [])
    print(f"\n找到 {len(tasks)} 个任务:\n")
    for idx, t in enumerate(tasks, 1):
        t_status = status_map.get(t.get('taskState'), t.get('taskState'))
        print(f"{idx}. {t.get('taskName')} [{t_status}]")
        print(f"   任务ID: {t.get('taskId')}")
        print(f"   开始: {t.get('taskStartDate')}")
        print(f"   结束: {t.get('taskEndDate') or '进行中'}")
        print()

# 4. Web界面信息
print("="*100)
print("【4】查看详细结果")
print("="*100)

print(f"""
🌐 Web界面访问:
   • 机构1: http://192.168.99.5:30811
   • 机构2: http://192.168.99.5:30812
   • 机构3: http://192.168.99.5:30813
   
   账号: admin
   密码: 123456
   
   查看路径: 模型管理 → 模型列表 → 找到模型 → 查看任务详情

📊 API查询:
   任务状态: GET {BASE_URL}/data/task/getTaskData?taskId={TASK_ID}
   任务日志: GET {BASE_URL}/data/task/getTaskLogInfo?taskId={TASK_ID}
   
🔍 如果任务仍在运行:
   • 联邦学习训练通常需要5-10分钟
   • 可以通过Web界面实时查看进度
   • 或者稍后重新运行此脚本检查结果
""")

print("="*100)
print(f"报告生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100 + "\n")
