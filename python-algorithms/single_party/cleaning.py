#!/usr/bin/env python3
"""单方数据清洗。前端字段: cleanMethod[](MISSING/DUPLICATE/OUTLIER/FORMAT),
missingStrategy(DROP_ROW/FILL_MEAN/FILL_MEDIAN/FILL_MODE/FILL_CONST),
dupStrategy(KEEP_FIRST/KEEP_LAST/DROP_ALL), outlierMethod(NONE/SIGMA3/IQR/ZSCORE)."""
from _common import load_params, read_dataset, listy, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    methods = [m.upper() for m in listy(params.get("cleanMethod"))]
    if not methods:
        fail("未选择清洗方法")
    origin_rows = len(df)
    filled_missing = 0

    if "FORMAT" in methods:
        df.columns = [str(c).strip() for c in df.columns]
        for c in df.select_dtypes(include="object").columns:
            df[c] = df[c].str.strip()

    if "MISSING" in methods:
        strategy = (params.get("missingStrategy") or "FILL_MEAN").upper()
        na_before = int(df.isna().sum().sum())
        if strategy == "DROP_ROW":
            df = df.dropna()
        else:
            num_cols = df.select_dtypes(include="number").columns
            if strategy == "FILL_MEAN":
                df[num_cols] = df[num_cols].fillna(df[num_cols].mean())
            elif strategy == "FILL_MEDIAN":
                df[num_cols] = df[num_cols].fillna(df[num_cols].median())
            elif strategy == "FILL_MODE":
                for c in df.columns:
                    mode = df[c].mode(dropna=True)
                    if len(mode):
                        df[c] = df[c].fillna(mode.iloc[0])
            elif strategy == "FILL_CONST":
                const = params.get("fillConst", 0)
                df = df.fillna(const)
            else:
                fail("不支持的缺失值策略: %s" % strategy)
            # 非数值列缺失，均值/中位数策略下退化为众数填充
            if strategy in ("FILL_MEAN", "FILL_MEDIAN"):
                for c in df.select_dtypes(exclude="number").columns:
                    mode = df[c].mode(dropna=True)
                    if len(mode):
                        df[c] = df[c].fillna(mode.iloc[0])
        filled_missing = na_before - int(df.isna().sum().sum())

    if "DUPLICATE" in methods:
        strategy = (params.get("dupStrategy") or "KEEP_FIRST").upper()
        keep = {"KEEP_FIRST": "first", "KEEP_LAST": "last", "DROP_ALL": False}.get(strategy)
        if keep is None:
            fail("不支持的重复值策略: %s" % strategy)
        df = df.drop_duplicates(keep=keep)

    if "OUTLIER" in methods:
        method = (params.get("outlierMethod") or "NONE").upper()
        num_cols = df.select_dtypes(include="number").columns
        if method in ("SIGMA3", "ZSCORE"):
            for c in num_cols:
                mean, std = df[c].mean(), df[c].std()
                if std and std > 0:
                    df = df[(df[c] - mean).abs() <= 3 * std]
        elif method == "IQR":
            for c in num_cols:
                q1, q3 = df[c].quantile(0.25), df[c].quantile(0.75)
                iqr = q3 - q1
                if iqr > 0:
                    df = df[(df[c] >= q1 - 1.5 * iqr) & (df[c] <= q3 + 1.5 * iqr)]
        elif method != "NONE":
            fail("不支持的异常值检测方法: %s" % method)

    cleaned_rows = len(df)
    p = save(df, params)
    emit(params, p, cleaned_rows,
         "原始%d行→清洗后%d行，删除%d行，填充缺失%d处" % (
             origin_rows, cleaned_rows, origin_rows - cleaned_rows, filled_missing))


if __name__ == "__main__":
    main()
