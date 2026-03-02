#!/usr/bin/env python3
"""
PIR (Private Information Retrieval / 匿踪查询) 任务创建模板

注意: 此脚本目前由于机构ID不匹配问题可能无法直接运行
请参考 PIR_API_GUIDE.md 了解详细信息和解决方案

问题: application服务的本地机构ID与fusion服务中的资源机构ID不匹配
- Nacos organ_info.json: 550e8400-e29b-41d4-a716-446655440000
- privacy1数据库: 000000000000000000000000test0001
- fusion1数据库: 000000000000000000000000demo0org0001
"""
import requests
import time
import json
import os
import argparse
import ipaddress
from datetime import datetime
from urllib.parse import urlparse


def _make_session(base_url: str = '') -> requests.Session:
    """代理感知的 Session：私有/本地/Tailscale 地址强制直连"""
    _PRIVATE = ('localhost', '127.0.0.1', '::1',
                '172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/16', '100.64.0.0/10')
    session = requests.Session()
    try:
        host = urlparse(base_url).hostname or ''
        addr = ipaddress.ip_address(host)
        for cidr in ('172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/16', '100.64.0.0/10'):
            if addr in ipaddress.ip_network(cidr):
                session.trust_env = False
                return session
    except ValueError:
        pass
    if urlparse(base_url).hostname in ('localhost', '127.0.0.1', '::1'):
        session.trust_env = False
        return session
    existing = os.environ.get('no_proxy') or os.environ.get('NO_PROXY') or ''
    needed = [s for s in _PRIVATE if s not in existing]
    if needed:
        os.environ['no_proxy'] = ','.join(filter(None, [existing] + list(needed)))
    return session


_parser = argparse.ArgumentParser(description='创建PIR匿踪查询任务', add_help=False)
_parser.add_argument('--url', default=os.environ.get('PRIMIHUB_URL', 'http://localhost:30811/prod-api'),
                     help='网关地址 (默认: http://localhost:30811/prod-api，可用 PRIMIHUB_URL 覆盖)')
_parser.add_argument('--resource-id', default='demo0org0001a1b2c3d4e5f6g7h8',
                     help='PIR资源ID (默认: demo0org0001a1b2c3d4e5f6g7h8)')
_parser.add_argument('--query', default='U001,U002',
                     help='查询参数 - 逗号分隔的查询值 (默认: U001,U002)')
_args, _ = _parser.parse_known_args()

BASE_URL = _args.url.rstrip('/prod-api').rstrip('/')
_session = _make_session(BASE_URL)


def login():
    """登录获取token"""
    data = {
        "userAccount": "admin",
        "userPassword": "123456",
        "timestamp": int(time.time() * 1000),
        "nonce": 123
    }
    response = _session.post(f"{BASE_URL}/prod-api/user/login", data=data)
    result = response.json()
    if result.get('code') == 0:
        user_data = result['result']
        return user_data.get('token'), user_data.get('sysUser', {}).get('userId')
    return None, None


def query_fusion_resources(token, user_id):
    """查询可用的融合资源"""
    headers = {"token": token, "userId": str(user_id)}
    response = _session.get(
        f"{BASE_URL}/prod-api/fusionResource/getResourceList",
        params={"pageNo": 1, "pageSize": 20},
        headers=headers
    )
    result = response.json()
    if result.get('code') == 0:
        result_data = result.get('result', {})
        if isinstance(result_data, dict):
            return result_data.get('data', [])
        return result_data
    return []


def create_pir_task(token, user_id, resource_id, pir_param):
    """创建PIR任务 - 使用简化API"""
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

    params = {
        "resourceId": resource_id,
        "pirParam": pir_param,
        "taskName": f"PIR匿踪查询_{timestamp_str}",
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }

    headers = {"token": token, "userId": str(user_id)}

    response = _session.post(
        f"{BASE_URL}/prod-api/pir/pirSubmitTask",
        params=params,
        headers=headers
    )

    return response


def get_pir_task_list(token, user_id, page_no=1, page_size=10):
    """获取PIR任务列表"""
    headers = {"token": token, "userId": str(user_id)}
    response = _session.get(
        f"{BASE_URL}/prod-api/pir/getPirTaskList",
        params={"pageNo": page_no, "pageSize": page_size},
        headers=headers
    )
    return response.json()


def get_pir_task_detail(token, user_id, task_id):
    """获取PIR任务详情"""
    headers = {"token": token, "userId": str(user_id)}
    response = _session.get(
        f"{BASE_URL}/prod-api/pir/getPirTaskDetail",
        params={"taskId": task_id},
        headers=headers
    )
    return response.json()


print("=" * 80)
print("PIR (Private Information Retrieval / 匿踪查询) 任务创建")
print("=" * 80)

# 登录
print("\n【步骤1】登录系统")
print(f"网关地址: {BASE_URL}/prod-api")
token, user_id = login()
if not token:
    print("❌ 登录失败")
    exit(1)
print(f"✅ 登录成功 - 用户ID: {user_id}")
print(f"Token: {token[:40]}...")

# 查询可用融合资源
print("\n【步骤2】查询可用PIR融合资源")
fusion_resources = query_fusion_resources(token, user_id)
print(f"找到 {len(fusion_resources)} 个融合资源")
if fusion_resources:
    for i, resource in enumerate(fusion_resources[:5], 1):
        print(f"  {i}. ID: {resource.get('resourceId', resource.get('id', 'N/A'))}")
        print(f"     名称: {resource.get('resourceName', resource.get('name', 'N/A'))}")
else:
    print("⚠️  未找到可用融合资源")
    print("提示: 融合资源需要明确授权或发布到融合网络")

# 创建PIR任务
print("\n【步骤3】创建PIR任务")
print(f"资源ID: {_args.resource_id}")
print(f"查询参数: {_args.query}")
print(f"说明: PIR (Private Information Retrieval) 允许在不泄露查询内容的情况下检索信息")

response = create_pir_task(token, user_id, _args.resource_id, _args.query)

print(f"\nHTTP状态码: {response.status_code}")

if response.text:
    result = response.json()
    print("\nAPI响应:")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result.get('code') == 0:
        pir_result = result.get('result', {})

        print("\n" + "=" * 80)
        print("🎉 PIR任务创建成功!")
        print("=" * 80)
        print(f"任务ID: {pir_result.get('taskId', 'N/A')}")
        print(f"任务UUID: {pir_result.get('taskIdName', 'N/A')}")
        print(f"任务状态: {pir_result.get('taskState')} (0=待执行, 1=成功, 2=运行中, 3=失败)")
        print(f"资源ID: {_args.resource_id}")
        print(f"查询参数: {_args.query}")
        print("=" * 80)

        # 等待任务完成
        task_id = pir_result.get('taskId')
        if task_id:
            print("\n【步骤4】等待任务完成...")
            for i in range(10):
                time.sleep(2)
                detail = get_pir_task_detail(token, user_id, task_id)
                if detail.get('code') == 0:
                    task_data = detail.get('result', {})
                    task_state = task_data.get('taskState', 0)
                    print(f"  检查 {i+1}/10 - 任务状态: {task_state}")
                    if task_state == 1:
                        print("\n✅ 任务执行成功!")
                        break
                    elif task_state == 3:
                        print("\n❌ 任务执行失败")
                        print(f"错误信息: {task_data.get('taskErrorMsg', 'N/A')}")
                        break
            else:
                print("\n⏳ 任务仍在运行中，请稍后查询")

    elif result.get('code') == 1007:
        print(f"\n❌ PIR任务创建失败: {result.get('msg')}")
        print("\n可能的原因:")
        print("  1. 资源ID不存在或格式错误")
        print("  2. 资源查询失败 - 机构ID不匹配")
        print("  3. fusion服务 (meta服务) 未正确注册或无法访问")
        print("\n调试步骤:")
        print("  1. 检查fusion服务是否在Nacos中注册:")
        print("     curl 'http://localhost:8848/nacos/v1/ns/service/list?namespaceId=demo0'")
        print("  2. 检查资源是否存在于fusion1数据库:")
        print(f"     docker exec mysql mysql -uroot -proot fusion1 -e \"SELECT * FROM fusion_resource WHERE resource_id='{_args.resource_id}'\\\\G\"")
        print("  3. 查看application0日志:")
        print("     docker logs application0 --tail=50 2>&1 | grep -E 'pir|PIR|资源|Feign'")
        print("  4. 参考PIR_API_GUIDE.md了解机构ID匹配问题")
        print(f"\n错误码: {result.get('code')}")
    else:
        print(f"\n❌ PIR任务创建失败: {result.get('msg')}")
        print(f"错误码: {result.get('code')}")
else:
    print("❌ 无响应内容")

# 显示任务列表
print("\n【步骤5】查看PIR任务列表")
task_list = get_pir_task_list(token, user_id, page_no=1, page_size=5)
if task_list.get('code') == 0:
    list_result = task_list.get('result', {})
    if isinstance(list_result, dict):
        tasks = list_result.get('data', [])
        total = list_result.get('total', 0)
    else:
        tasks = list_result if isinstance(list_result, list) else []
        total = len(tasks)

    print(f"共 {total} 个PIR任务 (显示最近5个):")
    for task in tasks[:5]:
        print(f"  任务ID: {task.get('taskId', task.get('id', 'N/A'))}")
        print(f"  任务名称: {task.get('taskName', 'N/A')}")
        print(f"  任务状态: {task.get('taskState', 'N/A')}")
        print(f"  创建时间: {task.get('createDate', 'N/A')}")
        print()

print("\n")
