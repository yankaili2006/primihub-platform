#!/usr/bin/env python3
"""
完整的项目运行流程：创建资源 -> 创建PSI任务 -> 执行并查看结果
"""

import requests
import time
import json
from datetime import datetime

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"

def make_api_call(endpoint, method="GET", data=None):
    """发送API请求"""
    url = f"{BASE_URL}{endpoint}"
    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    if method == "GET":
        params = {"timestamp": timestamp, "nonce": nonce, "token": TOKEN}
        headers = {"token": TOKEN}
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = TOKEN
        headers = {"Content-Type": "application/json", "token": TOKEN}
        response = requests.post(url, json=data, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  完整项目运行流程")
print("=" * 70)

# 步骤1: 检查项目状态
print("\n步骤1: 检查项目列表...")
response = make_api_call("/data/project/getProjectList")

if response.text:
    result = response.json()
    if result.get('code') == 0:
        projects = result.get('result', {}).get('data', [])
        print(f"✅ 找到 {len(projects)} 个项目")

        if projects:
            project = projects[0]
            project_id = project.get('projectId')
            print(f"\n使用项目:")
            print(f"   ID: {project_id}")
            print(f"   名称: {project.get('projectName')}")
            print(f"   状态: {project.get('status')}")

# 步骤2: 检查资源列表
print("\n步骤2: 检查数据资源...")
response = make_api_call("/data/resource/getresourcelist")

if response.text:
    result = response.json()
    print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)[:500]}")

    if result.get('code') == 0:
        resources = result.get('result', {}).get('list', [])
        print(f"✅ 找到 {len(resources)} 个资源")

        if resources:
            for i, res in enumerate(resources[:3], 1):
                print(f"   {i}. {res.get('resourceName')} (ID: {res.get('resourceId')})")

# 步骤3: 检查任务列表
print("\n步骤3: 检查任务列表...")
response = make_api_call("/data/task/getTaskList")

if response.text:
    result = response.json()
    if result.get('code') == 0:
        tasks = result.get('result', {}).get('list', [])
        print(f"✅ 找到 {len(tasks)} 个任务")

        if tasks:
            for i, task in enumerate(tasks[:3], 1):
                print(f"   {i}. {task.get('taskName')} - 状态: {task.get('taskState')}")

print("\n" + "=" * 70)
