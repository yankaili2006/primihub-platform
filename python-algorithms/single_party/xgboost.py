#!/usr/bin/env python3
"""单方 XGB 算法。前端字段: labelCol, featureCols(逗号串), objective(binary:logistic/
multi:softmax/reg:squarederror/rank:pairwise), nEstimators, eta, maxDepth,
subsample, colsampleBytree, minChildWeight."""
import os
import sys

# 本文件名与 xgboost 包同名，须先把脚本目录移出 sys.path 再 import 真包
from _common import load_params, read_dataset, listy, save, emit, fail
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path = [p for p in sys.path if os.path.abspath(p or ".") != _HERE]
sys.modules.pop("xgboost", None)

import pandas as pd


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

    objective = params.get("objective") or "binary:logistic"
    if objective == "rank:pairwise":
        fail("排序目标(rank:pairwise)需要分组信息(group)，当前数据集界面不支持，请改用其他目标")

    sub = df[feats + [label]].dropna()
    if len(sub) < 10:
        fail("有效样本不足(去缺失后 %d 行)" % len(sub))
    X, y = sub[feats], sub[label]

    import xgboost as xgb
    from sklearn.model_selection import train_test_split
    from sklearn import metrics as M

    kw = dict(n_estimators=int(params.get("nEstimators") or 100),
              learning_rate=float(params.get("eta") or 0.1),
              max_depth=int(params.get("maxDepth") or 6),
              subsample=float(params.get("subsample") or 0.8),
              colsample_bytree=float(params.get("colsampleBytree") or 0.8),
              min_child_weight=int(params.get("minChildWeight") or 1))

    regression = objective.startswith("reg:")
    if regression:
        model = xgb.XGBRegressor(objective=objective, **kw)
        stratify = None
    else:
        if y.nunique() < 2:
            fail("标签列只有一个取值，无法训练分类模型")
        y, classes = pd.factorize(y)
        y = pd.Series(y)
        model = xgb.XGBClassifier(objective=objective, **kw)
        stratify = y if y.value_counts().min() >= 2 else None

    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=42, stratify=stratify)
    model.fit(Xtr, ytr)
    pred = model.predict(Xte)

    rows = [("样本数(训练/测试)", "%d/%d" % (len(Xtr), len(Xte))),
            ("特征数", len(feats)), ("目标", objective)]
    if regression:
        rows += [("RMSE", round(float(M.mean_squared_error(yte, pred) ** 0.5), 6)),
                 ("MAE", round(float(M.mean_absolute_error(yte, pred)), 6)),
                 ("R2", round(float(M.r2_score(yte, pred)), 6))]
        headline = "R2=%s" % dict(rows)["R2"]
    else:
        binary = pd.Series(y).nunique() == 2
        avg = "binary" if binary else "macro"
        rows += [("准确率", round(M.accuracy_score(yte, pred), 6)),
                 ("精确率", round(M.precision_score(yte, pred, average=avg, zero_division=0), 6)),
                 ("召回率", round(M.recall_score(yte, pred, average=avg, zero_division=0), 6)),
                 ("F1", round(M.f1_score(yte, pred, average=avg, zero_division=0), 6))]
        if binary:
            try:
                rows.append(("AUC", round(M.roc_auc_score(yte, model.predict_proba(Xte)[:, 1]), 6)))
            except Exception:
                pass
        headline = "accuracy=%s" % dict(rows)["准确率"]
    for c, w in zip(feats, model.feature_importances_):
        rows.append(("特征重要度_" + c, round(float(w), 6)))

    out = pd.DataFrame(rows, columns=["指标", "值"])
    p = save(out, params)
    emit(params, p, len(out), "XGB 训练完成：%s，%d 特征，标签=%s" % (headline, len(feats), label))


if __name__ == "__main__":
    main()
