#!/usr/bin/env python3
"""
交互式数据资源创建助手
引导用户一步步获取token并创建数据资源
"""

import sys
import os

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient


def print_section(title):
    """打印章节标题"""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70 + "\n")


def get_user_input(prompt, default=""):
    """获取用户输入"""
    if default:
        user_input = input(f"{prompt} [{default}]: ").strip()
        return user_input if user_input else default
    else:
        return input(f"{prompt}: ").strip()


def test_token(url, token, node_name):
    """测试token是否有效"""
    try:
        client = PrimiHubAPIClient(url)
        client.token = token

        response = client.get_user_list(page=1, page_size=1)

        if response.get('code') == 0:
            print(f"✅ {node_name} Token验证成功！")
            return True
        else:
            print(f"❌ {node_name} Token验证失败: {response.get('msg')}")
            return False
    except Exception as e:
        print(f"❌ {node_name} Token验证失败: {e}")
        return False


def create_resource_interactive(url, token, node_name):
    """交互式创建资源"""
    from datetime import datetime
    import time

    client = PrimiHubAPIClient(url)
    client.token = token

    print(f"\n在 {node_name} 上创建数据资源")
    print("-" * 70)

    # 预定义的数据集
    datasets = {
        "1": {
            "name": "用户特征数据",
            "resourceName": f"{node_name}_用户特征数据_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "resourceDesc": f"{node_name}节点的用户特征数据集",
            "resourceColumnList": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "age", "columnType": "int", "columnDesc": "年龄"},
                {"columnName": "gender", "columnType": "int", "columnDesc": "性别"},
                {"columnName": "city", "columnType": "string", "columnDesc": "城市"},
                {"columnName": "income", "columnType": "float", "columnDesc": "收入"},
                {"columnName": "education", "columnType": "int", "columnDesc": "学历"},
            ],
            "rows": 10000
        },
        "2": {
            "name": "交易记录数据",
            "resourceName": f"{node_name}_交易记录数据_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "resourceDesc": f"{node_name}节点的交易记录数据集",
            "resourceColumnList": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "transaction_id", "columnType": "string", "columnDesc": "交易ID"},
                {"columnName": "amount", "columnType": "float", "columnDesc": "交易金额"},
                {"columnName": "timestamp", "columnType": "long", "columnDesc": "时间戳"},
                {"columnName": "merchant_id", "columnType": "string", "columnDesc": "商户ID"},
                {"columnName": "category", "columnType": "string", "columnDesc": "类别"},
            ],
            "rows": 50000
        },
        "3": {
            "name": "信用特征数据",
            "resourceName": f"{node_name}_信用特征数据_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "resourceDesc": f"{node_name}节点的信用特征数据集",
            "resourceColumnList": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "credit_score", "columnType": "int", "columnDesc": "信用分数"},
                {"columnName": "loan_count", "columnType": "int", "columnDesc": "贷款次数"},
                {"columnName": "overdue_count", "columnType": "int", "columnDesc": "逾期次数"},
                {"columnName": "total_debt", "columnType": "float", "columnDesc": "总负债"},
                {"columnName": "label", "columnType": "int", "columnDesc": "风险标签"},
            ],
            "rows": 8000
        }
    }

    print("\n可创建的数据集类型：")
    print("  1. 用户特征数据 (10,000行)")
    print("  2. 交易记录数据 (50,000行)")
    print("  3. 信用特征数据 (8,000行)")

    choices = get_user_input("\n请选择要创建的数据集 (多个用逗号分隔，如: 1,2)", "1,2")

    selected = [c.strip() for c in choices.split(',') if c.strip() in datasets]

    if not selected:
        print("❌ 无效的选择")
        return []

    created = []

    for choice in selected:
        dataset = datasets[choice]

        print(f"\n创建 {dataset['name']}...")

        resource_data = {
            "resourceName": dataset["resourceName"],
            "resourceDesc": dataset["resourceDesc"],
            "resourceType": "1",
            "resourceAuthType": "0",
            "resourceColumnList": dataset["resourceColumnList"],
            "resourceRowsCount": dataset["rows"],
            "resourceColumnCount": len(dataset["resourceColumnList"]),
            "resourceSize": dataset["rows"] * len(dataset["resourceColumnList"]) * 20
        }

        try:
            response = client.create_resource(resource_data)

            if response.get('code') == 0:
                resource_id = response.get('result', {}).get('resourceId')
                print(f"✅ 创建成功!")
                print(f"   资源名称: {resource_data['resourceName']}")
                print(f"   资源ID: {resource_id}")
                print(f"   数据行数: {resource_data['resourceRowsCount']:,}")

                created.append({
                    'node': node_name,
                    'name': dataset['name'],
                    'resource_id': resource_id
                })
            else:
                print(f"❌ 创建失败: {response.get('msg')}")

        except Exception as e:
            print(f"❌ 创建失败: {e}")

        time.sleep(0.5)

    return created


def main():
    """主函数"""

    print_section("PrimiHub 数据资源创建助手")

    print("此助手将帮助你在node0和node1上创建数据资源\n")
    print("📋 节点信息:")
    print("  Node0 (gateway0): http://172.20.0.12:8080")
    print("  Node1 (gateway1): http://172.20.0.2:8080")

    # 询问是否已有token
    print("\n" + "─" * 70)
    print("🔑 Token准备")
    print("─" * 70)

    has_token = get_user_input("\n是否已准备好token? (y/n)", "n").lower()

    if has_token != 'y':
        print("\n请按以下步骤获取Token：")
        print("\n1. 在浏览器中打开对应节点的地址并登录")
        print("2. 按 F12 打开开发者工具")
        print("3. 切换到 Network 标签")
        print("4. 刷新页面")
        print("5. 点击任意请求，查看 Headers 中的 token 字段")
        print("6. 复制完整的token值")
        print("\n获取token后重新运行此脚本。")
        return

    # Node0配置
    print_section("配置 Node0")

    node0_url = get_user_input("Node0 URL", "http://172.20.0.12:8080")

    print("\n请粘贴Node0的token:")
    print("(提示: 在终端中粘贴可能需要使用 Ctrl+Shift+V 或右键)")
    node0_token = input("Token: ").strip()

    if node0_token:
        print("\n验证Node0 Token...")
        if not test_token(node0_url, node0_token, "Node0"):
            print("\n❌ Node0 Token验证失败，请检查token是否正确")
            retry = get_user_input("是否重试? (y/n)", "n").lower()
            if retry != 'y':
                return
    else:
        print("⚠️  跳过Node0")
        node0_token = None

    # Node1配置
    print_section("配置 Node1")

    create_node1 = get_user_input("是否也在Node1上创建资源? (y/n)", "y").lower()

    node1_token = None
    node1_url = "http://172.20.0.2:8080"

    if create_node1 == 'y':
        node1_url = get_user_input("Node1 URL", "http://172.20.0.2:8080")

        print("\n请粘贴Node1的token:")
        node1_token = input("Token: ").strip()

        if node1_token:
            print("\n验证Node1 Token...")
            if not test_token(node1_url, node1_token, "Node1"):
                print("\n❌ Node1 Token验证失败")
                retry = get_user_input("是否继续仅在Node0创建? (y/n)", "y").lower()
                if retry != 'y':
                    return
                node1_token = None

    # 开始创建资源
    print_section("开始创建数据资源")

    all_created = []

    # 在Node0创建
    if node0_token:
        created = create_resource_interactive(node0_url, node0_token, "Node0")
        all_created.extend(created)

    # 在Node1创建
    if node1_token:
        created = create_resource_interactive(node1_url, node1_token, "Node1")
        all_created.extend(created)

    # 总结
    print_section("创建总结")

    if all_created:
        print(f"✅ 成功创建 {len(all_created)} 个数据资源:\n")
        for item in all_created:
            print(f"  [{item['node']}] {item['name']}")
            print(f"    资源ID: {item['resource_id']}\n")

        # 保存结果
        import json
        from datetime import datetime

        output_file = f"created_resources_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(all_created, f, indent=2, ensure_ascii=False)

        print(f"📄 资源信息已保存到: {output_file}")
    else:
        print("未创建任何资源")

    print("\n" + "=" * 70)
    print("  完成！")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
