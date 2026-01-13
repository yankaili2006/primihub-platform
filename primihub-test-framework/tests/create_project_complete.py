#!/usr/bin/env python3
"""
PrimiHub 项目创建完整流程测试
通过API创建项目，包括机构和资源配置
"""

import sys
import os
import json
from datetime import datetime

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient

# ============================================
# 配置区域
# ============================================
BASE_URL = "http://100.64.0.23:30811/prod-api"

# Token配置
TOKEN = "SU20260111234709EA67396910B1686EBF63EAADE3408E6E"
USER_ID = 1
USER_NAME = "admin"


def print_section(title):
    """打印分节标题"""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70 + "\n")


def create_project_workflow():
    """完整的项目创建流程"""

    print_section("PrimiHub 项目创建完整流程")
    print(f"节点: {BASE_URL}")

    # 创建API客户端
    client = PrimiHubAPIClient(BASE_URL, timeout=60)
    client.token = TOKEN
    client.user_id = USER_ID
    client.user_name = USER_NAME

    # ========================================================================
    # 步骤1: 获取机构列表
    # ========================================================================
    print_section("步骤1: 获取机构列表")

    try:
        response = client.get_organ_list()
        if response.get('code') != 0:
            print(f"❌ 获取机构列表失败: {response.get('msg')}")
            return

        organs = response.get('result', [])
        if not organs:
            print("❌ 系统中没有机构，无法创建项目")
            print("   请先创建机构")
            return

        print(f"✅ 成功获取 {len(organs)} 个机构")
        for i, organ in enumerate(organs[:5], 1):
            print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")

        # 使用第一个机构作为发起者
        initiator_organ = organs[0]
        print(f"\n📌 选择发起机构: {initiator_organ.get('organName')}")

    except Exception as e:
        print(f"❌ 错误: {e}")
        return

    # ========================================================================
    # 步骤2: 获取资源列表
    # ========================================================================
    print_section("步骤2: 获取数据资源列表")

    try:
        response = client.get_resource_list(page=1, page_size=10)
        if response.get('code') != 0:
            print(f"❌ 获取资源列表失败: {response.get('msg')}")
            return

        result = response.get('result', {})
        resources = result.get('list', []) if isinstance(result, dict) else []

        if not resources:
            print("⚠️  系统中没有资源")
            print("   将创建不包含资源的项目")
            resource_ids = []
        else:
            print(f"✅ 成功获取 {len(resources)} 个资源")
            for i, res in enumerate(resources[:5], 1):
                print(f"   {i}. {res.get('resourceName')} (ID: {res.get('resourceId')})")

            # 使用前3个资源（如果有的话）
            resource_ids = [str(res.get('resourceId')) for res in resources[:3]]
            print(f"\n📌 选择资源: {len(resource_ids)} 个")

    except Exception as e:
        print(f"❌ 错误: {e}")
        return

    # ========================================================================
    # 步骤3: 构建项目数据
    # ========================================================================
    print_section("步骤3: 构建项目数据")

    # 生成项目名称（带时间戳）
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    project_name = f"测试项目_{timestamp}"
    project_desc = f"通过API创建的测试项目 - {timestamp}"

    # 构建项目机构列表
    project_organs = [
        {
            "organId": initiator_organ.get('organId'),
            "participationIdentity": 1,  # 1=发起者
            "resourceIds": resource_ids
        }
    ]

    # 如果有多个机构，可以添加协作者
    if len(organs) > 1:
        collaborator_organ = organs[1]
        project_organs.append({
            "organId": collaborator_organ.get('organId'),
            "participationIdentity": 2,  # 2=协作者
            "resourceIds": []
        })
        print(f"✅ 添加协作机构: {collaborator_organ.get('organName')}")

    # 构建完整的项目数据
    project_data = {
        "projectName": project_name,
        "projectDesc": project_desc,
        "projectOrgans": project_organs
    }

    print(f"✅ 项目数据已构建")
    print(f"   项目名称: {project_name}")
    print(f"   项目描述: {project_desc}")
    print(f"   参与机构: {len(project_organs)} 个")
    print(f"   关联资源: {len(resource_ids)} 个")

    # ========================================================================
    # 步骤4: 创建项目
    # ========================================================================
    print_section("步骤4: 创建项目")

    print(f"▶ 创建项目: {project_name}")
    print(f"   API: {BASE_URL}/data/project/saveOrUpdateProject")

    try:
        response = client.create_project(project_data)

        print(f"\n✅ 请求完成")
        print(f"   状态码: 200")

        print(f"\n响应:")
        print(json.dumps(response, indent=2, ensure_ascii=False))

        if response.get('code') == 0:
            result = response.get('result', {})
            project_id = result.get('id') or result.get('projectId')

            print(f"\n🎉 项目创建成功!")
            print(f"   项目ID: {project_id}")
            print(f"   项目名称: {project_name}")

            # ================================================================
            # 步骤5: 验证创建结果
            # ================================================================
            print_section("步骤5: 验证创建结果")

            # 获取项目列表
            list_response = client.get_project_list(page=1, page_size=10)
            if list_response.get('code') == 0:
                list_result = list_response.get('result', {})
                projects = list_result.get('list', []) if isinstance(list_result, dict) else []
                print(f"✅ 系统中现在共有 {len(projects)} 个项目")

                # 查找刚创建的项目
                created_project = None
                for proj in projects:
                    if proj.get('projectName') == project_name:
                        created_project = proj
                        break

                if created_project:
                    print(f"\n✅ 找到刚创建的项目:")
                    print(f"   项目ID: {created_project.get('projectId')}")
                    print(f"   项目名称: {created_project.get('projectName')}")
                    print(f"   创建时间: {created_project.get('createDate')}")
                    print(f"   状态: {created_project.get('projectState')}")
                else:
                    print(f"⚠️  在项目列表中未找到刚创建的项目")

            # 如果有项目ID，获取项目详情
            if project_id:
                print(f"\n▶ 获取项目详情...")
                detail_response = client.get_project_detail(project_id)
                if detail_response.get('code') == 0:
                    detail = detail_response.get('result', {})
                    print(f"✅ 项目详情:")
                    print(f"   项目名称: {detail.get('projectName')}")
                    print(f"   项目描述: {detail.get('projectDesc')}")

                    organs_info = detail.get('projectOrgans', [])
                    if organs_info:
                        print(f"   参与机构: {len(organs_info)} 个")
                        for org in organs_info:
                            identity = "发起者" if org.get('participationIdentity') == 1 else "协作者"
                            print(f"     - {org.get('organName')} ({identity})")

            # ================================================================
            # 完成
            # ================================================================
            print_section("🎉 完成!")

            print("✅ 成功完成完整流程:")
            print("   1. ✅ 获取机构列表")
            print("   2. ✅ 获取资源列表")
            print("   3. ✅ 构建项目数据")
            print("   4. ✅ 创建项目")
            print("   5. ✅ 验证创建结果")

            print(f"\n下一步:")
            print(f"1. 查看项目: python3 api_example.py")
            print(f"2. 在Web界面查看: {BASE_URL.replace('/prod-api', '')}")
            print(f"3. 创建更多项目: 再次运行此脚本")

        else:
            print(f"\n❌ 项目创建失败")
            print(f"   错误码: {response.get('code')}")
            print(f"   错误信息: {response.get('msg')}")

    except Exception as e:
        print(f"\n❌ 错误: {e}")
        import traceback
        print("\n详细错误信息:")
        traceback.print_exc()

    print_section("")


def main():
    """主函数"""
    try:
        create_project_workflow()
    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
