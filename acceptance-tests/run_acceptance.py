#!/usr/bin/env python3
"""Minimal CLI for the PrimiHub 44-defect acceptance pass — portable, no pCloud deps.

Offline (invariants only, no platform):
    python3 -m pytest tests/ -m "not live" -q

Online (against a reachable platform):
    PRIMIHUB_WEB_URL=http://<vm>:30811 PRIMIHUB_USER=admin PRIMIHUB_PASS=<pw> \
        python3 run_acceptance.py            # 44-defect pass/fail/skip/manual report
    python3 run_acceptance.py --json          # machine-readable
    python3 run_acceptance.py D27             # single defect

Config via env (see automation/config.py): PRIMIHUB_WEB_URL / PRIMIHUB_USER /
PRIMIHUB_PASS / PRIMIHUB_API_BASE.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from automation import config  # noqa: E402
from automation.client import PrimihubClient, PrimihubError  # noqa: E402
from automation.defects import DEFECTS, defect_by_id  # noqa: E402
from automation.defect_check import evaluate, summarize  # noqa: E402

R, G, Y, C, B, N = "\033[91m", "\033[92m", "\033[93m", "\033[96m", "\033[1m", "\033[0m"
MARK = {"pass": f"{G}✅{N}", "fail": f"{R}❌{N}", "skip": f"{Y}—{N}", "manual": f"{C}✋{N}"}


def main() -> int:
    argv = [a for a in sys.argv[1:] if a not in ("--json", "-j")]
    json_fmt = "--json" in sys.argv or "-j" in sys.argv
    only = argv[0] if argv and not argv[0].startswith("-") else None

    targets = DEFECTS
    if only:
        d = defect_by_id(only.upper())
        if not d:
            print(f"unknown defect {only} (D01..D44)", file=sys.stderr)
            return 1
        targets = [d]

    c = PrimihubClient(config.WEB_URL, config.USER, config.PASS, config.API_BASE)
    try:
        c.login()
    except PrimihubError as e:
        msg = {"ok": False, "reachable": False, "error": str(e), "target": c.web_url}
        print(json.dumps(msg, ensure_ascii=False, indent=2) if json_fmt
              else f"{R}platform unreachable {c.web_url}: {e}{N}\n"
                   f"offline invariants still run: pytest tests/ -m 'not live'")
        return 1

    results = [evaluate(c, d) for d in targets]
    summary = summarize(results)
    if json_fmt:
        print(json.dumps({"target": c.web_url, "summary": summary,
                          "results": [r._asdict() for r in results]},
                         ensure_ascii=False, indent=2))
        return 0 if summary["fail"] == 0 else 2

    print(f"\n{B}PrimiHub 44-defect acceptance  target={c.web_url}{N}")
    print(f"  {'ID':4s} | {'状态':4s} | {'分类':6s} | 模块/说明")
    print(f"  {'-'*4} | {'-'*4} | {'-'*6} | {'-'*40}")
    for r in results:
        print(f"  {r.defect_id:4s} | {MARK.get(r.status, r.status):^4s} | {r.category:6s} | "
              f"{r.module}/{r.detail[:60]}")
    print(f"\n  {G}满足{N}={summary['pass']}  {R}未满足{N}={summary['fail']}  "
          f"{Y}待数据{N}={summary['skip']}  {C}需手工{N}={summary['manual']}  / {summary['total']}\n")
    return 0 if summary["fail"] == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
