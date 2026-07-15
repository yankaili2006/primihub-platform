#!/usr/bin/env python3
"""Registry: map each of the 224 demand.csv functions to a concrete verification.

For every module we define:
  * probe  — a side-effect-free GET (list/config) used for reachability + counts
  * ops    — named backend operations harvested from the webconsole src/api/*.js
             (authoritative), each tagged safe (GET/read) or unsafe (write)

Each demand row is then classified:
  kind = "api"   -> a concrete endpoint is known for this function
         "ui"    -> best exercised via the browser page (route in config.MODULES)
         "smoke" -> only module-level reachability is asserted (honestly labeled;
                    e.g. individual federated-algorithm variants share one task API)

No fake "通过": a function is only "verified" when its real endpoint answers code 0
(or, for whitelist, a full create→list→delete round-trip passes).
"""
from __future__ import annotations

import re
from typing import NamedTuple, Optional

from . import config
from .config import MODULES, parse_demand


class Op(NamedTuple):
    key: str
    path: str
    method: str          # get | post | post_json
    safe: bool           # True => no side effects, callable in `check`


# probe = the safe GET used to prove a module is wired + count rows.
# ops   = operations we can name/verify; verb rules below map 功能名称 -> op.
MODULE_OPS: dict[str, dict] = {
    "01": {  # 用户管理
        "probe": ("/sys/user/findUserPage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/sys/user/findUserPage", "get", True),
            Op("add", "/sys/user/saveOrUpdateUser", "post", False),
            Op("delete", "/sys/user/deleteSysUser", "post", False),
            Op("freeze", "/sys/user/freezeUser", "post", False),
            Op("bindRole", "/sys/user/saveOrUpdateUser", "post", False),
        ],
    },
    "02": {  # 白名单 (flagship — full CRUD)
        "probe": ("/whitelist/findWhitelistPage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/whitelist/findWhitelistPage", "get", True),
            Op("add", "/whitelist/addWhitelist", "post", False),
            Op("config", "/whitelist/saveWhitelistConfig", "post", False),
            Op("accessLog", "/whitelist/findWhitelistAccessLogPage", "get", True),
        ],
    },
    "03": {  # 租户管理
        "probe": ("/tenant/findTenantPage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/tenant/findTenantPage", "get", True),
            Op("add", "/tenant/addTenant", "post", False),
            Op("delete", "/tenant/deleteTenant", "post", False),
            Op("freeze", "/tenant/freezeTenant", "post", False),
            Op("resourceAdd", "/tenant/addTenantResource", "post", False),
            Op("isolation", "/tenant/getTenantIsolationConfig", "get", True),
        ],
    },
    "04": {  # 存证管理
        "probe": ("/evidence/findEvidencePage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("timestamp", "/evidence/findTimestampPage", "get", True),
            Op("config", "/evidence/getEvidenceConfig", "get", True),
            Op("query", "/evidence/findEvidencePage", "get", True),
            Op("export", "/evidence/exportEvidence", "post", False),
            Op("api", "/evidence/getApiList", "get", True),
        ],
    },
    "05": {  # 日志管理
        "probe": ("/log/findOperationLogPage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("opDef", "/log/findOperationLogDefinitionPage", "get", True),
            Op("schedDef", "/log/findScheduleLogDefinitionPage", "get", True),
            Op("computeDef", "/log/findComputeLogDefinitionPage", "get", True),
            Op("opLog", "/log/findOperationLogPage", "get", True),
            Op("schedLog", "/log/findScheduleLogPage", "get", True),
            Op("computeLog", "/log/findComputeLogPage", "get", True),
            Op("export", "/log/exportOperationLog", "get", True),
        ],
    },
    "06": {  # 角色管理
        "probe": ("/sys/role/findRolePage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/sys/role/findRolePage", "get", True),
            Op("add", "/sys/role/saveOrUpdateRole", "post", False),
            Op("delete", "/sys/role/deleteSysRole", "post", False),
            Op("authTree", "/sys/auth/getAuthTree", "get", True),
        ],
    },
    "07": {  # 监控管理
        "probe": ("/monitor/getSystemMonitor", {}),
        "ops": [
            Op("cpu", "/monitor/getCpuMonitor", "get", True),
            Op("memory", "/monitor/getMemoryMonitor", "get", True),
            Op("disk", "/monitor/getDiskMonitor", "get", True),
            Op("database", "/monitor/getDatabaseMonitor", "get", True),
            Op("jvm", "/monitor/getJvmMonitor", "get", True),
            Op("redis", "/monitor/getRedisMonitor", "get", True),
        ],
    },
    "08": {  # 项目管理
        "probe": ("/data/project/getProjectList", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/data/project/getProjectList", "get", True),
            Op("save", "/data/project/saveOrUpdateProject", "post_json", False),
            Op("close", "/data/project/closeProject", "post", False),
            Op("approval", "/data/project/approval", "post", False),
            Op("ledger", "/data/project/getListStatistics", "get", True),
        ],
    },
    "09": {  # 节点管理
        "probe": ("/node/access/findAccessPartyPage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("accessList", "/node/access/findAccessPartyPage", "get", True),
            Op("accessAdd", "/node/access/addAccessParty", "post", False),
        ],
    },
    "10": {  # 系统设置
        "probe": ("/systemConfig/getNetworkConfig", {}),
        "ops": [
            Op("network", "/systemConfig/getNetworkConfig", "get", True),
            Op("time", "/systemConfig/getTimeConfig", "get", True),
            Op("login", "/systemConfig/getLoginRestriction", "get", True),
            Op("personalization", "/systemConfig/getPersonalizationConfig", "get", True),
            Op("ftp", "/systemConfig/getFtpConfig", "get", True),
        ],
    },
    "11": {  # 数据管理 (数据源/数据集/数据需求/共享数据集)
        "probe": ("/data/resource/getdataresourcelist", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("resourceList", "/data/resource/getdataresourcelist", "get", True),
            Op("requirementList", "/dataRequirement/findDataRequirementPage", "get", True),
            Op("requirementAdd", "/dataRequirement/addDataRequirement", "post", False),
            Op("match", "/dataRequirement/matchDataRequirements", "post", False),
            Op("shareList", "/dataShare/list", "get", True),
        ],
    },
    "12": {  # 接口管理
        "probe": ("/apiManage/findApiPage", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/apiManage/findApiPage", "get", True),
            Op("add", "/apiManage/addApi", "post", False),
            Op("delete", "/apiManage/deleteApi", "post", False),
            Op("authList", "/apiManage/findApiAuthPage", "get", True),
            Op("authValidate", "/apiManage/validateApiAuth", "post", False),
            Op("logList", "/apiManage/findApiLogPage", "get", True),
        ],
    },
    "13": {  # 联邦查询
        "probe": ("/federatedQuery/list", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/federatedQuery/list", "get", True),
            Op("create", "/federatedQuery/create", "post", False),
            Op("run", "/federatedQuery/run", "post", False),
            Op("algorithms", "/federatedQuery/algorithms", "get", True),
            Op("logs", "/federatedQuery/logs", "get", True),
            Op("psiList", "/data/psi/getPsiTaskList", "get", True),
            Op("differenceList", "/data/difference/getDifferenceTaskList", "get", True),
            Op("unionList", "/data/union/getUnionTaskList", "get", True),
        ],
    },
    "14": {  # 联邦统计
        "probe": ("/data/federatedStatistics/task/list", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/data/federatedStatistics/task/list", "get", True),
            Op("create", "/data/federatedStatistics/task/create", "post_json", False),
            Op("run", "/data/federatedStatistics/task/run", "post", False),
        ],
    },
    "15": {  # 联邦分析
        "probe": ("/data/federatedAnalysis/task/list", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/data/federatedAnalysis/task/list", "get", True),
            Op("create", "/data/federatedAnalysis/task/create", "post_json", False),
            Op("run", "/data/federatedAnalysis/task/run", "post", False),
        ],
    },
    "16": {  # 联邦学习
        "probe": ("/federatedLearning/getTaskList", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("list", "/federatedLearning/getTaskList", "get", True),
            Op("create", "/federatedLearning/createTask", "post", False),
            Op("modelList", "/federatedLearning/getModelList", "get", True),
        ],
    },
    "17": {  # 场景定制化一 (警务)
        "probe": ("/policeFusion/task/list", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("taskList", "/policeFusion/task/list", "get", True),
            Op("apiList", "/policeFusion/api/list", "get", True),
            Op("keyList", "/policeFusion/key/list", "get", True),
            Op("keyGen", "/policeFusion/key/generate", "post", False),
        ],
    },
    "18": {  # 场景定制化二 (电子证件)
        "probe": ("/policeFusion/api/list", {"pageNum": 1, "pageSize": 10}),
        "ops": [
            Op("convert", "/electronicCert/feature/convert", "post", False),
            Op("compare", "/electronicCert/compare", "post", False),
            Op("import", "/electronicCert/import", "post", False),
            Op("export", "/electronicCert/export", "post", False),
        ],
    },
}


# 功能名称 (Chinese verb) -> op-key preference order. First match on a module that
# actually has that op wins; else the function is smoke-covered by the probe.
VERB_RULES: list[tuple[str, tuple[str, ...]]] = [
    (r"列表|展示", ("list", "resourceList", "taskList", "opLog", "query", "accessList")),
    (r"增加|新增|新建|添加|创建|建立", ("add", "create", "requirementAdd", "accessAdd", "resourceAdd", "keyGen", "convert", "save")),
    (r"删除|注销|取消", ("delete",)),
    (r"冻结", ("freeze",)),
    (r"配置", ("config", "isolation", "network", "login", "time", "ftp")),
    (r"记录", ("opLog", "logList", "logs", "accessLog")),
    (r"导出", ("export",)),
    (r"算法|求交|查询|求差|求并|统计|分析", ("run", "create", "algorithms", "list")),
]


class FuncSpec(NamedTuple):
    seq: int
    module_id: str
    module_name: str
    submodule: str
    func: str
    kind: str            # api | ui | smoke
    op: Optional[Op]


def _submodule_to_module_id(submodule: str) -> Optional[str]:
    m = config.module_by(submodule)
    return m.id if m else None


def resolve_op(module_id: str, func_name: str) -> Optional[Op]:
    ops = {o.key: o for o in MODULE_OPS.get(module_id, {}).get("ops", [])}
    for pattern, prefs in VERB_RULES:
        if re.search(pattern, func_name):
            for k in prefs:
                if k in ops:
                    return ops[k]
    return None


def build_registry() -> list[FuncSpec]:
    specs: list[FuncSpec] = []
    for row in parse_demand():
        mid = _submodule_to_module_id(row.submodule) or _submodule_to_module_id(row.module)
        if not mid:
            continue
        mod = config.module_by(mid)
        op = resolve_op(mid, row.func)
        if op is not None:
            kind = "api"
        else:
            kind = "ui" if mid in ("01", "02", "03", "06", "08", "11", "12") else "smoke"
        specs.append(FuncSpec(
            seq=row.seq, module_id=mid, module_name=mod.name if mod else row.submodule,
            submodule=row.submodule, func=row.func, kind=kind, op=op,
        ))
    return specs


def registry_by_module() -> dict[str, list[FuncSpec]]:
    out: dict[str, list[FuncSpec]] = {}
    for s in build_registry():
        out.setdefault(s.module_id, []).append(s)
    return out


def module_probe(module_id: str) -> Optional[tuple[str, dict]]:
    entry = MODULE_OPS.get(module_id)
    return entry["probe"] if entry else None


if __name__ == "__main__":
    import json
    reg = build_registry()
    by_kind: dict[str, int] = {}
    for s in reg:
        by_kind[s.kind] = by_kind.get(s.kind, 0) + 1
    print(json.dumps({"total": len(reg), "by_kind": by_kind}, ensure_ascii=False, indent=2))
    for s in reg[:8]:
        print(f"  #{s.seq:3d} [{s.module_id}] {s.func} -> {s.kind} "
              f"{s.op.path if s.op else '(probe)'}")
