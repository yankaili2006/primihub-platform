#!/usr/bin/env python3
"""
使用内置跨节点数据集测试 PSI 任务
资源 9: psi_client_data (node0, organ_id=1)
资源 10: psi_server_data (node1, organ_id=2)
"""
import requests
import time
import json
import sys

# 使用外部地址通过 Nginx 反向代理
BASE_URL = "http://localhost:30811/prod-api"
# 或使用 Docker 网络内部地址: http://gateway0:8080

def print_step(step, message):
    """打印步骤信息"""
    print(f"\n{'='*70}")
    print(f"[步骤{step}] {message}")
    print('='*70)

def login():
    """登录获取token"""
    print_step(1, "登录系统")

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
            print(f"✓ 登录成功")
            print(f"  Token: {token[:20]}...")
            print(f"  用户ID: {user_id}")
            return token, user_id
        else:
            print(f"✗ 登录失败: {result.get('msg')}")
            return None, None
    except Exception as e:
        print(f"✗ 登录异常: {e}")
        return None, None

def create_psi_project(token, user_id):
    """创建PSI项目"""
    print_step(2, "创建PSI项目")

    headers = {
        "token": token,
        "userId": str(user_id),
        "Content-Type": "application/json"
    }

    data = {
        "projectName": f"PSI跨节点测试_{int(time.time())}",
        "projectDesc": "使用内置跨节点数据集测试PSI功能",
        "projectType": 1,  # PSI项目类型
        "serverOrganId": "000000000000000000000000test0001",
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }

    try:
        response = requests.post(
            f"{BASE_URL}/project/saveProject",
            json=data,
            headers=headers,
            timeout=10
        )
        result = response.json()

        if result.get('code') == 0:
            project_id = result['result']
            print(f"✓ 项目创建成功")
            print(f"  项目ID: {project_id}")
            return project_id
        else:
            print(f"✗ 项目创建失败: {result.get('msg')}")
            return None
    except Exception as e:
        print(f"✗ 项目创建异常: {e}")
        return None

def create_psi_task(token, user_id, project_id):
    """创建PSI任务"""
    print_step(3, "创建PSI任务")

    headers = {
        "token": token,
        "userId": str(user_id),
        "Content-Type": "application/json"
    }

    # 使用跨节点的数据集
    # 资源9: psi_client_data (node0)
    # 资源10: psi_server_data (node1)
    data = {
        "projectId": project_id,
        "taskName": f"PSI_DH_测试_{int(time.time())}",
        "taskType": 1,  # PSI任务
        "psiTag": "0",  # 0=DH算法
        "serverAddress": "000000000000000000000000test0001",
        "clientAddress": "000000000000000000000000test0001",
        "psiParam": {
            "ownOrganId": "000000000000000000000000test0001",
            "ownResourceId": "9",  # psi_client_data on node0
            "otherOrganId": "000000000000000000000000test0002",
            "otherResourceId": "10",  # psi_server_data on node1
            "psiTag": "0",
            "resourceColumnName": ["ID"],  # 匹配字段
            "otherResourceColumnName": ["ID"]
        },
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }

    print("\n任务参数:")
    print(f"  发起方: 机构1, 资源9 (psi_client_data @ node0)")
    print(f"  协作方: 机构2, 资源10 (psi_server_data @ node1)")
    print(f"  算法: DH-PSI")
    print(f"  匹配字段: ID")

    try:
        response = requests.post(
            f"{BASE_URL}/task/psiTask/savePsiTask",
            json=data,
            headers=headers,
            timeout=30
        )
        result = response.json()

        if result.get('code') == 0:
            task_id = result.get('result')
            print(f"\n✓ PSI任务创建成功")
            print(f"  任务ID: {task_id}")
            return task_id
        else:
            print(f"\n✗ 任务创建失败")
            print(f"  错误信息: {result.get('msg')}")
            print(f"  错误码: {result.get('code')}")
            return None
    except Exception as e:
        print(f"\n✗ 任务创建异常: {e}")
        import traceback
        traceback.print_exc()
        return None

def check_task_status(token, user_id, task_id):
    """检查任务状态"""
    print_step(4, "检查任务状态")

    headers = {
        "token": token,
        "userId": str(user_id)
    }

    params = {
        "taskId": task_id,
        "token": token,
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }

    max_attempts = 30
    for attempt in range(max_attempts):
        try:
            response = requests.get(
                f"{BASE_URL}/task/getTaskById",
                params=params,
                headers=headers,
                timeout=10
            )
            result = response.json()

            if result.get('code') == 0:
                task = result['result']
                status = task.get('taskState')
                status_name = {
                    0: "待运行",
                    1: "运行中",
                    2: "成功",
                    3: "失败"
                }.get(status, f"未知({status})")

                print(f"\r  尝试 {attempt+1}/{max_attempts}: 状态={status_name}", end='', flush=True)

                if status == 2:  # 成功
                    print(f"\n\n✓ 任务执行成功!")
                    print(f"  结果文件: {task.get('taskResultPath', 'N/A')}")
                    return True
                elif status == 3:  # 失败
                    print(f"\n\n✗ 任务执行失败")
                    print(f"  错误信息: {task.get('taskErrorMsg', 'N/A')}")
                    return False

                time.sleep(2)
            else:
                print(f"\n✗ 状态查询失败: {result.get('msg')}")
                return False

        except Exception as e:
            print(f"\n✗ 状态查询异常: {e}")
            return False

    print(f"\n\n⚠ 任务超时（等待{max_attempts*2}秒）")
    return False

def main():
    """主函数"""
    print("\n" + "="*70)
    print("PrimiHub PSI 跨节点测试")
    print("使用内置测试数据集: psi_client_data (node0) + psi_server_data (node1)")
    print("="*70)

    # 登录
    token, user_id = login()
    if not token:
        print("\n✗ 测试失败: 无法登录")
        return 1

    # 创建项目
    project_id = create_psi_project(token, user_id)
    if not project_id:
        print("\n✗ 测试失败: 无法创建项目")
        return 1

    # 创建任务
    task_id = create_psi_task(token, user_id, project_id)
    if not task_id:
        print("\n✗ 测试失败: 无法创建任务")
        return 1

    # 检查任务状态
    success = check_task_status(token, user_id, task_id)

    print("\n" + "="*70)
    if success:
        print("✓ PSI 测试成功完成!")
    else:
        print("✗ PSI 测试失败")
    print("="*70 + "\n")

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
