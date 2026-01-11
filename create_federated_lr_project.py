#!/usr/bin/env python3
"""
创建并执行联邦学习LR项目
两方合作进行联邦逻辑回归算法
"""

import requests
import json
import time
from datetime import datetime
from urllib.parse import urlencode

# 测试配置
BASE_URL = "http://172.20.0.12:8080"
ADMIN_USER = "admin"
ADMIN_PASSWORD = "123456"


class FederatedLRClient:
    def __init__(self):
        self.base_url = BASE_URL
        self.session = requests.Session()
        self.token = None
        self.user_id = None

    def _make_request(self, method, endpoint, data=None, use_json=False, extra_headers=None):
        """发送HTTP请求"""
        url = f"{self.base_url}{endpoint}"

        # 添加timestamp和nonce
        if data is None:
            data = {}
        data['timestamp'] = int(time.time() * 1000)
        data['nonce'] = int(time.time() * 1000) % 1000 + 1

        # 添加token
        if self.token:
            data['token'] = self.token

        # 准备headers
        headers = {}
        if extra_headers:
            headers.update(extra_headers)

        try:
            if method.upper() == 'GET':
                response = self.session.get(url, params=data, headers=headers, timeout=30)
            elif method.upper() == 'POST':
                if use_json:
                    response = self.session.post(url, json=data, headers=headers, timeout=30)
                else:
                    # 使用form data格式
                    response = self.session.post(url, data=data, headers=headers, timeout=30)

            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"请求失败: {e}")
            return None

    def login(self):
        """登录系统"""
        print("\n▶ 步骤 1: 用户登录")
        print("-" * 70)

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
            return True
        else:
            print(f"❌ 登录失败: {result}")
            return False

    def get_organs(self):
        """获取机构列表"""
        print("\n▶ 步骤 2: 获取机构列表")
        print("-" * 70)

        result = self._make_request("GET", "/sys/organ/getOrganList", {"pageNo": 1, "pageSize": 100})

        if result and result.get('code') == 0:
            result_data = result.get('result', {})
            organs = result_data.get('data', [])
            total = result_data.get('total', 0)
            print(f"✅ 获取成功，共 {total} 个机构")
            for i, organ in enumerate(organs[:5], 1):
                print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")
            return organs
        else:
            print(f"❌ 获取失败: {result}")
            return []

    def get_resources(self):
        """获取资源列表"""
        print("\n▶ 步骤 3: 获取数据资源列表")
        print("-" * 70)

        result = self._make_request("GET", "/data/resource/getdataresourcelist", {
            "pageNo": 1,
            "pageSize": 10
        })

        if result and result.get('code') == 0:
            resources = result.get('result', {}).get('list', [])
            print(f"✅ 获取成功，共 {len(resources)} 个资源")
            for i, res in enumerate(resources[:5], 1):
                print(f"   {i}. {res.get('resourceName')} (ID: {res.get('resourceId')})")
            return resources
        else:
            print(f"❌ 获取失败: {result}")
            return []

    def create_project(self, organs, resources):
        """创建联邦学习项目"""
        print("\n▶ 步骤 4: 创建联邦学习项目")
        print("-" * 70)

        if len(organs) < 2:
            print("❌ 需要至少2个机构才能创建联邦学习项目")
            return None

        # 添加合作机构
        project_organs = [
            {
                "organId": organs[0].get('organId'),
                "participationIdentity": 1  # 发起方
            },
            {
                "organId": organs[1].get('organId'),
                "participationIdentity": 2  # 合作方
            }
        ]

        project_data = {
            "projectName": f"联邦LR项目_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "projectDesc": "两方合作进行联邦逻辑回归算法训练",
            "projectOrgans": project_organs
        }

        # 使用userId header
        headers = {"userId": str(self.user_id)} if self.user_id else {}

        result = self._make_request("POST", "/data/project/saveOrUpdateProject", project_data,
                                    use_json=True, extra_headers=headers)

        if result and result.get('code') == 0:
            project_id = result.get('result', {}).get('projectId')
            print(f"✅ 创建项目成功")
            print(f"   项目名称: {project_data['projectName']}")
            print(f"   项目ID: {project_id}")
            print(f"   合作机构: {len(project_organs)} 个")
            for org in project_organs:
                role = "发起方" if org['participationIdentity'] == 1 else "合作方"
                print(f"     - {organs[0].get('organName') if org['participationIdentity'] == 1 else organs[1].get('organName')} ({role})")
            return project_id
        else:
            print(f"❌ 创建项目失败: {result}")
            return None

    def get_model_components(self):
        """获取模型组件列表"""
        print("\n▶ 步骤 5: 获取可用的模型组件")
        print("-" * 70)

        result = self._make_request("GET", "/data/model/getModelComponent", {})

        if result and result.get('code') == 0:
            components = result.get('result', [])
            print(f"✅ 获取成功，共 {len(components)} 个组件")

            # 查找LR组件
            for comp in components[:10]:
                comp_name = comp.get('componentName', '')
                print(f"   - {comp_name} (Code: {comp.get('componentCode')})")
                if 'LR' in comp_name or '逻辑回归' in comp_name or 'Logistic' in comp_name:
                    print(f"     ✓ 找到LR组件")

            return components
        else:
            print(f"❌ 获取失败: {result}")
            return []

    def get_project_list(self):
        """获取项目列表"""
        print("\n▶ 查询项目列表")
        print("-" * 70)

        result = self._make_request("GET", "/data/project/getProjectList", {
            "pageNo": 1,
            "pageSize": 10
        })

        if result and result.get('code') == 0:
            projects = result.get('result', {}).get('list', [])
            print(f"✅ 获取成功，共 {len(projects)} 个项目")
            for i, proj in enumerate(projects[:5], 1):
                print(f"   {i}. {proj.get('projectName')} (ID: {proj.get('projectId')})")
                print(f"      状态: {proj.get('projectStatus')}, 类型: {proj.get('projectType')}")
            return projects
        else:
            print(f"❌ 获取失败: {result}")
            return []


def main():
    """主函数"""
    print("\n" + "="*70)
    print("联邦学习LR项目创建流程".center(70))
    print("="*70)

    client = FederatedLRClient()

    # 1. 登录
    if not client.login():
        print("\n❌ 登录失败，无法继续")
        return

    # 2. 获取机构列表
    organs = client.get_organs()
    if len(organs) < 2:
        print(f"\n⚠️  当前只有 {len(organs)} 个机构")
        print("   联邦学习需要至少2个机构")
        print("   但我们可以继续查看系统状态...")

    # 3. 获取资源列表
    resources = client.get_resources()

    # 4. 获取模型组件
    components = client.get_model_components()

    # 5. 创建联邦学习项目（如果有足够的机构）
    if len(organs) >= 2:
        project_id = client.create_project(organs, resources)

        if project_id:
            print(f"\n✅ 联邦学习项目创建成功！项目ID: {project_id}")
            print("\n💡 下一步操作:")
            print("   1. 通过Web界面访问项目详情")
            print("   2. 配置联邦LR模型参数")
            print("   3. 运行联邦学习任务")
            print(f"\n   Web界面地址: http://localhost:30811")
    else:
        print("\n⚠️  机构数量不足，无法创建联邦学习项目")

    # 6. 查询现有项目
    projects = client.get_project_list()

    print("\n" + "="*70)
    print("流程完成".center(70))
    print("="*70)
    print(f"\n📊 系统状态:")
    print(f"   - 机构数量: {len(organs)}")
    print(f"   - 资源数量: {len(resources)}")
    print(f"   - 项目数量: {len(projects)}")
    print(f"   - 模型组件: {len(components)}")


if __name__ == "__main__":
    main()
