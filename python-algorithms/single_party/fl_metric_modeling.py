#!/usr/bin/env python3
"""联邦学习-指标建模（本地真实计算）。前端字段: analysisMetrics[](KS/AUC/PSI/
GINI/IV), targetVariable(二分类标签), featureVariables[](空=全部数值列)。
真实流程: 7:3 切分 → LogisticRegression → 在测试集上计算所选指标。"""
import numpy as np
import pandas as pd

from _common import load_params, read_dataset, listy, pick_fields, save, emit, fail


def psi(expected, actual, bins=10):
    qs = np.unique(np.quantile(expected, np.linspace(0, 1, bins + 1)))
    if len(qs) < 3:
        return 0.0
    e_pct = np.histogram(expected, qs)[0] / max(len(expected), 1)
    a_pct = np.histogram(actual, qs)[0] / max(len(actual), 1)
    e_pct, a_pct = np.clip(e_pct, 1e-6, None), np.clip(a_pct, 1e-6, None)
    return float(np.sum((e_pct - a_pct) * np.log(e_pct / a_pct)))


def iv_of(feature, y, bins=10):
    d = pd.DataFrame({"x": feature, "y": y}).dropna()
    if d["x"].dtype.kind in "if" and d["x"].nunique() > bins:
        d["bin"] = pd.qcut(d["x"], bins, duplicates="drop")
    else:
        d["bin"] = d["x"]
    g = d.groupby("bin", observed=True)["y"].agg(["sum", "count"])
    good = (g["count"] - g["sum"]).clip(lower=0.5)
    bad = g["sum"].clip(lower=0.5)
    dist_g, dist_b = good / good.sum(), bad / bad.sum()
    return float(((dist_g - dist_b) * np.log(dist_g / dist_b)).sum())


def main():
    params = load_params()
    df = read_dataset(params)
    metrics = [m.upper() for m in listy(params.get("analysisMetrics"))]
    if not metrics:
        fail("未选择分析指标")
    target = (params.get("targetVariable") or "").strip()
    if not target:
        fail("请指定目标变量(targetVariable)")
    if target not in df.columns:
        fail("目标变量不存在: %s，数据集可用字段: %s" % (target, list(df.columns)))
    y_raw = df[target]
    if y_raw.nunique() != 2:
        fail("指标建模要求二分类目标变量，%s 有 %d 个取值" % (target, y_raw.nunique()))
    y = (y_raw == y_raw.value_counts().index[0]).astype(int) if y_raw.dtype.kind not in "if" \
        else (y_raw > y_raw.min()).astype(int)

    feats = pick_fields(df.drop(columns=[target]), params.get("featureVariables"), numeric=True)
    if not feats:
        fail("没有可用的数值特征变量")
    X = df[feats].fillna(df[feats].mean())

    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import roc_auc_score, roc_curve
    from sklearn.model_selection import train_test_split
    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)
    model = LogisticRegression(max_iter=1000).fit(Xtr, ytr)
    score_tr, score_te = model.predict_proba(Xtr)[:, 1], model.predict_proba(Xte)[:, 1]

    rows, summary_parts = [], []
    auc = roc_auc_score(yte, score_te)
    if "AUC" in metrics:
        rows.append(("AUC", round(auc, 4), "测试集 ROC 曲线下面积"))
        summary_parts.append("AUC=%.4f" % auc)
    if "KS" in metrics:
        fpr, tpr, _ = roc_curve(yte, score_te)
        ks = float(np.max(tpr - fpr))
        rows.append(("KS", round(ks, 4), "测试集 max(TPR-FPR)"))
        summary_parts.append("KS=%.4f" % ks)
    if "GINI" in metrics:
        rows.append(("GINI", round(2 * auc - 1, 4), "2*AUC-1"))
    if "PSI" in metrics:
        v = psi(score_tr, score_te)
        rows.append(("PSI", round(v, 4), "训练/测试模型分稳定性"))
    if "IV" in metrics:
        for f in feats:
            rows.append(("IV_%s" % f, round(iv_of(df[f], y), 4), "特征信息值"))

    out = pd.DataFrame(rows, columns=["metric", "value", "description"])
    p = save(out, params)
    emit(params, p, len(out),
         "指标建模(%d 特征, 测试集 %d 行): %s" % (len(feats), len(yte), ", ".join(summary_parts) or "完成"))


if __name__ == "__main__":
    main()
