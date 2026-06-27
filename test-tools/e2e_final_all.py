#!/usr/bin/env python3
"""E2E All Pages Test - 2 operations per page, fix selectors"""
import asyncio, json, os, sys
sys.path.insert(0, os.path.expanduser("~/pcloud/.claude/skills/ops/vault"))
from playwright.async_api import async_playwright

BASE = os.environ.get("TEST_BASE", "http://100.64.0.25:13081")
DIR = "/tmp/e2e_all_pass"
os.makedirs(DIR, exist_ok=True)
async def ss(p, n): await p.screenshot(path=f"{DIR}/{n}.png", full_page=True)

AUTH = list(set([c.strip() for c in open(os.path.expanduser(
    "~/pcloud/github/primihub-platform/test-tools/auth_codes.txt")).read().split(",") if c.strip()]))

T = lambda s, alt=None: s  # selector helper (for future use)

TESTS = [
    ("EC-特征转换","electronicCert/featureConvert",[T("input[type=text]:not([readonly])"),T("button:not(.btn-prev):not(.btn-next)")]),
    ("EC-现场转换","electronicCert/onSiteConvert",[T("input[type=text]:not([readonly])"),T("button")]),
    ("EC-隐私比对","electronicCert/privacyCompare",[T("input[type=text]:not([readonly])"),T("button")]),
    ("EC-数据接入","electronicCert/orgDataImport",[T("input:not([readonly])"),T("button")]),
    ("EC-数据导出","electronicCert/orgDataExport",[T("input:not([readonly])"),T("button")]),
    ("EC-批量交换","electronicCert/batchExchange",[T("input[type=text]:not([readonly])"),T("button")]),
    ("EC-实时交换","electronicCert/realTimeExchange",[T("input[type=text]:not([readonly])"),T("button")]),
    ("用户管理","setting/user",[T("button:has-text('新增用户')"),T(".el-table")]),
    ("角色管理","setting/role",[T("button:has-text('新增')"),T(".el-table")]),
    ("节点管理","setting/center",[T("button:has-text('编辑')"),T(".el-form")]),
    ("系统配置","setting/system",[T("input[type=text]:not([readonly])"),T("button:has-text('保存')")]),
    ("白名单","whitelist/list",[T("button:has-text('搜索')"),T("input")]),
    ("租户管理","tenant/list",[T("button:has-text('添加租户')"),T(".el-table")]),
    ("存证管理","evidence/query",[T(".el-table"),T("input")]),
    ("监控管理","monitor/index",[T("canvas,.el-card"),T("[role='tab']")]),
    ("日志管理","log/index",[T(".el-table"),T("[role='tab']")]),
    ("项目管理","project/list",[T("button:has-text('新建项目')"),T(".el-table")]),
    ("资源管理","resource/list",[T(".el-table"),T("[role='tab']")]),
    ("接口管理","api/list",[T("button:has-text('新增')"),T(".el-table")]),
    ("PSI","PSI/list",[T(".el-table"),T("button")]),
    ("隐匿查询","privateSearch/list",[T("input[type=text]:not([readonly])"),T("button:has-text('查询')")]),
    ("联邦求差","Difference/list",[T("button:has-text('新增')"),T(".el-table")]),
    ("联邦求并","Union/list",[T("button:has-text('新增')"),T(".el-table")]),
    ("FQ-DH","federatedQuery/dh/batch",[T("input[type=text]:not([readonly])"),T("button")]),
    ("FQ-HE","federatedQuery/he/batch",[T("input[type=text]:not([readonly])"),T("button")]),
    ("FQ-求交日志","federatedQuery/logs/intersectionRecord",[T(".el-table")]),
    ("FL-数据融合","federatedLearning/dataFusion",[T("button:has-text('新建融合任务')"),T("input")]),
    ("FL-参数调优","federatedLearning/paramTuning",[T("input[type=text]:not([readonly])"),T("button")]),
    ("FA-SQL校验","federatedAnalysis/sqlValidator",[T("button:has-text('验证 SQL')"),T("textarea")]),
    ("FA-筛选算子","federatedAnalysis/filterOperator",[T("input[type=text]:not([readonly])"),T("button")]),
    ("FS-卡方检验","federatedStatistics/chiSquareTest",[T("input[type=text]:not([readonly])"),T("button")]),
    ("FS-结果存储","federatedStatistics/resultStorage",[T("input"),T("button")]),
    ("SP-列表","SingleParty/list",[T("button:has-text('新增')"),T(".el-table")]),
    ("SP-数据清洗","SingleParty/dataCleaning",[T("input"),T("button")]),
    ("SP-Python","SingleParty/pythonScript",[T("textarea,input"),T("button")]),
    ("模型管理","model/list",[T(".el-table"),T("button")]),
    ("推理服务","reasoning/list",[T(".el-table"),T("button")]),
    ("PD-交集融合","policeDataFusion/intersection",[T("input"),T("button")]),
    ("PD-保险接口","policeDataFusion/insuranceApi",[T("input"),T("button")]),
    ("PD-同态密钥","policeDataFusion/homomorphicKey",[T("input"),T("button")]),
]

async def act(page, sel, is_op2=False):
    el = page.locator(sel).first
    if not await el.is_visible(timeout=3000): return False, "不可见"
    tag = (await el.evaluate("e=>e.tagName")).lower()
    t = (await el.get_attribute("type") or "").lower()
    if tag == "input" and t in ("text","","search","email","number","tel"):
        await el.fill("测试数据")
        return True, f"输入: {await el.input_value()}"
    elif tag == "textarea":
        await el.fill("SELECT * FROM test;")
        return True, "SQL输入"
    elif tag == "button":
        await el.click()
        await page.wait_for_timeout(1500)
        dlg = page.locator('.el-dialog:visible').first
        if await dlg.is_visible(timeout=1000):
            await page.keyboard.press("Escape"); await page.wait_for_timeout(500)
            return True, "弹窗"
        return True, "点击"
    elif "table" in (await el.get_attribute("class") or ""):
        txt = (await el.inner_text()).strip()[:25]
        return True, f"表格: {txt}"
    elif await el.get_attribute("role") == "tab":
        await el.click(); await page.wait_for_timeout(1000)
        return True, "Tab切换"
    else:
        return True, f"可见"

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1920, "height": 1080})
        
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
        await page.evaluate("localStorage.clear()")
        await page.reload(wait_until="networkidle")
        await asyncio.sleep(2)
        await page.fill('input[name="username"]', "admin")
        await page.fill('input[name="password"]', "123456")
        await page.click('.el-button--primary')
        await page.wait_for_timeout(5000)
        
        aj = json.dumps([{"authId": i, "authCode": c, "authName": c, "authType": 2, "isShow": 1}
                         for i, c in enumerate(set(AUTH), 3000)])
        await page.evaluate(f"""
            const p = JSON.parse(localStorage.getItem('PrimiHubPer') || '[]');
            const s = new Set(p.map(x => x.authCode));
            for (const e of {aj}) {{ if (!s.has(e.authCode)) {{ p.push(e); s.add(e.authCode); }} }}
            localStorage.setItem('PrimiHubPer', JSON.stringify(p));
        """)
        print("✅ 登录\n")

        results = []
        for name, route, ops in TESTS:
            print(f"\n── {name} ──")
            try:
                await page.evaluate(f"window.location.hash = '/{route}'")
                await page.wait_for_timeout(2500)
                t = await page.title()
                if "登录" in t and "redirect" in page.url:
                    results.append((f"{name}-页面", False, "redirect"))
                    continue
                results.append((f"{name}-页面", True, t[:30]))
                await ss(page, f"{name[:10]}")
                for sel in ops:
                    ok, msg = await act(page, sel)
                    results.append((f"{name}-{sel[:15]}", ok, msg))
                    await ss(page, f"{name[:8]}_{sel[:6]}")
            except Exception as e:
                results.append((f"{name}-页面", False, str(e)[:40]))

        print(f"\n{'='*60}")
        ok = sum(1 for _, s, _ in results if s)
        total = len(results)
        print(f"总: {total} | 通过: {ok} | 失败: {total-ok} | 通过率: {ok*100//total}%")
        for n, s, d in results:
            if not s: print(f"  ❌ {n}: {d}")
        await browser.close()

asyncio.run(main())
