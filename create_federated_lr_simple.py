#!/usr/bin/env python3
"""
创建并执行联邦学习LR项目 - 简化版
使用正确的API格式
"""

import requests
import json
import time
from datetime import datetime

# 配置
BASE_URL = "http://172.20.0.12:8080"
ADMIN_USER = "admin"
ADMIN_PASSWORD = "Admin@123456"

class FederatedLRClient:
    def __init__(self):
        self.base_url = BASE_URL
        self.session = requests.Session()
        self.token = None
        self.user_id = None

    def login(self):
        """登录系统"""
        print("▶ 登录系统...")

        # 尝试不同的登录方式
        # 方式1: 使用form data
        url = f"{self.base_url}/sys/user/login"

        # 先尝试不带validateKeyName
        data = {
            "userAccount": ADMIN_USER,
            "userPassword": ADMIN_PASSWORD,
            "timestamp": int(time.time() * 1000),
            "nonce": int(time.time() * 1000) % 1000 + 1
        }

        try:
            response = self.session.post(url, data=data)
            result = response.json()

            if result.get('code') == 0:
                self.token = result.get('result', {}).get('token')
                self.user_id = result.get('result', {}).get('userId')
                print(f"✅ 登录成功")
                print(f"   Token: {self.token[:20] if self.token else 'None'}...")
                print(f"   User ID: {self.user_id}")
                return True
            else:
                print(f"❌ 登录失败: {result.get('msg')}")

                # 如果需要validateKeyName，尝试添加空值
                if 'validateKeyName' in result.get('msg', ''):
                    print("   尝试添加validateKeyName参数...")
                    data['validateKeyName'] = ''
                    response = self.session.post(url, data=data)
                    result = response.json()

                    if result.get('code') == 0:
                        self.token = result.get('result', {}).get('token')
                        self.user_id = result.get('result', {}).get('userId')
                        print(f"✅ 登录成功")
                        return True

                return False
        except Exception as e:
            print(f"❌ 登录异常: {e}")
            return False

    def get_organs(self):
        """获取机构列表"""
        print("\n▶ 获取机构列表...")

        url = f"{self.base_url}/sys/organ/getOrganList"
        params = {
            "timestamp": int(time.time() * 1000),
            "nonce": int(time.time() * 1000) % 1000 + 1,
            "token": self.token
        }

        try:
            response = self.session.get(url, params=params)
            result = response.json()

            if result.get('code') == 0:
                organs = result.get('result', [])
                print(f"✅ 获取成功，共 {len(organs)} 个机构")
                for i, organ in enumerate(organs[:5], 1):
                    print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")
                return organs
            else:
                print(f"❌ 获取失败: {result.get('msg')}")
                return []
        except Exception as e:
            print(f"❌ 获取异常: {e}")
            return []

    def create_resource(self, resource_data):
        """创建数据资源"""
        url = f"{self.base_url}/data/resource/saveorupdateresource"

        data = resource_data.copy()
        data.update({
            "timestamp": int(time.time() * 1000),
            "nonce": int(time.time() * 1000) % 1000 + 1,
            "token": self.token
        })

        try:
            response = self.session.post(url, data=data)
            result = response.json()

            if result.get('code') == 0:
                return result.get('result', {}).get('resourceId')
            else:
                print(f"   创建资源失败: {result.get('msg')}")
                return None
        except Exception as e:
            print(f"   创建资源异常: {e}")
            return None

    def get_task_list(self):
        """获取任务列表"""
        print("\n▶ 查询任务列表...")

        url = f"{self.base_url}/data/task/getTaskList"
        params = {
            "pageNo": 1,
            "pageSize": 10,
            "timestamp": int(time.time() * 1000),
            "nonce": int(time.time() * 1000) % 1000 + 1,
            "token": self.token
        }

        try:
            response = self.session.get(url, params=params)
            result = response.json()

            if result.get('code') == 0:
                tasks = result.get('result', {}).get('list', [])
                print(f"✅ 获取成功，共 {len(tasks)} 个任务")

                if tasks:
                    print("   最近的任务:")
                    for i, task in enumerate(tasks[:5], 1):
                        print(f"   {i}. {task.get('taskName')} - 状态: {task.get('taskState')}")
                        print(f"      任务ID: {task.get('taskId')}")
                        print(f"      创建时间: {task.get('createDate')}")

                return tasks
            else:
                print(f"❌ 获取失败: {result.get('msg')}")
                return []
        except Exception as e:
            print(f"❌ 获取异常: {e}")
            return []


def main():
    """主函数"""
    print("\n" + "="*70)
    print("联邦学习LR项目创建和执行".center(70))
    print("="*70 + "\n")

    client = FederatedLRClient()

    # 1. 登录
    if not client.login():
        print("\n❌ 登录失败，无法继续")
        return

    # 2. 获取机构列表
    organs = client.get_organs()
    if len(organs) < 2:
        print(f"\n⚠️  当前只有 {len(organs)} 个机构，联邦学习需要至少2个机构")
        print("   但我们可以继续查看系统状态...")

    # 3. 查询现有任务
    tasks = client.get_task_list()

    print("\n" + "="*70)
    print("系统状态检查完成".center(70))
    print("="*70)
    print(f"\n✅ 机构数量: {len(organs)}")
    print(f"✅ 任务数量: {len(tasks)}")

    if len(organs) >= 2:
        print("\n💡 系统已准备好创建联邦学习项目")
        print("   下一步可以:")
        print("   1. 创建数据资源")
        print("   2. 创建联邦学习项目")
        print("   3. 配置并运行联邦LR模型")
    else:
        print("\n⚠️  需要配置更多机构才能进行联邦学习")


if __name__ == "__main__":
    main()
