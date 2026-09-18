#!/usr/bin/env python3
"""单方特征分箱。前端字段: binMethod(EQUAL_FREQ/EQUAL_WIDTH/CHI_SQUARE/CUSTOM), binFields[], binCount."""
import pandas as pd
from _common import load_params, read_dataset, pick_fields, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = (params.get("binMethod") or "EQUAL_WIDTH").upper()
    cols = pick_fields(df, params.get("binFields"), numeric=True)
    bins = int(params.get("binCount") or 5)
    if bins < 2:
        fail("分箱数须 >= 2")

    if method == "EQUAL_FREQ":
        for c in cols:
            df[c + "_bin"] = pd.qcut(df[c], q=bins, duplicates="drop").astype(str)
        summary = "等频分箱 %d 个字段(%d 箱)" % (len(cols), bins)
    elif method in ("EQUAL_WIDTH", "CUSTOM"):
        for c in cols:
            df[c + "_bin"] = pd.cut(df[c], bins=bins).astype(str)
        summary = "等宽分箱 %d 个字段(%d 箱)" % (len(cols), bins)
    elif method == "CHI_SQUARE":
        label = params.get("labelField") or ("label" if "label" in df.columns else None)
        if not label or label not in df.columns:
            fail("卡方分箱需要标签列：数据集无 label 列且未指定 labelField")
        from sklearn.tree import DecisionTreeClassifier
        # 以单特征决策树近似卡方最优切分（监督分箱的常用等价实现）
        for c in cols:
            sub = df[[c, label]].dropna()
            tree = DecisionTreeClassifier(max_leaf_nodes=bins, min_samples_leaf=max(1, len(sub) // 50))
            tree.fit(sub[[c]], sub[label])
            th = sorted(t for t, f in zip(tree.tree_.threshold, tree.tree_.feature) if f == 0)
            edges = [float("-inf")] + th + [float("inf")]
            df[c + "_bin"] = pd.cut(df[c], bins=edges).astype(str)
        summary = "卡方(监督)分箱 %d 个字段(≤%d 箱，标签=%s)" % (len(cols), bins, label)
    else:
        fail("不支持的分箱方法: %s" % method)

    p = save(df, params)
    emit(params, p, len(df), summary)


if __name__ == "__main__":
    main()
