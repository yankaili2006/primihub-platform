#!/usr/bin/env python3
"""
API客户端使用示例
演示如何使用token调用各种API
"""

import sys
import os

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient

# ============================================
# 配置区域
# ============================================
BASE_URL = "http://172.20.0.12:8080"

# 请在这里填入你的token
# 从浏览器开发者工具 -> Network -> Headers -> token 获取
TOKEN = ""


def example_with_token():
    """使用token的示例"""

    if not TOKEN:
        print("=" * 70)
        print("请先设置TOKEN！")
        print("=" * 70)
        print("\n获取Token的步骤：")
        print("1. 在浏览器中登录PrimiHub")
        print("2. 按F12打开开发者工具")
        print("3. 切换到Network标签")
        print("4. 刷新页面")
        print("5. 点击任意请求，找到Headers中的token字段")
        print("6. 复制token值到此脚本的TOKEN变量")
        print("\n然后重新运行此脚本。\n")
        return

    # 创建API客户端
    client = PrimiHubAPIClient(BASE_URL)

    # 设置token
    client.token = TOKEN
    client.user_id = 1
    client.user_name = "admin"

    print("\n" + "=" * 70)
    print("PrimiHub API客户端使用示例")
    print("=" * 70)

    # 1. 验证token
    print("\n【1】验证Token有效性...")
    try:
        response = client.get_user_list(page=1, page_size=1)
        if response.get('code') == 0:
            print("✅ Token有效！")
            print(f"   当前用户: {client.user_name}")
        else:
            print(f"❌ Token验证失败: {response.get('msg')}")
            return
    except Exception as e:
        print(f"❌ 错误: {e}")
        return

    # 2. 获取机构列表
    print("\n【2】获取机构列表...")
    try:
        response = client.get_organ_list()
        if response.get('code') == 0:
            organs = response.get('result', [])
            print(f"✅ 成功获取 {len(organs)} 个机构")
            for i, organ in enumerate(organs[:3], 1):
                print(f"   {i}. {organ.get('organName')} (ID: {organ.get('organId')})")
        else:
            print(f"❌ 失败: {response.get('msg')}")
    except Exception as e:
        print(f"❌ 错误: {e}")

    # 3. 获取资源列表
    print("\n【3】获取数据资源列表...")
    try:
        response = client.get_resource_list(page=1, page_size=5)
        if response.get('code') == 0:
            result = response.get('result', {})
            resources = result.get('list', []) if isinstance(result, dict) else []
            print(f"✅ 成功获取 {len(resources)} 个资源")
            for i, res in enumerate(resources, 1):
                print(f"   {i}. {res.get('resourceName')} (ID: {res.get('resourceId')})")
        else:
            print(f"❌ 失败: {response.get('msg')}")
    except Exception as e:
        print(f"❌ 错误: {e}")

    # 4. 获取项目列表
    print("\n【4】获取项目列表...")
    try:
        response = client.get_project_list(page=1, page_size=5)
        if response.get('code') == 0:
            result = response.get('result', {})
            projects = result.get('list', []) if isinstance(result, dict) else []
            print(f"✅ 成功获取 {len(projects)} 个项目")
            for i, proj in enumerate(projects, 1):
                print(f"   {i}. {proj.get('projectName')} (ID: {proj.get('projectId')})")
        else:
            print(f"❌ 失败: {response.get('msg')}")
    except Exception as e:
        print(f"❌ 错误: {e}")

    # 5. 获取任务列表
    print("\n【5】获取任务列表...")
    try:
        response = client.get_task_list(page=1, page_size=5)
        if response.get('code') == 0:
            result = response.get('result', {})
            tasks = result.get('list', []) if isinstance(result, dict) else []
            print(f"✅ 成功获取 {len(tasks)} 个任务")
            for i, task in enumerate(tasks, 1):
                print(f"   {i}. {task.get('taskName')} - 状态: {task.get('taskState')}")
        else:
            print(f"❌ 失败: {response.get('msg')}")
    except Exception as e:
        print(f"❌ 错误: {e}")

    # 6. 健康检查
    print("\n【6】系统健康检查...")
    try:
        response = client.health_check()
        if response.get('code') == 0:
            print(f"✅ 系统正常")
        else:
            print(f"⚠️  系统状态: {response.get('msg')}")
    except Exception as e:
        print(f"❌ 错误: {e}")

    print("\n" + "=" * 70)
    print("测试完成！")
    print("=" * 70 + "\n")


def show_api_reference():
    """显示API参考"""
    print("\n" + "=" * 70)
    print("API客户端功能列表")
    print("=" * 70)

    print("\n【认证相关】")
    print("  - login(username, password)              # 用户登录")
    print("  - logout()                               # 用户登出")

    print("\n【用户管理】")
    print("  - create_user(user_data)                 # 创建用户")
    print("  - get_user_list(page, page_size)         # 获取用户列表")
    print("  - get_user_by_account(user_account)      # 查询用户")
    print("  - update_user(user_data)                 # 更新用户")
    print("  - delete_user(user_ids)                  # 删除用户")
    print("  - freeze_user(user_id)                   # 冻结用户")
    print("  - unfreeze_user(user_id)                 # 解冻用户")

    print("\n【机构管理】")
    print("  - create_organ(organ_data)               # 创建机构")
    print("  - get_organ_list()                       # 获取机构列表")

    print("\n【资源管理】")
    print("  - create_resource(resource_data)         # 创建资源")
    print("  - get_resource_list(page, page_size)     # 获取资源列表")

    print("\n【项目管理】")
    print("  - create_project(project_data)           # 创建项目")
    print("  - get_project_list(page, page_size)      # 获取项目列表")
    print("  - get_project_detail(project_id)         # 获取项目详情")

    print("\n【任务管理】")
    print("  - get_task_list(page, page_size)         # 获取任务列表")
    print("  - get_task_detail(task_id)               # 获取任务详情")

    print("\n【隐私计算】")
    print("  - create_psi_task(psi_data)              # 创建PSI任务")
    print("  - get_psi_task_list(page, page_size)     # 获取PSI任务列表")
    print("  - create_pir_task(pir_data)              # 创建PIR任务")
    print("  - get_pir_task_list(page, page_size)     # 获取PIR任务列表")

    print("\n【模型管理】")
    print("  - create_model(model_data)               # 创建模型")
    print("  - get_model_list(page, page_size)        # 获取模型列表")

    print("\n【系统功能】")
    print("  - create_whitelist(whitelist_data)       # 创建白名单")
    print("  - get_whitelist_list(page, page_size)    # 获取白名单列表")
    print("  - health_check()                         # 健康检查")

    print("\n" + "=" * 70 + "\n")


def main():
    """主函数"""
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == '--help':
        show_api_reference()
    else:
        example_with_token()


if __name__ == "__main__":
    main()
