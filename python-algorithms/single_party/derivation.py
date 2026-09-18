#!/usr/bin/env python3
"""单方特征衍生。前端字段: deriveMethods[](POLYNOMIAL/CROSS/MATH_TRANSFORM/TIME_EXTRACT/TEXT_EXTRACT),
baseFields[], polyDegree."""
import numpy as np
import pandas as pd
from _common import load_params, read_dataset, pick_fields, listy, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    methods = [m.upper() for m in listy(params.get("deriveMethods"))]
    if not methods:
        fail("未选择衍生方法")
    degree = int(params.get("polyDegree") or 2)
    added = []

    if "POLYNOMIAL" in methods:
        cols = pick_fields(df, params.get("baseFields"), numeric=True)
        for c in cols:
            for d in range(2, max(degree, 2) + 1):
                name = "%s_pow%d" % (c, d)
                df[name] = df[c] ** d
                added.append(name)

    if "CROSS" in methods:
        cols = pick_fields(df, params.get("baseFields"), numeric=True)
        for i in range(len(cols)):
            for j in range(i + 1, len(cols)):
                name = "%s_x_%s" % (cols[i], cols[j])
                df[name] = df[cols[i]] * df[cols[j]]
                added.append(name)

    if "MATH_TRANSFORM" in methods:
        cols = pick_fields(df, params.get("baseFields"), numeric=True)
        for c in cols:
            if (df[c] >= 0).all():
                df[c + "_log1p"] = np.log1p(df[c])
                df[c + "_sqrt"] = np.sqrt(df[c])
                added += [c + "_log1p", c + "_sqrt"]
            df[c + "_square"] = df[c] ** 2
            added.append(c + "_square")

    if "TIME_EXTRACT" in methods:
        cols = listy(params.get("baseFields")) or list(df.columns)
        hit = 0
        for c in cols:
            if c not in df.columns or df[c].dtype.kind in "biufc":
                continue
            ts = pd.to_datetime(df[c], errors="coerce")
            if ts.notna().mean() < 0.8:
                continue
            for part, val in (("year", ts.dt.year), ("month", ts.dt.month),
                              ("day", ts.dt.day), ("weekday", ts.dt.weekday)):
                name = "%s_%s" % (c, part)
                df[name] = val
                added.append(name)
            hit += 1
        if not hit and methods == ["TIME_EXTRACT"]:
            fail("所选字段中没有可解析为时间的列")

    if "TEXT_EXTRACT" in methods:
        cols = listy(params.get("baseFields")) or list(df.select_dtypes(include="object").columns)
        hit = 0
        for c in cols:
            if c not in df.columns or df[c].dtype.kind != "O":
                continue
            s = df[c].astype(str)
            df[c + "_len"] = s.str.len()
            df[c + "_words"] = s.str.split().str.len()
            added += [c + "_len", c + "_words"]
            hit += 1
        if not hit and methods == ["TEXT_EXTRACT"]:
            fail("所选字段中没有文本列")

    unknown = [m for m in methods if m not in
               ("POLYNOMIAL", "CROSS", "MATH_TRANSFORM", "TIME_EXTRACT", "TEXT_EXTRACT")]
    if unknown:
        fail("不支持的衍生方法: %s" % unknown)

    p = save(df, params)
    emit(params, p, len(df), "衍生新特征 %d 个: %s" % (
        len(added), ",".join(added[:10]) + ("…" if len(added) > 10 else "")))


if __name__ == "__main__":
    main()
