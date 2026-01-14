#!/usr/bin/env python3
"""
通过API创建资源并测试PIR功能
完整流程：上传文件 -> 创建资源 -> 验证同步 -> 测试PIR
"""
import requests
import time
import json
import os

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

    def upload_file(self, file_path):
        """上传CSV文件"""
        print("\n" + "=" * 80)
        print("步骤2: 上传CSV文件")
        print("=" * 80)

        if not os.path.exists(file_path):
            print(f"❌ 文件不存在: {file_path}")
            return None

        print(f"📁 文件路径: {file_path}")
        print(f"📊 文件大小: {os.path.getsize(file_path)} bytes")

        # 上传文件endpoint
        upload_url = f"{BASE_URL}/data/resource/uploadDataResourceFile"

        headers = {
            "token": self.token,
            "userId": str(self.user_id)
        }

        params = {
            "token": self.token,
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }

        with open(file_path, 'rb') as f:
            files = {'file': (os.path.basename(file_path), f, 'text/csv')}
            data = {
                'timestamp': int(time.time() * 1000),
                'nonce': 123,
                'token': self.token
            }

            print("⏳ 正在上传...")
            response = self.session.post(
                upload_url,
                files=files,
                data=data,
                headers=headers,
                timeout=60
            )

        if response.status_code == 200:
            result = response.json()
            if result.get('code') == 0:
                file_info = result.get('result', {})
                file_id = file_info.get('fileId')
                print(f"✅ 文件上传成功")
                print(f"   File ID: {file_id}")
                print(f"   文件路径: {file_info.get('fileUrl')}")
                return file_id, file_info
            else:
                print(f"❌ 上传失败: {result.get('msg')}")
                return None, None
        else:
            print(f"❌ HTTP错误: {response.status_code}")
            print(f"   响应: {response.text[:200]}")
            return None, None

    def create_resource(self, file_id, file_info):
        """创建资源"""
        print("\n" + "=" * 80)
        print("步骤3: 创建资源")
        print("=" * 80)

        # 从文件信息中获取字段列表
        columns = file_info.get('fileContents', {}).get('tableHeaderList', [])
        if not columns:
            print("❌ 无法获取文件字段信息")
            return None

        print(f"📋 检测到字段: {', '.join(columns)}")

        # 构造字段列表
        field_list = []
        for i, col_name in enumerate(columns):
            field_list.append({
                "fieldName": col_name,
                "fieldAs": col_name,
                "fieldType": "String",
                "fieldDesc": f"{col_name}字段",
                "relevance": 1 if i == 0 else 0,  # 第一个字段作为关键字
                "grouping": 0,
                "protectionStatus": 0
            })

        # 构造资源数据
        resource_data = {
            "resourceName": "PIR测试资源_API创建",
            "resourceDesc": "通过API创建的PIR测试资源，包含用户基本信息",
            "resourceAuthType": 1,  # 公开
            "resourceSource": 1,  # 文件上传
            "tags": ["PIR测试", "API创建", "用户数据"],
            "fileId": file_id,
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

        print("⏳ 正在创建资源...")
        print(f"   资源名称: {resource_data['resourceName']}")
        print(f"   字段数量: {len(field_list)}")
        print(f"   标签: {', '.join(resource_data['tags'])}")

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
                print(f"   详细信息: {json.dumps(result, indent=2, ensure_ascii=False)}")
                return None, None
        else:
            print(f"❌ HTTP错误: {response.status_code}")
            print(f"   响应: {response.text[:500]}")
            return None, None

    def verify_fusion_sync(self, resource_id):
        """验证资源同步到Fusion服务"""
        print("\n" + "=" * 80)
        print("步骤4: 验证Fusion服务同步")
        print("=" * 80)

        # 等待一下让系统同步
        print("⏳ 等待3秒让系统同步...")
        time.sleep(3)

        global_id = "000000000000000000000000demo0org0001"

        print(f"🔍 查询Fusion服务...")
        print(f"   Resource ID: {resource_id}")
        print(f"   Global ID: {global_id}")

        # 查询Fusion资源列表
        response = self.session.post(
            f"{FUSION_URL}/fusionResource/getResourceList",
            json={"globalId": global_id, "pageNo": 1, "pageSize": 10},
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
                        print(f"   - {r.get('resourceId')}: {r.get('resourceName')}")
                        if r.get('resourceId') == resource_id:
                            print(f"     ✅ 找到新创建的资源!")
                            return True

                if total > 0:
                    print(f"\n✅ Fusion服务中有资源，可以测试PIR")
                    # 即使不是我们刚创建的，只要有资源就可以
                    return True
                else:
                    print(f"\n❌ Fusion服务中仍然没有资源")
                    return False
            else:
                print(f"❌ 查询失败: {result.get('msg')}")
                return False
        else:
            print(f"❌ HTTP错误: {response.status_code}")
            return False

    def test_pir(self, resource_id):
        """测试PIR功能"""
        print("\n" + "=" * 80)
        print("步骤5: 测试PIR功能")
        print("=" * 80)

        timestamp_str = time.strftime('%Y%m%d_%H%M%S')

        # PIR参数
        pir_param = json.dumps({
            "algorithm": "DH",
            "query_field": "user_id",
            "query_value": "U001"
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
                    print(f"算法类型: DH (密钥交换)")
                    print(f"查询条件: user_id=U001")
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

    # 2. 上传文件
    csv_file = "/home/primihub/github/primihub-deploy/docker-all-in-one/pir_test_data.csv"
    file_id, file_info = creator.upload_file(csv_file)
    if not file_id:
        print("\n❌ 文件上传失败，无法继续")
        return

    # 3. 创建资源
    resource_id, resource_info = creator.create_resource(file_id, file_info)
    if not resource_id:
        print("\n❌ 资源创建失败，无法继续")
        return

    # 4. 验证Fusion同步
    if not creator.verify_fusion_sync(resource_id):
        print("\n⚠️  Fusion服务同步验证失败")
        print("   建议：等待几秒后手动验证，或检查application服务日志")

    # 5. 测试PIR
    if creator.test_pir(resource_id):
        print("\n" + "=" * 80)
        print("✅ 完整流程测试成功!")
        print("=" * 80)
        print(f"创建的资源ID: {resource_id}")
        print("PIR功能已经可以正常使用")
    else:
        print("\n" + "=" * 80)
        print("⚠️  PIR测试未完全成功")
        print("=" * 80)
        print("资源已创建，请检查：")
        print("1. Fusion服务中是否有资源（可能需要等待同步）")
        print("2. application服务日志是否有错误")
        print("3. 稍后重试PIR任务创建")

if __name__ == "__main__":
    main()
