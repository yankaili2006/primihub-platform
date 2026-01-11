#!/usr/bin/env python3
"""
联邦学习LR完整流程自动化脚本
1. 上传训练数据
2. 创建数据资源
3. 关联资源到项目
4. 查看模型训练状态和结果
"""

import requests
import json
import time
from datetime import datetime

# 配置
BASE_URL = "http://172.20.0.12:8080"
ADMIN_USER = "admin"
ADMIN_PASSWORD = "123456"
PROJECT_ID = "demo0org0001-f9b7d4b1-01bf-4408-835d-a049e7cb3d75"  # 联邦LR项目ID


class FederatedLRRunner:
    def __init__(self):
        self.base_url = BASE_URL
        self.session = requests.Session()
        self.token = None
        self.user_id = None

    def _make_request(self, method, endpoint, data=None, use_json=False,
                     extra_headers=None, files=None):
        """发送HTTP请求"""
        url = f"{self.base_url}{endpoint}"

        if data is None:
            data = {}

        headers = {}
        if extra_headers:
            headers.update(extra_headers)

        try:
            if method.upper() == 'GET':
                params = dict(data)
                if self.token:
                    params['token'] = self.token
                params['timestamp'] = int(time.time() * 1000)
                params['nonce'] = int(time.time() * 1000) % 1000 + 1
                response = self.session.get(url, params=params, headers=headers, timeout=30)
            elif method.upper() == 'POST':
                if files:
                    # 文件上传，使用multipart/form-data
                    response = self.session.post(url, data=data, files=files,
                                                headers=headers, timeout=60)
                elif use_json:
                    # JSON请求，timestamp/nonce/token作为query参数
                    data['timestamp'] = int(time.time() * 1000)
                    data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    if self.token:
                        data['token'] = self.token
                    response = self.session.post(url, json=data,
                                                headers=headers, timeout=30)
                else:
                    # Form data
                    data['timestamp'] = int(time.time() * 1000)
                    data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    if self.token:
                        data['token'] = self.token
                    response = self.session.post(url, data=data, headers=headers, timeout=30)

            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"请求失败: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"响应内容: {e.response.text[:500]}")
            return None

    def login(self):
        """登录"""
        print("\n" + "="*70)
        print("▶ 步骤 1: 用户登录")
        print("="*70)

        data = {
            "userAccount": ADMIN_USER,
            "userPassword": ADMIN_PASSWORD
        }

        result = self._make_request("POST", "/sys/user/login", data)

        if result and result.get('code') == 0:
            user_data = result.get('result', {})
            self.token = user_data.get('token')
            self.user_id = user_data.get('sysUser', {}).get('userId')
            user_name = user_data.get('sysUser', {}).get('userName')
            print(f"✅ 登录成功")
            print(f"   用户: {user_name}")
            print(f"   用户ID: {self.user_id}")
            print(f"   Token: {self.token[:30]}...")
            return True
        else:
            print(f"❌ 登录失败: {result}")
            return False

    def upload_file(self, file_path, file_source=1):
        """上传文件"""
        print(f"\n▶ 上传文件: {file_path}")

        try:
            with open(file_path, 'rb') as f:
                files = {'file': f}
                data = {
                    'fileSource': file_source,
                    'timestamp': int(time.time() * 1000),
                    'nonce': int(time.time() * 1000) % 1000 + 1,
                    'token': self.token
                }

                result = self._make_request("POST", "/sys/file/upload",
                                          data=data, files=files)

                if result and result.get('code') == 0:
                    result_data = result.get('result', {})
                    # fileId在sysFile中
                    file_id = result_data.get('sysFile', {}).get('fileId')
                    print(f"✅ 文件上传成功，file_id: {file_id}")
                    return file_id
                else:
                    print(f"❌ 文件上传失败: {result}")
                    return None
        except Exception as e:
            print(f"❌ 文件上传异常: {e}")
            return None

    def create_resource(self, resource_name, resource_desc, file_id, field_list, tags):
        """创建数据资源"""
        print(f"\n▶ 创建资源: {resource_name}")

        resource_data = {
            "resourceName": resource_name,
            "resourceDesc": resource_desc,
            "resourceAuthType": 1,  # 公开
            "resourceSource": 1,  # 文件
            "fileId": file_id,
            "fieldList": field_list,
            "tags": tags
        }

        headers = {"userId": str(self.user_id)} if self.user_id else {}

        result = self._make_request("POST", "/data/resource/saveorupdateresource",
                                   resource_data, use_json=True, extra_headers=headers)

        if result and result.get('code') == 0:
            resource_id = result.get('result')
            print(f"✅ 资源创建成功，resource_id: {resource_id}")
            return resource_id
        else:
            print(f"❌ 资源创建失败: {result}")
            return None

    def get_project_details(self, project_id):
        """获取项目详情"""
        result = self._make_request("GET", "/data/project/getProjectDetails",
                                   {"id": project_id})
        return result

    def get_model_list(self, project_id):
        """获取项目的模型列表"""
        print(f"\n▶ 查询项目模型")

        result = self._make_request("GET", "/data/model/getmodellist",
                                   {"projectId": project_id, "pageNo": 1, "pageSize": 20})

        if result and result.get('code') == 0:
            models = result.get('result', {}).get('data', [])
            print(f"✅ 找到 {len(models)} 个模型")
            return models
        else:
            print(f"❌ 查询失败: {result}")
            return []

    def get_task_list(self):
        """获取任务列表"""
        print(f"\n▶ 查询任务列表")

        result = self._make_request("GET", "/data/task/getTaskList",
                                   {"pageNo": 1, "pageSize": 20})

        if result and result.get('code') == 0:
            tasks = result.get('result', {}).get('data', [])
            print(f"✅ 找到 {len(tasks)} 个任务")
            for task in tasks:
                print(f"\n任务: {task.get('taskName')}")
                print(f"  ID: {task.get('taskId')}")
                print(f"  状态: {task.get('taskState')}")
                print(f"  类型: {task.get('taskType')}")
                print(f"  创建时间: {task.get('createDate')}")
            return tasks
        else:
            print(f"❌ 查询失败: {result}")
            return []

    def get_task_detail(self, task_id):
        """获取任务详情"""
        print(f"\n▶ 查询任务详情: {task_id}")

        result = self._make_request("GET", "/data/task/getTaskData",
                                   {"taskId": task_id})

        if result and result.get('code') == 0:
            task = result.get('result', {})
            print(f"✅ 任务详情:")
            print(f"  名称: {task.get('taskName')}")
            print(f"  状态: {task.get('taskState')} (3=成功, 4=失败)")
            print(f"  开始时间: {task.get('taskStartDate')}")
            print(f"  结束时间: {task.get('taskEndDate')}")
            print(f"  耗时: {task.get('timeConsuming')}ms")

            if task.get('taskErrorMsg'):
                print(f"  错误: {task.get('taskErrorMsg')}")

            return task
        else:
            print(f"❌ 查询失败: {result}")
            return None


def main():
    print("\n" + "="*70)
    print("联邦学习LR完整流程自动化".center(70))
    print("="*70)

    runner = FederatedLRRunner()

    # 1. 登录
    if not runner.login():
        return

    # 2. 上传数据文件
    print("\n" + "="*70)
    print("▶ 步骤 2: 上传训练数据")
    print("="*70)

    org1_file_id = runner.upload_file('/tmp/org1_lr_data.csv', file_source=1)
    org2_file_id = runner.upload_file('/tmp/org2_lr_data.csv', file_source=1)

    if not org1_file_id or not org2_file_id:
        print("\n❌ 文件上传失败，无法继续")
        return

    # 3. 创建数据资源
    print("\n" + "="*70)
    print("▶ 步骤 3: 创建数据资源")
    print("="*70)

    field_list = [
        {"fieldName": "user_id", "fieldType": "String", "fieldDesc": "用户ID"},
        {"fieldName": "age", "fieldType": "Integer", "fieldDesc": "年龄"},
        {"fieldName": "income", "fieldType": "Integer", "fieldDesc": "收入"},
        {"fieldName": "credit_score", "fieldType": "Integer", "fieldDesc": "信用分"},
        {"fieldName": "label", "fieldType": "Integer", "fieldDesc": "标签"}
    ]

    org1_resource_id = runner.create_resource(
        resource_name=f"联邦LR训练数据_机构1_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
        resource_desc="机构1的用户特征数据，包含年龄、收入、信用分和标签",
        file_id=org1_file_id,
        field_list=field_list,
        tags=[{"tagName": "联邦学习"}, {"tagName": "LR训练"}]
    )

    org2_resource_id = runner.create_resource(
        resource_name=f"联邦LR训练数据_机构2_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
        resource_desc="机构2的用户特征数据，包含年龄、收入、信用分和标签",
        file_id=org2_file_id,
        field_list=field_list,
        tags=[{"tagName": "联邦学习"}, {"tagName": "LR训练"}]
    )

    if not org1_resource_id or not org2_resource_id:
        print("\n❌ 资源创建失败，无法继续")
        return

    # 4. 查询模型和任务
    print("\n" + "="*70)
    print("▶ 步骤 4: 查询现有模型和任务")
    print("="*70)

    models = runner.get_model_list(PROJECT_ID)
    tasks = runner.get_task_list()

    # 5. 显示结果摘要
    print("\n" + "="*70)
    print("流程执行完成".center(70))
    print("="*70)

    print(f"\n✅ 数据准备完成:")
    print(f"  - 机构1数据: resource_id={org1_resource_id}")
    print(f"  - 机构2数据: resource_id={org2_resource_id}")

    print(f"\n📊 当前状态:")
    print(f"  - 项目ID: {PROJECT_ID}")
    print(f"  - 模型数量: {len(models)}")
    print(f"  - 任务数量: {len(tasks)}")

    print(f"\n💡 下一步操作:")
    print(f"  由于PrimiHub的模型创建需要配置复杂的组件工作流（拖拽式配置），")
    print(f"  建议通过Web界面完成以下步骤：")
    print(f"")
    print(f"  1. 访问Web界面: http://localhost:30811")
    print(f"  2. 登录: admin / 123456")
    print(f"  3. 进入\"项目管理\" → 找到\"联邦LR项目_20260111_191254\"")
    print(f"  4. 点击\"模型管理\" → \"创建模型\"")
    print(f"  5. 配置组件:")
    print(f"     - 开始组件")
    print(f"     - 数据集组件（选择刚才上传的资源）")
    print(f"     - 模型组件（选择逻辑回归LR）")
    print(f"  6. 运行模型训练")
    print(f"  7. 查看训练结果")
    print(f"")
    print(f"  完成后，可以再次运行此脚本的第4步来查看任务结果")

    print(f"\n{'='*70}\n")


if __name__ == "__main__":
    main()
