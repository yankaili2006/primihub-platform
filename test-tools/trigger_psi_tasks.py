#!/usr/bin/env python3
"""
PSI任务触发脚本 - 通过RabbitMQ消息触发待执行的PSI任务
"""
import pika
import pymysql
import json
import sys
from datetime import datetime

# 数据库配置
DB_CONFIG = {
    'host': '172.23.0.2',
    'port': 3306,
    'user': 'primihub',
    'password': 'primihub@123',
    'database': 'privacy',
    'charset': 'utf8mb4'
}

# RabbitMQ配置
RABBITMQ_CONFIG = {
    'host': '172.23.0.5',
    'port': 5672,
    'username': 'guest',
    'password': 'guest',
    'virtual_host': '/'
}

def get_db_connection():
    """获取数据库连接"""
    return pymysql.connect(**DB_CONFIG)

def get_rabbitmq_connection():
    """获取RabbitMQ连接"""
    credentials = pika.PlainCredentials(
        RABBITMQ_CONFIG['username'],
        RABBITMQ_CONFIG['password']
    )
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_CONFIG['host'],
        port=RABBITMQ_CONFIG['port'],
        virtual_host=RABBITMQ_CONFIG['virtual_host'],
        credentials=credentials
    )
    return pika.BlockingConnection(parameters)

def get_pending_psi_tasks():
    """获取所有待执行的PSI任务"""
    conn = get_db_connection()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            sql = """
            SELECT
                dt.id as data_task_id,
                dt.task_id_name,
                dt.task_type,
                dpt.psi_id,
                dp.own_organ_id,
                dp.other_organ_id,
                dp.result_name,
                dp.tag as psi_type,
                dpt.create_date
            FROM data_task dt
            JOIN data_psi_task dpt ON dt.task_id_name = dpt.task_id
            JOIN data_psi dp ON dpt.psi_id = dp.id
            WHERE dt.task_state = 0
            AND dt.task_type = 2
            ORDER BY dpt.psi_id
            """
            cursor.execute(sql)
            return cursor.fetchall()
    finally:
        conn.close()

def create_task_message(task_info):
    """
    创建任务消息
    基于系统的消息格式构建RabbitMQ消息
    """
    message = {
        "taskId": task_info['task_id_name'],
        "taskType": task_info['task_type'],
        "psiId": task_info['psi_id'],
        "ownOrganId": task_info['own_organ_id'],
        "otherOrganId": task_info['other_organ_id'],
        "resultName": task_info['result_name'],
        "psiType": task_info['psi_type']
    }
    return message

def send_task_to_queue(channel, task_info, queue_name='singlTaskChannel'):
    """发送任务消息到RabbitMQ队列"""
    message = create_task_message(task_info)

    # 发送消息到exchange
    channel.basic_publish(
        exchange=queue_name,
        routing_key='',
        body=json.dumps(message),
        properties=pika.BasicProperties(
            content_type='application/json',
            delivery_mode=2  # 持久化消息
        )
    )

    return message

def update_task_state(task_id_name, state=1):
    """更新任务状态"""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = "UPDATE data_task SET task_state = %s WHERE task_id_name = %s"
            cursor.execute(sql, (state, task_id_name))
            conn.commit()
    finally:
        conn.close()

def main():
    print("=" * 80)
    print("PSI任务触发脚本 - 通过RabbitMQ触发待执行任务")
    print("=" * 80)
    print()

    # 1. 获取待执行的PSI任务
    print("[1/5] 查询待执行的PSI任务...")
    pending_tasks = get_pending_psi_tasks()

    if not pending_tasks:
        print("✓ 没有待执行的PSI任务")
        return 0

    print(f"✓ 发现 {len(pending_tasks)} 个待执行的PSI任务:")
    print()
    print(f"{'PSI ID':<10} {'Task ID':<25} {'Own Organ':<40} {'创建时间'}")
    print("-" * 110)
    for task in pending_tasks:
        print(f"{task['psi_id']:<10} {task['task_id_name']:<25} {task['own_organ_id']:<40} {task['create_date']}")
    print()

    # 2. 确认是否继续
    response = input(f"是否触发这 {len(pending_tasks)} 个任务的执行? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("操作已取消")
        return 0

    # 3. 连接RabbitMQ
    print()
    print("[2/5] 连接RabbitMQ...")
    try:
        connection = get_rabbitmq_connection()
        channel = connection.channel()
        print("✓ RabbitMQ连接成功")
    except Exception as e:
        print(f"✗ RabbitMQ连接失败: {e}")
        return 1

    # 4. 发送任务消息
    print()
    print("[3/5] 发送任务消息到RabbitMQ队列...")
    success_count = 0
    failed_tasks = []

    for task in pending_tasks:
        try:
            message = send_task_to_queue(channel, task)
            print(f"✓ PSI任务 {task['psi_id']} (task_id: {task['task_id_name']}) - 消息已发送")
            success_count += 1
        except Exception as e:
            print(f"✗ PSI任务 {task['psi_id']} (task_id: {task['task_id_name']}) - 发送失败: {e}")
            failed_tasks.append(task)

    # 5. 关闭连接
    connection.close()

    print()
    print(f"成功: {success_count}/{len(pending_tasks)}")
    if failed_tasks:
        print(f"失败: {len(failed_tasks)}/{len(pending_tasks)}")

    # 6. 验证消息队列
    print()
    print("[4/5] 验证RabbitMQ队列状态...")
    print("请运行以下命令检查队列中的消息数:")
    print("  docker exec rabbitmq0 rabbitmqctl list_queues name messages consumers")
    print()

    # 7. 后续步骤说明
    print("[5/5] 后续步骤")
    print("-" * 80)
    print("消息已发送到RabbitMQ队列，节点应该会自动消费并执行任务。")
    print()
    print("监控任务执行:")
    print("  1. 查看节点日志:")
    print("     docker logs -f node0 | grep PSI")
    print()
    print("  2. 查看任务状态:")
    print("     docker exec mysql mysql -uprimihub -p'primihub@123' privacy \\")
    print("       -e \"SELECT psi_id, task_id, task_state FROM data_psi_task ORDER BY psi_id DESC LIMIT 10;\"")
    print()
    print("  3. 如果任务仍未执行，可能需要:")
    print("     - 检查节点服务是否正常运行")
    print("     - 检查RabbitMQ消费者是否正常")
    print("     - 查看application日志中的错误信息")
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
