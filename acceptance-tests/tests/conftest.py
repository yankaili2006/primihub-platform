"""Shared pytest fixtures + import path for the primihub-platform-func tests.

Offline tests (test_menu_requirements / test_defects_registry / test_specs_alignment)
need only `automation` on the path. Online tests (test_defects_online, marked
`live`) also need a reachable platform; the `platform_client` fixture logs in and
skips the whole test cleanly when the platform can't be reached, so CI stays green
offline.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

# make `automation` importable no matter where pytest is invoked from
SKILL_DIR = Path(__file__).resolve().parent.parent
if str(SKILL_DIR) not in sys.path:
    sys.path.insert(0, str(SKILL_DIR))


@pytest.fixture(scope="session")
def platform_client():
    """A logged-in PrimihubClient, or skip if the platform is unreachable.

    Reads PRIMIHUB_WEB_URL / PRIMIHUB_USER / PRIMIHUB_PASS (automation.config
    defaults apply). Any login/network failure => pytest.skip, never a red test.
    """
    from automation.client import PrimihubClient, PrimihubError  # noqa: E402

    client = PrimihubClient()
    try:
        client.login(use_cache=True)
    except PrimihubError as e:
        pytest.skip(f"platform unreachable ({client.web_url}): {e}")
    except Exception as e:  # network/DNS/timeouts
        pytest.skip(f"platform unreachable ({client.web_url}): {e}")
    if not client.token:
        pytest.skip(f"platform login returned no token ({client.web_url})")
    return client
