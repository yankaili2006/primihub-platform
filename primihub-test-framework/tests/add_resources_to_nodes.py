#!/usr/bin/env python3
"""
在node0和node1添加数据资源
通过API在不同的节点上创建数据资源
"""

import sys
import os
import time
import json
from datetime import datetime

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient

# ============================================
# 配置区域
# ============================================
# node0 配置
NODE0_URL = "http://172.20.0.12:8080"  # gateway0的地址
NODE0_TOKEN = ""  # 请填入node0的token

# node1 配置
NODE1_URL = "http://172.20.0.2:8080"   # gateway1的地址
NODE1_TOKEN = ""  # 请填入node1的token


def create_sample_resource_data(node_name: str, dataset_name: str):
    """创建示例数据资源数据"""

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    # 定义不同节点的数据集
    datasets = {
        "user_features": {
            "name": f"{node_name}_用户特征数据_{timestamp}",
            "desc": f"{node_name}节点的用户特征数据集，包含用户基本信息和行为特征",
            "columns": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "age", "columnType": "int", "columnDesc": "年龄"},
                {"columnName": "gender", "columnType": "int", "columnDesc": "性别(0:女,1:男)"},
                {"columnName": "city", "columnType": "string", "columnDesc": "城市"},
                {"columnName": "income", "columnType": "float", "columnDesc": "收入"},
                {"columnName": "education", "columnType": "int", "columnDesc": "学历(1-5)"},
            ],
            "rows": 10000
        },
        "transaction_records": {
            "name": f"{node_name}_交易记录数据_{timestamp}",
            "desc": f"{node_name}节点的交易记录数据集，包含用户的交易行为数据",
            "columns": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "transaction_id", "columnType": "string", "columnDesc": "交易ID"},
                {"columnName": "amount", "columnType": "float", "columnDesc": "交易金额"},
                {"columnName": "timestamp", "columnType": "long", "columnDesc": "交易时间戳"},
                {"columnName": "merchant_id", "columnType": "string", "columnDesc": "商户ID"},
                {"columnName": "category", "columnType": "string", "columnDesc": "交易类别"},
            ],
            "rows": 50000
        },
        "credit_features": {
            "name": f"{node_name}_信用特征数据_{timestamp}",
            "desc": f"{node_name}节点的信用特征数据集，包含用户的信用评分和历史记录",
            "columns": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "credit_score", "columnType": "int", "columnDesc": "信用分数"},
                {"columnName": "loan_count", "columnType": "int", "columnDesc": "贷款次数"},
                {"columnName": "overdue_count", "columnType": "int", "columnDesc": "逾期次数"},
                {"columnName": "total_debt", "columnType": "float", "columnDesc": "总负债"},
                {"columnName": "label", "columnType": "int", "columnDesc": "标签(0:正常,1:风险)"},
            ],
            "rows": 8000
        }
    }

    dataset = datasets.get(dataset_name, datasets["user_features"])

    resource_data = {
        "resourceName": dataset["name"],
        "resourceDesc": dataset["desc"],
        "resourceType": "1",  # CSV类型
        "resourceAuthType": "0",  # 公开
        "resourceColumnList": dataset["columns"],
        "resourceRowsCount": dataset["rows"],
        "resourceColumnCount": len(dataset["columns"]),
        "resourceSize": dataset["rows"] * len(dataset["columns"]) * 20  # 估算大小
    }

    return resource_data


def add_resources_to_node(node_url: str, token: str, node_name: str, datasets: list):
    """在指定节点上添加数据资源"""

    if not token:
        print(f"\n❌ {node_name} 的Token未设置，跳过")
        return []

    print(f"\n{'='*70}")
    print(f"在 {node_name} 上添加数据资源")
    print(f"节点地址: {node_url}")
    print(f"{'='*70}")

    # 创建API客户端
    client = PrimiHubAPIClient(node_url)
    client.token = token
    client.user_name = f"{node_name}_user"

    # 验证token
    print(f"\n▶ 验证 {node_name} 的Token...")
    try:
        response = client.get_user_list(page=1, page_size=1)
        if response.get('code') == 0:
            print(f"✅ Token验证成功")
        else:
            print(f"❌ Token验证失败: {response.get('msg')}")
            return []
    except Exception as e:
        print(f"❌ Token验证失败: {e}")
        return []

    # 创建数据资源
    created_resources = []

    for i, dataset_type in enumerate(datasets, 1):
        print(f"\n▶ [{i}/{len(datasets)}] 创建数据资源: {dataset_type}")
        print("-" * 70)

        try:
            # 生成资源数据
            resource_data = create_sample_resource_data(node_name, dataset_type)

            # 调用API创建资源
            start_time = time.time()
            response = client.create_resource(resource_data)
            duration = time.time() - start_time

            if response.get('code') == 0:
                resource_id = response.get('result', {}).get('resourceId')

                print(f"✅ 创建成功 (耗时: {duration:.2f}秒)")
                print(f"   资源名称: {resource_data['resourceName']}")
                print(f"   资源描述: {resource_data['resourceDesc']}")
                print(f"   数据行数: {resource_data['resourceRowsCount']:,}")
                print(f"   字段数量: {resource_data['resourceColumnCount']}")
                print(f"   数据大小: {resource_data['resourceSize'] / 1024:.2f} KB")

                if resource_id:
                    print(f"   资源ID: {resource_id}")
                    created_resources.append({
                        'node': node_name,
                        'resource_id': resource_id,
                        'resource_name': resource_data['resourceName'],
                        'dataset_type': dataset_type
                    })

                # 显示字段信息
                print(f"   字段列表:")
                for col in resource_data['resourceColumnList']:
                    print(f"     - {col['columnName']} ({col['columnType']}): {col['columnDesc']}")

            else:
                print(f"❌ 创建失败: {response.get('msg')}")

        except Exception as e:
            print(f"❌ 创建失败: {e}")
            import traceback
            traceback.print_exc()

        # 稍微延迟，避免请求过快
        if i < len(datasets):
            time.sleep(0.5)

    return created_resources


def verify_resources(node_url: str, token: str, node_name: str):
    """验证节点上的资源"""

    print(f"\n▶ 验证 {node_name} 的资源列表...")

    client = PrimiHubAPIClient(node_url)
    client.token = token

    try:
        response = client.get_resource_list(page=1, page_size=20)
        if response.get('code') == 0:
            result = response.get('result', {})
            resources = result.get('list', []) if isinstance(result, dict) else []

            print(f"✅ {node_name} 共有 {len(resources)} 个数据资源")

            if resources:
                print(f"\n   最近创建的资源:")
                for i, res in enumerate(resources[:5], 1):
                    print(f"   {i}. {res.get('resourceName')}")
                    print(f"      ID: {res.get('resourceId')}, 行数: {res.get('resourceRowsCount', 0):,}")

            return len(resources)
        else:
            print(f"❌ 获取资源列表失败: {response.get('msg')}")
            return 0
    except Exception as e:
        print(f"❌ 验证失败: {e}")
        return 0


def main():
    """主函数"""

    print("\n" + "="*70)
    print("在node0和node1上添加数据资源".center(70))
    print("="*70)

    # 检查token配置
    if not NODE0_TOKEN and not NODE1_TOKEN:
        print("\n" + "="*70)
        print("错误：请先设置Token！".center(70))
        print("="*70)
        print("\n请按以下步骤操作：")
        print("\n1. 获取node0的token：")
        print("   - 在浏览器中访问 http://node0_ip:port 并登录")
        print("   - 按F12 → Network → 找到token")
        print("   - 复制token值到本脚本的 NODE0_TOKEN 变量")
        print("\n2. 获取node1的token：")
        print("   - 在浏览器中访问 http://node1_ip:port 并登录")
        print("   - 按F12 → Network → 找到token")
        print("   - 复制token值到本脚本的 NODE1_TOKEN 变量")
        print("\n然后重新运行此脚本。")
        print("="*70)
        return

    # 定义要创建的数据集类型
    # node0创建用户特征和交易记录
    node0_datasets = ["user_features", "transaction_records"]

    # node1创建信用特征和交易记录
    node1_datasets = ["credit_features", "transaction_records"]

    all_created_resources = []

    # 在node0上创建资源
    if NODE0_TOKEN:
        resources = add_resources_to_node(
            NODE0_URL,
            NODE0_TOKEN,
            "node0",
            node0_datasets
        )
        all_created_resources.extend(resources)
    else:
        print(f"\n⚠️  跳过node0（未配置token）")

    # 在node1上创建资源
    if NODE1_TOKEN:
        resources = add_resources_to_node(
            NODE1_URL,
            NODE1_TOKEN,
            "node1",
            node1_datasets
        )
        all_created_resources.extend(resources)
    else:
        print(f"\n⚠️  跳过node1（未配置token）")

    # 验证创建的资源
    print("\n" + "="*70)
    print("验证创建结果".center(70))
    print("="*70)

    if NODE0_TOKEN:
        verify_resources(NODE0_URL, NODE0_TOKEN, "node0")

    if NODE1_TOKEN:
        verify_resources(NODE1_URL, NODE1_TOKEN, "node1")

    # 总结
    print("\n" + "="*70)
    print("创建总结".center(70))
    print("="*70)

    print(f"\n总共创建了 {len(all_created_resources)} 个数据资源：\n")

    if all_created_resources:
        for item in all_created_resources:
            print(f"✓ [{item['node']}] {item['dataset_type']}")
            print(f"  资源名称: {item['resource_name']}")
            print(f"  资源ID: {item['resource_id']}")
            print()
    else:
        print("未创建任何资源")

    # 保存结果到文件
    if all_created_resources:
        output_file = f"created_resources_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(all_created_resources, f, indent=2, ensure_ascii=False)

        print(f"\n📄 资源信息已保存到: {output_file}")

    print("\n" + "="*70)
    print("完成！".center(70))
    print("="*70 + "\n")


if __name__ == "__main__":
    import logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    main()
