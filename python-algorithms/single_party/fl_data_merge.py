#!/usr/bin/env python3
"""单方数据合并（本地真实计算）。前端字段: dataSources[](资源ID，后端解析为
source_paths[]), mergeType(UNION=按同名字段追加行 / JOIN=按 joinKey 关联),
joinKey(JOIN 必填), deduplication(bool), outputFormat(CSV/PARQUET)。"""
import os

import pandas as pd

from _common import load_params, listy, save, emit, fail, result_dir


def main():
    params = load_params()
    paths = params.get("source_paths") or []
    if len(paths) < 2:
        fail("数据合并至少需要选择 2 个数据源，当前 %d 个" % len(paths))
    frames = []
    for p in paths:
        if not os.path.exists(p):
            fail("数据源文件不存在: %s" % p)
        frames.append(pd.read_csv(p))

    merge_type = (params.get("mergeType") or "UNION").upper()
    if merge_type == "UNION":
        common = set(frames[0].columns)
        for f in frames[1:]:
            common &= set(f.columns)
        if not common:
            fail("各数据源无共同字段，无法纵向合并；字段分别为: %s" %
                 [list(f.columns) for f in frames])
        cols = [c for c in frames[0].columns if c in common]
        out = pd.concat([f[cols] for f in frames], ignore_index=True)
        summary = "纵向合并 %d 个数据源(共同字段 %d 个): %d 行" % (len(frames), len(cols), len(out))
    elif merge_type == "JOIN":
        key = (params.get("joinKey") or "").strip()
        if not key:
            fail("横向合并需要指定关联字段(joinKey)")
        out = frames[0]
        for i, f in enumerate(frames[1:], 2):
            if key not in out.columns or key not in f.columns:
                fail("关联字段 %s 不存在于第 %d 个数据源，可用字段: %s" % (key, i, list(f.columns)))
            out = out.merge(f, on=key, how="inner", suffixes=("", "_%d" % i))
        summary = "横向合并 %d 个数据源(关联字段 %s): %d 行 × %d 列" % (
            len(frames), key, len(out), out.shape[1])
    else:
        fail("不支持的合并方式: %s" % merge_type)

    if params.get("deduplication"):
        before = len(out)
        out = out.drop_duplicates()
        summary += "；去重 %d 行" % (before - len(out))

    fmt = (params.get("outputFormat") or "CSV").upper()
    if fmt == "PARQUET":
        try:
            out.to_parquet(os.path.join(result_dir(params), "merged.parquet"), index=False)
            summary += "；另存 parquet"
        except ImportError:
            fail("运行时缺少 parquet 引擎(pyarrow)，请改选 CSV 输出格式")
    elif fmt not in ("CSV",):
        fail("不支持的输出格式: %s" % fmt)

    p = save(out, params)
    emit(params, p, len(out), summary)


if __name__ == "__main__":
    main()
