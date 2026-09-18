#!/usr/bin/env python3
"""单方特征编码。前端字段: encodeMethod(ONE_HOT/LABEL/BINARY/TARGET/FREQUENCY), encodeFields[]."""
import pandas as pd
from _common import load_params, read_dataset, pick_fields, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = (params.get("encodeMethod") or "ONE_HOT").upper()
    cols = pick_fields(df, params.get("encodeFields"))

    if method == "ONE_HOT":
        df = pd.get_dummies(df, columns=cols, dtype=int)
        summary = "OneHot 编码 %d 个字段" % len(cols)
    elif method == "LABEL":
        for c in cols:
            df[c] = pd.factorize(df[c])[0]
        summary = "Label 编码 %d 个字段" % len(cols)
    elif method == "BINARY":
        for c in cols:
            codes = pd.factorize(df[c])[0]
            width = max(int(codes.max()).bit_length(), 1)
            for b in range(width):
                df["%s_bin%d" % (c, b)] = (codes >> b) & 1
            df = df.drop(columns=[c])
        summary = "Binary 编码 %d 个字段" % len(cols)
    elif method == "TARGET":
        label = params.get("labelField") or ("label" if "label" in df.columns else None)
        if not label or label not in df.columns:
            fail("Target 编码需要标签列：数据集无 label 列且未指定 labelField")
        y = pd.to_numeric(df[label], errors="coerce")
        if y.isna().all():
            fail("Target 编码要求标签列为数值型: %s" % label)
        for c in cols:
            if c == label:
                continue
            df[c] = df[c].map(y.groupby(df[c]).mean())
        summary = "Target 编码 %d 个字段(标签=%s)" % (len(cols), label)
    elif method == "FREQUENCY":
        for c in cols:
            df[c] = df[c].map(df[c].value_counts(normalize=True)).round(6)
        summary = "Frequency 编码 %d 个字段" % len(cols)
    else:
        fail("不支持的编码方法: %s" % method)

    p = save(df, params)
    emit(params, p, len(df), summary)


if __name__ == "__main__":
    main()
