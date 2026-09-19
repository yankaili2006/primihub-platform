#!/usr/bin/env python3
"""联邦学习-特征填充（本地真实计算）。前端字段: fillMethod(MEAN/MEDIAN/MODE/
MODEL_PREDICT), fillFields[](空=全部含缺失列), missingRateThreshold(缺失率超过
该阈值的列不填充、在摘要中标注)。FEDERATED_MEAN 为多方语义，本地显式拒绝。"""
from _common import load_params, read_dataset, listy, pick_fields, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = (params.get("fillMethod") or "MEAN").upper()
    if method == "FEDERATED_MEAN":
        fail("联邦均值填充为多方任务，需经真实联邦引擎执行，本地无法诚实实现")
    threshold = float(params.get("missingRateThreshold") or 0.3)

    cols = pick_fields(df, params.get("fillFields"))
    na_cols = [c for c in cols if df[c].isna().any()]
    skipped = [c for c in na_cols if df[c].isna().mean() > threshold]
    targets = [c for c in na_cols if c not in skipped]
    na_before = int(df[targets].isna().sum().sum()) if targets else 0

    if method in ("MEAN", "MEDIAN"):
        for c in targets:
            s = df[c]
            if s.dtype.kind in "if":
                df[c] = s.fillna(s.mean() if method == "MEAN" else s.median())
            else:
                mode = s.mode(dropna=True)
                if len(mode):
                    df[c] = s.fillna(mode.iloc[0])
    elif method == "MODE":
        for c in targets:
            mode = df[c].mode(dropna=True)
            if len(mode):
                df[c] = df[c].fillna(mode.iloc[0])
    elif method == "MODEL_PREDICT":
        num_targets = [c for c in targets if df[c].dtype.kind in "if"]
        if num_targets:
            from sklearn.experimental import enable_iterative_imputer  # noqa: F401
            from sklearn.impute import IterativeImputer
            num_cols = df.select_dtypes(include="number").columns
            imputed = IterativeImputer(random_state=0).fit_transform(df[num_cols])
            import pandas as pd
            df[num_cols] = pd.DataFrame(imputed, columns=num_cols, index=df.index)
        for c in [c for c in targets if c not in num_targets]:
            mode = df[c].mode(dropna=True)
            if len(mode):
                df[c] = df[c].fillna(mode.iloc[0])
    else:
        fail("不支持的填充方法: %s" % method)

    filled = na_before - int(df[targets].isna().sum().sum()) if targets else 0
    p = save(df, params)
    summary = "%s 填充 %d 个缺失值(%d 列)" % (method, filled, len(targets))
    if skipped:
        summary += "；缺失率超阈值 %.0f%% 未填充: %s" % (threshold * 100, ",".join(skipped))
    emit(params, p, len(df), summary)


if __name__ == "__main__":
    main()
