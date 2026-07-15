"""Offline invariants for automation.crud.SPECS — every entry is a real MODULES
module, has a legal kind, and CRUD-kind specs carry a complete, safe round-trip
definition (endpoints + id/label fields + create/edit factories).
"""
from __future__ import annotations

import pytest

from automation.config import MODULES
from automation.crud import SPECS, Op

MODULE_IDS = {m.id for m in MODULES}
LEGAL_KINDS = {"crud", "heavy", "readonly", "task"}


def test_specs_cover_every_module_exactly_once():
    assert set(SPECS.keys()) == MODULE_IDS, "SPECS keys must be exactly the 18 module ids"
    for mid, spec in SPECS.items():
        assert spec.mid == mid, f"{mid}: spec.mid mismatch ({spec.mid})"


def test_spec_names_match_MODULES():
    by_id = {m.id: m.name for m in MODULES}
    for mid, spec in SPECS.items():
        assert spec.name == by_id[mid], f"{mid}: {spec.name!r} != MODULES {by_id[mid]!r}"


def test_kinds_legal():
    for mid, spec in SPECS.items():
        assert spec.kind in LEGAL_KINDS, f"{mid}: illegal kind {spec.kind!r}"


@pytest.mark.parametrize(
    "mid", [k for k, v in SPECS.items() if v.kind == "crud"],
    ids=[k for k, v in SPECS.items() if v.kind == "crud"],
)
def test_crud_specs_are_complete(mid):
    spec = SPECS[mid]
    assert spec.list_path and spec.list_path.startswith("/"), f"{mid}: bad list_path"
    for name, op in (("create", spec.create), ("update", spec.update), ("delete", spec.delete)):
        assert isinstance(op, Op), f"{mid}: missing {name} Op"
        assert op.path.startswith("/"), f"{mid}: {name} path must be absolute"
        assert op.method in ("post", "get"), f"{mid}: {name} bad method {op.method!r}"
    assert spec.id_field, f"{mid}: missing id_field"
    assert spec.label_field, f"{mid}: missing label_field"
    assert callable(spec.make_create) and callable(spec.make_edit), f"{mid}: missing factories"


@pytest.mark.parametrize(
    "mid", [k for k, v in SPECS.items() if v.kind == "crud"],
    ids=[k for k, v in SPECS.items() if v.kind == "crud"],
)
def test_crud_factories_produce_label_and_are_unique(mid):
    spec = SPECS[mid]
    create = spec.make_create("111222")
    edit = spec.make_edit("111222")
    assert spec.label_field in create, f"{mid}: make_create missing label_field {spec.label_field}"
    assert spec.label_field in edit, f"{mid}: make_edit missing label_field {spec.label_field}"
    # edit must differ from create in the check_field (or label) so a landed edit is provable
    field = spec.check_field or spec.label_field
    if field in create and field in edit:
        assert create[field] != edit[field], f"{mid}: edit does not change {field}; can't prove update"


def test_noncrud_specs_carry_an_honest_note():
    for mid, spec in SPECS.items():
        if spec.kind != "crud":
            assert spec.note.strip(), f"{mid}: {spec.kind} spec must document why (note)"
