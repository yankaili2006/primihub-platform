#!/usr/bin/env python3
"""Generic entity CRUD across the 18 PrimiHub platform modules.

The whitelist flow proved the shape: a module has a list endpoint, a create
(@RequestBody JSON, or a form `saveOrUpdate`), an update, and a delete (form
`@RequestParam id`, JSON `{id}`, or GET `?id=`). This registry captures that
per module so ONE generic driver can add/edit/delete real entities against the
real backend — no per-module bespoke code.

Honesty over coverage: modules without entity CRUD are recorded with their true
`kind` and never faked:
  * crud     — full add/edit/delete is testable via a safe self-created entity
  * heavy    — create needs external deps (uploaded file / resources / organs),
               so an unattended round-trip is skipped and labelled, not faked
  * readonly — logs / monitor / system config: nothing to add/edit/delete
  * task     — federated jobs & scene ops are "create task + run", not entity CRUD

Safety: `roundtrip` only ever creates a UNIQUE test entity, edits it, then
deletes it. It never touches pre-existing rows.
"""
from __future__ import annotations

import os
import time
from typing import Any, Callable, Optional

from .client import PrimihubClient, PrimihubError


class Op:
    """One backend operation + how to talk to it."""
    def __init__(self, path: str, json: bool = False, method: str = "post") -> None:
        self.path = path
        self.json = json          # True => JSON @RequestBody, False => form
        self.method = method      # "post" | "get"


class CrudSpec:
    def __init__(self, mid: str, name: str, kind: str, *,
                 list_path: Optional[str] = None, list_params: Optional[dict] = None,
                 id_field: str = "id", label_field: str = "name",
                 create: Optional[Op] = None, update: Optional[Op] = None,
                 delete: Optional[Op] = None,
                 make_create: Optional[Callable[[str], dict]] = None,
                 make_edit: Optional[Callable[[str], dict]] = None,
                 check_field: Optional[str] = None,
                 note: str = "") -> None:
        self.mid = mid
        self.name = name
        self.kind = kind
        self.list_path = list_path
        self.list_params = list_params or {}
        self.id_field = id_field
        self.label_field = label_field
        self.create = create
        self.update = update
        self.delete = delete
        self.make_create = make_create
        self.make_edit = make_edit
        # a secondary field whose change proves the edit landed (not the label)
        self.check_field = check_field
        self.note = note


def _sfx() -> str:
    # unique-enough per run without needing wall-clock determinism guarantees
    return f"{int(time.time()) % 100000}{os.getpid() % 1000}"


# --- registry: all 18 modules, honestly typed ---------------------------------
SPECS: dict[str, CrudSpec] = {
    "01": CrudSpec(
        "01", "用户管理", "crud",
        list_path="/sys/user/findUserPage", id_field="userId", label_field="userAccount",
        create=Op("/sys/user/saveOrUpdateUser", json=False),
        update=Op("/sys/user/saveOrUpdateUser", json=False),
        delete=Op("/sys/user/deleteSysUser", json=False),
        make_create=lambda s: {"userAccount": f"e2e_u_{s}", "userName": f"e2e {s}",
                               "roleIdList": [1000]},
        make_edit=lambda s: {"userAccount": f"e2e_u_{s}", "userName": f"e2e {s} edited",
                             "roleIdList": [1000]},
        check_field="userName",
    ),
    "06": CrudSpec(
        "06", "角色管理", "crud",
        list_path="/sys/role/findRolePage", id_field="roleId", label_field="roleName",
        create=Op("/sys/role/saveOrUpdateRole", json=False),
        update=Op("/sys/role/saveOrUpdateRole", json=False),
        delete=Op("/sys/role/deleteSysRole", json=False),
        make_create=lambda s: {"roleName": f"e2e_role_{s}"},
        make_edit=lambda s: {"roleName": f"e2e_role_{s}_ed"},
    ),
    "03": CrudSpec(
        "03", "租户管理", "crud",
        list_path="/tenant/findTenantPage", id_field="id", label_field="tenantCode",
        create=Op("/tenant/addTenant", json=True),
        update=Op("/tenant/updateTenant", json=True),
        delete=Op("/tenant/deleteTenant", json=False),
        make_create=lambda s: {"tenantCode": f"e2e{s}", "tenantName": f"e2e tenant {s}",
                               "contactPerson": "e2e", "contactPhone": "13800000000"},
        make_edit=lambda s: {"tenantCode": f"e2e{s}", "tenantName": f"e2e tenant {s} ed",
                             "contactPerson": "e2e", "contactPhone": "13800000000"},
        check_field="tenantName",
    ),
    "12": CrudSpec(
        "12", "接口管理", "crud",
        list_path="/apiManage/findApiPage", id_field="id", label_field="apiName",
        create=Op("/apiManage/addApi", json=True),
        update=Op("/apiManage/updateApi", json=True),
        delete=Op("/apiManage/deleteApi", json=True),
        make_create=lambda s: {"apiName": f"e2e_api_{s}", "method": "GET",
                               "apiPath": f"/e2e/{s}", "category": "SYSTEM",
                               "description": "e2e"},
        make_edit=lambda s: {"apiName": f"e2e_api_{s}", "method": "GET",
                             "apiPath": f"/e2e/{s}", "category": "SYSTEM",
                             "description": "e2e edited"},
        check_field="description",
    ),
    "09": CrudSpec(
        "09", "节点管理", "crud",
        list_path="/node/access/findAccessPartyPage", id_field="id", label_field="organId",
        create=Op("/node/access/addAccessParty", json=True),
        update=Op("/node/access/updateAccessParty", json=True),
        delete=Op("/node/access/deleteAccessParty", json=False),
        make_create=lambda s: {"organId": f"e2e_node_{s}", "organName": f"e2e node {s}",
                               "organGateway": "http://127.0.0.1:9999",
                               "applyReason": "e2e test"},
        make_edit=lambda s: {"organId": f"e2e_node_{s}", "organName": f"e2e node {s} ed",
                             "organGateway": "http://127.0.0.1:9999",
                             "applyReason": "e2e test"},
        check_field="organName",
        note="接入方审批流；创建的是 pending 记录，round-trip 后即删除",
    ),
    # --- heavy: create needs external deps, unattended round-trip is skipped ---
    "11": CrudSpec("11", "数据管理", "heavy",
                   note="saveorupdateresource 需已上传 fileId 或完整数据库连接 + fieldList；"
                        "无法在无依赖下安全自动建资源"),
    "08": CrudSpec("08", "项目管理", "heavy",
                   note="saveOrUpdateProject 需已存在的机构+资源 id，且仅软关闭(closeProject)"
                        "无硬删除"),
    # --- readonly: nothing to add/edit/delete ---------------------------------
    "04": CrudSpec("04", "存证管理", "readonly", note="查询/导出存证，无实体增删改"),
    "05": CrudSpec("05", "日志管理", "readonly", note="操作日志只读"),
    "07": CrudSpec("07", "监控管理", "readonly", note="监控指标只读"),
    "10": CrudSpec("10", "系统设置", "readonly", note="系统配置读取（保存接口未纳入实体 CRUD）"),
    # --- task: job create + run, not entity CRUD ------------------------------
    "13": CrudSpec("13", "联邦查询功能", "task", note="create/run 任务，非实体增删改"),
    "14": CrudSpec("14", "联邦统计功能", "task", note="create/run 任务"),
    "15": CrudSpec("15", "联邦分析功能", "task", note="create/run 任务"),
    "16": CrudSpec("16", "联邦学习功能", "task", note="createTask/run，非实体增删改"),
    "17": CrudSpec("17", "场景定制化一", "task", note="密钥生成/求交等算子动作"),
    "18": CrudSpec("18", "场景定制化二", "task", note="特征转换/比对等算子动作"),
    # 02 whitelist has its own dedicated flagship flow (client.whitelist_*)
    "02": CrudSpec("02", "白名单", "crud",
                   list_path="/whitelist/findWhitelistPage", id_field="id", label_field="value",
                   create=Op("/whitelist/addWhitelist", json=True),
                   update=Op("/whitelist/updateWhitelist", json=True),
                   delete=Op("/whitelist/deleteWhitelist", json=False),
                   make_create=lambda s: {"type": "IP", "value": f"10.99.{int(s) % 250}.{int(s) % 200}",
                                          "description": "e2e", "status": 1},
                   make_edit=lambda s: {"type": "IP", "value": f"10.99.{int(s) % 250}.{int(s) % 200}",
                                        "description": "e2e edited", "status": 0},
                   check_field="description"),
}


def resolve(module: str) -> Optional[CrudSpec]:
    if module in SPECS:
        return SPECS[module]
    for s in SPECS.values():
        if s.name == module or module in (s.name,):
            return s
    return None


# --- generic operations -------------------------------------------------------
def crud_list(c: PrimihubClient, spec: CrudSpec, page_size: int = 200) -> list[dict]:
    params = dict(spec.list_params)
    params.update({"pageNum": 1, "pageSize": page_size})
    res = c.call(spec.list_path, "get", params)
    result = res.get("result") or {}
    if isinstance(result, list):
        return result
    if isinstance(result, dict):
        # list endpoints wrap rows under varying keys: list / records / sysRoleList …
        for key in ("list", "records", "data"):
            if isinstance(result.get(key), list):
                return result[key]
        # otherwise take the first list-valued entry (e.g. sysRoleList)
        for v in result.values():
            if isinstance(v, list):
                return v
    return []


def crud_find(c: PrimihubClient, spec: CrudSpec, label_value: str) -> Optional[dict]:
    for row in crud_list(c, spec):
        if str(row.get(spec.label_field)) == str(label_value):
            return row
    return None


def crud_create(c: PrimihubClient, spec: CrudSpec, fields: dict) -> dict:
    return c.call(spec.create.path, spec.create.method, fields, json_body=spec.create.json)


def crud_update(c: PrimihubClient, spec: CrudSpec, id_: Any, fields: dict) -> dict:
    body = dict(fields)
    body[spec.id_field] = id_
    return c.call(spec.update.path, spec.update.method, body, json_body=spec.update.json)


def crud_delete(c: PrimihubClient, spec: CrudSpec, id_: Any) -> dict:
    return c.call(spec.delete.path, spec.delete.method,
                  {spec.id_field: id_}, json_body=spec.delete.json)


def roundtrip(c: PrimihubClient, spec: CrudSpec) -> dict:
    """Safe create -> find -> update -> verify -> delete -> gone, on a unique
    self-created test entity. Honest per-step result; never touches other rows."""
    if spec.kind != "crud":
        return {"module": spec.name, "kind": spec.kind, "ok": None,
                "skipped": True, "note": spec.note}

    s = _sfx()
    create_fields = spec.make_create(s)
    edit_fields = spec.make_edit(s)
    create_label = create_fields[spec.label_field]
    edit_label = edit_fields[spec.label_field]
    steps: list[dict] = []
    ok = True
    try:
        add = crud_create(c, spec, create_fields)
        steps.append({"create": add.get("code"), "msg": add.get("msg")})
        ok = ok and add.get("code") == 0

        row = crud_find(c, spec, create_label)
        steps.append({"find_after_create": bool(row)})
        ok = ok and bool(row)
        if not row:
            return {"module": spec.name, "kind": "crud", "ok": False, "steps": steps}
        rid = row.get(spec.id_field)

        upd = crud_update(c, spec, rid, edit_fields)
        steps.append({"update": upd.get("code"), "msg": upd.get("msg")})
        ok = ok and upd.get("code") == 0

        row2 = crud_find(c, spec, edit_label)
        edit_applied = bool(row2)
        if row2 and spec.check_field:
            edit_applied = str(row2.get(spec.check_field)) == str(edit_fields.get(spec.check_field))
        steps.append({"verify_edit": edit_applied})
        ok = ok and edit_applied
        rid2 = (row2 or row).get(spec.id_field)

        dele = crud_delete(c, spec, rid2)
        steps.append({"delete": dele.get("code"), "msg": dele.get("msg")})
        ok = ok and dele.get("code") == 0

        gone = crud_find(c, spec, edit_label) is None and crud_find(c, spec, create_label) is None
        steps.append({"gone": gone})
        ok = ok and gone
    except PrimihubError as e:
        steps.append({"error": str(e)})
        ok = False

    # honest diagnosis for the platform-blocked cases the round-trip surfaces
    diag = None
    if not ok:
        blob = " ".join(str(s.get("msg", "")) for s in steps if isinstance(s, dict))
        created_ok = any(s.get("create") == 0 for s in steps if isinstance(s, dict))
        not_found = any(s.get("find_after_create") is False for s in steps if isinstance(s, dict))
        if "Unknown column" in blob:
            diag = "platform 数据库 schema drift（部署库缺列，非 skill 问题）"
        elif created_ok and not_found:
            diag = "platform 写/读数据源不一致（写入生效但列表读不到）"
    return {"module": spec.name, "kind": "crud", "ok": ok,
            "test_label": create_label, "steps": steps, "diagnosis": diag}
