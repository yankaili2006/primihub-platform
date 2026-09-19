#!/usr/bin/env python3
"""联邦学习-数据变换（本地真实计算）。前端字段: transformOps[](TYPE_CAST/
MISSING_VALUE/NORMALIZE/STANDARDIZE/DISCRETIZE)。按选择顺序依次应用于数值列。"""
import pandas as pd

from _common import load_params, read_dataset, listy, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    ops = [o.upper() for o in listy(params.get("transformOps"))]
    if not ops:
        fail("未选择变换操作")
    notes = []

    if "TYPE_CAST" in ops:
        casted = 0
        for c in df.select_dtypes(include="object").columns:
            converted = pd.to_numeric(df[c], errors="coerce")
            # 只有整列都能转数值时才转换，避免把有效文本变成 NaN
            if converted.notna().sum() == df[c].notna().sum():
                df[c] = converted
                casted += 1
        notes.append("类型转换 %d 列" % casted)

    if "MISSING_VALUE" in ops:
        na_before = int(df.isna().sum().sum())
        num_cols = df.select_dtypes(include="number").columns
        df[num_cols] = df[num_cols].fillna(df[num_cols].mean())
        for c in df.select_dtypes(exclude="number").columns:
            mode = df[c].mode(dropna=True)
            if len(mode):
                df[c] = df[c].fillna(mode.iloc[0])
        notes.append("缺失值填充 %d 个" % (na_before - int(df.isna().sum().sum())))

    num_cols = df.select_dtypes(include="number").columns
    if "NORMALIZE" in ops:
        if len(num_cols) == 0:
            fail("归一化需要数值列，数据集中没有数值列")
        rng = df[num_cols].max() - df[num_cols].min()
        rng = rng.replace(0, 1)
        df[num_cols] = (df[num_cols] - df[num_cols].min()) / rng
        notes.append("归一化 %d 列" % len(num_cols))

    if "STANDARDIZE" in ops:
        if len(num_cols) == 0:
            fail("标准化需要数值列，数据集中没有数值列")
        std = df[num_cols].std(ddof=0).replace(0, 1)
        df[num_cols] = (df[num_cols] - df[num_cols].mean()) / std
        notes.append("标准化 %d 列" % len(num_cols))

    if "DISCRETIZE" in ops:
        if len(num_cols) == 0:
            fail("离散化需要数值列，数据集中没有数值列")
        for c in num_cols:
            if df[c].nunique() > 5:
                df[c] = pd.qcut(df[c], 5, labels=False, duplicates="drop")
        notes.append("离散化(5 分位)")

    p = save(df, params)
    emit(params, p, len(df), "；".join(notes))


if __name__ == "__main__":
    main()
