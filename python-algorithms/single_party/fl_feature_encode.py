#!/usr/bin/env python3
"""联邦学习-特征编码（本地真实计算）。前端字段: encodeMethod(ONEHOT/LABEL/BINARY),
encodeFields[](空=全部非数值列)。"""
import pandas as pd

from _common import load_params, read_dataset, listy, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = (params.get("encodeMethod") or "ONEHOT").upper()
    cols = listy(params.get("encodeFields"))
    if cols:
        missing = [c for c in cols if c not in df.columns]
        if missing:
            fail("字段不存在: %s，数据集可用字段: %s" % (missing, list(df.columns)))
    else:
        cols = list(df.select_dtypes(include="object").columns)
        if not cols:
            fail("没有可编码的非数值字段，请指定编码字段")

    if method == "ONEHOT":
        df = pd.get_dummies(df, columns=cols, dtype=int)
    elif method == "LABEL":
        for c in cols:
            df[c] = df[c].astype("category").cat.codes
    elif method == "BINARY":
        # 二进制编码: label 码按位展开成 ceil(log2(n)) 列
        for c in cols:
            codes = df[c].astype("category").cat.codes.astype(int)
            n_bits = max(int(codes.max()).bit_length(), 1)
            for b in range(n_bits):
                df["%s_bin%d" % (c, b)] = (codes // (2 ** b)) % 2
            df = df.drop(columns=[c])
    else:
        fail("不支持的编码方法: %s" % method)

    p = save(df, params)
    emit(params, p, len(df), "%s 编码 %d 个字段, 输出 %d 列" % (method, len(cols), df.shape[1]))


if __name__ == "__main__":
    main()
