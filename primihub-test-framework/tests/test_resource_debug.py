#!/usr/bin/env python3
"""
调试资源创建 - 最小化测试
"""

import requests
import time
import json
from datetime import datetime

BASE_URL = "http://100.64.0.23:30811/prod-api"
TOKEN = "SU202601111503542F1167CD6FFFD38A270C80D9D96A928C"

# 使用已上传的fileId=4
timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

# 最小化的资源数据
resource_data = {
    'resourceName': f'TEST_{timestamp_str}',
    'resourceDesc': 'test',
    'resourceAuthType': 1,
    'resourceSource': 1,
    'tags': ['test'],
    'fileId': 4,
    'fieldList': [
        {
            'fieldName': 'user_id',
            'fieldType': 'String',
            'fieldDesc': 'ID',
            'relevance': 1,
            'grouping': 0,
            'protectionStatus': 0
        }
    ],
    'fusionOrganList': []
}

timestamp = int(time.time() * 1000)
resource_data['timestamp'] = timestamp
resource_data['nonce'] = timestamp % 1000 + 1
resource_data['token'] = TOKEN

headers = {'Content-Type': 'application/json', 'userId': '1'}
url = f'{BASE_URL}/data/resource/saveorupdateresource?timestamp={timestamp}&nonce={resource_data["nonce"]}&token={TOKEN}'

print("发送请求:")
print(json.dumps(resource_data, indent=2, ensure_ascii=False))
print(f"\nURL: {url}")
print(f"\nHeaders: {headers}")
print("\n等待响应...")

response = requests.post(url, json=resource_data, headers=headers, timeout=30)
print(f"\n状态码: {response.status_code}")
print(f"\n响应:")
print(json.dumps(response.json(), indent=2, ensure_ascii=False))

# 同时检查日志
print("\n\n检查后端日志...")
time.sleep(2)
import subprocess
result = subprocess.run(['docker', 'logs', '--since=10s', 'application2'],
                       capture_output=True, text=True)
if 'Exception' in result.stderr or 'Exception' in result.stdout:
    print("发现异常:")
    print(result.stderr + result.stdout)
else:
    print("无异常日志")
