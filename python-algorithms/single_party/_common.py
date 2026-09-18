#!/usr/bin/env python3
"""单方算法脚本公共工具。

契约（与 SinglePartyExtService.runReal 对齐）：
- argv[1] = params.json 路径（或内联 JSON 串），含前端原始表单字段 +
  dataset_path / task_id / result_dir / sub_type。
- 结果写 result_dir/result.csv（utf-8-sig，Excel 可直接打开）。
- 成功：stdout 末行打印 JSON {task_id, result_path, result_rows, summary}，exit 0。
- 失败：stderr 打印原因，exit 1。
"""
import json
import os
import sys


def fail(msg, code=1):
    sys.stderr.write(str(msg) + "\n")
    sys.exit(code)


def load_params():
    if len(sys.argv) < 2:
        fail("缺少参数: params.json 路径")
    a = sys.argv[1]
    if a.strip().startswith("{"):
        return json.loads(a)
    with open(a, "r", encoding="utf-8") as f:
        return json.load(f)


def read_dataset(params):
    import pandas as pd
    path = params.get("dataset_path")
    if not path or not os.path.exists(path):
        fail("数据集文件不存在: %s" % path)
    for enc in ("utf-8", "utf-8-sig", "gbk", "gb18030"):
        try:
            df = pd.read_csv(path, encoding=enc)
            if df.shape[0] == 0:
                fail("数据集为空: %s" % path)
            return df
        except UnicodeDecodeError:
            continue
    fail("无法解码数据集(已尝试 utf-8/gbk/gb18030): %s" % path)


def result_dir(params):
    d = params.get("result_dir") or os.path.join(
        "/data/singleParty", str(params.get("task_id", "unknown")))
    os.makedirs(d, exist_ok=True)
    return d


def listy(v):
    """逗号分隔串或 list → 去空白 list。"""
    if v is None:
        return []
    if isinstance(v, list):
        return [str(x).strip() for x in v if str(x).strip()]
    return [s.strip() for s in str(v).split(",") if s.strip()]


def pick_fields(df, fields, numeric=False):
    """校验并返回字段列表；fields 为空 → 全列（numeric=True 时全数值列）。"""
    cols = listy(fields)
    if cols:
        missing = [c for c in cols if c not in df.columns]
        if missing:
            fail("字段不存在: %s，数据集可用字段: %s" % (missing, list(df.columns)))
        sub = df[cols]
    else:
        sub = df
    if numeric:
        sub = sub.select_dtypes(include="number")
        if sub.shape[1] == 0:
            fail("没有可用的数值字段（所选字段均非数值型）")
    return list(sub.columns)


def save(df, params, name="result.csv"):
    p = os.path.join(result_dir(params), name)
    df.to_csv(p, index=False, encoding="utf-8-sig")
    return p


def emit(params, result_path, rows, summary):
    print(json.dumps({
        "task_id": params.get("task_id"),
        "result_path": result_path,
        "result_rows": int(rows),
        "summary": summary,
    }, ensure_ascii=False))
