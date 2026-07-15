#!/usr/bin/env python3
"""Single source of truth for the 44 UI defects from
`隐私计算数据可信共享缺陷问题.docx` (项目根目录).

The docx lists 44 acceptance defects against the PrimiHub webconsole. This module
turns that prose into a structured registry so we can:
  * assert invariants offline (count, id uniqueness, category legality, module ∈ MODULES)
  * drive an online acceptance pass (per-defect verify -> pass / skip / fail)

Honesty over coverage (same discipline as automation/crud.py & functions.py):
a defect whose fix has **no safe, known backend endpoint** to observe (pure
frontend button render, "save" writes with unknown/destructive endpoints, or
"假成功" checks that need before/after state) carries `verify=None` and is
reported as **需手工/浏览器验证** — never faked green.

`Verify.assert_kind` semantics (what the online test actually proves):
  code0          — a safe GET returns business code == 0 (page/config loads)
  route_exists   — endpoint is wired: responds with a business code, and is
                   NOT a 404 / route-missing / '系统异常' (proves the request no
                   longer errors out; does NOT by itself prove a write succeeds)
  export_nonempty— an export endpoint returns non-empty content, or cleanly
                   refuses when there is no data (no fake "导出成功" on empty)
  search_scoped  — searching "001"/"-001" returns rows that ALL contain the
                   keyword (special char doesn't crash; match doesn't pollute)
  has_button     — the module's list/page endpoint loads (code 0) so the missing
                   button's page is functional; visual button presence stays manual
  roundtrip      — safe create->find->edit->delete on a unique self-made entity
                   via automation.crud (only for CRUD-safe modules); proves the
                   create/新增 defect is really fixed without leaving junk

`Verify.inferred=True` marks an endpoint path we deduced from the webconsole
naming convention but have NOT confirmed in the existing skill code — online it
may legitimately come back route-missing, which the report shows as "未满足"
rather than hiding it.
"""
from __future__ import annotations

from typing import NamedTuple, Optional

from .config import MODULES

# module-id -> canonical MODULES name, so defects never drift from config.py
_NAME_BY_ID = {m.id: m.name for m in MODULES}

# the 10 defect categories from the docx (分类标签)
CATEGORIES = frozenset({
    "无响应", "无按钮", "404", "请求异常", "假成功",
    "导出", "时间字段", "查询", "功能缺失", "整模块",
})

# legal assert kinds an online verify may use ("manual" == verify is None)
ASSERT_KINDS = frozenset({
    "code0", "route_exists", "export_nonempty",
    "search_scoped", "has_button", "roundtrip",
})


class Verify(NamedTuple):
    path: str
    method: str                 # get | post | post_json
    params: dict
    assert_kind: str            # ∈ ASSERT_KINDS
    json_body: bool = False
    inferred: bool = False      # endpoint deduced, not confirmed in skill code
    note: str = ""


class DefectMeta(NamedTuple):
    id: str                     # D01 .. D44
    mid: str                    # MODULES id, 01 .. 18
    page: str                   # 页面/子菜单 from the docx
    category: str               # ∈ CATEGORIES
    expect: str                 # 期望(需求)
    verify: Optional[Verify]    # None => needs manual/browser verification
    runbook: str                # docs/platform-fixes-runbook.md coverage / OPEN

    @property
    def module(self) -> str:
        """Canonical module name from config.MODULES (never hand-typed)."""
        return _NAME_BY_ID[self.mid]

    @property
    def manual(self) -> bool:
        return self.verify is None


def _V(path, method, kind, *, params=None, json_body=False, inferred=False, note=""):
    return Verify(path, method, params or {}, kind, json_body, inferred, note)


# --- the 44 defects (docx table -> structured; this table is the真源) ---------
DEFECTS: list[DefectMeta] = [
    DefectMeta("D01", "01", "新增用户", "无响应",
               "点确定成功创建, code=0", _V("/sys/user/saveOrUpdateUser", "post", "roundtrip"),
               "~Fix3/Fix5"),
    DefectMeta("D02", "02", "白名单列表", "无按钮",
               '渲染"新增"按钮', _V("/whitelist/findWhitelistPage", "get", "has_button",
                                params={"pageNum": 1, "pageSize": 5}), "Fix2"),
    DefectMeta("D03", "03", "租户列表", "无按钮",
               '渲染"新增"按钮', _V("/tenant/findTenantPage", "get", "has_button",
                                params={"pageNum": 1, "pageSize": 5}), "类Fix2"),
    DefectMeta("D04", "03", "租户间计算流程隔离", "404",
               "页面可达 code=0", _V("/tenant/isolation/config", "get", "route_exists",
                  note="真端点(webconsole JS: getComputeIsolationConfig)；live: code=0→已实现，skill 原猜 /tenant/getTenantIsolationConfig 才 404"), "OPEN"),
    DefectMeta("D05", "03", "租户流程隔离", "404",
               "页面可达 code=0", _V("/tenant/isolation/status/list", "get", "route_exists",
                  note="真端点(webconsole JS: getIsolationStatusList)；live: code=0→已实现"), "OPEN"),
    DefectMeta("D06", "04", "时间戳管理-申请时间戳", "无响应",
               "提交成功", None, "OPEN(申请时间戳为写操作，无安全只读端点，需手工)"),
    DefectMeta("D07", "05", "操作日志定义-新增", "请求异常",
               "新增成功", _V("/log/findOperationLogDefinitionPage", "get", "route_exists",
                          params={"pageNum": 1, "pageSize": 5}), "~Fix8 家族"),
    DefectMeta("D08", "05", "调度日志定义-新增", "请求异常",
               "新增成功", _V("/log/findScheduleLogDefinitionPage", "get", "route_exists",
                          params={"pageNum": 1, "pageSize": 5}), "~Fix8 家族"),
    DefectMeta("D09", "05", "计算日志定义-新增", "请求异常",
               "新增成功", _V("/log/findComputeLogDefinitionPage", "get", "route_exists",
                          params={"pageNum": 1, "pageSize": 5}), "OPEN"),
    DefectMeta("D10", "05", "计算日志记录-导出", "导出",
               "无数据不导出/不乱码(UTF-8 BOM)",
               _V("/log/exportComputeLog", "get", "export_nonempty", inferred=True), "~Fix10 模式"),
    DefectMeta("D11", "06", "新增角色", "时间字段",
               "创建时间=实时(时区/字段映射)", None,
               "OPEN(时间字段正确性需人工核对创建时间显示)"),
    DefectMeta("D12", "07", "操作系统CPU告警配置-保存", "无响应",
               "保存成功", None, "OPEN(告警保存为写操作，端点未知，需手工；页面 /monitor/getCpuMonitor)"),
    DefectMeta("D13", "07", "操作系统内存告警-保存", "无响应",
               "保存成功", None, "OPEN(需手工；页面 /monitor/getMemoryMonitor)"),
    DefectMeta("D14", "07", "操作系统磁盘告警-保存", "无响应",
               "保存成功", None, "OPEN(需手工；页面 /monitor/getDiskMonitor)"),
    DefectMeta("D15", "07", "数据库监控告警-保存", "无响应",
               "保存成功", None, "OPEN(需手工；页面 /monitor/getDatabaseMonitor)"),
    DefectMeta("D16", "07", "中间件JVM告警-保存", "无响应",
               "保存成功", None, "OPEN(需手工；页面 /monitor/getJvmMonitor)"),
    DefectMeta("D17", "07", "中间件Redis告警-保存", "无响应",
               "保存成功", None, "OPEN(需手工；页面 /monitor/getRedisMonitor)"),
    DefectMeta("D18", "08", "项目列表-新增项目", "无响应",
               "立即创建成功且有提示",
               _V("/data/project/saveOrUpdateProject", "post_json", "route_exists", json_body=True,
                  note="heavy: 建项目需机构+资源依赖，仅验路由已通(非404)"), "~需外部依赖"),
    DefectMeta("D19", "08", "项目台账导出-下载", "导出",
               "导出文件非空可下载",
               _V("/project/ledger/export", "post_json", "export_nonempty", json_body=True,
                  note="真端点(webconsole JS 确认)；live: code=1003 数据为空→路由已通"), "Feature1"),
    DefectMeta("D20", "09", "创建机构", "请求异常",
               "创建成功",
               _V("/sys/organ/createOrganNode", "post_json", "route_exists", json_body=True,
                  note="真端点(webconsole JS 确认前端调此)；live: 后端全 404 = 真缺陷(前端引用未实现)"), "OPEN"),
    DefectMeta("D21", "09", "接入方管理-新增", "请求异常",
               "新增成功", _V("/node/access/addAccessParty", "post", "roundtrip"), "OPEN"),
    DefectMeta("D22", "09", "合作方管理-建立合作", "假成功",
               "真建合作(非恒真提示)", None,
               "OPEN(假成功需前后状态比对，需手工)"),
    DefectMeta("D23", "10", "审批工作流-创建", "请求异常",
               "创建成功", None, "OPEN(工作流创建端点未知，需手工)"),
    DefectMeta("D24", "10", "数据交换日志-触发同步", "假成功",
               "真触发(非假成功提示)", None,
               "OPEN(假成功需前后状态比对，需手工)"),
    DefectMeta("D25", "11", "我的资源-新建资源", "请求异常",
               "保存成功",
               _V("/data/resource/saveorupdateresource", "post_json", "route_exists", json_body=True,
                  note="真端点(webconsole JS 确认)；live: code=100 缺少参数:resourceName→路由已通"), "~需外部依赖"),
    DefectMeta("D26", "11", "数据需求列表-新增需求", "请求异常",
               "新增成功(user_id)",
               _V("/dataRequirement/addDataRequirement", "post_json", "route_exists",
                  json_body=True,
                  note="@RequestBody 端点：须发 JSON，空体触发字段校验错(非404/系统异常)即证路由已通"), "Fix7"),
    DefectMeta("D27", "11", '数据需求列表-关键字"-001"查询', "查询",
               "特殊字符模糊查询正常返回",
               _V("/dataRequirement/findDataRequirementPage", "get", "search_scoped",
                  params={"pageNum": 1, "pageSize": 10, "keyword": "-001"}), "~Fix8(搜索)"),
    DefectMeta("D28", "11", "共享数据集列表-新增", "请求异常",
               "新增成功",
               _V("/sharedDataset/addSharedDataset", "post_json", "route_exists", json_body=True,
                  note="真端点(webconsole JS: /sharedDataset 非 /dataShare)；live: code=100→路由已通"), "Fix9"),
    DefectMeta("D29", "11", '共享数据集列表-关键字"-001"查询', "查询",
               "特殊字符模糊查询正常",
               _V("/sharedDataset/findSharedDatasetPage", "get", "search_scoped",
                  params={"pageNum": 1, "pageSize": 10, "keyword": "-001"}), "OPEN"),
    DefectMeta("D30", "12", "接口列表-新增", "无响应",
               "新增成功", _V("/apiManage/addApi", "post", "roundtrip"), "~crud已绿"),
    DefectMeta("D31", "12", "接口日志-导出", "导出",
               "无数据不提示成功导出",
               _V("/apiManage/exportApiLog", "get", "export_nonempty", inferred=True,
                  note="导出/假成功双属性：断言无数据时不乱报导出成功"), "OPEN"),
    DefectMeta("D32", "13", "联邦求差", "功能缺失",
               "功能存在可用",
               _V("/data/difference/getDifferenceTaskList", "get", "route_exists",
                  params={"pageNum": 1, "pageSize": 5}), "OPEN"),
    DefectMeta("D33", "13", "联邦求差日志记录", "功能缺失",
               "功能存在",
               _V("/data/difference/getDifferenceTaskList", "get", "route_exists",
                  params={"pageNum": 1, "pageSize": 5}), "OPEN"),
    DefectMeta("D34", "13", "联邦求差日志导出", "功能缺失",
               "功能存在",
               _V("/data/difference/exportDifferenceLog", "get", "export_nonempty", inferred=True), "OPEN"),
    DefectMeta("D35", "14", "联邦统计结果导出-下载", "导出",
               "导出非空可下载",
               _V("/federatedStatistics/result/batchExport", "post_json", "export_nonempty", json_body=True,
                  note="真端点(webconsole JS 确认)；live: 空文件体→路由已通(待数据)"),
               "~Fix10 模式"),
    DefectMeta("D36", "14", '联邦统计日志记录-任务ID"001"搜索', "查询",
               "精确/前缀匹配不污染其他数据",
               _V("/data/federatedStatistics/task/list", "get", "search_scoped",
                  params={"pageNum": 1, "pageSize": 10, "taskId": "001"},
                  note="scoped 字段=taskId"), "OPEN"),
    DefectMeta("D37", "14", "联邦统计日志导出", "导出",
               "导出非空可下载",
               _V("/federatedStatistics/logs/export", "post_json", "export_nonempty", json_body=True,
                  note="真端点(webconsole JS 确认)；live: code=-1 导出失败(需taskId)→路由已通"), "OPEN"),
    DefectMeta("D38", "16", "整模块各菜单", "整模块",
               '页面不报"请求错误/加载失败"',
               _V("/federatedLearning/getTaskList", "get", "route_exists",
                  params={"pageNum": 1, "pageSize": 5}), "Feature5/6 部分"),
    DefectMeta("D39", "16", "单方数据(只有合并)", "功能缺失",
               "补齐功能指标子模块",
               _V("/singleParty/preprocess/list", "get", "route_exists",
                  params={"pageNo": 1, "pageSize": 5}), "Feature4 部分"),
    DefectMeta("D40", "16", "创建联邦学习任务", "功能缺失",
               '非"功能开发中"，可创建',
               _V("/federatedLearning/createTask", "post_json", "route_exists",
                  json_body=True,
                  note="@RequestBody 端点：须发 JSON，空体触发字段校验错即证功能已接入(非'功能开发中')"), "Feature5"),
    DefectMeta("D41", "16", '日志记录-任务ID"001"搜索', "查询",
               "匹配不污染",
               _V("/federatedLearning/getTaskList", "get", "search_scoped",
                  params={"pageNum": 1, "pageSize": 10, "taskId": "001"},
                  note="scoped 字段=taskId；docx 误标于联邦统计"), "OPEN"),
    DefectMeta("D42", "16", "日志导出", "导出",
               "导出非空可下载",
               _V("/federatedLearning/batchExportLogs", "post_json", "export_nonempty", json_body=True,
                  note="真端点(webconsole JS 确认前端调此)；live: 后端全 404 = 真缺陷(前端引用未实现)"), "OPEN"),
    DefectMeta("D43", "17", "警务数据融合整模块", "整模块",
               "基础功能可用符合指标",
               _V("/policeFusion/task/list", "get", "route_exists",
                  params={"pageNum": 1, "pageSize": 5}), "OPEN"),
    DefectMeta("D44", "18", "电子证照对比整模块", "整模块",
               "基础功能可用符合指标",
               _V("/policeFusion/api/list", "get", "route_exists",
                  params={"pageNum": 1, "pageSize": 5},
                  note="场景二共用 policeFusion 网关探针"), "OPEN"),
]


# --- helpers ------------------------------------------------------------------
def defect_by_id(did: str) -> Optional[DefectMeta]:
    for d in DEFECTS:
        if d.id == did:
            return d
    return None


def by_module(mid: str) -> list[DefectMeta]:
    return [d for d in DEFECTS if d.mid == mid]


def open_defects() -> list[DefectMeta]:
    """Defects not clearly covered by a landed runbook fix (runbook == OPEN / ~…)."""
    return [d for d in DEFECTS if d.runbook == "OPEN" or d.runbook.startswith(("~", "类"))]


def manual_defects() -> list[DefectMeta]:
    return [d for d in DEFECTS if d.verify is None]


def category_counts() -> dict[str, int]:
    out: dict[str, int] = {}
    for d in DEFECTS:
        out[d.category] = out.get(d.category, 0) + 1
    return out


if __name__ == "__main__":
    import json
    print(json.dumps({
        "total": len(DEFECTS),
        "categories": category_counts(),
        "manual": len(manual_defects()),
        "auto": len([d for d in DEFECTS if d.verify]),
        "open": len(open_defects()),
    }, ensure_ascii=False, indent=2))
