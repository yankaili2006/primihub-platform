#!/usr/bin/env python3
"""
使用你的Token创建数据资源
"""

import sys
import os
import json
import time
from datetime import datetime

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient

# 你的配置
BASE_URL = "http://100.64.0.23:30811/prod-api"
TOKEN = "SU202601111503542F1167CD6FFFD38A270C80D9D96A928C"


def test_and_create_resources():
    """测试token并创建资源"""

    print("="*70)
    print("  使用你的Token创建数据资源")
    print("="*70)
    print(f"节点地址: {BASE_URL}")
    print(f"Token: {TOKEN[:30]}...")

    # 创建API客户端
    client = PrimiHubAPIClient(BASE_URL)
    client.token = TOKEN

    # 步骤1: 验证Token
    print(f"\n{'='*70}")
    print("  步骤1: 验证Token")
    print("="*70)

    try:
        response = client.get_user_list(page=1, page_size=1)

        if response.get('code') == 0:
            print(f"✅ Token验证成功!")
        else:
            print(f"❌ Token验证失败: {response.get('msg')}")
            return
    except Exception as e:
        print(f"❌ Token验证失败: {e}")
        return

    # 步骤2: 获取当前资源列表
    print(f"\n{'='*70}")
    print("  步骤2: 查看现有资源")
    print("="*70)

    try:
        response = client.get_resource_list(page=1, page_size=20)

        if response.get('code') == 0:
            result = response.get('result', {})
            resources = result.get('list', []) if isinstance(result, dict) else []
            total = result.get('total', 0) if isinstance(result, dict) else 0

            print(f"✅ 当前共有 {total} 个数据资源")

            if resources:
                print(f"\n最近的资源:")
                for i, res in enumerate(resources[:5], 1):
                    print(f"  {i}. {res.get('resourceName')}")
                    print(f"     ID: {res.get('resourceId')}, 行数: {res.get('resourceRowsCount', 0):,}")
        else:
            print(f"⚠️  获取资源列表失败: {response.get('msg')}")
    except Exception as e:
        print(f"⚠️  获取资源列表异常: {e}")

    # 步骤3: 创建新资源
    print(f"\n{'='*70}")
    print("  步骤3: 创建数据资源")
    print("="*70)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    # 定义要创建的资源
    datasets = [
        {
            "name": "用户特征数据",
            "resourceName": f"用户特征数据_{timestamp}",
            "resourceDesc": "用户基本信息和行为特征数据集",
            "resourceColumnList": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "age", "columnType": "int", "columnDesc": "年龄"},
                {"columnName": "gender", "columnType": "int", "columnDesc": "性别(0:女,1:男)"},
                {"columnName": "city", "columnType": "string", "columnDesc": "城市"},
                {"columnName": "income", "columnType": "float", "columnDesc": "收入"},
                {"columnName": "education", "columnType": "int", "columnDesc": "学历(1-5)"},
            ],
            "rows": 10000
        },
        {
            "name": "交易记录数据",
            "resourceName": f"交易记录数据_{timestamp}",
            "resourceDesc": "用户交易行为数据集",
            "resourceColumnList": [
                {"columnName": "user_id", "columnType": "string", "columnDesc": "用户ID"},
                {"columnName": "transaction_id", "columnType": "string", "columnDesc": "交易ID"},
                {"columnName": "amount", "columnType": "float", "columnDesc": "交易金额"},
                {"columnName": "timestamp", "columnType": "long", "columnDesc": "交易时间戳"},
                {"columnName": "merchant_id", "columnType": "string", "columnDesc": "商户ID"},
                {"columnName": "category", "columnType": "string", "columnDesc": "交易类别"},
            ],
            "rows": 50000
        }
    ]

    created_resources = []

    for i, dataset in enumerate(datasets, 1):
        print(f"\n▶ [{i}/{len(datasets)}] 创建: {dataset['name']}")
        print("-"*70)

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
            start_time = time.time()
            response = client.create_resource(resource_data)
            duration = time.time() - start_time

            if response.get('code') == 0:
                resource_id = response.get('result', {}).get('resourceId')

                print(f"✅ 创建成功 (耗时: {duration:.2f}秒)")
                print(f"   资源名称: {resource_data['resourceName']}")
                print(f"   资源ID: {resource_id}")
                print(f"   数据行数: {resource_data['resourceRowsCount']:,}")
                print(f"   字段数量: {resource_data['resourceColumnCount']}")

                created_resources.append({
                    'resource_id': resource_id,
                    'resource_name': resource_data['resourceName'],
                    'dataset_type': dataset['name']
                })

                # 显示字段
                print(f"   字段列表:")
                for col in resource_data['resourceColumnList']:
                    print(f"     - {col['columnName']} ({col['columnType']}): {col['columnDesc']}")
            else:
                print(f"❌ 创建失败: {response.get('msg')}")

        except Exception as e:
            print(f"❌ 创建失败: {e}")
            import traceback
            traceback.print_exc()

        # 延迟
        if i < len(datasets):
            time.sleep(0.5)

    # 总结
    print(f"\n{'='*70}")
    print("  创建总结")
    print("="*70)

    if created_resources:
        print(f"\n✅ 成功创建 {len(created_resources)} 个数据资源:\n")

        for item in created_resources:
            print(f"✓ {item['dataset_type']}")
            print(f"  资源名称: {item['resource_name']}")
            print(f"  资源ID: {item['resource_id']}")
            print()

        # 保存结果
        output_file = f"created_resources_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(created_resources, f, indent=2, ensure_ascii=False)

        print(f"📄 资源信息已保存到: {output_file}")
    else:
        print("\n未创建任何资源")

    print("\n" + "="*70 + "\n")


if __name__ == "__main__":
    try:
        test_and_create_resources()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
