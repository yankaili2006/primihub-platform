#!/usr/bin/env python3
"""
查看联邦学习训练结果
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

def get_task_status(token):
    """获取任务状态"""
    params = {
        "taskId": TASK_ID,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.get(f"{BASE_URL}/data/task/getTaskData", params=params)
    return response.json()

def get_task_log(token):
    """获取任务日志"""
    params = {
        "taskId": TASK_ID,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.get(f"{BASE_URL}/data/task/getTaskLogInfo", params=params)
    return response.json()

def get_model_detail(token, user_id):
    """获取模型详情"""
    params = {
        "taskId": TASK_ID,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    headers = {"userId": str(user_id)}
    response = requests.get(f"{BASE_URL}/data/model/getdatamodel", params=params, headers=headers)
    return response.json()

def get_task_components(token, user_id):
    """获取任务组件详情"""
    params = {
        "taskId": TASK_ID,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    headers = {"userId": str(user_id)}
    response = requests.get(f"{BASE_URL}/data/model/getTaskModelComponent", params=params, headers=headers)
    return response.json()

status_map = {
    0: "初始化",
    1: "等待中",
    2: "运行中",
    3: "成功",
    4: "失败"
}

print("\n" + "="*80)
print(" "*25 + "联邦学习训练结果查询")
print("="*80)

# 登录
token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)

print(f"\n✅ 登录成功 (用户ID: {user_id})")
print(f"查询时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"任务ID: {TASK_ID}")

# 1. 获取任务状态
print("\n" + "="*80)
print("【1】任务基本信息")
print("="*80)

task_result = get_task_status(token)
if task_result.get('code') == 0:
    task = task_result['result']
    status = task.get('taskState')
    status_text = status_map.get(status, f"未知({status})")
    
    print(f"\n任务名称: {task.get('taskName')}")
    print(f"任务描述: {task.get('taskDesc')}")
    print(f"任务ID名: {task.get('taskIdName')}")
    print(f"任务类型: {'联邦学习' if task.get('taskType') == 1 else '其他'}")
    print(f"当前状态: {status_text}")
    print(f"开始时间: {task.get('taskStartDate')}")
    print(f"结束时间: {task.get('taskEndDate') or '尚未结束'}")
    
    if task.get('timeConsuming'):
        time_sec = task.get('timeConsuming') / 1000
        print(f"执行耗时: {time_sec:.2f}秒")
    
    if task.get('taskErrorMsg'):
        print(f"\n❌ 错误信息: {task.get('taskErrorMsg')}")
    
    if status == 3:
        print("\n🎉 任务已成功完成！")
    elif status == 2:
        print("\n⏳ 任务仍在运行中...")
    elif status == 4:
        print("\n❌ 任务执行失败")
else:
    print(f"❌ 获取任务状态失败: {task_result.get('msg')}")
    exit(1)

# 2. 获取模型详情
print("\n" + "="*80)
print("【2】模型详细信息")
print("="*80)

model_result = get_model_detail(token, user_id)
if model_result.get('code') == 0:
    model = model_result.get('result', {})
    
    print(f"\n模型ID: {model.get('modelId')}")
    print(f"模型名称: {model.get('modelName')}")
    print(f"模型描述: {model.get('modelDesc')}")
    print(f"训练类型: {model.get('trainTypeValue')}")
    
    # 数据资源信息
    resources = model.get('modelProjectResourceList', [])
    if resources:
        print(f"\n参与数据资源 ({len(resources)}个):")
        for idx, res in enumerate(resources, 1):
            print(f"\n  [{idx}] {res.get('resourceName')}")
            print(f"      机构: {res.get('organName')}")
            print(f"      数据行数: {res.get('fileNum', 0)}")
            print(f"      参数数量: {res.get('primitiveParamNum', 0)}")
            print(f"      角色: {'发起者' if res.get('participationIdentity') == 1 else '协作者'}")
    
    # 模型组件信息
    components = model.get('taskComponentList', [])
    if components:
        print(f"\n模型组件配置 ({len(components)}个):")
        for comp in components:
            print(f"\n  • {comp.get('componentName')} ({comp.get('componentCode')})")
            values = comp.get('componentValues', [])
            if values and isinstance(values, list):
                for val in values:
                    if isinstance(val, dict) and val.get('key') not in ['selectData']:
                        print(f"    - {val.get('key')}: {val.get('val')}")
else:
    print(f"⚠️  获取模型详情失败: {model_result.get('msg')}")

# 3. 获取任务日志
print("\n" + "="*80)
print("【3】任务执行日志")
print("="*80)

log_result = get_task_log(token)
if log_result.get('code') == 0:
    logs = log_result.get('result', [])
    if logs:
        print(f"\n共 {len(logs)} 条日志记录:\n")
        for log in logs[-20:]:  # 显示最后20条
            log_time = log.get('ctime', '')
            log_content = log.get('content', '')
            identity = log.get('identity', 0)
            identity_text = "发起方" if identity == 1 else "协作方" if identity == 2 else "系统"
            print(f"[{log_time}] [{identity_text}] {log_content}")
    else:
        print("\n暂无日志记录")
else:
    print(f"⚠️  获取日志失败: {log_result.get('msg')}")

# 4. 获取组件详情
print("\n" + "="*80)
print("【4】训练组件执行详情")
print("="*80)

comp_result = get_task_components(token, user_id)
if comp_result.get('code') == 0:
    components = comp_result.get('result', {}).get('taskComponentList', [])
    if components:
        print(f"\n共 {len(components)} 个组件:\n")
        for comp in components:
            print(f"• {comp.get('componentName')}")
            print(f"  代码: {comp.get('componentCode')}")
            print(f"  状态: {comp.get('componentStatus', '未知')}")
            if comp.get('componentValues'):
                print(f"  参数: {len(comp.get('componentValues', []))} 个")
    else:
        print("\n暂无组件信息")
else:
    print(f"⚠️  获取组件详情失败: {comp_result.get('msg')}")

print("\n" + "="*80)
print("查询完成")
print("="*80)

# 提供后续操作建议
print("\n💡 后续操作:")
if status == 2:
    print("  • 任务仍在运行，请稍后再次查询")
    print(f"  • 命令: python3 /tmp/view_training_results.py")
elif status == 3:
    print("  • 任务已完成，可以查看训练结果")
    print("  • 可以通过Web界面查看更详细的结果可视化")
    print(f"  • Web地址: http://192.168.99.5:30811")
elif status == 4:
    print("  • 任务失败，请查看错误日志排查问题")
    print("  • 可以查看容器日志: docker compose logs primihub-node0")

print(f"\n查询结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
