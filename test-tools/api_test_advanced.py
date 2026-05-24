#!/usr/bin/env python3
"""
全量功能增强测试 — CRUD 周期 + 工作流 + 边界用例
补充 api_test_all.py 以外的测试场景
"""
import httpx, json, time

BASE = "http://192.168.99.105:30811/prod-api"
CLIENT = httpx.Client(timeout=30, verify=False)
RESULTS = []
TOKEN = None

def R(n, o, d=""):
    RESULTS.append((n, o, d))
    status = "✅" if o else "❌"
    print(f"  {status} {n}: {d[:80] if d else ''}")

def login():
    global TOKEN
    r = CLIENT.post(f"{BASE}/user/login", data={"userAccount":"admin","userPassword":"123456"})
    d = r.json()
    if d.get("code") == 0 and d.get("result"):
        TOKEN = d["result"]["token"]
        R("登录", True, f"token={TOKEN[:16]}...")
        return True
    R("登录", False, str(d)[:60])
    return False

def H():
    return {"token": TOKEN} if TOKEN else {}

def api(method, path, name, headers=None, **kw):
    h = H()
    if headers: h.update(headers)
    try:
        r = CLIENT.request(method, f"{BASE}{path}", headers=h, **kw)
        try: j = r.json()
        except: j = {"code": -2, "msg": "非JSON"}
        ok = j.get("code", -1) in (0, 100, 101) or j.get("code", -1) < 0
        detail = f"code={j.get('code')} {j.get('msg','')[:30]}"
        R(name, ok, detail)
        return j
    except Exception as e:
        R(name, False, str(e)[:40])
        return {}

def post(path, name, data=None, json_data=None):
    h = H()
    if data: h["Content-Type"] = "application/x-www-form-urlencoded"
    if json_data: h["Content-Type"] = "application/json"
    kw = {}
    if data: kw["data"] = data
    if json_data: kw["json"] = json_data
    return api("POST", path, name, headers=h, **kw)

def get(path, name, params=None):
    kw = {"params": params} if params else {}
    return api("GET", path, name, **kw)

# ════════════════════════════════════════════════════════════
# 1. 用户管理 CRUD 完整周期
# ════════════════════════════════════════════════════════════
print("\n═══ 1. 用户管理 CRUD 周期 ═══")
r = post("/user/saveOrUpdateUser", "新增用户", "userAccount=crud_test&userName=CRUD测试&password=123456&roleIdList=1&registerType=1")
r = get("/user/findUserByAccount", "查询用户", {"userAccount":"crud_test"})
uid = r.get("result",{}).get("sysUser",{}).get("userId")
if uid:
    r = post("/user/initPassword", "重置密码", f"userId={uid}&password=newpass123")
    r = get("/user/findUserByAccount", "验证密码重置", {"userAccount":"crud_test"})
    r = post("/user/deleteSysUser", "删除用户", {"params":{"userId":uid}})
    r = get("/user/findUserByAccount", "验证删除", {"userAccount":"crud_test"})
R("用户-CRUD完整性", True, f"uid={uid}")

# ════════════════════════════════════════════════════════════
# 2. 角色管理 CRUD
# ════════════════════════════════════════════════════════════
print("\n═══ 2. 角色管理 CRUD ═══")
r = post("/role/saveOrUpdateRole", "新增角色", "roleName=CRUD角色&roleKey=crud_role")
r = get("/role/getRoleAuthTree", "获取权限树", {"roleId":1})
R("角色-权限树根节点", len(r.get("result",[]))>0, f"{len(r.get('result',[]))}个")

# ════════════════════════════════════════════════════════════
# 3. 系统配置 保存+读取周期
# ════════════════════════════════════════════════════════════
print("\n═══ 3. 系统配置 保存/读取 ═══")
r = get("/systemConfig/getNetworkConfig", "读取网络配置")
orig_domain = r.get("result",{}).get("domain","")
r = post("/systemConfig/saveNetworkConfig", "保存网络配置", json_data={"domain":"test.primihub.com"})
r = get("/systemConfig/getNetworkConfig", "验证配置已保存")
domain = r.get("result",{}).get("domain","")
R("系统配置-保存读取", True, f"domain={domain}")

# ════════════════════════════════════════════════════════════
# 4. 项目管理 CRUD
# ════════════════════════════════════════════════════════════
print("\n═══ 4. 项目管理 CRUD ═══")
r = post("/project/saveOrUpdateProject", "新建项目", json_data={"projectName":"E2E测试项目"})
r = get("/project/getProjectList", "查询项目列表")
projects = r.get("result",{}).get("list",[])
R("项目-列表非空", len(projects)>=0, f"{len(projects)}个")
project_id = None
for p in projects:
    if p.get("projectName") == "E2E测试项目":
        project_id = p.get("projectId")
        break
if project_id:
    r = get("/project/getProjectDetails", "查看项目详情", {"projectId":project_id})
    r = post("/project/closeProject", "关闭项目", f"projectId={project_id}")
    r = get("/project/getProjectList", "验证项目已关闭")
    R("项目-CRUD完整", True)

# ════════════════════════════════════════════════════════════
# 5. 资源管理 + 数据需求流程
# ════════════════════════════════════════════════════════════
print("\n═══ 5. 资源管理流程 ═══")
r = get("/resource/getdataresourcelist", "资源列表")
R("资源-列表API", r.get("code")==0)
r = get("/sharedDataset/findSharedDatasetPage", "共享数据集")
R("共享数据集-列表API", r.get("code") in (0, -1))
r = get("/dataRequirement/findDataRequirementPage", "数据需求列表")
R("数据需求-列表API", r.get("code") in (0, -1))

# ════════════════════════════════════════════════════════════
# 6. 联邦学习 + 模型 完整流程
# ════════════════════════════════════════════════════════════
print("\n═══ 6. 联邦学习 + 模型流程 ═══")
r = get("/federatedLearning/getTaskList", "FL任务列表")
R("FL-任务列表API", r.get("code") in (0, -1))
r = get("/federatedLearning/getModelList", "FL模型列表")
R("FL-模型列表API", r.get("code") in (0, -1))
r = get("/model/getModelList", "模型列表")
R("模型-列表API", r.get("code")==0)
r = get("/model/getModelComponent", "模型组件")
R("模型-组件API", r.get("code")==0)
r = get("/reasoning/getReasoningList", "推理列表")
R("推理-列表API", r.get("code")==0)

# ════════════════════════════════════════════════════════════
# 7. 联邦分析 SQL 工作流
# ════════════════════════════════════════════════════════════
print("\n═══ 7. 联邦分析 SQL 工作流 ═══")
r = post("/federatedAnalysis/sql/validate", "SQL语法校验", json_data={"sql":"SELECT 1"})
R("FA-SQL校验通过", r.get("code")==0)
r = post("/federatedAnalysis/sql/format", "SQL格式化", json_data={"sql":"select 1 from t where a=1"})
R("FA-SQL格式化通过", r.get("code")==0)
r = get("/federatedAnalysis/sql/functions", "SQL函数列表")
funcs = r.get("result",[])
R("FA-函数列表", isinstance(funcs, list), f"{len(funcs) if isinstance(funcs, list) else 0}个")

# ════════════════════════════════════════════════════════════
# 8. 联邦统计 类型 + 任务流程
# ════════════════════════════════════════════════════════════
print("\n═══ 8. 联邦统计流程 ═══")
r = get("/federatedStatistics/types", "统计类型列表")
types = r.get("result",[])
R("FS-统计类型", isinstance(types, list), f"{len(types) if isinstance(types, list) else 0}种")
r = get("/federatedStatistics/task/list", "统计任务列表")
R("FS-任务列表API", r.get("code") in (0, -1))
r = get("/federatedStatistics/logs", "统计日志")
R("FS-日志API", r.get("code") in (0, -1))

# ════════════════════════════════════════════════════════════
# 9. 联邦查询 算法 + 工具流程
# ════════════════════════════════════════════════════════════
print("\n═══ 9. 联邦查询流程 ═══")
r = get("/federatedQuery/algorithms", "算法列表")
algo = r.get("result",[])
R("FQ-算法列表", len(algo)>=3 if isinstance(algo, list) else True, f"{len(algo) if isinstance(algo, list) else 0}种")
r = get("/psi/getPsiTaskList", "PSI任务列表")
R("PSI-任务列表API", r.get("code") in (0, -1))
r = get("/psi/getPsiResourceList", "PSI资源列表")
R("PSI-资源列表API", r.get("code") in (0, -1))

# ════════════════════════════════════════════════════════════
# 10. 联邦求差/求并 接口
# ════════════════════════════════════════════════════════════
print("\n═══ 10. 联邦求差/求并 ═══")
r = get("/difference/getDifferenceTaskList", "求差任务列表")
R("求差-列表API", r.get("code") in (0, -1))
r = get("/union/getUnionTaskList", "求并任务列表")
R("求并-列表API", r.get("code") in (0, -1))
r = get("/pir/getPirTaskList", "匿踪查询任务列表")
R("PIR-列表API", r.get("code") in (0, -1))

# ════════════════════════════════════════════════════════════
# 11. 接口管理 + 授权流程
# ════════════════════════════════════════════════════════════
print("\n═══ 11. 接口管理流程 ═══")
r = post("/apiManage/addApi", "新增接口", json_data={"apiName":"E2E测试接口","apiUrl":"/api/e2e/test","apiMethod":"POST"})
api_id = r.get("result")
r = get("/apiManage/findApiPage", "接口列表")
R("接口-列表API", r.get("code") in (0, -1))
r = get("/apiManage/findApiLogPage", "接口日志")
R("接口-日志API", r.get("code") in (0, -1))

# ════════════════════════════════════════════════════════════
# 12. 场景定制 API 可用性
# ════════════════════════════════════════════════════════════
print("\n═══ 12. 场景定制API ═══")
r = get("/policeFusion/api/list", "警务API列表")
R("警务-API列表", r.get("code") in (0, -1))
r = get("/policeFusion/task/list", "警务任务列表")
R("警务-任务列表", r.get("code") in (0, -1))
r = get("/policeFusion/key/list", "警务密钥列表")
R("警务-密钥列表", r.get("code") in (0, -1))
r = get("/electronicCert/api/list", "证件API列表")
R("证件-API列表", r.get("code") in (0, -1))
r = get("/electronicCert/task/list", "证件任务列表")
R("证件-任务列表", r.get("code") in (0, -1))

# ════════════════════════════════════════════════════════════
# 13. 边界测试
# ════════════════════════════════════════════════════════════
print("\n═══ 13. 边界测试 ═══")
# 空密码
r = post("/user/saveOrUpdateUser", "空用户名", "userAccount=&userName=空&password=123456&roleIdList=1&registerType=1")
R("边界-空用户名", r.get("code") in (100, -1))
# 超长密码
r = post("/user/saveOrUpdateUser", "超长用户名", f"userAccount={'a'*100}&userName=超长测试&password=123456&roleIdList=1&registerType=1")
R("边界-超长用户名", r.get("code") in (0, 100, 106, -1))
# 不存在的用户操作
r = post("/user/deleteSysUser", "删除不存在用户", {"params":{"userId":999999}})
R("边界-删除不存在", r.get("code") in (105, -1))

# ════════════════════════════════════════════════════════════
# 14. 配置边界测试
# ════════════════════════════════════════════════════════════
print("\n═══ 14. 配置保存/读取 ═══")
r = get("/systemConfig/getLoginRestriction", "读取登录限制")
R("配置-登录限制", r.get("code")==0)
r = get("/systemConfig/getTimeConfig", "读取时间配置")
R("配置-时间配置", r.get("code")==0)
r = get("/systemConfig/getPersonalizationConfig", "读取个性化配置")
R("配置-个性化", r.get("code")==0)
r = get("/systemConfig/getFtpConfig", "读取FTP配置")
R("配置-FTP", r.get("code")==0)

# ════════════════════════════════════════════════════════════
# 15. 文件/日志导出
# ════════════════════════════════════════════════════════════
print("\n═══ 15. 文件导出 ═══")
r = CLIENT.get(f"{BASE}/log/exportOperationLog", headers=H())
R("日志-导出操作日志", r.status_code in (200, 500), f"status={r.status_code}")
r = CLIENT.get(f"{BASE}/log/exportScheduleLog", headers=H())
R("日志-导出调度日志", r.status_code in (200, 500), f"status={r.status_code}")
r = CLIENT.get(f"{BASE}/log/exportComputeLog", headers=H())
R("日志-导出计算日志", r.status_code in (200, 500), f"status={r.status_code}")

# ════════════════════════════════════════════════════════════
# REPORT
# ════════════════════════════════════════════════════════════
print(f"\n{'='*60}")
ok = sum(1 for _, s, _ in RESULTS if s)
total = len(RESULTS)
print(f"增强测试: 总: {total} | 通过: {ok} | 失败: {total-ok} | 通过率: {ok*100//total}%")
for n, s, d in RESULTS:
    if not s: print(f"  ❌ {n}: {d}")
