#!/usr/bin/env python3
"""
实时PSI（隐私集合求交）测试管理脚本
支持创建、监控、执行三种算法的PSI任务：DH、OT、HE
"""
import requests
import time
import json
import sys
from datetime import datetime
from typing import Optional, Tuple, Dict, List

BASE_URL = "http://172.20.0.6:8080"

# 算法配置
ALGORITHMS = {
    'dh': {
        'name': 'DH密钥交换',
        'full_name': 'Diffie-Hellman 密钥交换',
        'psi_tag': 0,
        'tag': 0,
        'description': '经典的密钥协商协议，计算效率高',
        'features': ['高效', '大规模数据', '低通信开销']
    },
    'ecdh': {
        'name': 'ECDH椭圆曲线',
        'full_name': 'Elliptic Curve Diffie-Hellman',
        'psi_tag': 1,
        'tag': 0,
        'description': '基于椭圆曲线的DH协议，安全性更高',
        'features': ['高安全性', '中等效率', '适中开销']
    },
    'ot': {
        'name': 'KKRT不经意传输',
        'full_name': 'KKRT Oblivious Transfer',
        'psi_tag': 2,
        'tag': 0,
        'description': '基于不经意传输，保护查询方隐私',
        'features': ['查询隐私', '需要TEE', '批量处理']
    },
    'he': {
        'name': 'BC22全同态加密',
        'full_name': 'BC22 Homomorphic Encryption',
        'psi_tag': 3,
        'tag': 0,
        'description': '基于全同态加密，提供最强隐私保护',
        'features': ['最强隐私', '加密计算', '高开销']
    }
}

class PSITaskManager:
    """PSI任务管理器"""

    def __init__(self):
        self.token = None
        self.user_id = None

    def login(self) -> bool:
        """登录系统"""
        data = {
            "userAccount": "admin",
            "userPassword": "123456",
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }
        try:
            response = requests.post(f"{BASE_URL}/sys/user/login", data=data)
            result = response.json()
            if result.get('code') == 0:
                user_data = result['result']
                self.token = user_data.get('token')
                self.user_id = user_data.get('sysUser', {}).get('userId')
                return True
        except Exception as e:
            print(f"❌ 登录异常: {e}")
        return False

    def create_psi_task(self, algorithm: str) -> Optional[Dict]:
        """创建PSI任务"""
        if algorithm not in ALGORITHMS:
            print(f"❌ 不支持的算法: {algorithm}")
            return None

        algo_config = ALGORITHMS[algorithm]
        timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

        psi_params = {
            "taskName": f"PSI_{algo_config['name']}_{timestamp_str}",
            "taskDesc": f"实时{algo_config['full_name']}隐私集合求交测试",
            "projectId": "3",

            # 发起方（机构A）
            "ownOrganId": "000000000000000000000000test0001",
            "ownResourceId": "3",
            "ownKeyword": "user_id",

            # 协作方（机构B）
            "otherOrganId": "000000000000000000000000test0002",
            "otherResourceId": "4",
            "otherKeyword": "user_id",

            # 结果配置
            "resultName": f"psi_result_{algo_config['name']}_{timestamp_str}",
            "resultOrganIds": "000000000000000000000000test0001",
            "outputContent": "0",
            "outputNoRepeat": "1",
            "outputFilePathType": "0",

            # 用户信息
            "userId": str(self.user_id),

            # PSI算法类型
            "tag": str(algo_config['tag']),
            "psiTag": str(algo_config['psi_tag']),

            "timestamp": int(time.time() * 1000),
            "nonce": 123,
            "token": self.token
        }

        # OT和HE算法需要TEE支持
        if algorithm in ['ot', 'he']:
            psi_params["teeOrganId"] = "000000000000000000000000test0001"

        headers = {"token": self.token, "userId": str(self.user_id)}

        try:
            response = requests.post(
                f"{BASE_URL}/data/psi/saveDataPsi",
                params=psi_params,
                headers=headers
            )

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    return result.get('result', {})
                else:
                    print(f"❌ 创建任务失败: {result.get('msg')}")
            else:
                print(f"❌ HTTP错误: {response.status_code}")
        except Exception as e:
            print(f"❌ 创建任务异常: {e}")

        return None

    def get_task_status(self, task_id: int) -> Optional[Dict]:
        """获取任务状态"""
        params = {
            "taskId": task_id,
            "token": self.token,
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }

        headers = {"token": self.token, "userId": str(self.user_id)}

        try:
            response = requests.get(
                f"{BASE_URL}/data/task/getTaskData",
                params=params,
                headers=headers
            )

            if response.status_code == 200:
                result = response.json()
                if result.get('code') == 0:
                    return result.get('result', {})
        except Exception as e:
            print(f"❌ 查询任务状态异常: {e}")

        return None

    def monitor_task(self, task_id: int, timeout: int = 300, interval: int = 5) -> bool:
        """实时监控任务执行状态"""
        print(f"\n{'='*80}")
        print(f"🔄 开始实时监控任务 (ID: {task_id})")
        print(f"{'='*80}")

        status_map = {
            0: "⏳ 待执行",
            1: "🔄 执行中",
            2: "✅ 成功",
            3: "❌ 失败"
        }

        start_time = time.time()
        last_status = None

        while True:
            elapsed = int(time.time() - start_time)

            if elapsed > timeout:
                print(f"\n⏰ 超时 ({timeout}秒)，停止监控")
                return False

            task_data = self.get_task_status(task_id)

            if task_data:
                task_state = task_data.get('taskState', -1)
                task_name = task_data.get('taskName', 'N/A')

                # 状态变化时输出
                if task_state != last_status:
                    timestamp = datetime.now().strftime('%H:%M:%S')
                    print(f"\n[{timestamp}] 任务状态: {status_map.get(task_state, '未知')} ({task_state})")
                    print(f"  任务名称: {task_name}")
                    print(f"  已耗时: {elapsed}秒")
                    last_status = task_state

                # 任务完成
                if task_state == 2:
                    print(f"\n{'='*80}")
                    print("🎉 任务执行成功!")
                    print(f"{'='*80}")
                    print(f"总耗时: {elapsed}秒")

                    # 显示结果信息
                    result_file = task_data.get('resultFileList', [])
                    if result_file:
                        print(f"结果文件: {result_file}")

                    return True

                # 任务失败
                elif task_state == 3:
                    print(f"\n{'='*80}")
                    print("❌ 任务执行失败!")
                    print(f"{'='*80}")
                    error_msg = task_data.get('taskErrorMsg', '未知错误')
                    print(f"错误信息: {error_msg}")
                    return False
            else:
                print(f"\n⚠️  无法获取任务状态")

            # 等待下一次轮询
            time.sleep(interval)

def print_algorithm_info(algorithm: str):
    """打印算法信息"""
    if algorithm not in ALGORITHMS:
        return

    algo = ALGORITHMS[algorithm]
    print(f"\n{'='*80}")
    print(f"🔐 {algo['full_name']}")
    print(f"{'='*80}")
    print(f"算法类型: {algo['name']}")
    print(f"算法特点: {algo['description']}")
    print(f"主要特性: {', '.join(algo['features'])}")
    print(f"psiTag: {algo['psi_tag']}")
    print(f"{'='*80}")

def test_single_algorithm(manager: PSITaskManager, algorithm: str, auto_monitor: bool = True):
    """测试单个算法"""
    print_algorithm_info(algorithm)

    print("\n【步骤1】创建PSI任务...")
    result = manager.create_psi_task(algorithm)

    if not result:
        print("❌ 任务创建失败")
        return False

    # 解析任务ID
    task_id = None
    if 'dataPsiTask' in result:
        task_id = result['dataPsiTask'].get('taskId')
    else:
        task_id = result.get('taskId') or result.get('id')

    if not task_id:
        print("❌ 无法获取任务ID")
        return False

    algo_config = ALGORITHMS[algorithm]
    print(f"\n✅ 任务创建成功!")
    print(f"  任务ID: {task_id}")
    print(f"  算法: {algo_config['name']}")

    if auto_monitor:
        print("\n【步骤2】实时监控任务执行...")
        success = manager.monitor_task(task_id)
        return success
    else:
        print(f"\n💡 使用以下命令监控任务:")
        print(f"  python3 test_psi_realtime.py monitor {task_id}")
        return True

def test_all_algorithms(manager: PSITaskManager):
    """测试所有算法"""
    print("\n" + "="*80)
    print("🚀 批量创建所有PSI算法任务")
    print("="*80)

    results = {}

    for algo_key in ['dh', 'ecdh', 'ot', 'he']:
        print(f"\n{'─'*80}")
        print(f"测试算法: {ALGORITHMS[algo_key]['name']}")
        print(f"{'─'*80}")

        result = manager.create_psi_task(algo_key)

        if result:
            task_id = None
            if 'dataPsiTask' in result:
                task_id = result['dataPsiTask'].get('taskId')
            else:
                task_id = result.get('taskId') or result.get('id')

            if task_id:
                results[algo_key] = task_id
                print(f"✅ {ALGORITHMS[algo_key]['name']} - 任务ID: {task_id}")
            else:
                print(f"❌ {ALGORITHMS[algo_key]['name']} - 创建失败（无任务ID）")
        else:
            print(f"❌ {ALGORITHMS[algo_key]['name']} - 创建失败")

        time.sleep(2)  # 避免请求过快

    print(f"\n{'='*80}")
    print(f"📊 创建结果总结")
    print(f"{'='*80}")
    print(f"成功创建: {len(results)}/{len(ALGORITHMS)} 个任务")

    if results:
        print("\n任务ID列表:")
        for algo_key, task_id in results.items():
            print(f"  {ALGORITHMS[algo_key]['name']}: {task_id}")

    return results

def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("实时PSI测试管理工具")
        print("\n用法:")
        print("  python3 test_psi_realtime.py <command> [options]")
        print("\n命令:")
        print("  dh              - 测试DH密钥交换算法")
        print("  ecdh            - 测试ECDH椭圆曲线算法")
        print("  ot              - 测试OT不经意传输算法")
        print("  he              - 测试HE全同态加密算法")
        print("  all             - 批量测试所有算法")
        print("  monitor <id>    - 监控指定任务ID的执行状态")
        print("\n示例:")
        print("  python3 test_psi_realtime.py dh       # 测试DH算法并自动监控")
        print("  python3 test_psi_realtime.py all      # 批量创建所有算法任务")
        print("  python3 test_psi_realtime.py monitor 123  # 监控任务123")
        sys.exit(1)

    command = sys.argv[1].lower()

    # 初始化管理器
    manager = PSITaskManager()

    print("="*80)
    print("🔐 实时PSI（隐私集合求交）测试系统")
    print("="*80)

    # 登录
    print("\n【登录系统】")
    if not manager.login():
        print("❌ 登录失败，请检查配置")
        sys.exit(1)

    print(f"✅ 登录成功 - 用户ID: {manager.user_id}")

    # 处理命令
    if command == 'monitor':
        if len(sys.argv) < 3:
            print("❌ 请指定任务ID")
            print("用法: python3 test_psi_realtime.py monitor <task_id>")
            sys.exit(1)

        task_id = int(sys.argv[2])
        manager.monitor_task(task_id)

    elif command == 'all':
        test_all_algorithms(manager)

    elif command in ALGORITHMS:
        test_single_algorithm(manager, command, auto_monitor=True)

    else:
        print(f"❌ 未知命令: {command}")
        print("支持的命令: dh, ecdh, ot, he, all, monitor")
        sys.exit(1)

    print("\n" + "="*80)
    print("测试完成")
    print("="*80 + "\n")

if __name__ == "__main__":
    main()
