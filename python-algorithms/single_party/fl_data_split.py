#!/usr/bin/env python3
"""联邦学习-数据切分（本地真实计算）。前端字段: trainRatio(百分比),
splitMethod(RANDOM/TIME_BASED/STRATIFIED), randomSeed,
timeField(TIME_BASED 必填), stratifyField(STRATIFIED 必填)。
输出: result.csv=原数据+data_role 列(train/test)，另写 train.csv/test.csv。"""
import os

from _common import load_params, read_dataset, save, emit, fail, result_dir


def main():
    params = load_params()
    df = read_dataset(params)
    ratio = float(params.get("trainRatio") or 80) / 100.0
    if not 0 < ratio < 1:
        fail("训练集比例必须在 (0,100) 之间: %s" % params.get("trainRatio"))
    method = (params.get("splitMethod") or "RANDOM").upper()
    seed = int(params.get("randomSeed") or 42)

    if method == "RANDOM":
        train = df.sample(frac=ratio, random_state=seed)
    elif method == "TIME_BASED":
        field = (params.get("timeField") or "").strip()
        if not field:
            fail("按时间分割需要指定时间字段(timeField)")
        if field not in df.columns:
            fail("时间字段不存在: %s，数据集可用字段: %s" % (field, list(df.columns)))
        train = df.sort_values(field).head(int(len(df) * ratio))
    elif method == "STRATIFIED":
        field = (params.get("stratifyField") or "").strip()
        if not field:
            fail("分层分割需要指定分层字段(stratifyField)")
        if field not in df.columns:
            fail("分层字段不存在: %s，数据集可用字段: %s" % (field, list(df.columns)))
        train = df.groupby(field, group_keys=False).apply(
            lambda g: g.sample(frac=ratio, random_state=seed))
    else:
        fail("不支持的分割方式: %s" % method)

    out = df.copy()
    out["data_role"] = "test"
    out.loc[train.index, "data_role"] = "train"
    test = df.drop(train.index)

    d = result_dir(params)
    train.to_csv(os.path.join(d, "train.csv"), index=False, encoding="utf-8-sig")
    test.to_csv(os.path.join(d, "test.csv"), index=False, encoding="utf-8-sig")
    p = save(out, params)
    emit(params, p, len(out),
         "%s 分割: 训练集 %d 行 / 测试集 %d 行 (比例 %.0f%%)" % (method, len(train), len(test), ratio * 100))


if __name__ == "__main__":
    main()
