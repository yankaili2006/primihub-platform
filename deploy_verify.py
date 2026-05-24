#!/usr/bin/env python3
"""
PrimiHub 一键部署验证
用法:
  python3 deploy_verify.py                          # 快速验证（路由+API）
  python3 deploy_verify.py --full                   # 完整验证（含交互测试）
  python3 deploy_verify.py --base http://<host>:<port>
  python3 deploy_verify.py --fix-db
"""
import subprocess, sys, os, time, json, argparse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_BASE = os.environ.get("TEST_BASE", "http://100.64.0.25:13081")

def log(msg): print(f"\n{'='*60}\n{msg}\n{'='*60}")
def run(cmd, timeout=300):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "TIMEOUT"

def check_deps():
    log("[1/4] 检查依赖")
    deps = [
        ("python3", "python3 --version"),
        ("playwright", "python3 -c 'from playwright.sync_api import sync_playwright; print(\"ok\")'"),
        ("httpx", "python3 -c 'import httpx; print(httpx.__version__)'"),
    ]
    all_ok = True
    for name, cmd in deps:
        code, out, err = run(cmd, 10)
        ok = code == 0
        print(f"  {'✅' if ok else '❌'} {name}: {out.strip()[:50] if ok else '未安装'}")
        if not ok: all_ok = False
    if not all_ok:
        print("  安装: pip install playwright httpx && python3 -m playwright install chromium")
        return False
    return True

def fix_db():
    log("[2/4] 修复数据库")
    sql = os.path.join(BASE_DIR, "fix_missing_auth_entries.sql")
    if not os.path.exists(sql):
        print("  ⚠️ 未找到 fix_missing_auth_entries.sql，跳过")
        return True
    code, out, err = run(f"mysql -uroot privacy < {sql}", 30)
    if code == 0:
        print("  ✅ 数据库修复完成")
    else:
        print(f"  ⚠️ 数据库修复失败，可手动执行: mysql -uroot privacy < {sql}")
    return True

def run_tests(full=False):
    log("[3/4] 执行测试")
    os.environ["TEST_BASE"] = TEST_BASE
    results = {}

    # 路由测试
    print("\n  ── 路由测试 167 页面 ──")
    s = os.path.join(BASE_DIR, "test-tools", "e2e_all_167.py")
    if os.path.exists(s):
        code, out, err = run(f"python3 {s}", 480)
        for l in out.split("\n"):
            if "总页面" in l or "通过率" in l:
                results["路由"] = l.strip(); print(f"  {l.strip()}")
    else:
        results["路由"] = "跳过"

    # API 测试
    print("\n  ── API 测试 223 功能点 ──")
    s = os.path.join(BASE_DIR, "test-tools", "api_test_all.py")
    if os.path.exists(s):
        code, out, err = run(f"python3 {s}", 180)
        for l in out.split("\n"):
            if "总用例" in l or "通过率" in l:
                results["API"] = l.strip(); print(f"  {l.strip()}")
    else:
        results["API"] = "跳过"

    # 交互测试（仅 --full 时运行）
    if full:
        print("\n  ── 交互测试 99 操作（此步骤较慢）──")
        s = os.path.join(BASE_DIR, "test-tools", "e2e_final_v6.py")
        if os.path.exists(s):
            code, out, err = run(f"python3 {s}", 600)
            for l in out.split("\n"):
                if "Total:" in l or "Rate:" in l:
                    results["交互"] = l.strip(); print(f"  {l.strip()}")
        else:
            results["交互"] = "跳过"
    else:
        results["交互"] = "跳过(--full 可启用)"

    return results

def report(results):
    log("[4/4] 验证报告")
    print(f"  目标: {TEST_BASE}")
    print(f"  时间: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
    for name, r in results.items():
        ok = "100%" in r or ("通过" in r and "0" in r.split("|")[-1] if "|" in r else False)
        print(f"  {'✅' if ok else '⚠️'} {name}: {r}")
    print()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PrimiHub 一键验证")
    parser.add_argument("--base", help="目标地址")
    parser.add_argument("--full", action="store_true", help="含交互测试")
    parser.add_argument("--fix-db", action="store_true", help="先修复数据库")
    args = parser.parse_args()

    if args.base: TEST_BASE = args.base
    if not check_deps(): sys.exit(1)
    if args.fix_db: fix_db()
    results = run_tests(full=args.full)
    report(results)
