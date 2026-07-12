#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
浏览器模拟登录验证 —— 复刻前端登录流程，校验功能菜单是否正常。

等价于浏览器做的事：
  1) GET  /prod-api/sys/common/getValidatePublicKey   取 RSA 公钥
  2) 用 JSEncrypt 同款 RSA(PKCS#1 v1.5) 加密密码 (这里用 openssl 实现, 无需第三方库)
  3) POST /prod-api/sys/user/login (form: userAccount/userPassword/validateKeyName)
  4) 读登录响应 result.grantAuthRootList (= 前端构建侧边栏所用的授权菜单树)
  5) 断言: ① demand 根「基于隐私计算的数据可信共享」存在且 18 个模块
           ② demand 功能点 >= 224
           ③ 前端页面已解锁 (关键路由 code 均在授权树中)

仅依赖 python3 + openssl, 可在离线 CentOS/arm64 上运行。
用法:  python3 verify_menus.py [BASE_URL] [USER] [PASS]
返回:  0=菜单正常, 非0=异常
"""
import sys, json, base64, subprocess, tempfile, os, textwrap, urllib.request, urllib.parse

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:30811").rstrip("/")
USER = sys.argv[2] if len(sys.argv) > 2 else "admin"
PWD  = sys.argv[3] if len(sys.argv) > 3 else "123456"

# 期望值
EXPECT_DEMAND_ROOT = "基于隐私计算的数据可信共享"
EXPECT_MODULES = 18
EXPECT_LEAVES_MIN = 224
# 代表性前端页面路由(解锁后应出现在授权树里), 覆盖各新增模块
KEY_PAGES = ["FederatedLearning", "FederatedAnalysisIndex", "FederatedStatisticsIndex",
             "FederatedQuery", "Whitelist", "Tenant", "Evidence", "Monitor",
             "PoliceDataFusion", "ElectronicCertCompare", "ApiList", "SharedDatasetList"]

def http_get(path):
    return json.load(urllib.request.urlopen(urllib.request.Request(BASE + path), timeout=20))
def http_post_form(path, data):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(BASE + path, data=body,
            headers={"Content-Type": "application/x-www-form-urlencoded"}, method="POST")
    return json.load(urllib.request.urlopen(req, timeout=20))

def rsa_encrypt(pubkey_b64, plain):
    pem = "-----BEGIN PUBLIC KEY-----\n" + "\n".join(textwrap.wrap(pubkey_b64, 64)) + "\n-----END PUBLIC KEY-----\n"
    with tempfile.NamedTemporaryFile("w", suffix=".pem", delete=False) as f:
        f.write(pem); pemf = f.name
    try:
        # Python 3.6 兼容: 不用 capture_output
        p = subprocess.run(["openssl", "pkeyutl", "-encrypt", "-pubin", "-inkey", pemf,
                            "-pkeyopt", "rsa_padding_mode:pkcs1"],
                           input=plain.encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if p.returncode != 0:
            raise RuntimeError("openssl 加密失败: " + p.stderr.decode()[:200])
        return base64.b64encode(p.stdout).decode()
    finally:
        os.unlink(pemf)

def fail(msg): print("  \033[31m✗ %s\033[0m" % msg); return False
def ok(msg):   print("  \033[32m✓ %s\033[0m" % msg); return True

def main():
    print("== 浏览器模拟登录验证 @ %s (user=%s) ==" % (BASE, USER))
    try:
        pk = http_get("/prod-api/sys/common/getValidatePublicKey")["result"]
        enc = rsa_encrypt(pk["publicKey"], PWD)
        r = http_post_form("/prod-api/sys/user/login",
                           {"userAccount": USER, "userPassword": enc, "validateKeyName": pk["publicKeyName"]})
    except Exception as e:
        print(fail("登录请求失败: %s" % (str(e)[:160])) or "", end=""); return 2
    if r.get("code") != 0:
        fail("登录失败 code=%s msg=%s" % (r.get("code"), r.get("msg"))); return 3
    ok("登录成功 (code=0)")

    # 登录返回的授权清单(扁平): 前端据此点亮侧边栏页面
    granted = set()
    def walk(n):
        granted.add(n.get("authCode"))
        for c in (n.get("children") or []): walk(c)
    for n in (r.get("result") or {}).get("grantAuthRootList") or []: walk(n)

    passed = True
    # 取后端权限树(嵌套)做结构校验
    try:
        tree = http_get("/prod-api/sys/auth/getAuthTree")["result"]["sysAuthRootList"]
    except Exception as e:
        fail("拉取 getAuthTree 失败: %s" % (str(e)[:120])); return 4

    # ① demand 功能点根 + 18 模块 + 224 功能点
    droot = [n for n in tree if n.get("authName") == EXPECT_DEMAND_ROOT]
    if not droot:
        fail("未找到功能点根菜单「%s」(initsql 未灌入?)" % EXPECT_DEMAND_ROOT); passed = False
    else:
        mods = droot[0].get("children") or []
        passed = (ok if len(mods) == EXPECT_MODULES else fail)("功能点模块数 = %d (期望 %d)" % (len(mods), EXPECT_MODULES)) and passed
        leaves = 0
        def cnt(n):
            nonlocal leaves
            ch = n.get("children") or []
            if not ch: leaves += 1
            for c in ch: cnt(c)
        for m in mods: cnt(m)
        passed = (ok if leaves >= EXPECT_LEAVES_MIN else fail)("功能点数 = %d (期望 ≥ %d)" % (leaves, EXPECT_LEAVES_MIN)) and passed

    # ② 前端页面已解锁(关键路由 code 出现在登录授权清单 = 侧边栏可见可点)
    missing = [c for c in KEY_PAGES if c not in granted]
    passed = (ok if not missing else fail)("侧边栏关键页面解锁 %d/%d%s"
              % (len(KEY_PAGES) - len(missing), len(KEY_PAGES),
                 "" if not missing else "  缺: " + ",".join(missing))) and passed
    print("  admin 授权页面节点 = %d 个" % len(granted))

    print(("\033[32m✅ 功能菜单正常\033[0m" if passed else "\033[31m❌ 功能菜单异常\033[0m"))
    return 0 if passed else 1

if __name__ == "__main__":
    sys.exit(main())
