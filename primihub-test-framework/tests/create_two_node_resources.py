#!/usr/bin/env python3
"""
为两个机构创建数据资源，用于两方PSI任务
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
            # 文件上传
            if data is None:
                data = {}
            data.update({"timestamp": timestamp, "nonce": nonce, "token": TOKEN})
            response = requests.post(url, files=files, data=data, timeout=60)
        else:
            headers = {"token": TOKEN}
            response = requests.post(url, params=params, headers=headers, timeout=30)

    return response

print("=" * 70)
print("  为两个机构创建数据资源")
print("=" * 70)

# 步骤1: 创建机构A的数据文件（包含user_id: U001-U010）
print("\n步骤1: 创建机构A的数据文件...")

csv_content_a = """user_id,name,age,city
U001,Alice,25,北京
U002,Bob,30,上海
U003,Charlie,28,深圳
U004,David,35,广州
U005,Eve,22,杭州
U006,Frank,40,成都
U007,Grace,26,武汉
U008,Henry,33,南京
U009,Iris,29,西安
U010,Jack,31,重庆
"""

timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
filename_a = f"org_a_data_{timestamp_str}.csv"
temp_file_a = os.path.join(tempfile.gettempdir(), filename_a)

with open(temp_file_a, 'w', encoding='utf-8') as f:
    f.write(csv_content_a)

print(f"✅ 创建机构A数据文件: {filename_a}")
print(f"   数据行数: 10")
print(f"   user_id范围: U001-U010")

# 步骤2: 上传机构A的文件
print("\n步骤2: 上传机构A的文件...")

with open(temp_file_a, 'rb') as f:
    files = {'file': (filename_a, f, 'text/csv')}
    data = {
        'userId': USER_ID,
        'fileName': filename_a,
        'fileSource': 1
    }

    response = make_api_call("/data/file/upload", method="POST", data=data, files=files)

if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        file_id_a = result.get('result', {}).get('sysFile', {}).get('fileId')
        print(f"✅ 机构A文件上传成功")
        print(f"   fileId: {file_id_a}")

# 步骤3: 创建机构B的数据文件（包含user_id: U005-U015，与A有交集U005-U010）
print("\n步骤3: 创建机构B的数据文件...")

csv_content_b = """user_id,email,score,department
U005,eve@example.com,85,Sales
U006,frank@example.com,90,IT
U007,grace@example.com,88,HR
U008,henry@example.com,92,Finance
U009,iris@example.com,87,Marketing
U010,jack@example.com,91,IT
U011,Kate,kate@example.com,Tech
U012,Leo,leo@example.com,Sales
U013,Mary,mary@example.com,HR
U014,Nick,nick@example.com,Finance
U015,Olivia,olivia@example.com,Marketing
"""

filename_b = f"org_b_data_{timestamp_str}.csv"
temp_file_b = os.path.join(tempfile.gettempdir(), filename_b)

with open(temp_file_b, 'w', encoding='utf-8') as f:
    f.write(csv_content_b)

print(f"✅ 创建机构B数据文件: {filename_b}")
print(f"   数据行数: 11")
print(f"   user_id范围: U005-U015")
print(f"   预期交集: U005-U010 (6个)")

# 步骤4: 上传机构B的文件
print("\n步骤4: 上传机构B的文件...")

with open(temp_file_b, 'rb') as f:
    files = {'file': (filename_b, f, 'text/csv')}
    data = {
        'userId': USER_ID,
        'fileName': filename_b,
        'fileSource': 1
    }

    response = make_api_call("/data/file/upload", method="POST", data=data, files=files)

if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        file_id_b = result.get('result', {}).get('sysFile', {}).get('fileId')
        print(f"✅ 机构B文件上传成功")
        print(f"   fileId: {file_id_b}")

# 步骤5: 创建机构A的资源
print("\n步骤5: 创建机构A的资源...")

resource_data_a = {
    "resourceName": f"机构A用户数据_{timestamp_str}",
    "resourceDesc": "机构A的用户基本信息",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "fileId": file_id_a,
    "fieldList": [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID", "relevance": 1},
        {"fieldName": "name", "fieldType": "String", "fieldDesc": "姓名", "relevance": 0},
        {"fieldName": "age", "fieldType": "Integer", "fieldDesc": "年龄", "relevance": 0},
        {"fieldName": "city", "fieldType": "String", "fieldDesc": "城市", "relevance": 0}
    ]
}

# 添加timestamp和nonce到data中
timestamp = int(time.time() * 1000)
resource_data_a["timestamp"] = timestamp
resource_data_a["nonce"] = timestamp % 1000 + 1
resource_data_a["token"] = TOKEN

response = requests.post(
    f"{BASE_URL}/data/resource/saveorupdateresource",
    json=resource_data_a,
    headers={"Content-Type": "application/json", "token": TOKEN},
    timeout=30
)

if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        resource_id_a = result.get('result', {}).get('resourceId')
        print(f"✅ 机构A资源创建成功")
        print(f"   resourceId: {resource_id_a}")

# 步骤6: 创建机构B的资源
print("\n步骤6: 创建机构B的资源...")

resource_data_b = {
    "resourceName": f"机构B用户数据_{timestamp_str}",
    "resourceDesc": "机构B的用户信息",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "fileId": file_id_b,
    "fieldList": [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID", "relevance": 1},
        {"fieldName": "email", "fieldType": "String", "fieldDesc": "邮箱", "relevance": 0},
        {"fieldName": "score", "fieldType": "Integer", "fieldDesc": "评分", "relevance": 0},
        {"fieldName": "department", "fieldType": "String", "fieldDesc": "部门", "relevance": 0}
    ]
}

timestamp = int(time.time() * 1000)
resource_data_b["timestamp"] = timestamp
resource_data_b["nonce"] = timestamp % 1000 + 1
resource_data_b["token"] = TOKEN

response = requests.post(
    f"{BASE_URL}/data/resource/saveorupdateresource",
    json=resource_data_b,
    headers={"Content-Type": "application/json", "token": TOKEN},
    timeout=30
)

if response.status_code == 200:
    result = response.json()
    if result.get('code') == 0:
        resource_id_b = result.get('result', {}).get('resourceId')
        print(f"✅ 机构B资源创建成功")
        print(f"   resourceId: {resource_id_b}")

# 清理临时文件
os.remove(temp_file_a)
os.remove(temp_file_b)

print("\n" + "=" * 70)
print("  ✅ 两个机构的数据资源创建完成!")
print("=" * 70)

print(f"""
资源摘要:
- 机构A资源ID: {resource_id_a}
  - 数据范围: U001-U010 (10条)

- 机构B资源ID: {resource_id_b}
  - 数据范围: U005-U015 (11条)

- 预期PSI交集: U005-U010 (6条)

下一步: 使用这两个资源创建两方PSI任务
""")

print("=" * 70)
