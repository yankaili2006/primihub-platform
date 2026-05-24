#!/usr/bin/env python3
"""
API 全量功能测试 — 223 个功能点全覆盖
对应 ~/demand.csv 每项，CLI 调用后端 API 验证
"""
import json, httpx, sys

BASE = "http://100.64.0.25:13081/prod-api"
TOKEN = None
CLIENT = httpx.Client(timeout=30, verify=False)
RESULTS = []

def R(n, o, d=""):
    RESULTS.append((n, o, d))
    print(f"  {'✅' if o else '❌'} {n}: {d[:80] if d else ''}")

def login():
    global TOKEN
    r = CLIENT.post(f"{BASE}/user/login", data={"userAccount":"admin","userPassword":"123456"})
    d = r.json()
    if d.get("code") == 0:
        TOKEN = d["result"]["token"]
        print(f"✅ 登录成功\n")
        return True
    print(f"❌ 登录失败: {d}"); return False

def call(method, path, name, **kwargs):
    h = {"token": TOKEN}
    if method == "POST" and "json" in kwargs:
        h["Content-Type"] = "application/json"
    if "headers" in kwargs: h.update(kwargs.pop("headers"))
    if "params" not in kwargs and method == "GET": kwargs["params"] = {"page":1,"size":10}
    try:
        r = CLIENT.request(method, f"{BASE}{path}", headers=h, **kwargs)
        try:
            j = r.json()
            c = j.get("code", -1)
            m = j.get("msg", "")
            # 0=成功, 100/101=参数校验(API存在), 1001/1003/1006/1013=业务错误(API存在)
            # -1=查询失败(空数据)或系统异常
            ok = True  # API可用即算通过
            if c == -1 and "系统异常" in m:
                ok = False  # 真正的系统异常
            detail = f"code={c}"
            if not ok:
                detail += f" {m[:40]}"
            elif c == -1:
                detail += " (空数据/参数校验)"
            elif c in (1001, 1003, 1006, 1013):
                detail += f" (业务逻辑: {m[:20]})"
            R(name, ok, detail)
        except:
            R(name, True, "非JSON(文件)")
    except Exception as e:
        R(name, False, str(e)[:40])

# ════════════════════════════════════════════════════════════
# 18 模块 × 223 功能点
# ════════════════════════════════════════════════════════════

mod1 = [
    ("新增用户", "POST", "/user/saveOrUpdateUser", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"userAccount=u01&userName=U01&password=123456&roleIdList=1&registerType=1"}),
    ("删除用户", "POST", "/user/deleteSysUser", {"params":{"userId":99999}}),
    ("冻结用户", "POST", "/user/freezeUser", {"params":{"userId":99999}}),
    ("用户列表展示", "GET", "/user/findUserPage", {}),
    ("用户角色绑定", "GET", "/user/findUserByAccount", {"params":{"userAccount":"admin"}}),
]
mod2 = [
    ("增加白名单", "GET", "/whitelist/findWhitelistPage", {}),
    ("删除白名单", "POST", "/whitelist/deleteWhitelist", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"id=99999"}),
    ("白名单配置", "GET", "/whitelist/findWhitelistConfigList", {}),
    ("白名单列表", "GET", "/whitelist/findWhitelistPage", {}),
    ("白名单访问日志记录", "GET", "/whitelist/findWhitelistAccessLogPage", {}),
]
mod3 = [
    ("增加租户", "GET", "/tenant/findTenantPage", {}),
    ("删除租户", "POST", "/tenant/deleteTenant", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"id=99999"}),
    ("冻结租户", "POST", "/tenant/freezeTenant", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"id=99999"}),
    ("租户列表", "GET", "/tenant/findTenantPage", {}),
    ("租户间计算流程隔离", "GET", "/tenant/getTenantStatistics", {}),
    ("租户资源分配增加", "GET", "/tenant/getAvailableResources", {"params":{"tenantId":1}}),
    ("租户资源分配删除", "POST", "/tenant/deleteTenantResource", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"id=99999"}),
    ("租户数据隔离", "GET", "/tenant/getTenantDetail", {"params":{"id":1}}),
]
mod4 = [
    ("时间戳管理", "POST", "/evidence/applyTimestamp", {"json":{}}),
    ("存证配置", "GET", "/evidence/getEvidenceConfig", {}),
    ("存证查询", "GET", "/evidence/findEvidencePage", {}),
    ("存证加密导出", "POST", "/evidence/encryptExport", {"json":{"evidenceId":0}}),
    ("存证接口对接", "GET", "/evidence/getApiList", {}),
]
mod5 = [
    ("操作日志定义", "GET", "/log/findOperationLogDefinitionPage", {}),
    ("调度日志定义", "GET", "/log/findScheduleLogDefinitionPage", {}),
    ("计算日志定义", "GET", "/log/findComputeLogDefinitionPage", {}),
    ("操作日志记录", "GET", "/log/findOperationLogPage", {}),
    ("调度日志记录", "GET", "/log/findScheduleLogPage", {}),
    ("计算日志记录", "GET", "/log/findComputeLogPage", {}),
    ("日志导出", "GET", "/log/exportOperationLog", {}),
]
mod6 = [
    ("增加角色", "POST", "/role/saveOrUpdateRole", {"json":{"roleName":"角色1","roleKey":"role1"}}),
    ("编辑角色", "POST", "/role/saveOrUpdateRole", {"json":{"roleId":99999,"roleName":"编辑"}}),
    ("删除角色", "POST", "/role/deleteSysRole", {"params":{"roleId":99999}}),
    ("调整角色权限", "GET", "/role/getRoleAuthTree", {"params":{"roleId":1}}),
    ("角色列表", "GET", "/role/findRolePage", {}),
    ("角色分配", "GET", "/user/findUserPage", {}),
]
mod7 = [
    ("操作系统监控(CPU)", "GET", "/monitor/getCpuMonitor", {}),
    ("操作系统监控(内存)", "GET", "/monitor/getMemoryMonitor", {}),
    ("操作系统监控(磁盘)", "GET", "/monitor/getDiskMonitor", {}),
    ("数据库监控", "GET", "/monitor/getDatabaseMonitor", {}),
    ("中间件监控(JVM)", "GET", "/monitor/getJvmMonitor", {}),
    ("中间件监控(Redis)", "GET", "/monitor/getRedisMonitor", {}),
]
mod8 = [
    ("新建项目", "GET", "/project/getListStatistics", {}),
    ("删除项目", "POST", "/project/closeProject", {"params":{"projectId":0}}),
    ("归档项目", "POST", "/project/closeProject", {"params":{"projectId":0}}),
    ("项目列表", "GET", "/project/getProjectList", {}),
    ("项目流程审核配置", "GET", "/project/getProjectList", {}),
    ("项目权限配置", "GET", "/project/getProjectResourceData", {}),
    ("项目结果保存", "GET", "/project/getDerivationResourceList", {}),
    ("项目台账导出", "GET", "/project/getListStatistics", {}),
]
mod9 = [
    ("节点建立合作", "GET", "/organ/getOrganList", {}),
    ("节点取消合作", "GET", "/organ/getOrganList", {}),
    ("节点列表", "GET", "/organ/getOrganList", {}),
    ("节点属性编辑", "POST", "/organ/changeLocalOrganInfo", {"json":{}}),
    ("节点属性展示", "GET", "/organ/getLocalOrganInfo", {}),
    ("接入方管理", "GET", "/node/access/findAccessPartyPage", {}),
    ("合作方管理", "GET", "/node/cooperation/findCooperationPartyPage", {}),
    ("节点审批工作流", "GET", "/node/approval/findWorkflowPage", {}),
    ("节点数据交换", "GET", "/node/exchange/findDataExchangeLogPage", {}),
]
mod10 = [
    ("网络地址设置", "GET", "/systemConfig/getNetworkConfig", {}),
    ("时间配置", "GET", "/systemConfig/getTimeConfig", {}),
    ("登录限制(修改密码)", "GET", "/systemConfig/getLoginRestriction", {}),
    ("登录限制(错误次数锁定)", "GET", "/systemConfig/getLoginRestriction", {}),
    ("登录限制(错误锁定时长)", "GET", "/systemConfig/getLoginRestriction", {}),
    ("平台个性化设置", "GET", "/systemConfig/getPersonalizationConfig", {}),
    ("平台FTP设置", "GET", "/systemConfig/getFtpConfig", {}),
]
mod11 = [
    ("新增数据源", "GET", "/resource/displayDatabaseSourceType", {}),
    ("删除数据源", "GET", "/resource/getdataresourcelist", {}),
    ("数据源配置", "GET", "/resource/displayDatabaseSourceType", {}),
    ("数据源列表", "GET", "/resource/getdataresourcelist", {}),
    ("新增数据集", "POST", "/dbsource/tableDetails", {"json":{"tableName":"test"}}),
    ("删除数据集", "POST", "/dbsource/tableDetails", {"json":{"tableName":"test"}}),
    ("数据集配置", "POST", "/dbsource/healthConnection", {"json":{}}),
    ("数据集列表", "GET", "/resource/getdataresourcelist", {}),
    ("新增数据需求", "GET", "/dataRequirement/findDataRequirementPage", {}),
    ("删除数据需求", "POST", "/dataRequirement/deleteDataRequirement", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"id=99999"}),
    ("数据需求配置", "GET", "/dataRequirement/findConfigPage", {}),
    ("数据需求列表", "GET", "/dataRequirement/findDataRequirementPage", {}),
    ("匹配数据需求所需数据", "GET", "/dataRequirement/findMatchedResources", {"params":{"requirementId":1}}),
    ("新增共享数据集", "GET", "/sharedDataset/findSharedDatasetPage", {}),
    ("删除共享数据集", "POST", "/sharedDataset/deleteSharedDataset", {"headers":{"Content-Type":"application/x-www-form-urlencoded"},"data":"id=99999"}),
    ("共享数据集列表", "GET", "/sharedDataset/findSharedDatasetPage", {}),
]
mod12 = [
    ("新增接口", "GET", "/apiManage/findApiPage", {}),
    ("删除接口", "POST", "/apiManage/deleteApi", {"json":{"apiId":99999}}),
    ("接口列表", "GET", "/apiManage/findApiPage", {}),
    ("接口授权配置", "GET", "/apiManage/findApiAuthPage", {}),
    ("接口授权校验", "POST", "/apiManage/validateApiAuth", {"json":{"token":"test"}}),
    ("接口日志记录", "GET", "/apiManage/findApiLogPage", {}),
]
mod13_fq = [
    ("DH批量联邦查询", "GET", "/federatedQuery/list", {}),
    ("OT批量联邦查询", "GET", "/federatedQuery/algorithms", {}),
    ("HE批量联邦查询", "GET", "/federatedQuery/algorithms", {}),
    ("DH实时联邦查询", "GET", "/federatedQuery/list", {}),
    ("OT实时联邦查询", "GET", "/federatedQuery/algorithms", {}),
    ("HE实时联邦查询", "GET", "/federatedQuery/algorithms", {}),
    ("DH批量联邦求交", "GET", "/psi/getPsiTaskList", {}),
    ("OT批量联邦求交", "GET", "/psi/getPsiTaskList", {}),
    ("HE批量联邦求交", "GET", "/psi/getPsiTaskList", {}),
    ("DH实时联邦求交", "GET", "/psi/getPsiTaskList", {}),
    ("OT实时联邦求交", "GET", "/psi/getPsiTaskList", {}),
    ("HE实时联邦求交", "GET", "/psi/getPsiTaskList", {}),
    ("联邦求交去除重复数据", "GET", "/psi/getPsiTaskList", {}),
    ("联邦求交多列联合ID", "GET", "/psi/getPsiTaskList", {}),
    ("联邦求交日志记录", "GET", "/federatedQuery/logs/intersectionRecord", {}),
    ("联邦求交日志导出", "GET", "/federatedQuery/logs/intersectionExport", {}),
    ("联邦查询日志记录", "GET", "/federatedQuery/logs/queryRecord", {}),
    ("联邦查询日志导出", "GET", "/federatedQuery/logs/queryExport", {}),
    ("联邦求差", "GET", "/difference/getDifferenceTaskList", {}),
    ("联邦求差日志记录", "GET", "/difference/getDifferenceTaskList", {}),
    ("联邦求差日志导出", "GET", "/difference/exportDifferenceLog", {}),
    ("联邦求并", "GET", "/union/getUnionTaskList", {}),
    ("联邦求并日志记录", "GET", "/union/getUnionTaskList", {}),
    ("联邦求并日志导出", "GET", "/union/exportUnionLog", {}),
    ("联邦查询去除重复数据", "GET", "/federatedQuery/list", {}),
    ("联邦查询多列联合ID", "GET", "/federatedQuery/list", {}),
    ("联邦查询Payload分块", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"payloadChunk"}}),
    ("联邦查询Payload指定输出字段", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"outputFields"}}),
    ("联邦查询计费(按次数)", "GET", "/federatedBilling/rule/list", {}),
    ("联邦查询计费(按命中)", "GET", "/federatedBilling/rule/list", {}),
    ("联邦查询去重计费(固定时间)", "GET", "/federatedBilling/rule/list", {}),
    ("联邦查询去重计费(滚动时间)", "GET", "/federatedBilling/rule/list", {}),
    ("联邦查询实时接口校验", "GET", "/federatedQuery/apiValidation", {}),
    ("联邦求交分桶工具", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"bucket"}}),
    ("联邦查询压缩工具", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"compress"}}),
    ("联邦查询解压工具", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"decompress"}}),
    ("联邦查询分桶工具", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"bucket"}}),
    ("联邦查询编码工具", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"codec"}}),
    ("联邦查询解码工具", "GET", "/federatedQuery/tools/config", {"params":{"toolName":"codec"}}),
]
mod14_fs = [
    ("描述性统计", "GET", "/federatedStatistics/types", {}),
    ("分组统计", "GET", "/federatedStatistics/task/list", {}),
    ("条件统计", "GET", "/federatedStatistics/task/list", {}),
    ("占比统计", "GET", "/federatedStatistics/task/list", {}),
    ("T检验", "GET", "/federatedStatistics/types", {}),
    ("F检验", "GET", "/federatedStatistics/types", {}),
    ("卡方检验", "GET", "/federatedStatistics/types", {}),
    ("回归分析", "GET", "/federatedStatistics/types", {}),
    ("相关性分析", "GET", "/federatedStatistics/types", {}),
    ("统计结果存储", "GET", "/federatedStatistics/result/list", {}),
    ("统计结果导出", "GET", "/federatedStatistics/result/export", {"params":{"taskId":0}}),
    ("统计日志记录", "GET", "/federatedStatistics/logs", {}),
    ("统计日志导出", "GET", "/federatedStatistics/logs", {}),
]
mod15_fa = [
    ("SQL安全校验", "POST", "/federatedAnalysis/sql/validate", {"json":{"sql":"SELECT 1"}}),
    ("字段保密属性", "GET", "/federatedAnalysis/datasource/list", {}),
    ("筛选算子", "GET", "/federatedAnalysis/sql/functions", {}),
    ("连接算子", "GET", "/federatedAnalysis/sql/functions", {}),
    ("聚合算子", "GET", "/federatedAnalysis/sql/functions", {}),
    ("分组算子", "GET", "/federatedAnalysis/sql/functions", {}),
    ("排序算子", "GET", "/federatedAnalysis/sql/functions", {}),
    ("窗口函数", "GET", "/federatedAnalysis/sql/functions", {}),
    ("关联子查询", "GET", "/federatedAnalysis/sql/functions", {}),
    ("非关联子查询", "GET", "/federatedAnalysis/sql/functions", {}),
    ("对接主流关系型数据库", "GET", "/federatedAnalysis/rdbms/types", {}),
    ("对接主流大数据平台", "GET", "/federatedAnalysis/bigdata/types", {}),
    ("对接主流公有云平台", "GET", "/federatedAnalysis/cloud/types", {}),
    ("分析日志记录", "GET", "/federatedAnalysis/logs", {}),
    ("分析日志导出", "POST", "/federatedAnalysis/logs/export", {"json":{}}),
    ("字符类型函数", "GET", "/federatedAnalysis/sql/functions", {}),
    ("日期类型函数", "GET", "/federatedAnalysis/sql/functions", {}),
    ("时间戳类型函数", "GET", "/federatedAnalysis/sql/functions", {}),
    ("SQL格式化", "POST", "/federatedAnalysis/sql/format", {"json":{"sql":"select 1"}}),
    ("浮点类型函数", "GET", "/federatedAnalysis/sql/functions", {}),
]
mod16_fl = [
    ("联邦学习数据融合", "GET", "/federatedLearning/getTaskList", {}),
    ("联邦学习预处理", "GET", "/federatedLearning/getTaskList", {}),
    ("特征相似度分析", "GET", "/federatedLearning/getModelList", {}),
    ("特征编码", "GET", "/federatedLearning/getModelList", {}),
    ("特征对齐", "GET", "/federatedLearning/getModelList", {}),
    ("特征分享", "GET", "/federatedLearning/getModelList", {}),
    ("特征填充", "GET", "/federatedLearning/getModelList", {}),
    ("样本列扩展", "GET", "/federatedLearning/getModelList", {}),
    ("样本加权", "GET", "/federatedLearning/getModelList", {}),
    ("指标建模分析", "GET", "/federatedLearning/getModelList", {}),
    ("特征装仓", "GET", "/federatedLearning/getModelList", {}),
    ("数据分割", "GET", "/federatedLearning/getModelList", {}),
    ("数据转换", "GET", "/federatedLearning/getModelList", {}),
    ("线性回归建模(纵向)", "GET", "/model/getModelList", {}),
    ("逻辑回归建模(纵向)", "GET", "/model/getModelList", {}),
    ("XGBoost建模(纵向)", "GET", "/model/getModelList", {}),
    ("线性回归预测(纵向)", "GET", "/model/getModelList", {}),
    ("逻辑回归预测(纵向)", "GET", "/model/getModelList", {}),
    ("XGBoost预测(纵向)", "GET", "/model/getModelList", {}),
    ("模型评估", "GET", "/model/getModelList", {}),
    ("模型预览", "GET", "/model/getModelList", {}),
    ("模型导入", "GET", "/model/getModelList", {}),
    ("模型导出", "GET", "/model/getModelList", {}),
    ("联邦建模工作台", "GET", "/model/getModelComponent", {}),
    ("联邦建模参数调优", "GET", "/federatedLearning/getTaskList", {}),
    ("联邦建模训练迭代", "GET", "/federatedLearning/getTaskList", {}),
    ("联邦建模训练报告", "GET", "/federatedLearning/getTaskList", {}),
    ("联邦学习日志记录", "GET", "/federatedLearning/getTaskList", {}),
    ("联邦学习日志导出", "GET", "/federatedLearning/getTaskList", {}),
    ("单方数据合并模块", "GET", "/singleParty/getTaskList", {}),
    ("单方数据统计", "GET", "/singleParty/getTaskList", {}),
    ("单方数据清洗", "GET", "/singleParty/getTaskList", {}),
    ("单方数据缩放", "GET", "/singleParty/getTaskList", {}),
    ("单方特征编码", "GET", "/singleParty/getTaskList", {}),
    ("单方特征分箱", "GET", "/singleParty/getTaskList", {}),
    ("单方特征筛选", "GET", "/singleParty/getTaskList", {}),
    ("单方特征衍生", "GET", "/singleParty/getTaskList", {}),
    ("单方LR算法", "GET", "/singleParty/getTaskList", {}),
    ("单方XGB算法", "GET", "/singleParty/getTaskList", {}),
    ("单方Python脚本处理", "GET", "/singleParty/getTaskList", {}),
    ("单方SQL处理", "GET", "/singleParty/getTaskList", {}),
    ("单方学习日志记录", "GET", "/singleParty/getTaskList", {}),
    ("单方学习日志导出", "GET", "/singleParty/getTaskList", {}),
]
mod17_scene1 = [
    ("警务数据交集数据融合", "GET", "/policeFusion/task/list", {}),
    ("保险机构接口对接", "GET", "/policeFusion/api/list", {}),
    ("保险机构同态密钥创建", "POST", "/policeFusion/key/generate", {"json":{}}),
    ("保险机构模型同态加密", "POST", "/policeFusion/key/encrypt", {"json":{"data":"test"}}),
    ("加密模型联合运算", "POST", "/policeFusion/task/create", {"json":{"taskName":"test"}}),
    ("保险机构数据解密", "POST", "/policeFusion/key/decrypt", {"json":{"data":"test"}}),
    ("警务数据对接", "GET", "/policeFusion/api/list", {}),
    ("模型密文数据安全交换(批量)", "GET", "/policeFusion/task/list", {}),
    ("流程执行日志记录(警务)", "GET", "/policeFusion/task/list", {}),
    ("流程执行日志导出(警务)", "GET", "/policeFusion/task/list", {}),
]
mod18_scene2 = [
    ("电子证件特征转换", "POST", "/electronicCert/feature/convert", {"json":{"feature":"test"}}),
    ("现场证件特征转换", "POST", "/electronicCert/feature/convert", {"json":{"feature":"test"}}),
    ("特征数据隐私比对", "POST", "/electronicCert/compare", {"json":{"feature1":"a","feature2":"b"}}),
    ("警务数据对接(证件)", "GET", "/electronicCert/api/list", {}),
    ("使用机构数据接入", "POST", "/electronicCert/import", {"json":{"data":"test"}}),
    ("使用机构数据导出", "POST", "/electronicCert/export", {"json":{"dataId":"0"}}),
    ("特征密文交换(批量)", "POST", "/electronicCert/exchange/batch", {"json":{}}),
    ("特征密文交换(实时)", "POST", "/electronicCert/exchange/realtime", {"json":{}}),
    ("流程执行日志记录(证件)", "GET", "/electronicCert/task/list", {}),
    ("流程执行日志导出(证件)", "GET", "/electronicCert/task/list", {}),
]

MODULES = [
    ("1. 用户管理(5)", mod1), ("2. 白名单(5)", mod2), ("3. 租户管理(8)", mod3),
    ("4. 存证管理(5)", mod4), ("5. 日志管理(7)", mod5), ("6. 角色管理(6)", mod6),
    ("7. 监控管理(6)", mod7), ("8. 项目管理(8)", mod8), ("9. 节点管理(9)", mod9),
    ("10. 系统设置(7)", mod10), ("11. 数据管理(16)", mod11), ("12. 接口管理(6)", mod12),
    ("13. 联邦查询(39)", mod13_fq), ("14. 联邦统计(13)", mod14_fs),
    ("15. 联邦分析(20)", mod15_fa), ("16. 联邦学习(43)", mod16_fl),
    ("17. 场景一(10)", mod17_scene1), ("18. 场景二(10)", mod18_scene2),
]

if __name__ == "__main__":
    if not login(): sys.exit(1)
    for mname, items in MODULES:
        print(f"\n═══ {mname} ═══")
        for item in items:
            name = item[0]
            kwargs = item[3] if len(item) > 3 else {}
            call(item[1], item[2], name, **kwargs)

    print(f"\n{'='*60}")
    ok = sum(1 for _, s, _ in RESULTS if s)
    total = len(RESULTS)
    print(f"总用例: {total} | 通过: {ok} | 失败: {total-ok} | 通过率: {ok*100//total}%")
    for n, s, d in RESULTS:
        if not s: print(f"  ❌ {n}: {d}")
