#!/usr/bin/env python3
"""
简单的项目创建脚本
使用浏览器获取的token来创建项目
"""

import requests
import time
import json
from datetime import datetime

# ========== 配置区域 ==========
# 请从浏览器获取token后，粘贴到下面:
TOKEN = "YOUR_TOKEN_HERE"  # ← 在这里粘贴token

BASE_URL = "http://100.64.0.23:30811/prod-api"
# =============================

def make_api_call(endpoint, method="GET", data=None, token=None):
    """发送API请求"""
    url = f"{BASE_URL}{endpoint}"

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    headers = {
        "Content-Type": "application/json",
        "token": token
    }

    if method == "GET":
        params = {
            "timestamp": timestamp,
            "nonce": nonce,
            "token": token
        }
        response = requests.get(url, params=params, headers=headers, timeout=30)
    else:
        if data is None:
            data = {}
        data["timestamp"] = timestamp
        data["nonce"] = nonce
        data["token"] = token
        response = requests.post(url, json=data, headers=headers, timeout=30)

    if response.text:
        return response.json()
    else:
        return {"code": -1, "msg": "Empty response"}

def create_project():
    """创建项目的完整流程"""

    if TOKEN == "YOUR_TOKEN_HERE":
        print("\n" + "⚠️ " * 35)
        print("请先从浏览器获取token!")
        print("\n步骤:")
        print("1. 访问 http://100.64.0.23:30811")
        print("2. 登录 (admin / Admin@123456)")
        print("3. 按F12打开开发者工具 → Console标签")
        print("4. 在控制台输入: localStorage.getItem('token')")
        print("5. 复制返回的token（去掉引号）")
        print("6. 粘贴到本脚本第12行的TOKEN变量中")
        print("7. 保存文件后重新运行此脚本")
        print("⚠️ " * 35 + "\n")
        return

    print("=" * 70)
    print("  PrimiHub 项目创建")
    print("=" * 70)

    # 步骤1: 获取机构列表
    print("\n步骤1: 获取机构列表...")
    try:
        result = make_api_call("/sys/organ/getOrganList", token=TOKEN)

        if result.get('code') == 102:
            print("❌ Token已失效，请重新获取")
            return

        if result.get('code') != 0:
            print(f"❌ 获取机构列表失败: {result.get('msg')}")
            return

        organs = result.get('result', [])
        if not organs:
            print("❌ 系统中没有机构，无法创建项目")
            return

        print(f"✅ 找到 {len(organs)} 个机构")
        for i, organ in enumerate(organs[:5], 1):
            print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

        # 步骤2: 创建项目
        print("\n步骤2: 创建项目...")

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        project_data = {
            "projectName": f"API测试项目_{timestamp}",
            "projectDesc": f"通过API创建的测试项目 - {timestamp}",
            "projectOrgans": [
                {
                    "organId": organs[0].get('organId'),
                    "participationIdentity": 1,  # 1=发起者
                    "resourceIds": []
                }
            ]
        }

        print(f"   项目名称: {project_data['projectName']}")
        print(f"   发起机构: {organs[0].get('organName')}")

        result = make_api_call("/data/project/saveOrUpdateProject", method="POST",
                              data=project_data, token=TOKEN)

        print(f"\n响应:")
        print(json.dumps(result, indent=2, ensure_ascii=False))

        if result.get('code') == 0:
            project_id = result.get('result', {}).get('id') or result.get('result', {}).get('projectId')
            print(f"\n🎉 项目创建成功!")
            print(f"   项目ID: {project_id}")
            print(f"   项目名称: {project_data['projectName']}")

            # 步骤3: 验证项目
            print("\n步骤3: 验证项目...")
            list_result = make_api_call("/data/project/getProjectList", token=TOKEN)

            if list_result.get('code') == 0:
                projects = list_result.get('result', {}).get('list', [])
                print(f"✅ 系统中共有 {len(projects)} 个项目")

                # 查找刚创建的项目
                for proj in projects:
                    if proj.get('projectName') == project_data['projectName']:
                        print(f"\n✅ 找到刚创建的项目:")
                        print(f"   项目ID: {proj.get('projectId')}")
                        print(f"   项目名称: {proj.get('projectName')}")
                        print(f"   状态: {proj.get('projectState')}")
                        print(f"   创建时间: {proj.get('createDate')}")
                        break
        else:
            print(f"\n❌ 项目创建失败: {result.get('msg')}")

    except Exception as e:
        print(f"\n❌ 错误: {e}")
        import traceback
        traceback.print_exc()

    print("\n" + "=" * 70)

if __name__ == "__main__":
    create_project()
