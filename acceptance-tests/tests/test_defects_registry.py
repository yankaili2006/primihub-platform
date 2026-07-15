"""Offline invariants for the 44-defect registry (automation.defects.DEFECTS).

Locks the docx → structured mapping: count, id uniqueness, legal categories,
module ∈ MODULES, verify well-formedness, and the per-category tally derived from
the docx table (authoritative over the plan's rounded summary line).
"""
from __future__ import annotations

import pytest

from automation.config import MODULES
from automation.defects import (
    ASSERT_KINDS,
    CATEGORIES,
    DEFECTS,
    Verify,
    category_counts,
    defect_by_id,
    manual_defects,
    open_defects,
)

MODULE_IDS = {m.id for m in MODULES}
MODULE_NAMES = {m.name for m in MODULES}

# per-category counts taken directly from the docx 44-row table (single primary
# category per row; D31 "导出/假成功" -> 导出). Sums to 44.
EXPECTED_CATEGORY_COUNTS = {
    "无响应": 10,
    "无按钮": 2,
    "404": 2,
    "请求异常": 9,
    "导出": 6,
    "时间字段": 1,
    "假成功": 2,
    "查询": 4,
    "功能缺失": 5,
    "整模块": 3,
}


def test_exactly_44_defects():
    assert len(DEFECTS) == 44


def test_ids_are_D01_to_D44_unique():
    ids = [d.id for d in DEFECTS]
    assert len(set(ids)) == 44, "defect ids must be unique"
    assert set(ids) == {f"D{i:02d}" for i in range(1, 45)}


def test_every_module_in_MODULES():
    for d in DEFECTS:
        assert d.mid in MODULE_IDS, f"{d.id}: mid {d.mid!r} not a MODULES id"
        assert d.module in MODULE_NAMES, f"{d.id}: module {d.module!r} not in MODULES names"


def test_every_category_legal():
    for d in DEFECTS:
        assert d.category in CATEGORIES, f"{d.id}: illegal category {d.category!r}"


def test_category_counts_match_docx_table():
    assert category_counts() == EXPECTED_CATEGORY_COUNTS
    assert sum(EXPECTED_CATEGORY_COUNTS.values()) == 44


def test_expect_and_page_nonempty():
    for d in DEFECTS:
        assert d.page.strip(), f"{d.id}: empty page"
        assert d.expect.strip(), f"{d.id}: empty expect"
        assert d.runbook.strip(), f"{d.id}: empty runbook"


@pytest.mark.parametrize("d", [d for d in DEFECTS if d.verify], ids=[d.id for d in DEFECTS if d.verify])
def test_verify_wellformed(d):
    v = d.verify
    assert isinstance(v, Verify)
    assert v.assert_kind in ASSERT_KINDS, f"{d.id}: bad assert_kind {v.assert_kind!r}"
    assert v.method in ("get", "post", "post_json"), f"{d.id}: bad method {v.method!r}"
    assert v.path.startswith("/"), f"{d.id}: path must be absolute, got {v.path!r}"
    assert isinstance(v.params, dict)


def test_manual_defects_have_no_verify_and_are_flagged():
    for d in manual_defects():
        assert d.verify is None
        assert d.manual is True


def test_roundtrip_defects_target_crud_safe_modules():
    from automation.crud import SPECS
    for d in DEFECTS:
        if d.verify and d.verify.assert_kind == "roundtrip":
            spec = SPECS.get(d.mid)
            assert spec is not None and spec.kind == "crud", \
                f"{d.id}: roundtrip requires a CRUD-safe module, {d.mid} is {spec and spec.kind}"


def test_helpers_consistent():
    assert defect_by_id("D01") is DEFECTS[0]
    assert defect_by_id("DXX") is None
    assert len(manual_defects()) + len([d for d in DEFECTS if d.verify]) == 44
    # open_defects is a subset of all defects
    assert all(d in DEFECTS for d in open_defects())


def test_search_scoped_defects_carry_a_keyword():
    for d in DEFECTS:
        if d.verify and d.verify.assert_kind == "search_scoped":
            p = d.verify.params
            assert p.get("keyword") or p.get("taskId"), \
                f"{d.id}: search_scoped needs a keyword/taskId param"
