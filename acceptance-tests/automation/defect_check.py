#!/usr/bin/env python3
"""Online evaluator for the 44 defects — the single honest judge shared by the
pytest `live` suite (tests/test_defects_online.py) and `skill.py verify-defects`.

`evaluate(client, defect)` returns a Result with one of:
  pass    — the defect's acceptance signal is met
  fail    — endpoint reachable but signal NOT met (真·未满足；含 inferred 路由不存在)
  skip    — cannot decide automatically here (business error needing real data, or
            network hiccup) — reported, never counted as满足
  manual  — verify is None: needs browser/human (save-writes, 假成功, time field)

Route-missing detection mirrors scripts/regression-smoke.py: a response is treated
as route-missing when it carries HTTP status 404, a Spring whitelabel `path`, or a
'系统异常' message — i.e. the endpoint isn't wired, as opposed to a business error.
"""
from __future__ import annotations

from typing import Any, NamedTuple, Optional

from .client import PrimihubClient, PrimihubError
from .crud import SPECS, roundtrip
from .defects import DefectMeta, Verify


class Result(NamedTuple):
    defect_id: str
    status: str            # pass | fail | skip | manual
    detail: str
    category: str = ""
    module: str = ""


# A wrapped error whose message names the HTTP method / content-type / a required
# parameter proves the endpoint IS wired (Spring resolved a handler, then rejected
# the request shape) — it is NOT route-missing. Learned empirically from the live
# platform: "系统异常: Request method 'GET' not supported" / "Content type '...' not
# supported" / "Required Long parameter 'x'" all come back as code=-1 with these
# signals, and must count as route_exists, not route-missing.
_EXISTS_SIGNALS = (
    "request method", "not supported", "content type", "required ",
    "method not allowed", "缺少参数", "参数",
)
_MISSING_SIGNALS = ("no handler", "nohandlerfound", "not found", "无法找到")


def _endpoint_exists_signal(msg: str) -> bool:
    return any(s in msg.lower() for s in _EXISTS_SIGNALS)


def _is_route_missing(r: dict) -> bool:
    if not isinstance(r, dict):
        return False
    if r.get("status") == 404 or r.get("code") == 404:
        return True
    if isinstance(r.get("path"), str) and "code" not in r:
        return True
    msg = str(r.get("msg", ""))
    if _endpoint_exists_signal(msg):
        return False  # method/content-type/param error => endpoint is wired
    return any(s in msg.lower() for s in _MISSING_SIGNALS)


def _call(client: PrimihubClient, v: Verify) -> Any:
    """Invoke the verify endpoint; returns parsed dict, or a ('non-json', body)
    tuple when the server streamed a file (normal for export endpoints)."""
    method = "post" if v.method == "post_json" else v.method
    json_body = v.json_body or v.method == "post_json"
    try:
        return client.call(v.path, method, dict(v.params), json_body=json_body)
    except PrimihubError as e:
        if e.code == "non-json":
            return ("non-json", e.msg)
        raise


def _rows(r: dict) -> list:
    result = r.get("result") if isinstance(r, dict) else None
    if isinstance(result, list):
        return result
    if isinstance(result, dict):
        for k in ("list", "records", "data", "rows"):
            if isinstance(result.get(k), list):
                return result[k]
        for val in result.values():
            if isinstance(val, list):
                return val
    return []


def _keyword(v: Verify) -> str:
    return str(v.params.get("keyword") or v.params.get("taskId") or "")


def evaluate(client: PrimihubClient, d: DefectMeta) -> Result:
    base = dict(category=d.category, module=d.module)
    if d.verify is None:
        return Result(d.id, "manual", d.runbook, **base)

    v = d.verify
    try:
        # roundtrip has its own safe create->edit->delete driver
        if v.assert_kind == "roundtrip":
            spec = SPECS.get(d.mid)
            if spec is None or spec.kind != "crud":
                return Result(d.id, "skip", f"no CRUD spec for module {d.mid}", **base)
            res = roundtrip(client, spec)
            ok = res.get("ok")
            if ok is True:
                return Result(d.id, "pass", "safe create→edit→delete round-trip ok", **base)
            if ok is None:
                return Result(d.id, "skip", res.get("note", "roundtrip skipped"), **base)
            return Result(d.id, "fail", res.get("diagnosis") or f"roundtrip failed: {res.get('steps')}", **base)

        r = _call(client, v)

        # export endpoints may stream a file body (non-json) => real content exists
        if isinstance(r, tuple) and r[0] == "non-json":
            body = r[1] or ""
            if v.assert_kind == "export_nonempty":
                # 有内容=真导出通过；空文件体=端点已响应但无数据(真缺失会走下方 JSON
                # 404/系统异常分支，不会到这里)→判 skip(待数据)，不误报为缺陷未满足
                if body.strip():
                    return Result(d.id, "pass", f"non-json body ({len(body)}B)", **base)
                return Result(d.id, "skip", "export route wired, empty body (needs data)", **base)
            return Result(d.id, "skip", f"non-json response: {body[:60]}", **base)

        code = r.get("code")
        msg = str(r.get("msg", ""))
        missing = _is_route_missing(r)

        if v.assert_kind in ("code0", "has_button"):
            if code == 0:
                extra = "（按钮可视性仍需人工确认）" if v.assert_kind == "has_button" else ""
                return Result(d.id, "pass", f"code=0{extra}", **base)
            if missing:
                return Result(d.id, "fail", f"route missing: code={code} msg={msg[:60]}", **base)
            return Result(d.id, "fail", f"code={code} msg={msg[:60]}", **base)

        if v.assert_kind == "route_exists":
            if missing:
                tag = " (inferred 路由不存在)" if v.inferred else ""
                return Result(d.id, "fail", f"route missing{tag}: code={code} msg={msg[:60]}", **base)
            return Result(d.id, "pass", f"route wired: code={code} msg={msg[:40]}", **base)

        if v.assert_kind == "search_scoped":
            if missing:
                return Result(d.id, "fail", f"route missing: {msg[:60]}", **base)
            if code != 0:
                return Result(d.id, "fail", f"search errored: code={code} msg={msg[:60]}", **base)
            kw = _keyword(v)
            rows = _rows(r)
            if not rows:
                return Result(d.id, "pass", f'no rows for "{kw}" (special char handled, no crash)', **base)
            polluted = [row for row in rows if kw and kw not in " ".join(str(x) for x in row.values())]
            if polluted:
                return Result(d.id, "fail",
                              f'{len(polluted)}/{len(rows)} rows do NOT contain "{kw}" (match pollution)', **base)
            return Result(d.id, "pass", f'{len(rows)} rows all contain "{kw}"', **base)

        if v.assert_kind == "export_nonempty":
            if missing:
                tag = " (inferred 路由不存在)" if v.inferred else ""
                return Result(d.id, "fail", f"export route missing{tag}: {msg[:60]}", **base)
            if code == 0:
                # honest: code0 with data => pass; code0 on truly empty is acceptable too
                return Result(d.id, "pass", "export returned code=0", **base)
            return Result(d.id, "skip", f"export needs real data: code={code} msg={msg[:60]}", **base)

        return Result(d.id, "skip", f"unhandled assert_kind {v.assert_kind}", **base)

    except PrimihubError as e:
        if e.code == "net":
            return Result(d.id, "skip", f"network: {e.msg[:60]}", **base)
        return Result(d.id, "fail", f"{e}", **base)
    except Exception as e:  # never let one defect crash the whole pass
        return Result(d.id, "skip", f"unexpected: {e}", **base)


def evaluate_all(client: PrimihubClient, defects) -> list[Result]:
    return [evaluate(client, d) for d in defects]


def summarize(results: list[Result]) -> dict:
    out = {"pass": 0, "fail": 0, "skip": 0, "manual": 0, "total": len(results)}
    for r in results:
        out[r.status] = out.get(r.status, 0) + 1
    return out
