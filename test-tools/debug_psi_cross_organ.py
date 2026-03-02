#!/usr/bin/env python3
"""
PSI跨机构任务执行诊断脚本
逐步验证PSI跨机构任务的前置条件并排查执行失败原因
"""
import requests
import json
import time
import sys

BASE_URL = "http://172.23.0.15:8080"  # gateway0 Docker network IP

# 预期的机构和资源配置
OWN_ORGAN_ID = "000000000000000000000000test0001"
OTHER_ORGAN_ID = "000000000000000000000000test0002"
OWN_RESOURCE_ID = "3"
OTHER_RESOURCE_ID = "4"
KEYWORD = "user_id"
PROJECT_ID = "3"

PASS = "PASS"
FAIL = "FAIL"
WARN = "WARN"

results = []

def log(level, step, msg):
    icon = {"PASS": "[OK]", "FAIL": "[FAIL]", "WARN": "[WARN]"}.get(level, "[INFO]")
    print(f"  {icon} {step}: {msg}")
    results.append((level, step, msg))

def login():
    """Step 1: 登录"""
    print("\n[Step 1] 登录系统")
    try:
        resp = requests.post(f"{BASE_URL}/user/login", data={
            "userAccount": "admin",
            "userPassword": "123456",
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }, timeout=10)
        r = resp.json()
        if r.get("code") == 0:
            token = r["result"]["token"]
            user_id = r["result"]["sysUser"]["userId"]
            log(PASS, "登录", f"用户ID={user_id}")
            return token, user_id
        else:
            log(FAIL, "登录", f"失败: {r.get('msg')}")
            return None, None
    except Exception as e:
        log(FAIL, "登录", f"异常: {e}")
        return None, None

def check_project(token, user_id):
    """Step 2: 检查项目存在且包含两个机构"""
    print(f"\n[Step 2] 检查项目 ID={PROJECT_ID}")
    headers = {"token": token, "userId": str(user_id)}
    try:
        resp = requests.get(f"{BASE_URL}/data/project/getProjectDetails", params={
            "projectId": PROJECT_ID,
            "token": token,
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }, headers=headers, timeout=10)
        r = resp.json()
        if r.get("code") == 0:
            proj = r.get("result", {})
            status = proj.get("status", -1)
            organs = proj.get("dataProjectOrganList", [])
            organ_ids = [o.get("organId") for o in organs]

            status_map = {0: "审核中(不可用)", 1: "可用", 2: "已关闭"}
            log(PASS if status == 1 else FAIL, "项目状态",
                f"{status_map.get(status, status)} - 项目名: {proj.get('projectName')}")

            if OWN_ORGAN_ID in organ_ids:
                log(PASS, "发起方机构", f"{OWN_ORGAN_ID[:20]}... 在项目中")
            else:
                log(FAIL, "发起方机构", f"{OWN_ORGAN_ID[:20]}... 不在项目机构列表中: {organ_ids}")

            if OTHER_ORGAN_ID in organ_ids:
                log(PASS, "协作方机构", f"{OTHER_ORGAN_ID[:20]}... 在项目中")
            else:
                log(FAIL, "协作方机构", f"{OTHER_ORGAN_ID[:20]}... 不在项目机构列表中: {organ_ids}")

            return status == 1
        else:
            log(FAIL, "项目查询", f"API错误: code={r.get('code')}, msg={r.get('msg')}")
            return False
    except Exception as e:
        log(FAIL, "项目查询", f"异常: {e}")
        return False

def check_resources(token, user_id):
    """Step 3: 检查两个机构的资源是否存在"""
    print(f"\n[Step 3] 检查资源可用性")
    headers = {"token": token, "userId": str(user_id)}
    resource_ok = True

    for res_id, organ_id, label in [
        (OWN_RESOURCE_ID, OWN_ORGAN_ID, "发起方"),
        (OTHER_RESOURCE_ID, OTHER_ORGAN_ID, "协作方")
    ]:
        try:
            resp = requests.get(f"{BASE_URL}/data/resource/getDataResource", params={
                "resourceId": res_id,
                "token": token,
                "timestamp": int(time.time() * 1000),
                "nonce": 123
            }, headers=headers, timeout=10)
            r = resp.json()
            if r.get("code") == 0:
                res = r.get("result", {})
                res_organ = res.get("organId") or res.get("organ_id")
                res_state = res.get("resourceState", -1)
                fields = res.get("fileHandleField", "")

                log(PASS if res_state == 0 else FAIL, f"{label}资源(ID={res_id})",
                    f"名称={res.get('resourceName')}, 状态={'上线' if res_state==0 else '下线'}")

                # 检查keyword字段是否存在
                if KEYWORD in (fields or ""):
                    log(PASS, f"{label}关键字字段", f"'{KEYWORD}' 存在于资源字段")
                else:
                    log(WARN, f"{label}关键字字段",
                        f"'{KEYWORD}' 可能不在字段列表中(需手动确认), 字段: {str(fields)[:100]}")

                resource_ok = resource_ok and (res_state == 0)
            else:
                log(FAIL, f"{label}资源(ID={res_id})", f"查询失败: {r.get('msg')}")
                resource_ok = False
        except Exception as e:
            log(FAIL, f"{label}资源(ID={res_id})", f"异常: {e}")
            resource_ok = False

    return resource_ok

def check_node_connectivity(token, user_id):
    """Step 4: 检查节点/机构连通性"""
    print(f"\n[Step 4] 检查机构节点连通性")
    headers = {"token": token, "userId": str(user_id)}
    try:
        resp = requests.get(f"{BASE_URL}/sys/organ/getGlobalOrganList", params={
            "token": token,
            "timestamp": int(time.time() * 1000),
            "nonce": 123
        }, headers=headers, timeout=10)
        r = resp.json()
        if r.get("code") == 0:
            organs = r.get("result", [])
            for organ in organs:
                organ_id = organ.get("organId", "")
                if organ_id in [OWN_ORGAN_ID, OTHER_ORGAN_ID]:
                    label = "发起方" if organ_id == OWN_ORGAN_ID else "协作方"
                    enable = organ.get("enable", 0)
                    gateway = organ.get("organGateway", "N/A")
                    log(PASS if enable else WARN, f"{label}节点连通性",
                        f"organId={organ_id[:20]}..., gateway={gateway}, enable={enable}")
        else:
            log(WARN, "节点连通性", f"无法获取机构列表: {r.get('msg')}")
    except Exception as e:
        log(WARN, "节点连通性", f"异常: {e}")

def test_psi_create_dh(token, user_id):
    """Step 5: 创建DH PSI任务并检查响应"""
    print(f"\n[Step 5] 创建DH PSI任务(算法验证)")
    headers = {"token": token, "userId": str(user_id)}
    ts = str(int(time.time()))
    params = {
        "taskName": f"PSI_DEBUG_DH_{ts}",
        "taskDesc": "调试脚本创建的PSI DH任务",
        "projectId": PROJECT_ID,
        "ownOrganId": OWN_ORGAN_ID,
        "ownResourceId": OWN_RESOURCE_ID,
        "ownKeyword": KEYWORD,
        "otherOrganId": OTHER_ORGAN_ID,
        "otherResourceId": OTHER_RESOURCE_ID,
        "otherKeyword": KEYWORD,
        "resultName": f"psi_debug_dh_{ts}",
        "resultOrganIds": OWN_ORGAN_ID,
        "outputContent": "0",
        "outputNoRepeat": "1",
        "outputFilePathType": "0",
        "tag": "0",      # 固定0，库类型标识
        "psiTag": "0",   # 0 = DH算法
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }
    try:
        resp = requests.post(f"{BASE_URL}/psi/saveDataPsi",
                             params=params, headers=headers, timeout=30)
        r = resp.json()
        print(f"  API响应: code={r.get('code')}, msg={r.get('msg')}")

        if r.get("code") == 0:
            result = r.get("result", {})
            task = result.get("dataPsiTask", {})
            task_id = task.get("taskId") or task.get("id")
            task_state = task.get("taskState")
            log(PASS, "DH PSI任务创建", f"taskId={task_id}, state={task_state}")
            return task_id
        else:
            log(FAIL, "DH PSI任务创建", f"code={r.get('code')}, msg={r.get('msg')}")
            print("  完整响应:")
            print(json.dumps(r, indent=4, ensure_ascii=False))
            return None
    except Exception as e:
        log(FAIL, "DH PSI任务创建", f"异常: {e}")
        return None

def test_psi_create_kkrt(token, user_id):
    """Step 6: 创建KKRT PSI任务并检查响应"""
    print(f"\n[Step 6] 创建KKRT PSI任务(算法验证)")
    headers = {"token": token, "userId": str(user_id)}
    ts = str(int(time.time()))
    params = {
        "taskName": f"PSI_DEBUG_KKRT_{ts}",
        "taskDesc": "调试脚本创建的PSI KKRT任务",
        "projectId": PROJECT_ID,
        "ownOrganId": OWN_ORGAN_ID,
        "ownResourceId": OWN_RESOURCE_ID,
        "ownKeyword": KEYWORD,
        "otherOrganId": OTHER_ORGAN_ID,
        "otherResourceId": OTHER_RESOURCE_ID,
        "otherKeyword": KEYWORD,
        "resultName": f"psi_debug_kkrt_{ts}",
        "resultOrganIds": OWN_ORGAN_ID,
        "outputContent": "0",
        "outputNoRepeat": "1",
        "outputFilePathType": "0",
        "tag": "0",      # 固定0，库类型标识（KKRT也用0）
        "psiTag": "2",   # 2 = KKRT算法
        "timestamp": int(time.time() * 1000),
        "nonce": 123,
        "token": token
    }
    try:
        resp = requests.post(f"{BASE_URL}/psi/saveDataPsi",
                             params=params, headers=headers, timeout=30)
        r = resp.json()
        print(f"  API响应: code={r.get('code')}, msg={r.get('msg')}")

        if r.get("code") == 0:
            result = r.get("result", {})
            task = result.get("dataPsiTask", {})
            task_id = task.get("taskId") or task.get("id")
            task_state = task.get("taskState")
            log(PASS, "KKRT PSI任务创建", f"taskId={task_id}, state={task_state}")
            return task_id
        else:
            log(FAIL, "KKRT PSI任务创建", f"code={r.get('code')}, msg={r.get('msg')}")
            print("  完整响应:")
            print(json.dumps(r, indent=4, ensure_ascii=False))
            return None
    except Exception as e:
        log(FAIL, "KKRT PSI任务创建", f"异常: {e}")
        return None

def monitor_task(token, user_id, task_id, label="PSI任务", max_wait=60):
    """Step 7: 监控任务状态"""
    if not task_id:
        return
    print(f"\n[Step 7] 监控{label}执行状态 (最多等待{max_wait}秒)")
    headers = {"token": token, "userId": str(user_id)}
    state_map = {0: "待执行", 1: "执行中", 2: "成功", 3: "失败"}
    start = time.time()

    while time.time() - start < max_wait:
        try:
            resp = requests.get(f"{BASE_URL}/psi/getPsiTaskDetails", params={
                "psiTaskId": task_id,
                "token": token,
                "timestamp": int(time.time() * 1000),
                "nonce": 123
            }, headers=headers, timeout=10)
            r = resp.json()
            if r.get("code") == 0:
                task = r.get("result", {})
                state = task.get("taskState", -1)
                state_text = state_map.get(state, f"未知({state})")
                elapsed = int(time.time() - start)
                print(f"  [{elapsed:3d}s] 状态: {state_text}", end="\r")

                if state == 2:
                    print()
                    log(PASS, f"{label}执行", "任务成功完成!")
                    rows = task.get("fileRows", 0)
                    print(f"       交集结果行数: {rows}")
                    return True
                elif state == 3:
                    print()
                    log(FAIL, f"{label}执行", "任务执行失败")
                    print(f"  完整任务详情:")
                    print(json.dumps(task, indent=4, ensure_ascii=False))
                    return False
        except Exception as e:
            print(f"\n  查询异常: {e}")
        time.sleep(3)

    print()
    log(WARN, f"{label}执行", f"超时({max_wait}秒)，任务可能仍在执行中")
    return None

def print_summary():
    """打印诊断汇总"""
    print("\n" + "=" * 70)
    print("诊断结果汇总")
    print("=" * 70)
    pass_count = sum(1 for r in results if r[0] == PASS)
    fail_count = sum(1 for r in results if r[0] == FAIL)
    warn_count = sum(1 for r in results if r[0] == WARN)

    for level, step, msg in results:
        icon = {"PASS": "[OK]  ", "FAIL": "[FAIL]", "WARN": "[WARN]"}.get(level, "[    ]")
        print(f"  {icon} {step}: {msg}")

    print("-" * 70)
    print(f"  汇总: {pass_count}项通过, {fail_count}项失败, {warn_count}项警告")
    if fail_count > 0:
        print("\n  失败项排查建议:")
        for level, step, msg in results:
            if level == FAIL:
                if "项目" in step:
                    print(f"    - {step}: 确认project_id={PROJECT_ID}存在且status=1(可用)")
                    print(f"             两个机构均在data_project_organ表中")
                elif "机构" in step:
                    print(f"    - {step}: 运行 fix_node_network_state.sql 或检查sys_organ表enable字段")
                elif "资源" in step:
                    print(f"    - {step}: 确认resource_id={OWN_RESOURCE_ID}/{OTHER_RESOURCE_ID}存在且resource_state=0")
                elif "PSI任务" in step:
                    print(f"    - {step}: 检查日志: docker logs primihub-application0 | grep psi")
                    print(f"             确认tag='0', psiTag=算法类型(0/1/2/3)")
    print("=" * 70)

if __name__ == "__main__":
    print("=" * 70)
    print("PSI跨机构任务执行诊断")
    print(f"目标: {BASE_URL}")
    print(f"发起方: {OWN_ORGAN_ID[:20]}... 资源{OWN_RESOURCE_ID}")
    print(f"协作方: {OTHER_ORGAN_ID[:20]}... 资源{OTHER_RESOURCE_ID}")
    print("=" * 70)

    token, user_id = login()
    if not token:
        print("\n无法登录，终止诊断")
        sys.exit(1)

    check_project(token, user_id)
    check_resources(token, user_id)
    check_node_connectivity(token, user_id)

    # 创建测试任务（仅在前置检查通过时）
    fail_count = sum(1 for r in results if r[0] == FAIL)
    if fail_count == 0:
        dh_task_id = test_psi_create_dh(token, user_id)
        if dh_task_id:
            monitor_task(token, user_id, dh_task_id, "DH PSI任务", max_wait=60)

        kkrt_task_id = test_psi_create_kkrt(token, user_id)
        if kkrt_task_id:
            monitor_task(token, user_id, kkrt_task_id, "KKRT PSI任务", max_wait=60)
    else:
        print(f"\n[跳过] 前置检查有 {fail_count} 项失败，跳过任务创建测试")
        print("  请先解决上述失败项，然后重新运行此脚本")

    print_summary()
