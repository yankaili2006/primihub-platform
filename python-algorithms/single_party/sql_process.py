#!/usr/bin/env python3
"""单方 SQL 处理。前端字段: sqlContent(默认模板用表名 dataset)。
CSV 载入 sqlite 内存库，表名 dataset（并提供别名视图 data / t），执行查询导出 result.csv。"""
import re
import sqlite3

import pandas as pd
from _common import load_params, read_dataset, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    sql = (params.get("sqlContent") or "").strip()
    if not sql:
        fail("SQL 内容为空")
    # 去注释后须是单条查询语句（不放行写库/DDL）
    stripped = re.sub(r"--[^\n]*", "", sql).strip().rstrip(";").strip()
    if ";" in stripped:
        fail("仅支持单条 SQL 查询语句")
    if not re.match(r"(?is)^(select|with)\b", stripped):
        fail("仅支持 SELECT/WITH 查询语句")

    conn = sqlite3.connect(":memory:")
    try:
        df.to_sql("dataset", conn, index=False)
        conn.execute("CREATE VIEW data AS SELECT * FROM dataset")
        conn.execute("CREATE VIEW t AS SELECT * FROM dataset")
        try:
            result = pd.read_sql_query(stripped, conn)
        except Exception as e:
            fail("SQL 执行出错: %s（表名为 dataset，共 %d 行，字段: %s）" % (
                e, len(df), list(df.columns)))
    finally:
        conn.close()

    p = save(result, params)
    emit(params, p, len(result), "SQL 执行成功，返回 %d 行 × %d 列" % (len(result), result.shape[1]))


if __name__ == "__main__":
    main()
