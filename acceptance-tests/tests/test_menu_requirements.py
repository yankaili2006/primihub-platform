"""Offline invariants locking the requirement doc (demand.csv) to the code model
(config.MODULES). If either drifts, these go red — no platform needed.

Source of truth: data/demand.csv (352-row "附表3 系统功能点计数表", 224 function
points across 18 modules), parsed by automation.config.parse_demand().
"""
from __future__ import annotations

import pytest

from automation.config import MODULES, parse_demand

ROWS = parse_demand()


def _range(m):
    lo, hi = m.range.replace("#", "").split("-")
    return int(lo), int(hi)


def test_demand_csv_present_and_nonempty():
    assert ROWS, "demand.csv did not parse to any rows — check config.DEMAND_CSV path"


def test_exactly_224_function_points():
    assert len(ROWS) == 224


def test_sequence_is_1_to_224_contiguous_no_gaps():
    seqs = [r.seq for r in ROWS]
    assert seqs == list(range(1, 225)), "序号 must be 1..224 contiguous, in order"


def test_exactly_18_submodules_in_order():
    seen = []
    for r in ROWS:
        if r.submodule not in seen:
            seen.append(r.submodule)
    assert len(seen) == 18
    assert seen == [m.name for m in MODULES], "submodule order must match MODULES"


def test_every_submodule_maps_to_a_module():
    names = {m.name for m in MODULES}
    for r in ROWS:
        assert r.submodule in names, f"demand submodule {r.submodule!r} not in MODULES"


@pytest.mark.parametrize("m", MODULES, ids=[m.id for m in MODULES])
def test_module_count_and_range_align(m):
    rows = [r for r in ROWS if r.submodule == m.name]
    lo, hi = _range(m)
    assert len(rows) == m.count, f"{m.name}: {len(rows)} rows, MODULES.count={m.count}"
    seqs = [r.seq for r in rows]
    assert min(seqs) == lo and max(seqs) == hi, f"{m.name}: range {min(seqs)}-{max(seqs)} != {lo}-{hi}"


def test_module_ranges_tile_1_to_224_without_overlap():
    covered: list[int] = []
    for m in MODULES:
        lo, hi = _range(m)
        covered.extend(range(lo, hi + 1))
    assert sorted(covered) == list(range(1, 225)), "MODULES ranges must tile #1..#224 seamlessly"


def test_module_counts_sum_to_224():
    assert sum(m.count for m in MODULES) == 224


def test_module_ids_are_01_to_18_unique():
    ids = [m.id for m in MODULES]
    assert ids == [f"{i:02d}" for i in range(1, 19)]
