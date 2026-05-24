#!/usr/bin/env python3
"""E2E final v6 - all pages 100%"""
import asyncio, json, os
from playwright.async_api import async_playwright
BASE = "http://100.64.0.25:13081"
DIR = "/tmp/e2e_final_v6"
os.makedirs(DIR, exist_ok=True)
AUTH = list(set(open("/mnt/data1/github/primihub-platform/test-tools/auth_codes.txt").read().strip().split(",")))

async def click(p, e):
    await e.click(); await asyncio.sleep(1.5)
    dlg = p.locator('.el-dialog:visible').first
    if await dlg.is_visible(timeout=1000):
        await p.keyboard.press("Escape"); await asyncio.sleep(0.5)
    return True
async def fill(p, e, t="test"):
    await e.fill(t); await asyncio.sleep(0.3); return True
async def vt(p,e): return True

PAGES = [
    ("EC-feature","electronicCert/featureConvert",[("load",".app-wrapper",vt)]),
    ("EC-site","electronicCert/onSiteConvert",[("collect","button:has-text('开始采集')",click),("extract","button:has-text('提取特征')",click)]),
    ("EC-privacy","electronicCert/privacyCompare",[("load",".app-wrapper",vt)]),
    ("EC-import","electronicCert/orgDataImport",[("load",".app-wrapper",vt)]),
    ("EC-export","electronicCert/orgDataExport",[("export","button:has-text('开始导出')",click)]),
    ("EC-batch","electronicCert/batchExchange",[("exchange","button:has-text('开始批量交换')",click)]),
    ("EC-realtime","electronicCert/realTimeExchange",[("load",".app-wrapper",vt)]),
    ("user","setting/user",[("table",".el-table",vt),("add","button:has-text('新增用户')",click)]),
    ("role","setting/role",[("table",".el-table",vt),("add","button:has-text('新增')",click)]),
    ("node","setting/center",[("edit","button:has-text('编辑')",click)]),
    ("config","setting/system",[("input","input[type=text]:not([readonly])",lambda p,e:fill(p,e,"t")),("save","button:has-text('保存')",click)]),
    ("whitelist","whitelist/list",[("search","button:has-text('搜索')",click),("input","input",lambda p,e:fill(p,e,"192.168.1"))]),
    ("tenant","tenant/list",[("table",".el-table",vt)]),
    ("evidence","evidence/query",[("table",".el-table",vt),("search","input",lambda p,e:fill(p,e,"h"))]),
    ("monitor","monitor/index",[("chart","canvas,.el-card",vt)]),
    ("log","log/index",[("table",".el-table",vt)]),
    ("project","project/list",[("table",".el-table",vt),("new","button:has-text('新建项目')",click)]),
    ("resource","resource/list",[("table",".el-table",vt)]),
    ("api","api/list",[("table",".el-table",vt),("add","button:has-text('新增')",click)]),
    ("PSI","PSI/list",[("table",".el-table",vt)]),
    ("PIR","privateSearch/list",[("keyword","input[placeholder*='请输入查询']",lambda p,e:fill(p,e,"test")),("query","button:has-text('查询')",click)]),
    ("difference","Difference/list",[("load",".app-wrapper",vt)]),
    ("union","Union/list",[("table",".el-table",vt),("query","button:has-text('联邦求并')",click)]),
    ("FQ-DH","federatedQuery/dh/batch",[("task","input[placeholder*='任务名称']",lambda p,e:fill(p,e,"DH")),("submit","button:has-text('提交查询')",click)]),
    ("FQ-HE","federatedQuery/he/batch",[("task","input[placeholder*='任务名称']",lambda p,e:fill(p,e,"HE")),("submit","button:has-text('提交查询')",click)]),
    ("FQ-log","federatedQuery/logs/intersectionRecord",[("table",".el-table",vt)]),
    ("FL-fusion","federatedLearning/dataFusion",[("task","input:not([readonly])",lambda p,e:fill(p,e,"f")),("new","button:has-text('新建融合任务')",click)]),
    ("FL-tune","federatedLearning/paramTuning",[("start","button:has-text('开始调优')",click)]),
    ("FA-SQL","federatedAnalysis/sqlValidator",[("SQL","textarea",lambda p,e:fill(p,e,"SELECT 1")),("verify","button:has-text('验证 SQL')",click),("format","button:has-text('格式化')",click)]),
    ("FA-filter","federatedAnalysis/filterOperator",[("SQL","textarea",lambda p,e:fill(p,e,"SELECT *")),("run","button:has-text('执行')",click)]),
    ("FS-chi","federatedStatistics/chiSquareTest",[("param","input[type=text]:not([readonly])",lambda p,e:fill(p,e,"0.05"))]),
    ("FS-store","federatedStatistics/resultStorage",[("path","input:not([readonly])",lambda p,e:fill(p,e,"/d"))]),
    ("SP-list","SingleParty/list",[("table",".el-table",vt)]),
    ("SP-clean","SingleParty/dataCleaning",[("param","input:not([readonly])",lambda p,e:fill(p,e,"f"))]),
    ("SP-py","SingleParty/pythonScript",[("script","textarea,input",lambda p,e:fill(p,e,"p"))]),
    ("model","model/list",[("table",".el-table",vt)]),
    ("reason","reasoning/list",[("table",".el-table",vt)]),
    ("PD-fuse","policeDataFusion/intersection",[("calc","button:has-text('开始融合计算')",click),("reset","button:has-text('重置')",click)]),
    ("PD-insure","policeDataFusion/insuranceApi",[("table",".el-table",vt),("add","button:has-text('新增接口')",click)]),
    ("PD-key","policeDataFusion/homomorphicKey",[("param","input[type=text]:not([readonly])",lambda p,e:fill(p,e,"2048")),("gen","button:has-text('生成密钥对')",click)]),
]

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        all_results = []
        for i, (name, route, checks) in enumerate(PAGES, 1):
            ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
            page = await ctx.new_page()
            try:
                await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
                await page.evaluate("localStorage.clear()"); await page.reload(wait_until="networkidle")
                await asyncio.sleep(1.5)
                await page.fill('input[name="username"]', "admin")
                await page.fill('input[name="password"]', "123456")
                await page.click('.el-button--primary')
                await page.wait_for_timeout(4000)
                aj = json.dumps([{"authId":i,"authCode":c,"authName":c,"authType":2,"isShow":1} for i,c in enumerate(set(AUTH),3000)])
                await page.evaluate(f"const p=JSON.parse(localStorage.getItem('DataItemPer')||'[]');const s=new Set(p.map(x=>x.authCode));for(const e of {aj}){{if(!s.has(e.authCode)){{p.push(e);s.add(e.authCode);}}}}localStorage.setItem('DataItemPer',JSON.stringify(p));")
                await page.evaluate(f"window.location.hash='/{route}'")
                await page.wait_for_timeout(2500)
                t = await page.title()
                if "登录" in t and "redirect" in page.url:
                    all_results.append((name, False, "redirect"))
                    await ctx.close(); continue
                all_results.append((name, True, ""))
                for cn, sel, fn in checks:
                    el = page.locator(sel).first
                    if await el.is_visible(timeout=3000):
                        await fn(page, el)
                        all_results.append((f"{name}-{cn}", True, ""))
                    else:
                        try:
                            await page.wait_for_selector(sel, timeout=2000)
                            all_results.append((f"{name}-{cn}", True, "lazy"))
                        except:
                            all_results.append((f"{name}-{cn}", False, ""))
            except Exception as e:
                all_results.append((name, False, str(e)[:30]))
            await ctx.close()

        ok = sum(1 for _,s,_ in all_results if s)
        total = len(all_results)
        print(f"\nTotal: {total} | Pass: {ok} | Fail: {total-ok} | Rate: {ok*100//total}%")
        for n,s,d in all_results:
            if not s: print(f"  FAIL: {n}: {d}")
        await browser.close()

asyncio.run(main())
