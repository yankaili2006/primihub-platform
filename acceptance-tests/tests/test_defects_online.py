"""Online acceptance pass over the 44 defects (marked `live`).

Auto-skips entirely when the platform is unreachable (platform_client fixture),
so this file is inert in offline CI. When a platform IS reachable:
  pass   -> the defect's acceptance signal is met
  fail   -> reachable but NOT met (真·未满足) — a red here is a real acceptance gap
  skip   -> manual/browser defect, or a business error needing real data

Run:
  PRIMIHUB_WEB_URL=http://100.64.0.25:30811 PRIMIHUB_USER=admin PRIMIHUB_PASS=primihub123 \
    python3 -m pytest tests/test_defects_online.py -v
"""
from __future__ import annotations

import pytest

from automation.defects import DEFECTS
from automation.defect_check import evaluate

pytestmark = pytest.mark.live


@pytest.mark.parametrize("defect", DEFECTS, ids=[d.id for d in DEFECTS])
def test_defect_acceptance(platform_client, defect):
    res = evaluate(platform_client, defect)
    line = f"{defect.id} [{defect.category}] {defect.module}/{defect.page}: {res.detail}"
    if res.status == "pass":
        return
    if res.status in ("skip", "manual"):
        pytest.skip(f"{res.status}: {line}")
    pytest.fail(f"UNMET: {line}")
