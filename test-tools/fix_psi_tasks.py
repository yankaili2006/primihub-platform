#!/usr/bin/env python3
"""
PSI任务修复脚本 - 为缺失data_task记录的PSI任务创建补偿记录
"""
import pymysql
import sys
from datetime import datetime

# 数据库配置
DB_CONFIG = {
    'host': '172.23.0.2',  # mysql容器IP
    'port': 3306,
    'user': 'primihub',
    'password': 'primihub@123',
    'database': 'privacy',
    'charset': 'utf8mb4'
}

def get_connection():
    """获取数据库连接"""
    return pymysql.connect(**DB_CONFIG)

def find_missing_tasks():
    """查找缺失data_task记录的PSI任务"""
    conn = get_connection()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            sql = """
            SELECT
                dpt.psi_id,
                dpt.task_id,
                dp.own_organ_id,
                dp.result_name,
                dpt.create_date
            FROM data_psi_task dpt
            JOIN data_psi dp ON dpt.psi_id = dp.id
            LEFT JOIN data_task dt ON dpt.task_id = dt.task_id_name
            WHERE dt.task_id_name IS NULL
            AND dpt.task_state = 0
            ORDER BY dpt.psi_id
            """
            cursor.execute(sql)
            return cursor.fetchall()
    finally:
        conn.close()

def create_data_task(task_info):
    """为PSI任务创建data_task记录"""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            # 获取当前时间戳（毫秒）
            timestamp_ms = int(datetime.now().timestamp() * 1000)

            sql = """
            INSERT INTO data_task (
                task_id_name,
                task_name,
                task_desc,
                task_state,
                task_type,
                task_start_time,
                task_user_id,
                is_cooperation,
                is_del
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
            """

            values = (
                task_info['task_id'],                           # task_id_name
                f"PSI_补偿_{task_info['psi_id']}",              # task_name
                "PSI任务补偿创建 - 自动修复",                    # task_desc
                0,                                              # task_state (0=待执行)
                2,                                              # task_type (2=PSI)
                timestamp_ms,                                   # task_start_time
                1,                                              # task_user_id
                0,                                              # is_cooperation
                0                                               # is_del
            )

            cursor.execute(sql, values)
            conn.commit()
            return cursor.lastrowid
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def verify_task_creation(task_id_name):
    """验证data_task记录是否创建成功"""
    conn = get_connection()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            sql = "SELECT * FROM data_task WHERE task_id_name = %s"
            cursor.execute(sql, (task_id_name,))
            return cursor.fetchone()
    finally:
        conn.close()

def main():
    print("=" * 80)
    print("PSI任务修复脚本")
    print("=" * 80)
    print()

    # 1. 查找缺失data_task的PSI任务
    print("[1/4] 查找缺失data_task记录的PSI任务...")
    missing_tasks = find_missing_tasks()

    if not missing_tasks:
        print("✓ 没有发现缺失data_task记录的PSI任务")
        return 0

    print(f"✓ 发现 {len(missing_tasks)} 个PSI任务缺失data_task记录:")
    print()
    print(f"{'PSI ID':<10} {'Task ID':<25} {'Organ ID':<45} {'创建时间'}")
    print("-" * 110)
    for task in missing_tasks:
        print(f"{task['psi_id']:<10} {task['task_id']:<25} {task['own_organ_id']:<45} {task['create_date']}")
    print()

    # 2. 确认是否继续
    response = input(f"是否为这 {len(missing_tasks)} 个任务创建data_task记录? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("操作已取消")
        return 0

    # 3. 创建data_task记录
    print()
    print("[2/4] 创建data_task记录...")
    success_count = 0
    failed_tasks = []

    for task in missing_tasks:
        try:
            task_id = create_data_task(task)
            print(f"✓ PSI任务 {task['psi_id']} (task_id: {task['task_id']}) - data_task记录已创建 (ID: {task_id})")
            success_count += 1
        except Exception as e:
            print(f"✗ PSI任务 {task['psi_id']} (task_id: {task['task_id']}) - 创建失败: {e}")
            failed_tasks.append(task)

    print()
    print(f"成功: {success_count}/{len(missing_tasks)}")
    if failed_tasks:
        print(f"失败: {len(failed_tasks)}/{len(missing_tasks)}")

    # 4. 验证创建结果
    print()
    print("[3/4] 验证data_task记录...")
    verified_count = 0
    for task in missing_tasks:
        if task not in failed_tasks:
            result = verify_task_creation(task['task_id'])
            if result:
                verified_count += 1
            else:
                print(f"✗ 验证失败: task_id {task['task_id']}")

    print(f"✓ 验证通过: {verified_count}/{success_count}")

    # 5. 说明后续步骤
    print()
    print("[4/4] 后续步骤")
    print("-" * 80)
    print("data_task记录已创建，但任务可能不会自动执行，因为:")
    print("1. RabbitMQ消息在任务创建时发送，现在补偿创建不会触发消息")
    print("2. 系统可能需要重启application服务来重新扫描待执行任务")
    print()
    print("建议操作:")
    print("  方案1: 重启application服务")
    print("    docker restart application0 application1 application2")
    print()
    print("  方案2: 使用调度器手动触发（如果系统有定时扫描机制）")
    print("    等待系统定时任务扫描并执行")
    print()
    print("  方案3: 通过API重新提交任务")
    print("    使用现有的PSI配置重新调用saveDataPsi API")
    print()

    return 0 if not failed_tasks else 1

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n操作已取消")
        sys.exit(1)
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
