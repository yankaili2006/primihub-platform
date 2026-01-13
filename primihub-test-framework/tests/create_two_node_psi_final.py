#!/usr/bin/env python3
"""
修复CSV格式并创建两节点PSI任务
"""

import requests
import time
import json
import tempfile
import os
from datetime import datetime

TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
BASE_URL = "http://100.64.0.23:30811/prod-api"
USER_ID = 1

def make_api_call(endpoint, method="GET", params=None, data=None, files=None):
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

        if files:
            if data is None:
                data = {}
            data.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})
            response = requests.post(url, files=files, data=data, timeout=60)
        elif data:
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
print("  创建两节点PSI任务（修复CSV格式）")
print("=" * 70)

timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

# 步骤1: 创建修复后的机构B数据文件
print("\n步骤1: 创建修复后的机构B数据文件...")

csv_content_b = """user_id,email,score,department
U005,eve@example.com,85,Sales
U006,frank@example.com,90,IT
U007,grace@example.com,88,HR
U008,henry@example.com,92,Finance
U009,iris@example.com,87,Marketing
U010,jack@example.com,91,IT
U011,kate@example.com,86,Tech
U012,leo@example.com,89,Sales
U013,mary@example.com,84,HR
U014,nick@example.com,93,Finance
U015,olivia@example.com,88,Marketing
"""

filename_b = f"org_b_fixed_{timestamp_str}.csv"
temp_file_b = os.path.join(tempfile.gettempdir(), filename_b)

with open(temp_file_b, 'w', encoding='utf-8') as f:
    f.write(csv_content_b)

print(f"✅ 创建机构B数据文件: {filename_b}")
print(f"   数据范围: U005-U015 (11条)")

# 步骤2: 上传机构B的文件
print("\n步骤2: 上传机构B的文件...")

with open(temp_file_b, 'rb') as f:
    files = {'file': (filename_b, f, 'text/csv')}
    data = {
        'userId': USER_ID,
        'fileName': filename_b,
        'fileSource': 1
    }

    response = make_api_call("/data/file/upload", method="POST", data=data, files=files)

file_id_b = None
if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        file_id_b = result.get('result', {}).get('sysFile', {}).get('fileId')
        print(f"✅ 文件上传成功")
        print(f"   fileId: {file_id_b}")

os.remove(temp_file_b)

if not file_id_b:
    print("❌ 文件上传失败")
    exit(1)

# 步骤3: 创建机构B的资源
print("\n步骤3: 创建机构B的资源...")

resource_data_b = {
    "resourceName": f"机构B用户数据_{timestamp_str}",
    "resourceDesc": "机构B的用户信息（U005-U015）",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "tags": ["PSI测试", "机构B"],
    "fileId": file_id_b,
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
    else:
        print(f"❌ 失败: {result.get('msg')}")
        exit(1)

# 使用之前创建的机构A资源
resource_id_a = 3

# 步骤4: 获取项目信息
print("\n步骤4: 获取项目信息...")
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

# 步骤5: 创建两节点PSI任务
print("\n步骤5: 创建两节点PSI任务...")

organ_id_a = "000000000000000000000000test0001"
organ_id_b = "000000000000000000000000test0002"

psi_params = {
    "taskName": f"两节点PSI_{timestamp_str}",
    "taskDesc": "两机构隐私求交测试",
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
print(f"   匹配字段: user_id")
print(f"   预期交集: U005-U010 (6条)")

response = make_api_call("/data/psi/saveDataPsi", method="POST", params=psi_params)

if response.text:
    result = response.json()
    print(f"\nResponse:")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result.get('code') == 0:
        task_data = result.get('result', {}).get('dataPsiTask', {})
        task_id = task_data.get('taskId')
        task_id_name = task_data.get('taskIdName')

        print(f"\n🎉 两节点PSI任务创建成功!")
        print(f"   任务ID: {task_id}")
        print(f"   任务标识: {task_id_name}")

        # 步骤6: 监控任务状态
        print("\n步骤6: 监控任务执行状态...")

        for i in range(6):
            time.sleep(5)
            response = make_api_call("/data/psi/getPsiTaskList")

            if response.text:
                result = response.json()
                if result.get('code') == 0:
                    tasks = result.get('result', {}).get('data', [])

                    for task in tasks:
                        if task.get('taskId') == task_id:
                            state = task.get('taskState')
                            state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}
                            state_name = state_map.get(state, '未知')

                            print(f"   [{i+1}/6] 状态: {state_name} (code: {state}), 耗时: {task.get('consuming')}ms")

                            if state == 2:
                                print(f"\n   ✅ PSI任务执行成功!")
                                print(f"   结果名称: {task.get('resultName')}")
                                print(f"   交集数量: 预期6条 (U005-U010)")
                                break
                            elif state == 3:
                                print(f"\n   ❌ PSI任务执行失败")
                                break

        print("\n" + "=" * 70)
        print("  ✅ 两节点PSI任务已创建并提交执行!")
        print("=" * 70)

        print(f"""
任务摘要:
- 任务ID: {task_id}
- 任务标识: {task_id_name}
- 机构A: API测试机构 (资源{resource_id_a})
  - 数据: U001-U010 (10条)
- 机构B: PSI协作机构 (资源{resource_id_b})
  - 数据: U005-U015 (11条)
- 匹配字段: user_id
- 预期交集: U005-U010 (6条)
""")
    else:
        print(f"\n❌ PSI任务创建失败: {result.get('msg')}")

print("\n" + "=" * 70)
