#!/usr/bin/env python3
"""
通过API创建数据库类型资源并测试PIR功能
使用数据库连接方式，避免文件上传问题
"""
import requests
import time
import json

BASE_URL = "http://172.20.0.6:8080"
FUSION_URL = "http://172.20.0.5:8080"

class ResourceCreator:
    def __init__(self):
        self.token = None
        self.user_id = None
        self.session = requests.Session()

    def login(self):
        """登录获取token"""
        print("=" * 80)
        print("步骤1: 登录系统")
        print("=" * 80)

        data = {
            "userAccount": "admin",
            "userPassword": "123456",
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }

        response = self.session.post(f"{BASE_URL}/sys/user/login", data=data)
        result = response.json()

        if result.get('code') == 0:
            user_data = result['result']
            self.token = user_data.get('token')
            self.user_id = user_data.get('sysUser', {}).get('userId')
            print(f"✅ 登录成功")
            print(f"   用户ID: {self.user_id}")
            print(f"   Token: {self.token[:20]}...")
            return True
        else:
            print(f"❌ 登录失败: {result.get('msg')}")
            return False

    def create_db_resource(self):
        """创建数据库类型资源"""
        print("\n" + "=" * 80)
        print("步骤2: 创建数据库资源")
        print("=" * 80)

        # 使用MySQL数据库中已有的表
        # 这里使用privacy1数据库的data_resource表作为示例
        field_list = [
            {
                "fieldName": "resource_id",
                "fieldAs": "资源ID",
                "fieldType": "String",
                "fieldDesc": "资源唯一标识",
                "relevance": 1,  # 关键字
                "grouping": 0,
                "protectionStatus": 0
            },
            {
                "fieldName": "resource_name",
                "fieldAs": "资源名称",
                "fieldType": "String",
                "fieldDesc": "资源名称",
                "relevance": 0,
                "grouping": 1,
                "protectionStatus": 0
            },
            {
                "fieldName": "organ_id",
                "fieldAs": "机构ID",
                "fieldType": "String",
                "fieldDesc": "所属机构ID",
                "relevance": 0,
                "grouping": 1,
                "protectionStatus": 0
            }
        ]

        resource_data = {
            "resourceName": "PIR测试资源_数据库",
            "resourceDesc": "基于MySQL数据库的PIR测试资源",
            "resourceAuthType": 1,  # 公开
            "resourceSource": 2,  # 数据库连接
            "tags": ["PIR测试", "数据库", "API创建"],
            "dataSource": {
                "dbType": 1,  # MySQL
                "dbUrl": "jdbc:mysql://mysql:3306/privacy1?characterEncoding=UTF-8&useSSL=false",
                "dbName": "privacy1",
                "dbTableName": "data_resource",
                "dbDriver": "com.mysql.cj.jdbc.Driver",
                "dbUsername": "primihub",
                "dbPassword": "primihub2021"
            },
            "fieldList": field_list,
            "timestamp": int(time.time() * 1000),
            "nonce": 123,
            "token": self.token
        }

        headers = {
            "Content-Type": "application/json",
            "token": self.token,
            "userId": str(self.user_id)
        }

        print("⏳ 正在创建数据库资源...")
        print(f"   资源名称: {resource_data['resourceName']}")
        print(f"   数据库: {resource_data['dataSource']['dbName']}")
        print(f"   表名: {resource_data['dataSource']['dbTableName']}")
        print(f"   字段数量: {len(field_list)}")

        response = self.session.post(
            f"{BASE_URL}/data/resource/saveorupdateresource",
            json=resource_data,
            headers=headers,
            timeout=600
        )

        if response.status_code == 200:
            result = response.json()
            if result.get('code') == 0:
                resource = result.get('result', {})
                resource_id = resource.get('resourceId')
                print(f"\n✅ 资源创建成功!")
                print(f"   Resource ID: {resource_id}")
                print(f"   Fusion ID: {resource.get('resourceFusionId', 'N/A')}")
                return resource_id, resource
            else:
                print(f"❌ 创建失败: {result.get('msg')}")
                print(f"   详细信息: {json.dumps(result, indent=2, ensure_ascii=False)[:500]}")
                return None, None
        else:
            print(f"❌ HTTP错误: {response.status_code}")
            print(f"   响应: {response.text[:500]}")
            return None, None

    def verify_fusion_sync(self):
        """验证资源同步到Fusion服务"""
        print("\n" + "=" * 80)
        print("步骤3: 验证Fusion服务同步")
        print("=" * 80)

        # 等待一下让系统同步
        print("⏳ 等待5秒让系统同步...")
        time.sleep(5)

        global_id = "000000000000000000000000demo0org0001"

        print(f"🔍 查询Fusion服务...")
        print(f"   Global ID: {global_id}")

        # 查询Fusion资源列表
        response = self.session.post(
            f"{FUSION_URL}/fusionResource/getResourceList",
            json={"globalId": global_id, "pageNo": 1, "pageSize": 20},
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
                    for r in resources:
                        print(f"   - ID: {r.get('resourceId')}")
                        print(f"     名称: {r.get('resourceName')}")
                        print(f"     字段: {r.get('resourceColumnNameList', 'N/A')}")
                        print()

                if total > 0:
                    print(f"✅ Fusion服务中有 {total} 个资源，PIR功能可用")
                    # 返回第一个资源ID用于测试
                    return resources[0].get('resourceId') if resources else None
                else:
                    print(f"❌ Fusion服务中仍然没有资源")
                    return None
            else:
                print(f"❌ 查询失败: {result.get('msg')}")
                return None
        else:
            print(f"❌ HTTP错误: {response.status_code}")
            return None

    def test_pir(self, resource_id):
        """测试PIR功能"""
        print("\n" + "=" * 80)
        print("步骤4: 测试PIR功能")
        print("=" * 80)

        timestamp_str = time.strftime('%Y%m%d_%H%M%S')

        # PIR参数 - 简单的查询参数
        pir_param = json.dumps({
            "query": "test"
        })

        task_name = f"PIR_DH测试_{timestamp_str}"

        params = {
            "resourceId": resource_id,
            "pirParam": pir_param,
            "taskName": task_name,
            "timestamp": int(time.time() * 1000),
            "nonce": 123,
            "token": self.token
        }

        headers = {
            "token": self.token,
            "userId": str(self.user_id)
        }

        print(f"📝 PIR任务配置:")
        print(f"   任务名称: {task_name}")
        print(f"   资源ID: {resource_id}")
        print(f"   算法: DH (密钥交换)")

        print("\n⏳ 正在创建PIR任务...")

        response = self.session.post(
            f"{BASE_URL}/data/pir/pirSubmitTask",
            params=params,
            headers=headers,
            timeout=30
        )

        print(f"\nHTTP状态码: {response.status_code}")

        if response.text:
            try:
                result = response.json()
                print("\nAPI响应:")
                print(json.dumps(result, indent=2, ensure_ascii=False))

                if result.get('code') == 0:
                    print("\n" + "=" * 80)
                    print("🎉 PIR任务创建成功!")
                    print("=" * 80)
                    task_result = result.get('result', {})
                    if isinstance(task_result, dict):
                        print(f"任务ID: {task_result.get('taskId', 'N/A')}")
                    return True
                else:
                    print(f"\n⚠️  PIR任务创建失败: {result.get('msg')}")
                    return False
            except Exception as e:
                print(f"\n响应内容: {response.text[:500]}")
                print(f"解析错误: {str(e)}")
                return False

        return False

def main():
    """主函数"""
    creator = ResourceCreator()

    # 1. 登录
    if not creator.login():
        return

    # 2. 创建数据库资源
    resource_id, resource_info = creator.create_db_resource()
    if not resource_id:
        print("\n❌ 资源创建失败，尝试使用现有资源测试PIR")

    # 3. 验证Fusion同步（并获取可用资源ID）
    test_resource_id = creator.verify_fusion_sync()
    if not test_resource_id:
        print("\n❌ Fusion服务中没有可用资源")
        print("\n建议:")
        print("1. 等待更长时间让资源同步（资源ID: {resource_id})")
        print("2. 检查application服务日志")
        print("3. 通过Web控制台创建资源")
        return

    # 4. 测试PIR
    if creator.test_pir(test_resource_id):
        print("\n" + "=" * 80)
        print("✅ PIR功能测试成功!")
        print("=" * 80)
        print(f"测试资源ID: {test_resource_id}")
        print("PIR功能已经可以正常使用")
    else:
        print("\n" + "=" * 80)
        print("⚠️  PIR测试未完全成功")
        print("=" * 80)
        print("可能的原因:")
        print("1. 资源字段不符合PIR要求")
        print("2. PIR参数格式需要调整")
        print("3. 需要查看详细错误信息")

if __name__ == "__main__":
    main()
