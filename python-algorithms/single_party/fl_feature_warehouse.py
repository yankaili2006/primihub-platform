#!/usr/bin/env python3
"""联邦学习-特征入仓（本地真实计算）。前端字段: warehouseName, featureVersion,
featureFields[](空=全列), storageFormat(PARQUET/CSV/ORC)。
result.csv 恒为所选特征子集；PARQUET/ORC 另写仓储文件（缺引擎则任务失败，不静默降级）。"""
import json
import os

from _common import load_params, read_dataset, pick_fields, save, emit, fail, result_dir


def main():
    params = load_params()
    df = read_dataset(params)
    name = (params.get("warehouseName") or "").strip()
    if not name:
        fail("仓库名称不能为空")
    version = (params.get("featureVersion") or "v1.0.0").strip()
    fmt = (params.get("storageFormat") or "PARQUET").upper()

    cols = pick_fields(df, params.get("featureFields"))
    sub = df[cols]
    d = result_dir(params)
    base = "%s_%s" % (name, version)

    if fmt == "PARQUET":
        try:
            store = os.path.join(d, base + ".parquet")
            sub.to_parquet(store, index=False)
        except ImportError:
            fail("运行时缺少 parquet 引擎(pyarrow/fastparquet)，无法按 PARQUET 入仓；可改选 CSV 格式")
    elif fmt == "ORC":
        try:
            store = os.path.join(d, base + ".orc")
            sub.to_orc(store, index=False)
        except (ImportError, AttributeError, NotImplementedError):
            fail("运行时不支持 ORC 写出(需 pyarrow)，无法按 ORC 入仓；可改选 CSV 格式")
    elif fmt == "CSV":
        store = os.path.join(d, base + ".csv")
        sub.to_csv(store, index=False, encoding="utf-8-sig")
    else:
        fail("不支持的存储格式: %s" % fmt)

    meta = {"warehouseName": name, "featureVersion": version, "storageFormat": fmt,
            "features": cols, "rows": len(sub), "storePath": store}
    with open(os.path.join(d, "warehouse_meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    p = save(sub, params)
    emit(params, p, len(sub),
         "入仓 %s@%s: %d 特征 × %d 行, 格式 %s" % (name, version, len(cols), len(sub), fmt))


if __name__ == "__main__":
    main()
