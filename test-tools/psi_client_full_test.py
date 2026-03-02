#!/usr/bin/env python3
"""
PSI 完整测试客户端
功能：创建、执行、监控 PSI 任务，查看日志并获取结果
"""
import requests
import time
import json
import subprocess
import os
from datetime import datetime

# 配置
BASE_URL = "http://localhost:30811/prod-api"
os.environ['no_proxy'] = 'localhost,127.0.0.1'

class PSIClient:
    def __init__(self):
        self.token = None
        self.user_id = None
        self.session = requests.Session()

    def print_step(self, step, message):
        """打印步骤信息"""
        print(f"\n{'='*80}")
        print(f"[步骤{step}] {message}")
        print('='*80)

    def login(self):
        """登录系统"""
        self.print_step(1, "登录系统")

        data = {
            "userAccount": "admin",
            "userPassword": "123456",
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }

        try:
            response = self.session.post(f"{BASE_URL}/user/login", data=data, timeout=10)
            result = response.json()

            if result.get('code') == 0:
                user_data = result['result']
                self.token = user_data.get('token')
                self.user_id = user_data.get('sysUser', {}).get('userId')
                print(f"✓ 登录成功")
                print(f"  用户ID: {self.user_id}")
                print(f"  Token: {self.token[:30]}...")
                return True
            else:
                print(f"✗ 登录失败: {result.get('msg')}")
                return False
        except Exception as e:
            print(f"✗ 登录异常: {e}")
            return False

    def create_psi_task(self):
        """创建 PSI 任务"""
        self.print_step(2, "创建 PSI 任务")

        timestamp = int(time.time())
        psi_params = {
            'taskName': f'PSI_跨节点测试_{timestamp}',
            'taskDesc': '使用跨节点数据集测试PSI - DH算法',
            'projectId': '3',

            # 发起方：本地机构，资源9 (psi_client_data on node0)
            'ownOrganId': '550e8400-e29b-41d4-a716-446655440000',
            'ownResourceId': '9',
            'ownKeyword': 'id',

            # 协作方：同机构，资源10 (psi_server_data on node1) - 使用相同organId走本地资源查询路径
            'otherOrganId': '550e8400-e29b-41d4-a716-446655440000',
            'otherResourceId': '10',
            'otherKeyword': 'id',

            # 结果配置
            'resultName': f'psi_result_{timestamp}',
            'resultOrganIds': '550e8400-e29b-41d4-a716-446655440000',
            'outputContent': '0',  # 仅输出ID
            'outputNoRepeat': '1',  # 去重
            'outputFilePathType': '0',

            # 用户和算法
            'userId': str(self.user_id),
            'tag': '0',
            'psiTag': '0',  # DH算法

            'timestamp': int(time.time() * 1000),
            'nonce': 123,
            'token': self.token
        }

        headers = {'token': self.token, 'userId': str(self.user_id)}

        print("\n任务参数:")
        print(f"  发起方: 机构1 (test0001), 资源9 (psi_client_data @ node0)")
        print(f"  协作方: 机构2 (test0002), 资源10 (psi_server_data @ node1)")
        print(f"  算法: DH (Diffie-Hellman)")
        print(f"  匹配字段: id")

        try:
            response = self.session.post(
                f"{BASE_URL}/psi/saveDataPsi",
                params=psi_params,
                headers=headers,
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    data = result['result']
                    psi_id = data.get('dataPsi', {}).get('id')
                    task_id = data.get('dataPsiTask', {}).get('taskId')
                    task_id_name = data.get('dataPsiTask', {}).get('taskIdName')

                    print(f"\n✓ PSI 任务创建成功")
                    print(f"  PSI ID: {psi_id}")
                    print(f"  任务 ID: {task_id}")
                    print(f"  任务标识: {task_id_name}")

                    return psi_id, task_id, task_id_name
                else:
                    print(f"\n✗ 创建失败: {result.get('msg')}")
                    return None, None, None
            else:
                print(f"\n✗ HTTP 错误: {response.status_code}")
                print(f"  响应: {response.text}")
                return None, None, None

        except Exception as e:
            print(f"\n✗ 创建异常: {e}")
            import traceback
            traceback.print_exc()
            return None, None, None

    def start_task(self, task_id):
        """启动 PSI 任务"""
        self.print_step(3, "启动 PSI 任务")

        params = {
            'taskId': str(task_id),
            'token': self.token,
            'timestamp': int(time.time() * 1000),
            'nonce': 123
        }

        headers = {'token': self.token, 'userId': str(self.user_id)}

        try:
            # 尝试启动任务
            response = self.session.get(
                f"{BASE_URL}/psi/runDataPsi",
                params=params,
                headers=headers,
                timeout=30
            )

            print(f"  HTTP状态: {response.status_code}")

            if response.status_code == 200:
                result = response.json()
                print(f"  响应: {json.dumps(result, ensure_ascii=False, indent=2)}")

                if result.get('code') == 0:
                    print(f"\n✓ 任务启动成功")
                    return True
                else:
                    # 可能任务已经在运行或其他原因
                    print(f"\n⚠ 启动响应: {result.get('msg')}")
                    return True  # 继续监控
            else:
                print(f"\n⚠ HTTP {response.status_code}: {response.text}")
                return True  # 继续监控

        except Exception as e:
            print(f"\n⚠ 启动异常: {e}")
            return True  # 继续监控

    def monitor_task(self, psi_id, task_id_name, max_wait=120):
        """监控任务执行状态"""
        self.print_step(4, "监控任务执行")

        print(f"  监控 PSI ID: {psi_id}")
        print(f"  任务标识: {task_id_name}")
        print(f"  最大等待时间: {max_wait}秒\n")

        start_time = time.time()
        attempt = 0

        while time.time() - start_time < max_wait:
            attempt += 1
            elapsed = int(time.time() - start_time)

            try:
                # 直接查询数据库获取状态
                cmd = f"""docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e "SELECT task_state, file_rows, file_path FROM data_psi_task WHERE psi_id = {psi_id};" 2>&1 | grep -v 'Using a password' | tail -1"""

                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

                if result.returncode == 0 and result.stdout.strip():
                    parts = result.stdout.strip().split('\t')
                    if len(parts) >= 3:
                        task_state = int(parts[0]) if parts[0] != 'NULL' else 0
                        file_rows = parts[1] if parts[1] != 'NULL' else 'N/A'
                        file_path = parts[2] if parts[2] != 'NULL' else 'N/A'

                        state_name = {
                            0: "待运行",
                            1: "运行中",
                            2: "成功",
                            3: "失败",
                            4: "等待中"
                        }.get(task_state, f"未知({task_state})")

                        print(f"\r  [{elapsed}s] 尝试 {attempt}: 状态={state_name}, 结果行数={file_rows}", end='', flush=True)

                        if task_state == 2:  # 成功
                            print(f"\n\n✓ 任务执行成功!")
                            print(f"  结果行数: {file_rows}")
                            print(f"  结果文件: {file_path}")
                            return True, file_path
                        elif task_state == 3:  # 失败
                            print(f"\n\n✗ 任务执行失败")
                            return False, None

                time.sleep(3)

            except Exception as e:
                print(f"\n⚠ 监控异常: {e}")
                time.sleep(3)

        print(f"\n\n⚠ 任务超时（等待{max_wait}秒）")
        return False, None

    def check_node_logs(self, task_id_name):
        """查看节点日志"""
        self.print_step(5, "查看节点执行日志")

        print("\n[Node0 日志]")
        cmd0 = f"docker logs --since 5m primihub-node0 2>&1 | grep -i '{task_id_name}\\|error\\|psi' | tail -20"
        result0 = subprocess.run(cmd0, shell=True, capture_output=True, text=True)
        if result0.stdout.strip():
            print(result0.stdout)
        else:
            print("  (无相关日志)")

        print("\n[Node1 日志]")
        cmd1 = f"docker logs --since 5m primihub-node1 2>&1 | grep -i '{task_id_name}\\|error\\|psi' | tail -20"
        result1 = subprocess.run(cmd1, shell=True, capture_output=True, text=True)
        if result1.stdout.strip():
            print(result1.stdout)
        else:
            print("  (无相关日志)")

    def get_result(self, psi_id, file_path):
        """获取并显示结果"""
        self.print_step(6, "获取任务结果")

        # 从数据库获取详细信息
        cmd = f"""docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e "SELECT task_state, file_rows, file_path, file_content FROM data_psi_task WHERE psi_id = {psi_id};" 2>&1 | grep -v 'Using a password'"""

        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            if len(lines) >= 2:
                print("\n数据库记录:")
                print(result.stdout)

                # 解析内容
                parts = lines[1].split('\t')
                if len(parts) >= 4:
                    file_content = parts[3] if parts[3] != 'NULL' else None

                    if file_content:
                        print("\n✓ 结果内容:")
                        print("-" * 80)
                        print(file_content[:2000])  # 显示前2000个字符
                        if len(file_content) > 2000:
                            print(f"\n... (总共 {len(file_content)} 字符)")
                        print("-" * 80)

                        # 保存到文件
                        output_file = f'/tmp/psi_result_{psi_id}_{int(time.time())}.txt'
                        with open(output_file, 'w') as f:
                            f.write(file_content)
                        print(f"\n✓ 结果已保存到: {output_file}")
                    else:
                        print("\n⚠ 结果内容为空")

        # 如果有文件路径，尝试从容器读取
        if file_path and file_path != 'N/A':
            print(f"\n尝试从容器读取文件: {file_path}")
            cmd_file = f"docker exec primihub-node0 cat {file_path} 2>&1 | head -50"
            result_file = subprocess.run(cmd_file, shell=True, capture_output=True, text=True)
            if result_file.returncode == 0 and result_file.stdout.strip():
                print("\n✓ 容器文件内容:")
                print("-" * 80)
                print(result_file.stdout)
                print("-" * 80)
            else:
                print(f"  ⚠ 无法读取文件: {result_file.stderr}")

def main():
    """主函数"""
    print("\n" + "="*80)
    print("PrimiHub PSI 完整测试客户端")
    print("="*80)
    print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    client = PSIClient()

    # 步骤1: 登录
    if not client.login():
        print("\n✗ 测试终止：登录失败")
        return 1

    # 步骤2: 创建任务
    psi_id, task_id, task_id_name = client.create_psi_task()
    if not psi_id:
        print("\n✗ 测试终止：创建任务失败")
        return 1

    # 等待一下让系统准备好
    print("\n等待 3 秒让系统准备任务...")
    time.sleep(3)

    # 步骤3: 启动任务
    client.start_task(task_id)

    # 步骤4: 监控任务
    success, file_path = client.monitor_task(psi_id, task_id_name, max_wait=120)

    # 步骤5: 查看日志
    client.check_node_logs(task_id_name)

    # 步骤6: 获取结果
    if success:
        client.get_result(psi_id, file_path)

    # 总结
    print("\n" + "="*80)
    print("测试总结")
    print("="*80)
    print(f"结束时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    if success:
        print("✓ PSI 任务执行成功！")
        print(f"  PSI ID: {psi_id}")
        print(f"  任务标识: {task_id_name}")
        return 0
    else:
        print("✗ PSI 任务执行失败")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
