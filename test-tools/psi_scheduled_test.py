#!/usr/bin/env python3
"""
PSI 调度器测试客户端
说明：PSI任务由后台调度器自动执行（每10分钟），不需要手动触发
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

class PSIScheduledClient:
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
            'taskName': f'PSI_调度器测试_{timestamp}',
            'taskDesc': '测试调度器自动执行PSI任务',
            'projectId': '3',

            # 发起方：本地机构，资源9 (psi_client_data on node0)
            'ownOrganId': '550e8400-e29b-41d4-a716-446655440000',
            'ownResourceId': '9',
            'ownKeyword': 'id',

            # 协作方：同机构，资源10 (psi_server_data on node1)
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
        print(f"  发起方: 资源9 (psi_client_data @ node0)")
        print(f"  协作方: 资源10 (psi_server_data @ node1)")
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

                    print(f"\n✓ PSI 任务创建成功")
                    print(f"  PSI ID: {psi_id}")
                    print(f"  任务 ID: {task_id}")

                    return psi_id, task_id
                else:
                    print(f"\n✗ 创建失败: {result.get('msg')}")
                    return None, None
            else:
                print(f"\n✗ HTTP 错误: {response.status_code}")
                print(f"  响应: {response.text}")
                return None, None

        except Exception as e:
            print(f"\n✗ 创建异常: {e}")
            import traceback
            traceback.print_exc()
            return None, None

    def check_scheduler_status(self):
        """检查调度器状态"""
        self.print_step(3, "检查调度器状态")

        print("\n查询最近的调度器日志...")
        cmd = """docker logs application0 2>&1 | grep "定时处理节点业务" | tail -5"""
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

        if result.stdout.strip():
            print("\n最近5次调度器运行:")
            for line in result.stdout.strip().split('\n'):
                print(f"  {line}")

            # 解析最后一次运行时间
            last_line = result.stdout.strip().split('\n')[-1]
            time_str = last_line.split()[0]
            print(f"\n最后运行时间: {time_str}")
            print("调度器每10分钟运行一次")

            # 计算下次运行时间
            current_minute = datetime.now().minute
            next_run_minute = ((current_minute // 10) + 1) * 10
            if next_run_minute >= 60:
                next_run_minute = 0
            print(f"预计下次运行: {next_run_minute:02d}分")
        else:
            print("  ⚠ 未找到调度器日志")

    def monitor_task(self, psi_id, max_wait=660):
        """监控任务执行状态（最多等待11分钟）"""
        self.print_step(4, "监控任务执行")

        print(f"  监控 PSI ID: {psi_id}")
        print(f"  最大等待时间: {max_wait}秒 (11分钟)")
        print(f"\n  说明: 调度器每10分钟运行一次，任务将在下次调度时自动执行")
        print(f"  当前时间: {datetime.now().strftime('%H:%M:%S')}\n")

        start_time = time.time()
        attempt = 0
        last_state = -1

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

                        # 状态变化时打印新行
                        if task_state != last_state:
                            if last_state != -1:
                                print()  # 换行
                            print(f"\n  [{elapsed}s] 状态变化: {state_name}")
                            last_state = task_state
                        else:
                            print(f"\r  [{elapsed}s] 尝试 {attempt}: 状态={state_name}, 结果行数={file_rows}", end='', flush=True)

                        if task_state == 2:  # 成功
                            print(f"\n\n✓ 任务执行成功!")
                            print(f"  结果行数: {file_rows}")
                            print(f"  结果文件: {file_path}")
                            return True, file_path
                        elif task_state == 3:  # 失败
                            print(f"\n\n✗ 任务执行失败")
                            return False, None

                time.sleep(5)  # 每5秒检查一次

            except Exception as e:
                print(f"\n⚠ 监控异常: {e}")
                time.sleep(5)

        print(f"\n\n⚠ 任务超时（等待{max_wait}秒）")
        return False, None

    def get_result(self, psi_id, file_path):
        """获取并显示结果"""
        self.print_step(5, "获取任务结果")

        # 从数据库获取详细信息
        cmd = f"""docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e "SELECT task_state, file_rows, file_path, LEFT(file_content, 500) as content_preview FROM data_psi_task WHERE psi_id = {psi_id};" 2>&1 | grep -v 'Using a password'"""

        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

        if result.returncode == 0:
            print("\n数据库记录:")
            print(result.stdout)

            # 获取完整内容
            cmd_full = f"""docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e "SELECT file_content FROM data_psi_task WHERE psi_id = {psi_id};" 2>&1 | grep -v 'Using a password' | tail -1"""
            result_full = subprocess.run(cmd_full, shell=True, capture_output=True, text=True)

            if result_full.returncode == 0 and result_full.stdout.strip():
                file_content = result_full.stdout.strip()
                if file_content and file_content != 'NULL':
                    print("\n✓ 结果内容预览:")
                    print("-" * 80)
                    print(file_content[:1000])
                    if len(file_content) > 1000:
                        print(f"\n... (总共 {len(file_content)} 字符)")
                    print("-" * 80)

                    # 保存到文件
                    output_file = f'/tmp/psi_result_{psi_id}_{int(time.time())}.txt'
                    with open(output_file, 'w') as f:
                        f.write(file_content)
                    print(f"\n✓ 完整结果已保存到: {output_file}")

def main():
    """主函数"""
    print("\n" + "="*80)
    print("PrimiHub PSI 调度器测试客户端")
    print("="*80)
    print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("\n说明: PSI任务由后台调度器自动执行，无需手动触发")

    client = PSIScheduledClient()

    # 步骤1: 登录
    if not client.login():
        print("\n✗ 测试终止：登录失败")
        return 1

    # 步骤2: 创建任务
    psi_id, task_id = client.create_psi_task()
    if not psi_id:
        print("\n✗ 测试终止：创建任务失败")
        return 1

    # 步骤3: 检查调度器状态
    client.check_scheduler_status()

    # 步骤4: 监控任务（等待调度器执行）
    print("\n等待调度器拾取任务...")
    success, file_path = client.monitor_task(psi_id, max_wait=660)

    # 步骤5: 获取结果
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
        return 0
    else:
        print("✗ PSI 任务执行失败或超时")
        print(f"  PSI ID: {psi_id}")
        print(f"\n提示: 可以稍后手动检查任务状态:")
        print(f"  docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e \"SELECT * FROM data_psi_task WHERE psi_id = {psi_id};\"")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
