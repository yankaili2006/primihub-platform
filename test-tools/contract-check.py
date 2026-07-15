#!/usr/bin/env python3
# contract-check.py — 前端↔后端↔部署 seed 契约检查（防「部署 initsql 落后于后端」类 bug）。
#
# 硬失败(exit 1):
#   A. 前端按钮码(buttonPermissionList.includes) 未在部署 initsql 里 seed 为 authType=3
#   C. 后端 mybatis mapper 用到的表(有 CREATE TABLE 定义) 未在部署 initsql 里建
# 警告(不失败):
#   B. 前端 API url 的末段在后端找不到 @*Mapping
#
# 用法: python3 test-tools/contract-check.py [repo_root]
import re, sys, glob, os
ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
WEB  = os.path.join(ROOT, "primihub-webconsole", "src")
SVC  = os.path.join(ROOT, "primihub-service")
INITSQL = sorted(glob.glob(os.path.join(ROOT, "arm64-deploy", "data", "initsql", "*.sql")))
# Flyway migrations (app-owned schema evolution) are also a deployment seed source.
MIGRATIONS = sorted(glob.glob(os.path.join(ROOT, "primihub-service", "biz", "src", "main", "resources", "db", "migration", "*.sql")))
SEED_FILES = INITSQL + MIGRATIONS

def read(p):
    try: return open(p, encoding="utf-8", errors="ignore").read()
    except Exception: return ""

def read_glob(pat):
    return "".join(read(p) for p in glob.glob(pat, recursive=True))

# ---------- gather frontend ----------
web_txt = read_glob(os.path.join(WEB, "**", "*.vue")) + read_glob(os.path.join(WEB, "**", "*.js"))
fe_btn  = set(re.findall(r"buttonPermissionList\.includes\(\s*['\"]([A-Za-z0-9_]+)['\"]", web_txt))
fe_urls = set(re.findall(r"url:\s*[`'\"](/[A-Za-z0-9/_-]+)", read_glob(os.path.join(WEB, "api", "*.js"))))

# ---------- gather backend ----------
mapper_txt = read_glob(os.path.join(SVC, "**", "mybatis", "**", "*.xml"))
# tables the backend DEFINES (real app tables)
def_sql = read_glob(os.path.join(SVC, "script", "*.sql")) + \
          read_glob(os.path.join(SVC, "**", "resources", "data-mysql.sql"))
defined_tables = set(re.findall(r"CREATE TABLE (?:IF NOT EXISTS )?`?([a-z][a-z0-9_]+)`?", def_sql))
# of those, the ones actually referenced by a mapper
used_tables = {t for t in defined_tables if re.search(r"\b" + re.escape(t) + r"\b", mapper_txt)}
# backend endpoint mapping last-segments
be_segs = set()
for m in re.findall(r'@(?:Request|Post|Get|Put|Delete)Mapping\(\s*(?:value\s*=\s*)?["\']([^"\']+)', read_glob(os.path.join(SVC, "**", "*.java"))):
    be_segs.add(m.strip("/").split("/")[-1])

# ---------- gather deployment seed (initsql dumps + Flyway migrations) ----------
seed_txt = "".join(read(p) for p in SEED_FILES)
# authType=3 codes: privacy dump style  'name','CODE',3,
seed_btn = set(re.findall(r"'[^']*'\s*,\s*'([A-Za-z0-9_]+)'\s*,\s*3\s*,", seed_txt))
# zz-*.sql / Flyway migrations seed buttons via _btn_map / grant IN-lists (not the literal
# ',CODE',3, form): treat any fe code present (non-comment line) as seeded.
for p in SEED_FILES:
    if os.path.basename(p).startswith("zz") or p in MIGRATIONS:
        body = "\n".join(l for l in read(p).splitlines() if not l.strip().startswith("--"))
        for c in fe_btn:
            if re.search(r"'" + re.escape(c) + r"'", body): seed_btn.add(c)
seed_tables = set(re.findall(r"CREATE TABLE (?:IF NOT EXISTS )?`?([a-z][a-z0-9_]+)`?", seed_txt))

# ---------- checks ----------
fails = []
miss_btn = sorted(fe_btn - seed_btn)
miss_tbl = sorted(used_tables - seed_tables)
warn_url = sorted(u for u in fe_urls if u.strip("/").split("/")[-1] not in be_segs)

print("== contract-check ==")
print("frontend button codes: %d | seeded authType=3: %d" % (len(fe_btn), len(seed_btn)))
print("backend mapper-used tables: %d | seeded in initsql: %d" % (len(used_tables), len(seed_tables)))
print("frontend api urls: %d" % len(fe_urls))

if miss_btn:
    fails.append("A"); print("\n[A] ❌ frontend button perms NOT seeded (authType=3) in initsql:")
    for c in miss_btn: print("   -", c)
else: print("\n[A] ✅ all frontend button codes seeded")

if miss_tbl:
    fails.append("C"); print("\n[C] ❌ backend mapper tables NOT created in initsql:")
    for t in miss_tbl: print("   -", t)
else: print("[C] ✅ all backend mapper-used tables present in initsql")

if warn_url:
    print("\n[B] ⚠ frontend api urls with no backend @*Mapping (verify manually — may be dead stubs):")
    for u in warn_url: print("   -", u)
else: print("[B] ✅ all frontend api urls map to a backend endpoint")

print()
if fails:
    print("❌ contract-check FAILED:", ",".join(fails)); sys.exit(1)
print("✅ contract-check PASSED"); sys.exit(0)
