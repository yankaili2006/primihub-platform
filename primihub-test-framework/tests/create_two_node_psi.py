#!/usr/bin/env python3
"""
创建并执行两节点PSI任务
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
            # POST with JSON body
            data["timestamp"] = timestamp
            data["nonce"] = nonce
            data["token"] = TOKEN
            headers = {"Content-Type": "application/json", "token": TOKEN}
            response = requests.post(url, json=data, headers=headers, timeout=30)
        else:
            # POST with only query params
            headers = {"token": TOKEN}
            response = requests.post(url, params=params, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  创建两节点PSI任务")
print("=" * 70)

# 步骤1: 创建机构A的资源（使用已上传的文件）
print("\n步骤1: 创建机构A的资源...")

timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

resource_data_a = {
    "resourceName": f"机构A用户数据_{timestamp_str}",
    "resourceDesc": "机构A的用户基本信息",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "fileId": 15,  # 使用已上传的文件
    "fieldList": [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID", "relevance": 1},
        {"fieldName": "name", "fieldType": "String", "fieldDesc": "姓名", "relevance": 0},
        {"fieldName": "age", "fieldType": "Integer", "fieldDesc": "年龄", "relevance": 0},
        {"fieldName": "city", "fieldType": "String", "fieldDesc": "城市", "relevance": 0}
    ]
}

response = make_api_call("/data/resource/saveorupdateresource", method="POST", data=resource_data_a)

print(f"Status: {response.status_code}")
print(f"Response: {response.text[:500]}")

resource_id_a = None
if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        resource_id_a = result.get('result', {}).get('resourceId')
        print(f"✅ 机构A资源创建成功")
        print(f"   resourceId: {resource_id_a}")
    else:
        print(f"❌ 失败: {result.get('msg')}")

# 步骤2: 创建机构B的资源
print("\n步骤2: 创建机构B的资源...")

resource_data_b = {
    "resourceName": f"机构B用户数据_{timestamp_str}",
    "resourceDesc": "机构B的用户信息",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "fileId": 16,  # 使用已上传的文件
    "fieldList": [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID", "relevance": 1},
        {"fieldName": "email", "fieldType": "String", "fieldDesc": "邮箱", "relevance": 0},
        {"fieldName": "score", "fieldType": "Integer", "fieldDesc": "评分", "relevance": 0},
        {"fieldName": "department", "fieldType": "String", "fieldDesc": "部门", "relevance": 0}
    ]
}

response = make_api_call("/data/resource/saveorupdateresource", method="POST", data=resource_data_b)

print(f"Status: {response.status_code}")
print(f"Response: {response.text[:500]}")

resource_id_b = None
if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        resource_id_b = result.get('result', {}).get('resourceId')
        print(f"✅ 机构B资源创建成功")
        print(f"   resourceId: {resource_id_b}")
    else:
        print(f"❌ 失败: {result.get('msg')}")

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
            print(f"   项目ID: {project_id}")

if not project_id:
    print("❌ 未找到项目")
    exit(1)

# 步骤4: 创建两节点PSI任务
print("\n步骤4: 创建两节点PSI任务...")

# 机构ID
organ_id_a = "000000000000000000000000test0001"  # API测试机构
organ_id_b = "000000000000000000000000test0002"  # PSI协作机构

psi_params = {
    "taskName": f"两节点PSI_{timestamp_str}",
    "taskDesc": "两个机构的隐私求交任务",
    "projectId": project_id,

    # 机构A（发起方）
    "ownOrganId": organ_id_a,
    "ownResourceId": str(resource_id_a),
    "ownKeyword": "user_id",

    # 机构B（协作方）
    "otherOrganId": organ_id_b,
    "otherResourceId": str(resource_id_b),
    "otherKeyword": "user_id",

    # 结果配置
    "resultName": f"psi_result_{timestamp_str}",
    "resultOrganIds": organ_id_a,  # 结果返回给机构A
    "psiTag": "0",
    "outputContent": "0",
    "outputNoRepeat": "1",
    "outputFilePathType": "0",
    "userId": str(USER_ID)
}

print(f"   任务名称: {psi_params['taskName']}")
print(f"   机构A: {organ_id_a} (资源ID: {resource_id_a})")
print(f"   机构B: {organ_id_b} (资源ID: {resource_id_b})")
print(f"   匹配字段: user_id")
print(f"   预期交集: U005-U010 (6条记录)")

response = make_api_call("/data/psi/saveDataPsi", method="POST", params=psi_params)

print(f"\nStatus: {response.status_code}")

if response.text:
    result = response.json()
    print(f"\nResponse:")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result.get('code') == 0:
        psi_result = result.get('result', {})
        task_id = psi_result.get('dataPsiTask', {}).get('taskId')
        task_id_name = psi_result.get('dataPsiTask', {}).get('taskIdName')

        print(f"\n🎉 两节点PSI任务创建成功!")
        print(f"   任务ID: {task_id}")
        print(f"   任务标识: {task_id_name}")

        # 步骤5: 查询任务状态
        print("\n步骤5: 等待并查询任务状态...")

        for i in range(3):
            time.sleep(3)
            print(f"\n   查询第 {i+1} 次...")

            response = make_api_call("/data/psi/getPsiTaskList")

            if response.text:
                result = response.json()
                if result.get('code') == 0:
                    psi_tasks = result.get('result', {}).get('data', [])

                    for task in psi_tasks:
                        if task.get('taskId') == task_id:
                            task_state = task.get('taskState')
                            task_state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}
                            state_name = task_state_map.get(task_state, "未知")

                            print(f"   任务状态: {state_name} (code: {task_state})")
                            print(f"   耗时: {task.get('consuming')}ms")

                            if task_state == 2:
                                print(f"\n   ✅ PSI任务执行成功!")
                                break
                            elif task_state == 3:
                                print(f"\n   ❌ PSI任务执行失败")
                                break

        print("\n" + "=" * 70)
        print("  ✅ 两节点PSI任务已创建并提交执行!")
        print("=" * 70)

        print(f"""
任务摘要:
- 任务ID: {task_id}
- 任务标识: {task_id_name}
- 机构A: API测试机构 (资源: {resource_id_a})
- 机构B: PSI协作机构 (资源: {resource_id_b})
- 匹配字段: user_id
- 预期交集: U005-U010 (6条)

查看任务详情:
python3 verify_psi_task.py
""")
    else:
        print(f"\n❌ PSI任务创建失败: {result.get('msg')}")

print("\n" + "=" * 70)
