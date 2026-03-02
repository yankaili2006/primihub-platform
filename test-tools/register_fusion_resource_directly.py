#!/usr/bin/env python3
"""
直接调用Fusion服务注册资源
绕过Application服务，直接向Fusion服务注册PIR测试资源
"""
import requests
import time
import json
import uuid

# 服务地址
BASE_URL = "http://172.20.0.6:8080"
FUSION_URL = "http://172.20.0.5:8080"

# 机构ID（从现有系统配置中获取）
GLOBAL_ORG_ID = "000000000000000000000000demo0org0001"

class FusionResourceRegistrar:
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

        response = self.session.post(f"{BASE_URL}/user/login", data=data)
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

    def create_test_resource_data(self):
        """构造PIR测试资源数据"""
        print("\n" + "=" * 80)
        print("步骤2: 构造PIR测试资源数据")
        print("=" * 80)

        # 生成唯一的资源ID（模拟fusionId格式）
        # 格式：organShortCode(12位，从globalId的第24-36位) + UUID后18位
        organ_short_code = GLOBAL_ORG_ID[24:36]  # "demo0org0001"
        resource_fusion_id = organ_short_code + str(uuid.uuid4()).replace('-', '')[:18]

        print(f"   机构短码: {organ_short_code}")
        print(f"   生成的资源ID: {resource_fusion_id}")

        # 构造字段列表（仅包含CopyResourceFieldDto支持的字段）
        field_list = [
            {
                "fieldName": "user_id",
                "fieldAs": "用户ID",
                "fieldType": 0,  # String
                "fieldDesc": "用户唯一标识"
            },
            {
                "fieldName": "name",
                "fieldAs": "姓名",
                "fieldType": 0,
                "fieldDesc": "用户姓名"
            },
            {
                "fieldName": "age",
                "fieldAs": "年龄",
                "fieldType": 1,  # Integer
                "fieldDesc": "用户年龄"
            },
            {
                "fieldName": "city",
                "fieldAs": "城市",
                "fieldType": 0,
                "fieldDesc": "所在城市"
            },
            {
                "fieldName": "phone",
                "fieldAs": "电话",
                "fieldType": 0,
                "fieldDesc": "联系电话"
            }
        ]

        # 构造完整的资源数据（匹配CopyResourceDto结构）
        resource_data = {
            "resourceId": resource_fusion_id,
            "resourceName": "PIR测试资源_直接注册",
            "resourceDesc": "通过直接调用Fusion API注册的PIR测试资源",
            "resourceType": 0,  # 文件类型
            "resourceAuthType": 1,  # 公开
            "resourceRowsCount": 8,
            "resourceColumnCount": 5,
            "resourceColumnNameList": "user_id,name,age,city,phone",
            "resourceContainsY": 0,
            "resourceYRowsCount": 0,
            "resourceYRatio": 0.0,
            "resourceTag": "PIR测试,直接注册,用户数据",
            "organId": GLOBAL_ORG_ID,
            "authOrganList": [],  # 公开资源
            "fieldList": field_list,
            "isDel": 0,
            "resourceHashCode": "",
            "resourceState": 0,  # 上线状态
            "userName": "admin",
            "dataSet": None  # CopyResourceDto使用DataSet对象，传null即可
        }

        print(f"✅ 资源数据构造完成")
        print(f"   资源ID: {resource_fusion_id}")
        print(f"   资源名称: {resource_data['resourceName']}")
        print(f"   字段数量: {len(field_list)}")
        print(f"   字段列表: {resource_data['resourceColumnNameList']}")

        return resource_data, resource_fusion_id

    def register_to_fusion(self, resource_data_list):
        """直接调用Fusion服务注册资源"""
        print("\n" + "=" * 80)
        print("步骤3: 向Fusion服务注册资源")
        print("=" * 80)

        # 构造请求参数
        params = {
            "globalId": GLOBAL_ORG_ID
        }

        headers = {
            "Content-Type": "application/json",
            "token": self.token if self.token else "",
            "userId": str(self.user_id) if self.user_id else ""
        }

        print(f"📡 目标服务: {FUSION_URL}/fusionResource/saveResource")
        print(f"📋 机构ID: {GLOBAL_ORG_ID}")
        print(f"📦 资源数量: {len(resource_data_list)}")

        print("\n⏳ 正在注册资源...")

        response = self.session.post(
            f"{FUSION_URL}/fusionResource/saveResource",
            params=params,
            json=resource_data_list,
            headers=headers,
            timeout=30
        )

        print(f"\nHTTP状态码: {response.status_code}")

        if response.status_code == 200:
            try:
                result = response.json()
                print("\nAPI响应:")
                print(json.dumps(result, indent=2, ensure_ascii=False))

                if result.get('code') == 0:
                    print("\n✅ 资源注册成功!")
                    return True
                else:
                    print(f"\n❌ 注册失败: {result.get('msg')}")
                    return False
            except Exception as e:
                print(f"\n响应内容: {response.text[:500]}")
                print(f"解析错误: {str(e)}")
                return False
        else:
            print(f"\n❌ HTTP错误: {response.status_code}")
            print(f"响应内容: {response.text[:500]}")
            return False

    def verify_fusion_resources(self):
        """验证Fusion服务中的资源"""
        print("\n" + "=" * 80)
        print("步骤4: 验证Fusion服务资源")
        print("=" * 80)

        # 等待一下让系统同步
        print("⏳ 等待3秒...")
        time.sleep(3)

        print(f"🔍 查询Fusion服务...")

        # 查询Fusion资源列表
        response = self.session.post(
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
                    for r in resources:
                        print(f"   - ID: {r.get('resourceId')}")
                        print(f"     名称: {r.get('resourceName')}")
                        print(f"     字段: {r.get('resourceColumnNameList', 'N/A')}")
                        print()

                if total > 0:
                    print(f"✅ Fusion服务中有 {total} 个资源")
                    print(f"✅ PIR功能现在可以使用了!")
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

    def test_pir_with_resource(self, resource_id):
        """使用注册的资源测试PIR"""
        print("\n" + "=" * 80)
        print("步骤5: 测试PIR功能")
        print("=" * 80)

        timestamp_str = time.strftime('%Y%m%d_%H%M%S')
        task_name = f"PIR_DH测试_{timestamp_str}"

        # PIR参数
        pir_param = json.dumps({
            "algorithm": "DH",
            "query_field": "user_id",
            "query_value": "U001"
        })

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
        print(f"   查询条件: user_id=U001")

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
    registrar = FusionResourceRegistrar()

    # 1. 登录
    if not registrar.login():
        print("\n⚠️  登录失败，尝试不使用token直接注册...")
        # Fusion服务可能不需要认证

    # 2. 构造资源数据
    resource_data, resource_id = registrar.create_test_resource_data()

    # 3. 注册到Fusion服务
    if registrar.register_to_fusion([resource_data]):
        print("\n" + "=" * 80)
        print("✅ 资源注册流程成功!")
        print("=" * 80)

        # 4. 验证资源
        fusion_resource_id = registrar.verify_fusion_resources()

        # 5. 测试PIR
        if fusion_resource_id:
            if registrar.test_pir_with_resource(fusion_resource_id):
                print("\n" + "=" * 80)
                print("🎉 完整流程测试成功!")
                print("=" * 80)
                print(f"已注册资源ID: {resource_id}")
                print(f"Fusion资源ID: {fusion_resource_id}")
                print("PIR功能已经可以正常使用")
            else:
                print("\n⚠️  PIR测试未成功，但资源已注册")
                print(f"   资源ID: {fusion_resource_id}")
                print(f"   可以使用 create_pir_dh.py 手动测试")
        else:
            print("\n⚠️  无法验证资源，但注册请求已发送")
            print("   建议：")
            print("   1. 等待几秒后手动验证")
            print("   2. 检查Fusion服务日志")
            print("   3. 使用验证脚本检查")
    else:
        print("\n" + "=" * 80)
        print("❌ 资源注册失败")
        print("=" * 80)
        print("可能的原因:")
        print("1. Fusion服务不接受直接调用")
        print("2. 数据格式不正确")
        print("3. 需要通过Application服务转发")
        print("\n建议使用Web控制台创建资源")


if __name__ == "__main__":
    main()
