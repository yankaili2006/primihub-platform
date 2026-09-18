#!/usr/bin/env python3
"""单方特征筛选。前端字段: selectMethod(VARIANCE/CORRELATION/CHI_SQUARE/RFE/L1),
labelField, featureFields[], keepCount."""
import pandas as pd
from _common import load_params, read_dataset, pick_fields, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = (params.get("selectMethod") or "VARIANCE").upper()
    label = (params.get("labelField") or "").strip()
    keep = int(params.get("keepCount") or 10)

    feats = pick_fields(df, params.get("featureFields"), numeric=True)
    if label:
        if label not in df.columns:
            fail("标签字段不存在: %s" % label)
        feats = [c for c in feats if c != label]
    if not feats:
        fail("没有可筛选的数值特征")
    keep = min(keep, len(feats))
    sub = df[feats + ([label] if label else [])].dropna()
    if sub.empty:
        fail("去除缺失后无可用样本，请先做数据清洗")
    X = sub[feats]

    if method == "VARIANCE":
        scores = X.var().sort_values(ascending=False)
        summary = "方差过滤"
    elif method == "CORRELATION":
        if not label:
            fail("相关系数过滤需要指定标签字段")
        y = pd.to_numeric(sub[label], errors="coerce")
        scores = X.apply(lambda c: c.corr(y)).abs().sort_values(ascending=False)
        summary = "相关系数过滤(标签=%s)" % label
    elif method == "CHI_SQUARE":
        if not label:
            fail("卡方检验需要指定标签字段")
        from sklearn.feature_selection import chi2
        Xs = X - X.min()  # chi2 要求非负
        sc, _ = chi2(Xs, sub[label])
        scores = pd.Series(sc, index=feats).sort_values(ascending=False)
        summary = "卡方检验(标签=%s)" % label
    elif method == "RFE":
        if not label:
            fail("RFE 需要指定标签字段")
        from sklearn.feature_selection import RFE
        from sklearn.linear_model import LogisticRegression
        rfe = RFE(LogisticRegression(max_iter=1000), n_features_to_select=keep)
        rfe.fit(X, sub[label])
        scores = pd.Series((len(feats) - rfe.ranking_ + 1).astype(float), index=feats).sort_values(ascending=False)
        summary = "RFE 递归特征消除(标签=%s)" % label
    elif method == "L1":
        if not label:
            fail("L1 正则化筛选需要指定标签字段")
        from sklearn.linear_model import LogisticRegression
        m = LogisticRegression(penalty="l1", solver="liblinear", max_iter=1000)
        m.fit(X, sub[label])
        scores = pd.Series(abs(m.coef_).sum(axis=0), index=feats).sort_values(ascending=False)
        summary = "L1 正则化筛选(标签=%s)" % label
    else:
        fail("不支持的筛选方法: %s" % method)

    chosen = list(scores.head(keep).index)
    out_cols = chosen + ([label] if label else [])
    result = df[out_cols]
    p = save(result, params)
    score_df = pd.DataFrame({"字段": scores.index, "得分": scores.values.round(6),
                             "入选": [c in chosen for c in scores.index]})
    save(score_df, params, "scores.csv")
    emit(params, p, len(result), "%s：%d 个特征中保留 %d 个(%s)" % (
        summary, len(feats), len(chosen), ",".join(chosen[:8]) + ("…" if len(chosen) > 8 else "")))


if __name__ == "__main__":
    main()
