#!/usr/bin/env python3
"""Shared configuration + demand.csv parsing for the primihub-platform-func skill.

Single source of truth for: target platform URL/creds, the 18-module metadata,
and the 224-row demand.csv -> (module, function) mapping.
"""
from __future__ import annotations

import csv
import os
from pathlib import Path
from typing import NamedTuple, Optional

SKILL_DIR = Path(__file__).resolve().parent.parent

# -- target platform --------------------------------------------------------
WEB_URL = os.environ.get("PRIMIHUB_WEB_URL", "http://100.64.0.25:30811")
API_BASE = os.environ.get("PRIMIHUB_API_BASE", "/prod-api")
USER = os.environ.get("PRIMIHUB_USER", "admin")
PASS = os.environ.get("PRIMIHUB_PASS", "primihub123")

# -- source / artifacts -----------------------------------------------------
def _first_existing(*cands: str) -> Path:
    for c in cands:
        if c and Path(c).exists():
            return Path(c)
    return Path(cands[0])


DEMAND_CSV = _first_existing(
    os.environ.get("PRIMIHUB_DEMAND_CSV", ""),
    str(SKILL_DIR / "data" / "demand.csv"),                 # bundle-local copy
    str(SKILL_DIR.parent.parent / "data" / "demand.csv"),   # pcloud repo copy
    str(Path.home() / "demand.csv"),
    "/mnt/data1/github/primihub-deploy/demand.csv",
)
PLATFORM_DIR = _first_existing(
    os.environ.get("PRIMIHUB_PLATFORM_DIR", ""),
    "/mnt/data1/github/primihub-platform",
)
SCREENSHOT_DIR = Path(os.environ.get(
    "PRIMIHUB_SCREENSHOT_DIR",
    str(SKILL_DIR / "screenshots"),
))


class ModuleMeta(NamedTuple):
    id: str
    name: str          # canonical module name (matches demand.csv 功能模块名称)
    range: str         # demand.csv row range, e.g. "#7-#11"
    route: str         # webconsole hash route, e.g. "whitelist/list"
    controller: str
    service: str
    count: int


# 18 modules covering demand.csv rows #1..#224 (aligned with the router + api/*.js)
MODULES: list[ModuleMeta] = [
    ModuleMeta("01", "用户管理", "#1-#6", "setting/user", "UserController", "SysUserService", 6),
    ModuleMeta("02", "白名单", "#7-#11", "whitelist/list", "WhitelistController", "WhitelistService", 5),
    ModuleMeta("03", "租户管理", "#12-#19", "tenant/list", "TenantController", "TenantService", 8),
    ModuleMeta("04", "存证管理", "#20-#24", "evidence/query", "EvidenceController", "EvidenceService", 5),
    ModuleMeta("05", "日志管理", "#25-#31", "logManagement/operationDefinition", "LogManagementController", "LogManagementService", 7),
    ModuleMeta("06", "角色管理", "#32-#37", "setting/role", "RoleController", "SysRoleService", 6),
    ModuleMeta("07", "监控管理", "#38-#43", "monitor/index", "MonitorController", "MonitorService", 6),
    ModuleMeta("08", "项目管理", "#44-#51", "project/list", "ProjectController", "DataProjectService", 8),
    ModuleMeta("09", "节点管理", "#52-#60", "setting/center", "NodeEnhancedController", "NodeCooperationService", 9),
    ModuleMeta("10", "系统设置", "#61-#67", "setting/system", "SystemConfigController", "SysConfigServiceImpl", 7),
    ModuleMeta("11", "数据管理", "#68-#83", "resource/list", "ResourceController", "DataResourceService", 16),
    ModuleMeta("12", "接口管理", "#84-#89", "api/list", "ApiManageController", "ApiManageService", 6),
    ModuleMeta("13", "联邦查询功能", "#90-#128", "federatedQuery/index", "FederatedQueryController", "FederatedQueryServiceImpl", 39),
    ModuleMeta("14", "联邦统计功能", "#129-#141", "federatedStatistics/index", "FederatedStatsController", "FederatedStatsServiceImpl", 13),
    ModuleMeta("15", "联邦分析功能", "#142-#161", "federatedAnalysis/index", "FederatedAnalysisController", "FederatedAnalysisServiceImpl", 20),
    ModuleMeta("16", "联邦学习功能", "#162-#204", "federatedLearning/index", "FederatedLearningController", "FederatedLearningService", 43),
    ModuleMeta("17", "场景定制化一", "#205-#214", "policeDataFusion/intersection", "SceneController", "SceneServiceImpl", 10),
    ModuleMeta("18", "场景定制化二", "#215-#224", "electronicCert/featureConvert", "SceneController", "SceneServiceImpl", 10),
]


def module_by(name_or_id: str) -> Optional[ModuleMeta]:
    key = (name_or_id or "").strip().lower().replace("功能", "").replace("管理", "").replace(" ", "")
    for m in MODULES:
        if name_or_id == m.id:
            return m
    for m in MODULES:
        mkey = m.name.lower().replace("功能", "").replace("管理", "").replace(" ", "")
        if key and (key in mkey or mkey in key):
            return m
    for m in MODULES:
        if key and key in m.name.lower():
            return m
    return None


class DemandRow(NamedTuple):
    seq: int           # 1..224
    module: str        # 一级功能模块 (top-level, e.g. 基于隐私计算的数据可信共享)
    submodule: str     # 功能模块名称 (e.g. 白名单)
    func: str          # 功能名称 (e.g. 增加白名单)
    ftype: str         # EI/EQ/EO/ILF/EIF


def parse_demand(csv_path: Path = DEMAND_CSV) -> list[DemandRow]:
    """Parse demand.csv into the 224 function rows.

    The CSV has a large multi-line quoted cell in the first data row (the事项列表);
    csv.reader handles the quoting. We keep only rows with a numeric 序号 and a
    non-empty 功能名称, carrying 子模块 (功能模块名称) forward when blank.
    """
    rows: list[DemandRow] = []
    if not csv_path.exists():
        return rows
    cur_module = ""
    cur_sub = ""
    with open(csv_path, encoding="utf-8", errors="replace", newline="") as fh:
        reader = csv.reader(fh)
        for rec in reader:
            if len(rec) < 6:
                continue
            seq_raw = (rec[0] or "").strip()
            if not seq_raw.isdigit():
                continue
            top = (rec[2] or "").strip()
            sub = (rec[3] or "").strip()
            func = (rec[5] or "").strip()
            ftype = (rec[6] or "").strip() if len(rec) > 6 else ""
            if top:
                cur_module = top
            if sub:
                cur_sub = sub
            if not func or func == "总　计":
                continue
            rows.append(DemandRow(int(seq_raw), cur_module, cur_sub, func, ftype))
    return rows
