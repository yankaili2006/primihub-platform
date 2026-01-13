#!/usr/bin/env python3
"""
创建并执行两节点PSI任务（修复版）
"""

import requests
import time
import json
from datetime import datetime

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"
USER_ID = 1

def make_api_call(endpoint, method="GET", params=None, data=None):
    """发送API请求"""
    url = f"{BASE_URL}{endpoint}"
    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    if method == "GET":
        if params is None:
            params = {}
        params.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})
        headers = {"token": TOKEN}
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if params is None:
            params = {}
        params.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})

        if data:
            data["timestamp"] = timestamp
            data["nonce"] = nonce
            data["token"] = TOKEN
            headers = {"Content-Type": "application/json", "token": TOKEN}
            response = requests.post(url, json=data, headers=headers, timeout=30)
        else:
            headers = {"token": TOKEN}
            response = requests.post(url, params=params, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  创建两节点PSI任务（完整版）")
print("=" * 70)

timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

# 步骤1: 创建机构A的资源
print("\n步骤1: 创建机构A的资源...")

resource_data_a = {
    "resourceName": f"机构A用户数据_{timestamp_str}",
    "resourceDesc": "机构A的用户基本信息（U001-U010）",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "tags": ["PSI测试", "机构A"],  # 添加tags参数
    "fileId": 15,
    "fieldList": [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID", "relevance": 1, "grouping": 0, "protectionStatus": 0},
        {"fieldName": "name", "fieldType": "String", "fieldDesc": "姓名", "relevance": 0, "grouping": 0, "protectionStatus": 0},
        {"fieldName": "age", "fieldType": "Integer", "fieldDesc": "年龄", "relevance": 0, "grouping": 0, "protectionStatus": 0},
        {"fieldName": "city", "fieldType": "String", "fieldDesc": "城市", "relevance": 0, "grouping": 0, "protectionStatus": 0}
    ],
    "fusionOrganList": []
}

response = make_api_call("/data/resource/saveorupdateresource", method="POST", data=resource_data_a)

resource_id_a = None
if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        resource_id_a = result.get('result', {}).get('resourceId')
        print(f"✅ 机构A资源创建成功")
        print(f"   resourceId: {resource_id_a}")
        print(f"   数据范围: U001-U010 (10条)")
    else:
        print(f"❌ 失败: {result.get('msg')}")
        print(f"   Response: {response.text[:500]}")

# 步骤2: 创建机构B的资源
print("\n步骤2: 创建机构B的资源...")

resource_data_b = {
    "resourceName": f"机构B用户数据_{timestamp_str}",
    "resourceDesc": "机构B的用户信息（U005-U015）",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "tags": ["PSI测试", "机构B"],  # 添加tags参数
    "fileId": 16,
    "fieldList": [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID", "relevance": 1, "grouping": 0, "protectionStatus": 0},
        {"fieldName": "email", "fieldType": "String", "fieldDesc": "邮箱", "relevance": 0, "grouping": 0, "protectionStatus": 0},
        {"fieldName": "score", "fieldType": "Integer", "fieldDesc": "评分", "relevance": 0, "grouping": 0, "protectionStatus": 0},
        {"fieldName": "department", "fieldType": "String", "fieldDesc": "部门", "relevance": 0, "grouping": 0, "protectionStatus": 0}
    ],
    "fusionOrganList": []
}

response = make_api_call("/data/resource/saveorupdateresource", method="POST", data=resource_data_b)

resource_id_b = None
if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        resource_id_b = result.get('result', {}).get('resourceId')
        print(f"✅ 机构B资源创建成功")
        print(f"   resourceId: {resource_id_b}")
        print(f"   数据范围: U005-U015 (11条)")
    else:
        print(f"❌ 失败: {result.get('msg')}")
        print(f"   Response: {response.text[:500]}")

if not resource_id_a or not resource_id_b:
    print("\n❌ 资源创建失败，无法继续")
    exit(1)

# 步骤3: 获取项目信息
print("\n步骤3: 获取项目信息...")
response = make_api_call("/data/project/getProjectList")

project_id = None
if response.text:
    result = response.json()
    if result.get('code') == 0:
        projects = result.get('result', {}).get('data', [])
        if projects:
            project = projects[0]
            project_id = project.get('projectId')
            print(f"✅ 使用项目: {project.get('projectName')}")

# 步骤4: 创建两节点PSI任务
print("\n步骤4: 创建两节点PSI任务...")

organ_id_a = "000000000000000000000000test0001"
organ_id_b = "000000000000000000000000test0002"

psi_params = {
    "taskName": f"两节点PSI_{timestamp_str}",
    "taskDesc": "两机构隐私求交",
    "projectId": project_id,
    "ownOrganId": organ_id_a,
    "ownResourceId": str(resource_id_a),
    "ownKeyword": "user_id",
    "otherOrganId": organ_id_b,
    "otherResourceId": str(resource_id_b),
    "otherKeyword": "user_id",
    "resultName": f"psi_result_{timestamp_str}",
    "resultOrganIds": organ_id_a,
    "psiTag": "0",
    "outputContent": "0",
    "outputNoRepeat": "1",
    "outputFilePathType": "0",
    "userId": str(USER_ID)
}

print(f"   机构A: API测试机构 (资源{resource_id_a}: U001-U010)")
print(f"   机构B: PSI协作机构 (资源{resource_id_b}: U005-U015)")
print(f"   预期交集: U005-U010 (6条)")

response = make_api_call("/data/psi/saveDataPsi", method="POST", params=psi_params)

if response.text:
    result = response.json()
    print(f"\nResponse: {json.dumps(result, indent=2, ensure_ascii=False)[:800]}")

    if result.get('code') == 0:
        task_data = result.get('result', {}).get('dataPsiTask', {})
        task_id = task_data.get('taskId')
        task_id_name = task_data.get('taskIdName')

        print(f"\n🎉 两节点PSI任务创建成功!")
        print(f"   任务ID: {task_id}")
        print(f"   任务标识: {task_id_name}")

        # 步骤5: 监控任务状态
        print("\n步骤5: 监控任务执行...")

        for i in range(5):
            time.sleep(3)
            response = make_api_call("/data/psi/getPsiTaskList")

            if response.text:
                result = response.json()
                if result.get('code') == 0:
                    tasks = result.get('result', {}).get('data', [])

                    for task in tasks:
                        if task.get('taskId') == task_id:
                            state = task.get('taskState')
                            state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}
                            print(f"   [{i+1}/5] 状态: {state_map.get(state, '未知')} ({state})")

                            if state == 2:
                                print(f"\n   ✅ PSI任务执行成功!")
                                print(f"   结果名称: {task.get('resultName')}")
                                break
                            elif state == 3:
                                print(f"\n   ❌ PSI任务执行失败")
                                break

        print("\n" + "=" * 70)
        print("  ✅ 两节点PSI任务已创建!")
        print("=" * 70)
    else:
        print(f"\n❌ 失败: {result.get('msg')}")

print("\n" + "=" * 70)
