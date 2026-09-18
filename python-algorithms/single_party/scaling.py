#!/usr/bin/env python3
"""单方数据缩放。前端字段: scaleMethod(StandardScaler/MinMaxScaler/RobustScaler/MaxAbsScaler), scaleFields[]."""
from _common import load_params, read_dataset, pick_fields, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    method = params.get("scaleMethod") or "StandardScaler"
    cols = pick_fields(df, params.get("scaleFields"), numeric=True)

    from sklearn import preprocessing
    scalers = {
        "StandardScaler": preprocessing.StandardScaler,
        "MinMaxScaler": preprocessing.MinMaxScaler,
        "RobustScaler": preprocessing.RobustScaler,
        "MaxAbsScaler": preprocessing.MaxAbsScaler,
    }
    if method not in scalers:
        fail("不支持的缩放方法: %s" % method)
    sub = df[cols].dropna()
    if len(sub) < len(df):
        fail("所选字段含缺失值，请先做数据清洗（缺失 %d 行）" % (len(df) - len(sub)))
    df[cols] = scalers[method]().fit_transform(df[cols])

    p = save(df, params)
    emit(params, p, len(df), "%s 缩放 %d 个字段" % (method, len(cols)))


if __name__ == "__main__":
    main()
