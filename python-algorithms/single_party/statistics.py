#!/usr/bin/env python3
"""单方数据统计。前端字段: statType(DESCRIBE/COUNT/SUM/FREQ/MISSING/UNIQUE), fields[], groupField."""
import pandas as pd
from _common import load_params, read_dataset, pick_fields, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    stat_type = (params.get("statType") or "DESCRIBE").upper()
    group_field = (params.get("groupField") or "").strip()
    if group_field and group_field not in df.columns:
        fail("分组字段不存在: %s" % group_field)

    if stat_type == "DESCRIBE":
        cols = pick_fields(df, params.get("fields"), numeric=True)
        if group_field:
            out = df.groupby(group_field)[cols].describe()
            out.columns = ["_".join(c) for c in out.columns]
            out = out.reset_index()
        else:
            out = df[cols].describe().T.reset_index().rename(columns={"index": "字段"})
        summary = "描述性统计 %d 个字段" % len(cols)
    elif stat_type == "COUNT":
        cols = pick_fields(df, params.get("fields"))
        if group_field:
            out = df.groupby(group_field)[cols].count().reset_index()
        else:
            out = df[cols].count().rename("非空计数").reset_index().rename(columns={"index": "字段"})
        summary = "计数统计 %d 个字段" % len(cols)
    elif stat_type == "SUM":
        cols = pick_fields(df, params.get("fields"), numeric=True)
        if group_field:
            out = df.groupby(group_field)[cols].sum().reset_index()
        else:
            out = df[cols].sum().rename("求和").reset_index().rename(columns={"index": "字段"})
        summary = "求和统计 %d 个字段" % len(cols)
    elif stat_type == "FREQ":
        cols = pick_fields(df, params.get("fields"))
        parts = []
        for c in cols:
            vc = df[c].value_counts(dropna=False).head(50)
            parts.append(pd.DataFrame({
                "字段": c, "取值": vc.index.astype(str), "频数": vc.values,
                "频率": (vc.values / len(df)).round(6)}))
        out = pd.concat(parts, ignore_index=True)
        summary = "频率分布 %d 个字段(每字段前50取值)" % len(cols)
    elif stat_type == "MISSING":
        cols = pick_fields(df, params.get("fields"))
        na = df[cols].isna().sum()
        out = pd.DataFrame({"字段": na.index, "缺失数": na.values,
                            "缺失率": (na.values / len(df)).round(6)})
        summary = "缺失值统计 %d 个字段" % len(cols)
    elif stat_type == "UNIQUE":
        cols = pick_fields(df, params.get("fields"))
        nu = df[cols].nunique()
        out = pd.DataFrame({"字段": nu.index, "唯一值数": nu.values})
        summary = "唯一值统计 %d 个字段" % len(cols)
    else:
        fail("不支持的统计类型: %s" % stat_type)

    p = save(out, params)
    emit(params, p, len(out), summary)


if __name__ == "__main__":
    main()
