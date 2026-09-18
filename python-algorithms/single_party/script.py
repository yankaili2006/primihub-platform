#!/usr/bin/env python3
"""单方 Python 脚本。前端字段: scriptContent(用户脚本，约定读 df 写 result_df), outputVar.
用户脚本在受限全局环境执行：输入 df=数据集 DataFrame，产出写入 outputVar(默认 result_df)。"""
import numpy as np
import pandas as pd
from _common import load_params, read_dataset, save, emit, fail


def main():
    params = load_params()
    df = read_dataset(params)
    code = params.get("scriptContent") or ""
    if not code.strip():
        fail("脚本内容为空")
    output_var = (params.get("outputVar") or "result_df").strip() or "result_df"

    env = {"df": df.copy(), "pd": pd, "np": np, "__name__": "__sp_script__"}
    try:
        exec(compile(code, "<用户脚本>", "exec"), env)
    except Exception as e:
        fail("用户脚本执行出错: %s: %s" % (type(e).__name__, e))

    result = env.get(output_var)
    if result is None:
        fail("脚本未产出输出变量 %s（请在脚本中给它赋值）" % output_var)
    if not isinstance(result, pd.DataFrame):
        try:
            result = pd.DataFrame(result)
        except Exception:
            fail("输出变量 %s 无法转换为表格(DataFrame)" % output_var)

    p = save(result, params)
    emit(params, p, len(result), "脚本执行成功，输出 %d 行 × %d 列" % (len(result), result.shape[1]))


if __name__ == "__main__":
    main()
