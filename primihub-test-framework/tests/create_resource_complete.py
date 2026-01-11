#!/usr/bin/env python3
"""
完整的资源创建流程:
1. 创建CSV数据文件
2. 上传文件获取fileId
3. 使用fileId创建资源
"""

import sys
import os
import json
import time
import requests
from datetime import datetime
import tempfile

# 添加lib目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

# 你的配置
BASE_URL = "http://100.64.0.23:30811/prod-api"
TOKEN = "SU202601111503542F1167CD6FFFD38A270C80D9D96A928C"
USER_ID = 1


def create_sample_csv():
    """创建示例CSV文件"""
    print("="*70)
    print("  步骤1: 创建示例数据文件")
    print("="*70)

    csv_content = """user_id,age,gender,city,income,education
U001,25,1,北京,8000.5,3
U002,30,0,上海,12000.0,4
U003,28,1,深圳,10000.0,3
U004,35,0,广州,15000.0,5
U005,22,1,杭州,6000.0,2
U006,40,1,成都,18000.0,5
U007,26,0,武汉,7500.0,3
U008,33,1,南京,13000.0,4
U009,29,0,西安,9500.0,3
U010,31,1,重庆,11000.0,4
"""

    # 创建临时文件
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"user_features_{timestamp_str}.csv"
    temp_file = os.path.join(tempfile.gettempdir(), filename)

    with open(temp_file, 'w', encoding='utf-8') as f:
        f.write(csv_content)

    print(f"\n✅ 创建CSV文件: {temp_file}")
    print(f"   文件名: {filename}")
    print(f"   数据行数: 10")
    print(f"   字段数: 6")

    return temp_file, filename


def upload_file(file_path, filename):
    """上传文件到系统"""
    print("\n" + "="*70)
    print("  步骤2: 上传文件")
    print("="*70)

    url = f'{BASE_URL}/data/file/upload'

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    params = {
        'timestamp': timestamp,
        'nonce': nonce,
        'token': TOKEN
    }

    try:
        with open(file_path, 'rb') as f:
            files = {
                'file': (filename, f, 'text/csv')
            }

            # 需要的参数 - 包含timestamp/nonce/token
            data = {
                'userId': USER_ID,
                'fileName': filename,
                'fileSource': 1,  # 文件来源: 1=本地上传
                'timestamp': timestamp,
                'nonce': nonce,
                'token': TOKEN
            }

            print(f"\n▶ 上传文件: {filename}")
            print(f"   API: {url}")

            response = requests.post(
                url,
                files=files,
                data=data,
                params=params,
                timeout=30
            )

            print(f"\n✅ 上传完成")
            print(f"   状态码: {response.status_code}")

            if response.status_code == 200:
                result = response.json()
                print(f"\n响应:")
                print(json.dumps(result, indent=2, ensure_ascii=False))

                if result.get('code') == 0:
                    # fileId在 result.sysFile.fileId
                    sys_file = result.get('result', {}).get('sysFile', {})
                    file_id = sys_file.get('fileId')

                    if file_id:
                        print(f"\n🎉 文件上传成功!")
                        print(f"   fileId: {file_id}")
                        print(f"   文件路径: {sys_file.get('fileUrl')}")
                        print(f"   文件大小: {sys_file.get('fileSize')} bytes")
                        return file_id
                    else:
                        print(f"\n⚠️  未找到fileId，完整响应:")
                        print(json.dumps(result, indent=2, ensure_ascii=False))
                        return None
                else:
                    print(f"\n❌ 上传失败: {result.get('msg')}")
                    return None
            else:
                print(f"\n❌ HTTP错误: {response.status_code}")
                print(f"   响应: {response.text}")
                return None

    except Exception as e:
        print(f"\n❌ 上传错误: {e}")
        import traceback
        traceback.print_exc()
        return None


def create_resource(file_id, filename):
    """使用fileId创建资源"""
    print("\n" + "="*70)
    print("  步骤3: 创建资源")
    print("="*70)

    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

    resource_data = {
        "resourceName": f"用户特征数据_{timestamp_str}",
        "resourceDesc": "用户基本信息和行为特征数据集",
        "resourceAuthType": 1,
        "resourceSource": 1,
        "tags": ["测试数据", "用户特征"],
        "fileId": file_id,
        "fieldList": [
            {
                "fieldName": "user_id",
                "fieldType": "String",  # 使用大写
                "fieldDesc": "用户ID",
                "relevance": 1,
                "grouping": 0,
                "protectionStatus": 0
            },
            {
                "fieldName": "age",
                "fieldType": "Integer",  # 使用Integer
                "fieldDesc": "年龄",
                "relevance": 0,
                "grouping": 0,
                "protectionStatus": 0
            },
            {
                "fieldName": "gender",
                "fieldType": "Integer",
                "fieldDesc": "性别(0:女,1:男)",
                "relevance": 0,
                "grouping": 1,
                "protectionStatus": 0
            },
            {
                "fieldName": "city",
                "fieldType": "String",
                "fieldDesc": "城市",
                "relevance": 0,
                "grouping": 1,
                "protectionStatus": 0
            },
            {
                "fieldName": "income",
                "fieldType": "Double",  # 使用Double
                "fieldDesc": "收入",
                "relevance": 0,
                "grouping": 0,
                "protectionStatus": 1
            },
            {
                "fieldName": "education",
                "fieldType": "Integer",
                "fieldDesc": "学历(1-5)",
                "relevance": 0,
                "grouping": 0,
                "protectionStatus": 0
            }
        ],
        "fusionOrganList": []  # 添加fusionOrganList字段
    }

    url = f'{BASE_URL}/data/resource/saveorupdateresource'

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1
    url = f'{url}?timestamp={timestamp}&nonce={nonce}&token={TOKEN}'

    resource_data['timestamp'] = timestamp
    resource_data['nonce'] = nonce
    resource_data['token'] = TOKEN

    headers = {
        'Content-Type': 'application/json',
        'userId': str(USER_ID)
    }

    print(f"\n▶ 创建资源: {resource_data['resourceName']}")
    print(f"   fileId: {file_id}")

    try:
        response = requests.post(
            url,
            json=resource_data,
            headers=headers,
            timeout=30
        )

        print(f"\n✅ 请求完成")
        print(f"   状态码: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print(f"\n响应:")
            print(json.dumps(result, indent=2, ensure_ascii=False))

            if result.get('code') == 0:
                print(f"\n🎉 资源创建成功!")
                resource_id = result.get('result', {}).get('resourceId')
                if resource_id:
                    print(f"   资源ID: {resource_id}")
                print(f"   资源名称: {resource_data['resourceName']}")
                return True
            else:
                print(f"\n❌ 创建失败: {result.get('msg')}")
                return False
        else:
            print(f"\n❌ HTTP错误: {response.status_code}")
            return False

    except Exception as e:
        print(f"\n❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_resources():
    """验证资源列表"""
    print("\n" + "="*70)
    print("  步骤4: 验证创建结果")
    print("="*70)

    timestamp = int(time.time() * 1000)
    nonce = timestamp % 1000 + 1

    url = f'{BASE_URL}/data/fusionResource/getResourceList'
    params = {
        'pageNo': 1,
        'pageSize': 10,
        'resourceId': '',
        'resourceName': '',
        'tagName': '',
        'resourceSource': '',
        'organId': '',
        'fileContainsY': '',
        'timestamp': timestamp,
        'nonce': nonce,
        'token': TOKEN
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        result = response.json()

        if result.get('code') == 0:
            resource_result = result.get('result', {})
            total = resource_result.get('total', 0)
            resources = resource_result.get('data', [])

            print(f"\n✅ 系统中现在共有 {total} 个资源")

            if resources:
                print(f"\n   资源列表:")
                for i, res in enumerate(resources, 1):
                    print(f"\n   {i}. {res.get('resourceName')}")
                    print(f"      资源ID: {res.get('resourceId')}")
                    print(f"      来源: {res.get('resourceSource')}")
                    print(f"      行数: {res.get('resourceRowsCount', 0):,}")
                    print(f"      列数: {res.get('resourceColumnCount', 0)}")
        else:
            print(f"⚠️  验证失败: {result.get('msg')}")

    except Exception as e:
        print(f"⚠️  验证异常: {e}")


def main():
    """主函数"""

    print("\n" + "="*70)
    print("  PrimiHub 完整资源创建流程")
    print(f"  节点: {BASE_URL}")
    print("="*70 + "\n")

    # 步骤1: 创建CSV文件
    csv_file, filename = create_sample_csv()

    if not csv_file:
        print("\n❌ 创建CSV文件失败")
        return False

    # 步骤2: 上传文件
    file_id = upload_file(csv_file, filename)

    # 清理临时文件
    try:
        os.remove(csv_file)
        print(f"\n🗑️  已清理临时文件: {csv_file}")
    except:
        pass

    if not file_id:
        print("\n❌ 文件上传失败，无法继续")
        return False

    # 步骤3: 创建资源
    success = create_resource(file_id, filename)

    if not success:
        print("\n❌ 资源创建失败")
        return False

    # 步骤4: 验证
    time.sleep(1)
    verify_resources()

    print("\n" + "="*70)
    print("  🎉 完成!")
    print("="*70)
    print("""
✅ 成功完成完整流程:
   1. ✅ 创建CSV数据文件
   2. ✅ 上传文件到系统
   3. ✅ 创建数据资源
   4. ✅ 验证资源创建

下一步:
1. 查看资源: python3 your_system_tool.py list
2. 在Web界面查看: http://100.64.0.23:30811
3. 创建更多资源: 再次运行此脚本
    """)
    print("="*70 + "\n")

    return True


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  操作已取消")
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
