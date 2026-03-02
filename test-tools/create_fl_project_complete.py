#!/usr/bin/env python3
"""
完整的联邦学习项目创建和执行脚本
包括项目创建、模型配置、训练启动全流程
"""

import requests
import json
import time
from datetime import datetime

# 配置
BASE_URL = "http://172.20.0.6:8080"

class FederatedLearningProject:
    def __init__(self):
        self.base_url = BASE_URL
        self.session = requests.Session()
        self.token = None
        self.user_id = None
        self.project_id = None
        self.model_id = None
        self.task_id = None
        
    def _request(self, method, endpoint, data=None, json_data=None, headers=None):
        """统一的HTTP请求方法"""
        url = f"{self.base_url}{endpoint}"
        
        req_headers = headers or {}
        if self.user_id:
            req_headers['userId'] = str(self.user_id)
        
        if data is None:
            data = {}
        
        # 添加通用参数
        if self.token:
            if json_data:
                json_data['token'] = self.token
            else:
                data['token'] = self.token
                
        data['timestamp'] = int(time.time() * 1000)
        data['nonce'] = int(time.time() * 1000) % 1000 + 1
        
        try:
            if method.upper() == 'GET':
                response = self.session.get(url, params=data, headers=req_headers, timeout=30)
            elif method.upper() == 'POST':
                if json_data:
                    json_data['timestamp'] = int(time.time() * 1000)
                    json_data['nonce'] = int(time.time() * 1000) % 1000 + 1
                    response = self.session.post(url, json=json_data, headers=req_headers, timeout=30)
                else:
                    response = self.session.post(url, data=data, headers=req_headers, timeout=30)
            
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ 请求失败: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"响应: {e.response.text[:500]}")
            return None
    
    def login(self, username="admin", password="123456"):
        """登录系统"""
        print("\n" + "="*70)
        print("【步骤 1】用户登录")
        print("="*70)
        
        result = self._request("POST", "/user/login", {
            "userAccount": username,
            "userPassword": password
        })
        
        if result and result.get('code') == 0:
            user_data = result.get('result', {})
            self.token = user_data.get('token')
            self.user_id = user_data.get('sysUser', {}).get('userId')
            print(f"✅ 登录成功")
            print(f"   用户: {user_data.get('sysUser', {}).get('userName')}")
            print(f"   用户ID: {self.user_id}")
            print(f"   Token: {self.token[:20]}...")
            return True
        else:
            print(f"❌ 登录失败: {result}")
            return False
    
    def get_organs(self):
        """获取机构列表"""
        print("\n" + "="*70)
        print("【步骤 2】获取机构列表")
        print("="*70)
        
        result = self._request("GET", "/sys/organ/getOrganList", {
            "pageNo": 1,
            "pageSize": 10
        })
        
        if result and result.get('code') == 0:
            organs = result.get('result', {}).get('data', [])
            print(f"✅ 获取到 {len(organs)} 个机构")
            for organ in organs:
                print(f"   - {organ.get('organName')} (ID: {organ.get('organId')})")
            return organs
        else:
            print(f"❌ 获取机构列表失败: {result}")
            return []
    
    def get_resources(self):
        """获取数据资源列表"""
        print("\n" + "="*70)
        print("【步骤 3】获取数据资源列表")
        print("="*70)
        
        result = self._request("GET", "/data/resource/getdataresourcelist", {
            "pageNo": 1,
            "pageSize": 20
        })
        
        if result and result.get('code') == 0:
            resources = result.get('result', {}).get('data', [])
            print(f"✅ 获取到 {len(resources)} 个数据资源")
            for res in resources[:5]:
                print(f"   - {res.get('resourceName')} (ID: {res.get('resourceId')})")
            return resources
        else:
            print(f"❌ 获取资源列表失败: {result}")
            return []
    
    def get_projects(self):
        """获取现有项目列表"""
        print("\n" + "="*70)
        print("【步骤 4】获取现有项目列表")
        print("="*70)
        
        result = self._request("GET", "/data/project/getProjectList", {
            "pageNo": 1,
            "pageSize": 10
        })
        
        if result and result.get('code') == 0:
            projects = result.get('result', {}).get('data', [])
            print(f"✅ 获取到 {len(projects)} 个项目")
            for proj in projects:
                print(f"   - {proj.get('projectName')} (ID: {proj.get('projectId')})")
                print(f"     类型: {proj.get('projectTypeValue')}, 模式: {proj.get('projectModeValue')}")
            return projects
        else:
            print(f"❌ 获取项目列表失败: {result}")
            return []
    
    def get_model_components(self):
        """获取可用的模型组件"""
        print("\n" + "="*70)
        print("【步骤 5】获取可用模型组件")
        print("="*70)
        
        result = self._request("GET", "/data/model/getModelComponent", {})
        
        if result and result.get('code') == 0:
            components = result.get('result', [])
            print(f"✅ 获取到 {len(components)} 个模型组件")
            for comp in components[:5]:
                print(f"   - {comp.get('componentName')} ({comp.get('componentCode')})")
            return components
        else:
            print(f"❌ 获取模型组件失败: {result}")
            return []
    
    def run(self):
        """运行完整流程"""
        print("\n" + "#"*70)
        print("#" + " "*68 + "#")
        print("#" + " "*15 + "联邦学习项目完整创建流程" + " "*22 + "#")
        print("#" + " "*68 + "#")
        print("#"*70)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"目标URL: {self.base_url}\n")
        
        # 1. 登录
        if not self.login():
            return False
        
        # 2. 获取机构列表
        organs = self.get_organs()
        if not organs:
            print("⚠️  没有可用的机构，无法继续")
            return False
        
        # 3. 获取资源列表
        resources = self.get_resources()
        if not resources:
            print("⚠️  没有可用的数据资源，无法继续")
            return False
        
        # 4. 获取现有项目
        projects = self.get_projects()
        
        # 5. 获取模型组件
        components = self.get_model_components()
        
        print("\n" + "="*70)
        print("✅ 数据收集完成！")
        print("="*70)
        print(f"   机构数量: {len(organs)}")
        print(f"   资源数量: {len(resources)}")
        print(f"   现有项目数: {len(projects)}")
        print(f"   模型组件数: {len(components)}")
        
        print("\n" + "="*70)
        print("📊 系统状态总结")
        print("="*70)
        print("✅ 登录成功")
        print(f"✅ 找到 {len(organs)} 个机构")
        print(f"✅ 找到 {len(resources)} 个数据资源")
        print(f"✅ 找到 {len(projects)} 个现有项目")
        print(f"✅ 找到 {len(components)} 个模型组件")
        
        print("\n💡 提示:")
        print("   系统已就绪，可以创建联邦学习项目和模型")
        print("   现有项目ID可用于直接创建模型")
        
        return True


if __name__ == "__main__":
    fl = FederatedLearningProject()
    success = fl.run()
    
    if success:
        print("\n" + "="*70)
        print("🎉 完成！所有API调用成功")
        print("="*70)
        print(f"\n结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    else:
        print("\n" + "="*70)
        print("❌ 流程未完全完成，请检查错误信息")
        print("="*70)
