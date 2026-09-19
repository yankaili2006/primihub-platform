#!/usr/bin/env python3
"""联邦学习-样本加权（本地真实计算）。前端字段: weightMethod(EQUAL/
INVERSE_FREQUENCY/CUSTOM), targetField(INVERSE_FREQUENCY 必填),
weightCoefficient。输出: 原数据 + sample_weight 列。"""
from _common import load_params, read_dataset, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = (params.get("weightMethod") or "EQUAL").upper()
    coef = float(params.get("weightCoefficient") or 1.0)

    if method == "EQUAL":
        df["sample_weight"] = 1.0
        summary = "均等权重: 全部样本 weight=1.0"
    elif method == "CUSTOM":
        df["sample_weight"] = coef
        summary = "自定义权重: 全部样本 weight=%.4f" % coef
    elif method == "INVERSE_FREQUENCY":
        field = (params.get("targetField") or "").strip()
        if not field:
            fail("逆频率加权需要指定目标字段(targetField)")
        if field not in df.columns:
            fail("目标字段不存在: %s，数据集可用字段: %s" % (field, list(df.columns)))
        counts = df[field].value_counts(dropna=False)
        n, k = len(df), len(counts)
        df["sample_weight"] = df[field].map(lambda v: coef * n / (k * counts[v]))
        summary = "逆频率加权: %d 个类别, 权重范围 [%.4f, %.4f]" % (
            k, df["sample_weight"].min(), df["sample_weight"].max())
    else:
        fail("不支持的加权方法: %s" % method)

    p = save(df, params)
    emit(params, p, len(df), summary)


if __name__ == "__main__":
    main()
