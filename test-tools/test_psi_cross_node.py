#!/usr/bin/env python3
"""
PSI跨节点测试脚本
使用内置的测试数据集验证跨机构隐私求交功能
"""
import requests
import time
import json
import sys
from datetime import datetime

BASE_URL = "http://172.23.0.15:8080"

def login():
    """登录获取token - 使用特殊方法绕过token验证问题"""
    print("\n[步骤1] 尝试登录系统...")

    # 方法1: 标准POST请求
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }

    try:
        response = requests.post(f"{BASE_URL}/user/login", data=data, timeout=10)
        result = response.json()

        if result.get('code') == 0:
            user_data = result['result']
            token = user_data.get('token')
            user_id = user_data.get('sysUser', {}).get('userId')
            print(f"✓ 登录成功 - 用户ID: {user_id}")
            return token, user_id
        else:
            print(f"✗ 登录失败: {result.get('msg')}")
            print(f"  错误码: {result.get('code')}")

            # 如果是token参数问题，提供解决建议
            if "token" in result.get('msg', '').lower():
                print("\n⚠ 检测到登录API的token参数问题")
                print("  建议: 联系管理员检查Gateway配置，登录接口不应要求token参数")
                print("  临时方案: 可以尝试直接访问application服务（如果有端口映射）")

            return None, None

    except Exception as e:
        print(f"✗ 登录异常: {e}")
        return None, None

def query_datasets(token, user_id):
    """查询可用的数据集"""
    print("\n[步骤2] 查询已注册的数据集...")

    headers = {"token": token, "userId": str(user_id)}
    params = {
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }

    try:
        # 尝试获取数据集列表
        response = requests.get(
            f"{BASE_URL}/data/dataset/getDatasetList",
            params=params,
            headers=headers,
            timeout=10
        )

        if response.status_code == 200:
            result = response.json()
            if result.get('code') == 0:
                datasets = result.get('result', {}).get('data', [])
                print(f"✓ 找到 {len(datasets)} 个数据集")

                # 查找跨节点的数据集
                node0_datasets = []
                node1_datasets = []

                for ds in datasets:
                    dataset_id = ds.get('id', '')
                    dataset_name = ds.get('name', '')
                    # 这里需要根据实际API返回的字段判断节点位置
                    print(f"  - {dataset_name} (ID: {dataset_id[:30]}...)")

                return datasets

        print(f"✗ 查询失败: HTTP {response.status_code}")
        return []

    except Exception as e:
        print(f"✗ 查询异常: {e}")
        return []

def create_psi_with_builtin_datasets(token, user_id):
    """
    使用内置测试数据集创建PSI任务

    注意: 这需要正确配置资源ID映射
    - 资源ID应该指向不同节点的数据集
    - node0: psi_client_data
    - node1: psi_server_data
    """
    print("\n[步骤3] 创建PSI跨节点测试任务...")

    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

    # 这里使用资源ID，但需要确保它们指向不同节点
    # 如果资源ID 3和4仍然都在node0，任务会失败
    psi_params = {
        "taskName": f"PSI_CrossNode_Test_{timestamp_str}",
        "taskDesc": "跨节点PSI测试 - 使用内置测试数据集",
        "projectId": "3",

        # 发起方（应该在node0）
        "ownOrganId": "000000000000000000000000test0001",
        "ownResourceId": "3",  # 需要确保这个资源在node0
        "ownKeyword": "id",    # 内置测试数据使用'id'字段

        # 协作方（应该在node1）
        "otherOrganId": "000000000000000000000000test0002",
        "otherResourceId": "4",  # 需要确保这个资源在node1
        "otherKeyword": "id",

        # 结果配置
        "resultName": f"psi_cross_node_result_{timestamp_str}",
        "resultOrganIds": "000000000000000000000000test0001",
        "outputContent": "0",
        "outputNoRepeat": "1",
        "outputFilePathType": "0",

        # 用户信息
        "userId": str(user_id),

        # PSI算法: DH
        "tag": "0",
        "psiTag": "0",

        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }

    headers = {"token": token, "userId": str(user_id)}

    try:
        response = requests.post(
            f"{BASE_URL}/psi/saveDataPsi",
            params=psi_params,
            headers=headers,
            timeout=30
        )

        result = response.json()
        print(f"\nAPI响应: code={result.get('code')}, msg={result.get('msg')}")

        if result.get('code') == 0:
            psi_result = result.get('result', {})
            task = psi_result.get('dataPsiTask', {})
            task_id = task.get('taskId') or task.get('id')

            print("\n" + "=" * 70)
            print("✓ PSI任务创建成功!")
            print("=" * 70)
            print(f"任务ID: {task_id}")
            print(f"任务状态: {task.get('taskState')} (0=待执行, 1=执行中, 2=成功, 3=失败)")
            print("=" * 70)

            return task_id
        else:
            print("\n" + "=" * 70)
            print("✗ PSI任务创建失败")
            print("=" * 70)
            print(f"错误信息: {result.get('msg')}")
            print(f"错误码: {result.get('code')}")
            print("\n完整响应:")
            print(json.dumps(result, indent=2, ensure_ascii=False))
            print("=" * 70)

            # 提供诊断建议
            if "resource" in result.get('msg', '').lower():
                print("\n⚠ 可能的问题:")
                print("  1. 资源ID 3或4不存在")
                print("  2. 资源未正确配置到不同节点")
                print("  3. 资源状态不是'上线'状态")

            return None

    except Exception as e:
        print(f"\n✗ 创建任务异常: {e}")
        return None

def monitor_task(token, user_id, task_id, max_wait=60):
    """监控任务执行状态"""
    if not task_id:
        return False

    print(f"\n[步骤4] 监控任务执行 (最多等待{max_wait}秒)...")

    headers = {"token": token, "userId": str(user_id)}
    state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}
    start = time.time()

    while time.time() - start < max_wait:
        try:
            params = {
                "psiTaskId": task_id,
                "token": token,
                "timestamp": int(time.time() * 1000),
                "nonce": 123
            }

            response = requests.get(
                f"{BASE_URL}/psi/getPsiTaskDetails",
                params=params,
                headers=headers,
                timeout=10
            )

            result = response.json()
            if result.get('code') == 0:
                task = result.get('result', {})
                state = task.get('taskState', -1)
                state_text = state_map.get(state, f"未知({state})")
                elapsed = int(time.time() - start)

                print(f"  [{elapsed:3d}s] 状态: {state_text}", end="\r")

                if state == 2:
                    print()
                    print("\n" + "=" * 70)
                    print("✓ PSI任务执行成功!")
                    print("=" * 70)
                    print(f"交集结果行数: {task.get('fileRows', 0)}")
                    print(f"结果文件: {task.get('resultName', 'N/A')}")
                    print("=" * 70)
                    return True

                elif state == 3:
                    print()
                    print("\n" + "=" * 70)
                    print("✗ PSI任务执行失败")
                    print("=" * 70)
                    print(f"错误信息: {task.get('taskErrorMsg', '无详细错误信息')}")
                    print("\n完整任务详情:")
                    print(json.dumps(task, indent=2, ensure_ascii=False))
                    print("=" * 70)

                    # 提供诊断建议
                    print("\n⚠ 失败原因分析:")
                    print("  最可能的原因: 资源ID 3和4对应的数据集都在同一个节点上")
                    print("  解决方案:")
                    print("    1. 检查数据库: SELECT resource_id, file_path FROM privacy.data_resource WHERE resource_id IN (3,4)")
                    print("    2. 确保资源3在node0，资源4在node1")
                    print("    3. 或者使用已知的跨节点数据集ID")
                    print("\n  查看详细分析报告: PSI_FAILURE_ANALYSIS.md")

                    return False

        except Exception as e:
            print(f"\n  查询异常: {e}")

        time.sleep(3)

    print()
    print(f"\n⚠ 任务监控超时({max_wait}秒)，任务可能仍在执行中")
    return None

def print_diagnostic_info():
    """打印诊断信息"""
    print("\n" + "=" * 70)
    print("诊断信息")
    print("=" * 70)
    print("\n当前配置:")
    print(f"  Gateway地址: {BASE_URL}")
    print(f"  项目ID: 3")
    print(f"  发起方机构: 000000000000000000000000test0001")
    print(f"  协作方机构: 000000000000000000000000test0002")
    print(f"  发起方资源ID: 3")
    print(f"  协作方资源ID: 4")

    print("\n预期配置:")
    print("  ✓ node0应有: psi_client_data (data/client_e.csv)")
    print("  ✓ node1应有: psi_server_data (data/server_e.csv)")
    print("  ✓ 资源ID 3应映射到node0的数据集")
    print("  ✓ 资源ID 4应映射到node1的数据集")

    print("\n验证命令:")
    print("  docker exec primihub-node0 ls -la /app/data/client_e.csv")
    print("  docker exec primihub-node1 ls -la /app/data/server_e.csv")
    print("  docker logs primihub-node0 | grep ERROR")

    print("\n相关文档:")
    print("  - PSI_FAILURE_ANALYSIS.md (详细问题分析)")
    print("  - debug_psi_cross_organ.py (诊断脚本)")
    print("=" * 70)

def main():
    print("=" * 70)
    print("PSI跨节点测试")
    print("=" * 70)

    # 登录
    token, user_id = login()
    if not token:
        print("\n✗ 无法登录，测试终止")
        print("\n可能的原因:")
        print("  1. Gateway配置问题（登录接口要求token参数）")
        print("  2. 网络连接问题")
        print("  3. 服务未正常启动")
        sys.exit(1)

    # 查询数据集（可选）
    # datasets = query_datasets(token, user_id)

    # 创建PSI任务
    task_id = create_psi_with_builtin_datasets(token, user_id)

    # 监控任务执行
    if task_id:
        success = monitor_task(token, user_id, task_id, max_wait=60)

        if success:
            print("\n🎉 测试成功! PSI跨节点任务正常执行")
        elif success is False:
            print("\n❌ 测试失败! 请查看上述错误信息和诊断建议")
        else:
            print("\n⏱ 测试超时，请手动检查任务状态")
    else:
        print("\n❌ 任务创建失败，无法继续测试")

    # 打印诊断信息
    print_diagnostic_info()

if __name__ == "__main__":
    main()
