#!/usr/bin/env python3
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
    params = {
        "taskId": TASK_ID,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.get(f"{BASE_URL}/data/task/getTaskData", params=params)
    return response.json()

def get_task_log(token):
    params = {
        "taskId": TASK_ID,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = requests.get(f"{BASE_URL}/data/task/getTaskLogInfo", params=params)
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

token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)

print(f"\n✅ 登录成功 (用户ID: {user_id})")
print(f"查询时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"任务ID: {TASK_ID}")

# 获取任务状态
print("\n" + "="*80)
print("【1】任务状态")
print("="*80)

task_result = get_task_status(token)
if task_result.get('code') == 0:
    task = task_result['result']
    status = task.get('taskState')
    status_text = status_map.get(status, f"未知({status})")
    
    print(f"\n任务名称: {task.get('taskName')}")
    print(f"任务描述: {task.get('taskDesc')}")
    print(f"任务类型: {'联邦学习' if task.get('taskType') == 1 else '其他'}")
    print(f"\n当前状态: {status_text}")
    print(f"开始时间: {task.get('taskStartDate')}")
    print(f"结束时间: {task.get('taskEndDate') or '尚未结束'}")
    
    if task.get('timeConsuming') and task.get('timeConsuming') > 0:
        time_sec = task.get('timeConsuming') / 1000
        print(f"执行耗时: {time_sec:.2f}秒 ({task.get('timeConsuming')}ms)")
    
    if task.get('taskErrorMsg'):
        print(f"\n❌ 错误信息:\n{task.get('taskErrorMsg')}")
    
    if status == 3:
        print("\n🎉 任务已成功完成！")
    elif status == 2:
        print("\n⏳ 任务仍在运行中...")
    elif status == 4:
        print("\n❌ 任务执行失败")
else:
    print(f"❌ 获取任务状态失败: {task_result.get('msg')}")

# 获取任务日志
print("\n" + "="*80)
print("【2】任务执行日志")
print("="*80)

log_result = get_task_log(token)
if log_result.get('code') == 0:
    result_data = log_result.get('result')
    
    if isinstance(result_data, dict):
        # 如果result是字典，提取日志列表
        logs = result_data.get('data', []) or result_data.get('logs', []) or []
    elif isinstance(result_data, list):
        logs = result_data
    else:
        logs = []
    
    if logs:
        print(f"\n共 {len(logs)} 条日志记录:\n")
        # 显示最后20条日志
        display_logs = logs[-20:] if len(logs) > 20 else logs
        for log in display_logs:
            if isinstance(log, dict):
                log_time = log.get('ctime', log.get('createDate', ''))
                log_content = log.get('content', log.get('message', ''))
                identity = log.get('identity', 0)
                identity_text = "发起方" if identity == 1 else "协作方" if identity == 2 else "系统"
                print(f"[{log_time}] [{identity_text}] {log_content}")
            else:
                print(f"  {log}")
    else:
        print("\n暂无日志记录或日志格式异常")
        print(f"原始响应: {json.dumps(result_data, indent=2, ensure_ascii=False)[:500]}")
else:
    print(f"⚠️  获取日志失败: {log_result.get('msg')}")

print("\n" + "="*80)
print("💡 提示")
print("="*80)

if status == 2:
    print("\n任务仍在运行中，预计还需要几分钟完成")
    print("\n可以通过以下方式继续监控:")
    print("  1. 重新运行此脚本: python3 /tmp/view_results_fixed.py")
    print("  2. 查看Web界面: http://192.168.99.5:30811")
    print("  3. 查看节点日志: docker compose logs -f primihub-node0")
elif status == 3:
    print("\n✅ 训练已完成！可以查看详细结果")
    print("\nWeb界面查看结果:")
    print("  • 访问: http://192.168.99.5:30811")
    print("  • 路径: 模型管理 → 模型列表 → 查看任务详情")
elif status == 4:
    print("\n❌ 训练失败，请检查错误日志")
    print("\n查看详细日志:")
    print("  • docker compose logs application0 | grep -i error")
    print("  • docker compose logs primihub-node0 | grep -i error")

print(f"\n查询时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
