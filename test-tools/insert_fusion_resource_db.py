#!/usr/bin/env python3
"""
直接向fusion1数据库插入资源记录
这是最直接的方式，绕过所有服务层
"""
import mysql.connector
import uuid
import time
from datetime import datetime

# 数据库配置
DB_CONFIG = {
    'host': '172.20.0.8',  # MySQL容器IP
    'port': 3306,
    'user': 'primihub',
    'password': 'primihub@123',
    'database': 'fusion1'
}

# 机构ID
GLOBAL_ORG_ID = "000000000000000000000000demo0org0001"


def insert_fusion_resource():
    """直接插入资源到fusion_resource表"""
    print("=" * 80)
    print("直接数据库插入方式注册Fusion资源")
    print("=" * 80)

    try:
        # 连接数据库
        print("\n⏳ 连接MySQL数据库...")
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print(f"✅ 数据库连接成功: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")

        # 生成资源ID
        organ_short_code = GLOBAL_ORG_ID[24:36]  # "demo0org0001"
        resource_id = organ_short_code + str(uuid.uuid4()).replace('-', '')[:18]

        print(f"\n📝 资源信息:")
        print(f"   资源ID: {resource_id}")
        print(f"   机构ID: {GLOBAL_ORG_ID}")
        print(f"   机构短码: {organ_short_code}")

        # 插入主资源记录
        resource_sql = """
        INSERT INTO fusion_resource (
            resource_id, resource_name, resource_desc, resource_type,
            resource_auth_type, resource_rows_count, resource_column_count,
            resource_column_name_list, resource_contains_y, resource_y_rows_count,
            resource_y_ratio, resource_tag, organ_id, resource_hash_code,
            resource_state, user_name, is_del, c_time, u_time
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
            %s, %s, %s, %s, %s, %s, %s, %s, %s
        )
        """

        now = datetime.now()
        resource_values = (
            resource_id,
            "PIR测试资源_DB直接插入",
            "通过数据库直接插入的PIR测试资源",
            0,  # resource_type: 文件类型
            1,  # resource_auth_type: 公开
            8,  # resource_rows_count
            5,  # resource_column_count
            "user_id,name,age,city,phone",  # resource_column_name_list
            0,  # resource_contains_y
            0,  # resource_y_rows_count
            0.0,  # resource_y_ratio
            "PIR测试,DB插入,用户数据",  # resource_tag
            GLOBAL_ORG_ID,  # organ_id
            "",  # resource_hash_code
            0,  # resource_state: 上线
            "admin",  # user_name
            0,  # is_del
            now,  # c_time
            now   # u_time
        )

        print("\n⏳ 插入fusion_resource表...")
        cursor.execute(resource_sql, resource_values)
        resource_db_id = cursor.lastrowid
        print(f"✅ 资源记录插入成功，数据库ID: {resource_db_id}")

        # 插入字段记录
        fields = [
            ("user_id", "用户ID", 0, "用户唯一标识"),
            ("name", "姓名", 0, "用户姓名"),
            ("age", "年龄", 1, "用户年龄"),
            ("city", "城市", 0, "所在城市"),
            ("phone", "电话", 0, "联系电话")
        ]

        field_sql = """
        INSERT INTO fusion_resource_field (
            resource_id, field_name, field_as, field_type, field_desc,
            is_del, c_time, u_time
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """

        print(f"\n⏳ 插入 {len(fields)} 个字段记录...")
        for field_name, field_as, field_type, field_desc in fields:
            field_values = (
                resource_db_id,  # resource_id (数据库ID)
                field_name,
                field_as,
                field_type,
                field_desc,
                0,  # is_del
                now,  # c_time
                now   # u_time
            )
            cursor.execute(field_sql, field_values)

        print(f"✅ {len(fields)} 个字段记录插入成功")

        # 提交事务
        conn.commit()
        print("\n" + "=" * 80)
        print("🎉 数据插入成功!")
        print("=" * 80)

        # 验证插入
        print("\n⏳ 验证数据...")
        cursor.execute(
            "SELECT resource_id, resource_name, organ_id FROM fusion_resource WHERE resource_id = %s",
            (resource_id,)
        )
        result = cursor.fetchone()
        if result:
            print(f"✅ 验证成功:")
            print(f"   资源ID: {result[0]}")
            print(f"   资源名称: {result[1]}")
            print(f"   机构ID: {result[2]}")
        else:
            print("❌ 验证失败：未找到插入的记录")

        cursor.close()
        conn.close()

        return resource_id

    except mysql.connector.Error as err:
        print(f"\n❌ 数据库错误: {err}")
        return None
    except Exception as e:
        print(f"\n❌ 错误: {str(e)}")
        return None


def verify_via_api(resource_id):
    """通过API验证资源是否可用"""
    import requests

    print("\n" + "=" * 80)
    print("通过API验证资源")
    print("=" * 80)

    FUSION_URL = "http://172.20.0.5:8080"

    try:
        response = requests.post(
            f"{FUSION_URL}/fusionResource/getResourceList",
            json={"globalId": GLOBAL_ORG_ID, "pageNo": 1, "pageSize": 20},
            timeout=10
        )

        if response.status_code == 200:
            result = response.json()
            if result.get('code') == 0:
                resources = result.get('result', {}).get('data', [])
                total = result.get('result', {}).get('total', 0)

                print(f"\n📊 Fusion服务资源统计:")
                print(f"   总数量: {total}")

                if resources:
                    print(f"\n📋 资源列表:")
                    found = False
                    for r in resources:
                        print(f"   - ID: {r.get('resourceId')}")
                        print(f"     名称: {r.get('resourceName')}")
                        print(f"     字段: {r.get('resourceColumnNameList', 'N/A')}")
                        if r.get('resourceId') == resource_id:
                            found = True
                            print(f"     ✅ 这是我们刚插入的资源!")
                        print()

                    if found:
                        print(f"✅ 成功！资源已可通过Fusion API访问")
                        return True
                    else:
                        print(f"⚠️  资源在数据库中，但API返回的列表中未找到")
                        return False
                else:
                    print(f"❌ Fusion API返回资源数量为0")
                    return False
            else:
                print(f"❌ API调用失败: {result.get('msg')}")
                return False
        else:
            print(f"❌ HTTP错误: {response.status_code}")
            return False

    except Exception as e:
        print(f"❌ API验证错误: {str(e)}")
        return False


def test_pir(resource_id):
    """测试PIR功能"""
    import requests
    import json

    print("\n" + "=" * 80)
    print("测试PIR功能")
    print("=" * 80)

    BASE_URL = "http://172.20.0.6:8080"

    try:
        # 登录
        print("⏳ 登录...")
        data = {
            "userAccount": "admin",
            "userPassword": "123456",
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }
        response = requests.post(f"{BASE_URL}/user/login", data=data)
        result = response.json()

        if result.get('code') != 0:
            print(f"❌ 登录失败: {result.get('msg')}")
            return False

        user_data = result['result']
        token = user_data.get('token')
        user_id = user_data.get('sysUser', {}).get('userId')
        print(f"✅ 登录成功，用户ID: {user_id}")

        # 创建PIR任务
        print(f"\n⏳ 创建PIR任务...")
        timestamp_str = time.strftime('%Y%m%d_%H%M%S')
        task_name = f"PIR_DH测试_DB插入_{timestamp_str}"

        pir_param = json.dumps({
            "algorithm": "DH",
            "query": "test"
        })

        params = {
            "resourceId": resource_id,
            "pirParam": pir_param,
            "taskName": task_name,
            "timestamp": int(time.time() * 1000),
            "nonce": 123,
            "token": token
        }

        headers = {
            "token": token,
            "userId": str(user_id)
        }

        response = requests.post(
            f"{BASE_URL}/data/pir/pirSubmitTask",
            params=params,
            headers=headers,
            timeout=30
        )

        print(f"HTTP状态码: {response.status_code}")

        if response.text:
            result = response.json()
            print("\nAPI响应:")
            print(json.dumps(result, indent=2, ensure_ascii=False))

            if result.get('code') == 0:
                print("\n" + "=" * 80)
                print("🎉 PIR任务创建成功!")
                print("=" * 80)
                return True
            else:
                print(f"\n⚠️  PIR任务创建失败: {result.get('msg')}")
                return False

    except Exception as e:
        print(f"❌ PIR测试错误: {str(e)}")
        return False


def main():
    print("\n" + "=" * 80)
    print("🚀 通过数据库直接注册Fusion资源并测试PIR")
    print("=" * 80)

    # 1. 插入资源到数据库
    resource_id = insert_fusion_resource()

    if not resource_id:
        print("\n❌ 资源插入失败")
        return

    # 2. 通过API验证
    print("\n⏳ 等待3秒...")
    time.sleep(3)

    if verify_via_api(resource_id):
        # 3. 测试PIR
        if test_pir(resource_id):
            print("\n" + "=" * 80)
            print("✅ 完整流程测试成功!")
            print("=" * 80)
            print(f"已创建资源ID: {resource_id}")
            print("PIR功能现在可以使用了!")
        else:
            print("\n⚠️  PIR测试未成功，但资源已创建")
            print(f"资源ID: {resource_id}")
    else:
        print("\n⚠️  API验证未成功，但资源已插入数据库")
        print(f"资源ID: {resource_id}")
        print("可以手动检查数据库和API")


if __name__ == "__main__":
    main()
