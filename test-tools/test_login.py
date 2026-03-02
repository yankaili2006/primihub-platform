#!/usr/bin/env python3
import requests
import time
import json

BASE_URL = "http://172.20.0.6:8080"

def test_login():
    print("测试登录...")
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": int(time.time() * 1000) % 1000 + 1
    }
    
    try:
        response = requests.post(f"{BASE_URL}/user/login", data=data, timeout=10)
        print(f"状态码: {response.status_code}")
        print(f"响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.json()
    except Exception as e:
        print(f"错误: {e}")
        return None

if __name__ == "__main__":
    test_login()
