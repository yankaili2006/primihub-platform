#!/usr/bin/env python3
"""联邦学习-样本扩充（本地真实计算）。前端字段: expandDirection(VERTICAL=按关联
字段扩展列 / HORIZONTAL=追加行), linkFields[](VERTICAL 必填), expandSource(资源ID,
后端已解析为 expand_source_path)。"""
import os

import pandas as pd

from _common import load_params, read_dataset, listy, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    direction = (params.get("expandDirection") or "VERTICAL").upper()
    src_path = params.get("expand_source_path")
    if not src_path or not os.path.exists(src_path):
        fail("请选择扩充数据来源资源（expandSource），且该资源需有本地数据文件")
    src = pd.read_csv(src_path)
    if src.shape[0] == 0:
        fail("扩充数据来源为空: %s" % src_path)

    if direction == "VERTICAL":
        links = listy(params.get("linkFields"))
        if not links:
            fail("纵向扩展列需要指定关联字段(linkFields)")
        for c in links:
            if c not in df.columns:
                fail("关联字段不存在于本数据集: %s，可用字段: %s" % (c, list(df.columns)))
            if c not in src.columns:
                fail("关联字段不存在于扩充来源: %s，来源字段: %s" % (c, list(src.columns)))
        out = df.merge(src, on=links, how="left", suffixes=("", "_ext"))
        new_cols = [c for c in out.columns if c not in df.columns]
        hit = 100.0 * out[new_cols].notna().any(axis=1).mean() if new_cols else 0.0
        summary = "纵向扩展: 关联字段 %s, 新增 %d 列, 命中率 %.1f%%" % (
            ",".join(links), len(new_cols), hit)
    elif direction == "HORIZONTAL":
        common = [c for c in df.columns if c in src.columns]
        if not common:
            fail("两数据集无同名字段，无法追加行；本集: %s，来源: %s" % (list(df.columns), list(src.columns)))
        out = pd.concat([df, src[common]], ignore_index=True, sort=False)
        summary = "横向扩展: 追加 %d 行(对齐 %d 个同名字段), 共 %d 行" % (len(src), len(common), len(out))
    else:
        fail("不支持的扩展方向: %s" % direction)

    p = save(out, params)
    emit(params, p, len(out), summary)


if __name__ == "__main__":
    main()
