#!/usr/bin/env python3
"""单方 LR 算法。前端字段: labelCol, featureCols(逗号串), penalty(l1/l2/none),
C, maxIter, tol, threshold."""
import pandas as pd
from _common import load_params, read_dataset, listy, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    label = (params.get("labelCol") or "label").strip()
    if label not in df.columns:
        fail("标签列不存在: %s，数据集可用字段: %s" % (label, list(df.columns)))
    feats = listy(params.get("featureCols"))
    if feats:
        missing = [c for c in feats if c not in df.columns]
        if missing:
            fail("特征列不存在: %s" % missing)
    else:
        feats = [c for c in df.select_dtypes(include="number").columns if c != label]
    if not feats:
        fail("没有可用的数值特征列")

    sub = df[feats + [label]].dropna()
    if len(sub) < 10:
        fail("有效样本不足(去缺失后 %d 行)" % len(sub))
    X, y = sub[feats], sub[label]
    if y.nunique() < 2:
        fail("标签列只有一个取值，无法训练分类模型")

    from sklearn.linear_model import LogisticRegression
    from sklearn.model_selection import train_test_split
    from sklearn import metrics as M

    penalty = (params.get("penalty") or "l2").lower()
    C = float(params.get("C") or 1.0)
    max_iter = int(params.get("maxIter") or 100)
    tol = float(params.get("tol") or 1e-4)
    threshold = float(params.get("threshold") or 0.5)

    kw = {"C": C, "max_iter": max_iter, "tol": tol}
    if penalty == "l1":
        kw.update(penalty="l1", solver="liblinear")
    elif penalty == "none":
        kw.update(penalty=None, solver="lbfgs")
    else:
        kw.update(penalty="l2", solver="lbfgs")

    stratify = y if y.value_counts().min() >= 2 else None
    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=42, stratify=stratify)
    model = LogisticRegression(**kw)
    model.fit(Xtr, ytr)

    binary = y.nunique() == 2
    if binary:
        proba = model.predict_proba(Xte)[:, 1]
        pred = (proba >= threshold).astype(int) if set(y.unique()) <= {0, 1} else model.predict(Xte)
    else:
        pred = model.predict(Xte)

    rows = [("样本数(训练/测试)", "%d/%d" % (len(Xtr), len(Xte))),
            ("特征数", len(feats)),
            ("准确率", round(M.accuracy_score(yte, pred), 6)),
            ("精确率", round(M.precision_score(yte, pred, average="binary" if binary else "macro", zero_division=0), 6)),
            ("召回率", round(M.recall_score(yte, pred, average="binary" if binary else "macro", zero_division=0), 6)),
            ("F1", round(M.f1_score(yte, pred, average="binary" if binary else "macro", zero_division=0), 6))]
    if binary:
        try:
            rows.append(("AUC", round(M.roc_auc_score(yte, proba), 6)))
        except Exception:
            pass
    rows.append(("截距", round(float(model.intercept_[0]), 6)))
    for c, w in zip(feats, model.coef_[0]):
        rows.append(("系数_" + c, round(float(w), 6)))

    out = pd.DataFrame(rows, columns=["指标", "值"])
    p = save(out, params)
    acc = dict(rows)["准确率"]
    emit(params, p, len(out), "LR 训练完成：accuracy=%s，%d 特征，标签=%s" % (acc, len(feats), label))


if __name__ == "__main__":
    main()
