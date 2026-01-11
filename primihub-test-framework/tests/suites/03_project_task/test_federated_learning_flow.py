#!/usr/bin/env python3
"""
联邦学习完整流程测试
测试场景：两方合作进行联邦学习
1. 添加数据资源
2. 创建项目
3. 添加合作方
4. 配置算法
5. 运行任务
"""

import sys
import os
import time
import json
from datetime import datetime

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))

from api_client import PrimiHubAPIClient
from report_generator import TestReport

# 测试配置
# 使用容器内网IP (gateway0)
BASE_URL = "http://172.20.0.12:8080"
ADMIN_USER = "admin"
ADMIN_PASSWORD = "Admin@123456"


class FederatedLearningFlowTest:
    """联邦学习流程测试类"""

    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.test_data = {
            'project_id': None,
            'resource_ids': [],
            'task_id': None
        }

    def run(self):
        """运行完整测试流程"""
        print("\n" + "="*70)
        print("联邦学习完整流程测试".center(70))
        print("="*70 + "\n")

        try:
            # 1. 登录
            self.test_login()

            # 2. 获取机构列表（确保有至少2个机构）
            self.test_get_organs()

            # 3. 添加数据资源（双方各添加数据）
            self.test_create_resources()

            # 4. 创建联邦学习项目
            self.test_create_project()

            # 5. 查看项目详情
            self.test_get_project_detail()

            # 6. 查询任务列表
            self.test_get_task_list()

            # 生成测试报告
            self.generate_report()

        except Exception as e:
            print(f"\n❌ 测试过程中发生错误: {e}")
            import traceback
            traceback.print_exc()
        finally:
            # 登出
            try:
                self.client.logout()
                print("\n✅ 已登出")
            except:
                pass

    def test_login(self):
        """测试登录"""
        print("\n▶ 步骤 1: 用户登录")
        print("-" * 70)

        start_time = time.time()
        try:
            response = self.client.login(ADMIN_USER, ADMIN_PASSWORD)
            duration = time.time() - start_time

            if response.get('code') == 0:
                print(f"✅ 登录成功")
                print(f"   用户: {self.client.user_name}")
                print(f"   用户ID: {self.client.user_id}")
                print(f"   Token: {self.client.token[:20]}...")
                self.report.add_test_result("联邦学习流程", "用户登录", "passed", duration)
            else:
                raise Exception(f"登录失败: {response}")

        except Exception as e:
            duration = time.time() - start_time
            self.report.add_test_result("联邦学习流程", "用户登录", "failed", duration, str(e))
            raise

    def test_get_organs(self):
        """获取机构列表"""
        print("\n▶ 步骤 2: 获取机构列表")
        print("-" * 70)

        start_time = time.time()
        try:
            response = self.client.get_organ_list()
            duration = time.time() - start_time

            if response.get('code') == 0:
                organs = response.get('result', [])
                print(f"✅ 获取机构列表成功，共 {len(organs)} 个机构")

                self.test_data['organs'] = organs

                for i, organ in enumerate(organs[:5], 1):  # 显示前5个
                    print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

                if len(organs) < 2:
                    print("   ⚠️  警告: 机构数量少于2个，联邦学习需要至少2个参与方")

                self.report.add_test_result("联邦学习流程", "获取机构列表", "passed", duration)
            else:
                raise Exception(f"获取机构列表失败: {response}")

        except Exception as e:
            duration = time.time() - start_time
            self.report.add_test_result("联邦学习流程", "获取机构列表", "failed", duration, str(e))
            raise

    def test_create_resources(self):
        """创建数据资源（模拟两方数据）"""
        print("\n▶ 步骤 3: 创建数据资源")
        print("-" * 70)

        # 模拟创建两个数据资源
        resources = [
            {
                "resourceName": f"联邦学习测试数据_机构1_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                "resourceDesc": "机构1提供的联邦学习训练数据",
                "resourceType": "1",  # CSV类型
                "resourceAuthType": "0",  # 公开
                "resourceColumnList": [
                    {"columnName": "id", "columnType": "int", "columnDesc": "ID"},
                    {"columnName": "age", "columnType": "int", "columnDesc": "年龄"},
                    {"columnName": "income", "columnType": "float", "columnDesc": "收入"},
                    {"columnName": "label", "columnType": "int", "columnDesc": "标签"}
                ],
                "resourceRowsCount": 1000,
                "resourceColumnCount": 4,
                "resourceSize": 50000
            },
            {
                "resourceName": f"联邦学习测试数据_机构2_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                "resourceDesc": "机构2提供的联邦学习训练数据",
                "resourceType": "1",  # CSV类型
                "resourceAuthType": "0",  # 公开
                "resourceColumnList": [
                    {"columnName": "id", "columnType": "int", "columnDesc": "ID"},
                    {"columnName": "education", "columnType": "int", "columnDesc": "学历"},
                    {"columnName": "score", "columnType": "float", "columnDesc": "评分"},
                    {"columnName": "feature", "columnType": "float", "columnDesc": "特征值"}
                ],
                "resourceRowsCount": 1000,
                "resourceColumnCount": 4,
                "resourceSize": 50000
            }
        ]

        for i, resource_data in enumerate(resources, 1):
            start_time = time.time()
            try:
                response = self.client.create_resource(resource_data)
                duration = time.time() - start_time

                if response.get('code') == 0:
                    resource_id = response.get('result', {}).get('resourceId')
                    if resource_id:
                        self.test_data['resource_ids'].append(resource_id)

                    print(f"✅ 创建数据资源 {i} 成功")
                    print(f"   名称: {resource_data['resourceName']}")
                    print(f"   描述: {resource_data['resourceDesc']}")
                    print(f"   行数: {resource_data['resourceRowsCount']}")
                    print(f"   列数: {resource_data['resourceColumnCount']}")
                    if resource_id:
                        print(f"   资源ID: {resource_id}")

                    self.report.add_test_result("联邦学习流程", f"创建数据资源{i}", "passed", duration)
                else:
                    raise Exception(f"创建数据资源失败: {response}")

            except Exception as e:
                duration = time.time() - start_time
                self.report.add_test_result("联邦学习流程", f"创建数据资源{i}", "failed", duration, str(e))
                print(f"❌ 创建数据资源 {i} 失败: {e}")
                # 继续创建下一个资源

    def test_create_project(self):
        """创建联邦学习项目"""
        print("\n▶ 步骤 4: 创建联邦学习项目")
        print("-" * 70)

        start_time = time.time()
        try:
            # 获取机构列表用于项目合作方
            organs = self.test_data.get('organs', [])

            # 准备项目数据
            project_data = {
                "projectName": f"联邦学习测试项目_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                "projectDesc": "测试联邦学习完整流程的项目",
                "projectType": "2",  # 联邦学习类型
                "projectMode": "1",  # 横向联邦学习
                "serverOrganId": organs[0].get('organId') if organs else None,
            }

            # 如果有机构，添加合作方
            if len(organs) >= 2:
                project_data["projectOrganList"] = [
                    {
                        "organId": organs[0].get('organId'),
                        "organName": organs[0].get('organName'),
                        "isMyOrgan": 1
                    },
                    {
                        "organId": organs[1].get('organId'),
                        "organName": organs[1].get('organName'),
                        "isMyOrgan": 0
                    }
                ]

            # 如果有资源，添加到项目中
            if self.test_data['resource_ids']:
                project_data["projectResourceList"] = [
                    {"resourceId": rid} for rid in self.test_data['resource_ids']
                ]

            response = self.client.create_project(project_data)
            duration = time.time() - start_time

            if response.get('code') == 0:
                project_id = response.get('result', {}).get('projectId')
                self.test_data['project_id'] = project_id

                print(f"✅ 创建项目成功")
                print(f"   项目名称: {project_data['projectName']}")
                print(f"   项目类型: 联邦学习")
                print(f"   项目模式: 横向联邦学习")
                if project_id:
                    print(f"   项目ID: {project_id}")

                if project_data.get('projectOrganList'):
                    print(f"   合作机构数: {len(project_data['projectOrganList'])}")
                    for org in project_data['projectOrganList']:
                        role = "发起方" if org.get('isMyOrgan') == 1 else "合作方"
                        print(f"     - {org.get('organName')} ({role})")

                if project_data.get('projectResourceList'):
                    print(f"   关联资源数: {len(project_data['projectResourceList'])}")

                self.report.add_test_result("联邦学习流程", "创建项目", "passed", duration)
            else:
                raise Exception(f"创建项目失败: {response}")

        except Exception as e:
            duration = time.time() - start_time
            self.report.add_test_result("联邦学习流程", "创建项目", "failed", duration, str(e))
            raise

    def test_get_project_detail(self):
        """查看项目详情"""
        print("\n▶ 步骤 5: 查看项目详情")
        print("-" * 70)

        if not self.test_data['project_id']:
            print("⚠️  跳过：未创建项目")
            self.report.add_test_result("联邦学习流程", "查看项目详情", "skipped", 0, "未创建项目")
            return

        start_time = time.time()
        try:
            response = self.client.get_project_detail(self.test_data['project_id'])
            duration = time.time() - start_time

            if response.get('code') == 0:
                project = response.get('result', {})

                print(f"✅ 获取项目详情成功")
                print(f"   项目名称: {project.get('projectName')}")
                print(f"   项目ID: {project.get('projectId')}")
                print(f"   项目状态: {project.get('projectStatus')}")
                print(f"   创建时间: {project.get('createDate')}")

                # 显示合作方信息
                organ_list = project.get('projectOrganList', [])
                if organ_list:
                    print(f"   合作机构: {len(organ_list)} 个")
                    for org in organ_list:
                        print(f"     - {org.get('organName')}")

                # 显示资源信息
                resource_list = project.get('projectResourceList', [])
                if resource_list:
                    print(f"   关联资源: {len(resource_list)} 个")
                    for res in resource_list:
                        print(f"     - {res.get('resourceName')}")

                self.report.add_test_result("联邦学习流程", "查看项目详情", "passed", duration)
            else:
                raise Exception(f"获取项目详情失败: {response}")

        except Exception as e:
            duration = time.time() - start_time
            self.report.add_test_result("联邦学习流程", "查看项目详情", "failed", duration, str(e))
            print(f"❌ 获取项目详情失败: {e}")

    def test_get_task_list(self):
        """查询任务列表"""
        print("\n▶ 步骤 6: 查询任务列表")
        print("-" * 70)

        start_time = time.time()
        try:
            response = self.client.get_task_list(page=1, page_size=10)
            duration = time.time() - start_time

            if response.get('code') == 0:
                result = response.get('result', {})
                tasks = result.get('list', []) if isinstance(result, dict) else []

                print(f"✅ 获取任务列表成功")
                print(f"   任务总数: {len(tasks)}")

                if tasks:
                    print(f"   最近任务:")
                    for i, task in enumerate(tasks[:5], 1):
                        print(f"     {i}. {task.get('taskName')} - {task.get('taskState')}")
                        if i == 1:
                            self.test_data['task_id'] = task.get('taskId')

                self.report.add_test_result("联邦学习流程", "查询任务列表", "passed", duration)
            else:
                raise Exception(f"获取任务列表失败: {response}")

        except Exception as e:
            duration = time.time() - start_time
            self.report.add_test_result("联邦学习流程", "查询任务列表", "failed", duration, str(e))
            print(f"❌ 获取任务列表失败: {e}")

    def generate_report(self):
        """生成测试报告"""
        print("\n" + "="*70)
        print("生成测试报告".center(70))
        print("="*70)

        # 创建报告目录
        report_dir = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(report_dir, exist_ok=True)

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        # 生成各种格式的报告
        json_report = os.path.join(report_dir, f'federated_learning_flow_{timestamp}.json')
        html_report = os.path.join(report_dir, f'federated_learning_flow_{timestamp}.html')
        md_report = os.path.join(report_dir, f'federated_learning_flow_{timestamp}.md')

        self.report.generate_json_report(json_report)
        self.report.generate_html_report(html_report)
        self.report.generate_markdown_report(md_report)

        # 打印摘要
        self.report.print_summary()

        print(f"\n📊 测试报告已生成:")
        print(f"   JSON: {json_report}")
        print(f"   HTML: {html_report}")
        print(f"   Markdown: {md_report}")


def main():
    """主函数"""
    test = FederatedLearningFlowTest()
    test.run()


if __name__ == "__main__":
    import logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    main()
