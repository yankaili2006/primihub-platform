#!/usr/bin/env python3
"""Optimized E2E test - 37 pages, 3-4 operations each"""
import asyncio, json, os
from playwright.async_api import async_playwright

BASE = "http://100.64.0.25:13081"
DIR = "/tmp/e2e_opt"
os.makedirs(DIR, exist_ok=True)
async def ss(p, n): await p.screenshot(path=f"{DIR}/{n}.png")
AUTH = list(set(open("/mnt/data1/github/primihub-platform/test-tools/auth_codes.txt").read().strip().split(",")))

async def click(p, e):
    await e.click(); await asyncio.sleep(1.5)
    dlg = p.locator('.el-dialog:visible').first
    if await dlg.is_visible(timeout=1000):
        await p.keyboard.press("Escape"); await asyncio.sleep(0.5)
        return (True, "弹窗")
    return (True, "点击")
async def fill(p, e, t="test"):
    await e.fill(t); await asyncio.sleep(0.3)
    return (True, f"输入:{t[:10]}")
async def visible(p, e): return (True, "可见")
async def table(p, e): return (True, "表格")
async def tab(p, e): await e.click(); await asyncio.sleep(1); return (True, "Tab")
async def check(p, e):
    if not await e.is_checked(): await e.check()
    return (True, "勾选")

PAGES = [
    ("EC-现场","electronicCert/onSiteConvert",[("采集","button:has-text('开始采集')",click),("提取","button:has-text('提取特征')",click)]),
    ("EC-导出","electronicCert/orgDataExport",[("导出","button:has-text('开始导出')",click),("时间","input[placeholder*='开始时间']",lambda p,e:fill(p,e,"2026-01"))]),
    ("EC-交换","electronicCert/batchExchange",[("交换","button:has-text('开始批量交换')",click)]),
    ("用户管理","setting/user",[("表格",".el-table",table),("新增","button:has-text('新增用户')",click)]),
    ("角色管理","setting/role",[("表格",".el-table",table),("新增","button:has-text('新增')",click)]),
    ("节点管理","setting/center",[("编辑","button:has-text('编辑')",click),("表单",".el-form",visible)]),
    ("系统配置","setting/system",[("输入","input:not([readonly])[type=text]",lambda p,e:fill(p,e,"test")),("保存","button:has-text('保存')",click),("Tab","[role='tab']",tab)]),
    ("白名单","whitelist/list",[("搜索","button:has-text('搜索')",click),("输入","input:not([readonly])",lambda p,e:fill(p,e,"192.168.1"))]),
    ("租户管理","tenant/list",[("表格",".el-table",table),("新增","button:has-text('添加租户')",click)]),
    ("存证管理","evidence/query",[("表格",".el-table",table),("搜索","input",lambda p,e:fill(p,e,"hash"))]),
    ("监控管理","monitor/index",[("图表","canvas,.el-card",visible),("Tab","[role='tab']",tab)]),
    ("日志管理","log/index",[("表格",".el-table",table),("Tab","[role='tab']",tab)]),
    ("项目管理","project/list",[("表格",".el-table",table),("新建","button:has-text('新建项目')",click)]),
    ("资源管理","resource/list",[("表格",".el-table",table),("Tab","[role='tab']",tab)]),
    ("接口管理","api/list",[("表格",".el-table",table),("新增","button:has-text('新增')",click),("Tab","[role='tab']",tab)]),
    ("PSI","PSI/list",[("表格",".el-table",table)]),
    ("隐匿查询","privateSearch/list",[("输入","input:not([readonly])[type=text]",lambda p,e:fill(p,e,"张三")),("查询","button:has-text('查询')",click)]),
    ("联邦求差","Difference/list",[("表格",".el-table",table),("新增","button:has-text('新增')",click)]),
    ("联邦求并","Union/list",[("表格",".el-table",table),("新增","button:has-text('新增')",click)]),
    ("FQ-DH","federatedQuery/dh/batch",[("任务名","input[placeholder*='任务名称']",lambda p,e:fill(p,e,"DH")),("提交","button:has-text('提交查询')",click)]),
    ("FQ-HE","federatedQuery/he/batch",[("任务名","input[placeholder*='任务名称']",lambda p,e:fill(p,e,"HE")),("提交","button:has-text('提交查询')",click)]),
    ("FQ-日志","federatedQuery/logs/intersectionRecord",[("表格",".el-table",table)]),
    ("FL-融合","federatedLearning/dataFusion",[("任务名","input:not([readonly])",lambda p,e:fill(p,e,"融合")),("新建","button:has-text('新建融合任务')",click)]),
    ("FL-调优","federatedLearning/paramTuning",[("勾选","input[type=checkbox]",check),("开始","button:has-text('开始调优')",click)]),
    ("FA-SQL","federatedAnalysis/sqlValidator",[("SQL","textarea",lambda p,e:fill(p,e,"SELECT 1")),("验证","button:has-text('验证 SQL')",click),("格式化","button:has-text('格式化')",click)]),
    ("FA-筛选","federatedAnalysis/filterOperator",[("输入","input:not([readonly])[type=text]",lambda p,e:fill(p,e,"age>18")),("查询","button",click)]),
    ("FS-卡方","federatedStatistics/chiSquareTest",[("参数","input:not([readonly])[type=text]",lambda p,e:fill(p,e,"0.05")),("计算","button",click)]),
    ("FS-存储","federatedStatistics/resultStorage",[("路径","input:not([readonly])",lambda p,e:fill(p,e,"/data")),("保存","button",click)]),
    ("SP-列表","SingleParty/list",[("表格",".el-table",table),("新增","button:has-text('新增')",click)]),
    ("SP-清洗","SingleParty/dataCleaning",[("参数","input:not([readonly])",lambda p,e:fill(p,e,"填充")),("执行","button",click)]),
    ("SP-Python","SingleParty/pythonScript",[("脚本","textarea,input",lambda p,e:fill(p,e,"print(1)")),("运行","button",click)]),
    ("模型管理","model/list",[("表格",".el-table",table),("添加","button",click)]),
    ("推理服务","reasoning/list",[("表格",".el-table",table),("新增","button",click)]),
    ("PD-融合","policeDataFusion/intersection",[("计算","button:has-text('开始融合计算')",click),("重置","button:has-text('重置')",click)]),
    ("PD-保险","policeDataFusion/insuranceApi",[("输入","input:not([readonly])",lambda p,e:fill(p,e,"http://api")),("保存","button",click)]),
    ("PD-密钥","policeDataFusion/homomorphicKey",[("参数","input:not([readonly])[type=text]",lambda p,e:fill(p,e,"2048")),("生成","button:has-text('生成密钥对')",click)]),
]

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        all_results = []
        for i, (name, route, checks) in enumerate(PAGES, 1):
            ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
            page = await ctx.new_page()
            print(f"\n[{i:2d}/{len(PAGES)}] {name}...", end=" ", flush=True)
            try:
                await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
                await page.evaluate("localStorage.clear()")
                await page.reload(wait_until="networkidle")
                await asyncio.sleep(1.5)
                await page.fill('input[name="username"]', "admin")
                await page.fill('input[name="password"]', "123456")
                await page.click('.el-button--primary')
                await page.wait_for_timeout(4000)
                aj = json.dumps([{"authId": i, "authCode": c, "authName": c, "authType": 2, "isShow": 1}
                                 for i, c in enumerate(set(AUTH), 3000)])
                await page.evaluate(f"const p=JSON.parse(localStorage.getItem('PrimiHubPer')||'[]');const s=new Set(p.map(x=>x.authCode));for(const e of {aj}){{if(!s.has(e.authCode)){{p.push(e);s.add(e.authCode);}}}}localStorage.setItem('PrimiHubPer',JSON.stringify(p));")
                await page.evaluate(f"window.location.hash='/{route}'")
                await page.wait_for_timeout(2500)
                t = await page.title()
                if "登录" in t and "redirect" in page.url:
                    print("❌ redirect", end="")
                    all_results.append((name, False, "redirect"))
                    await ctx.close(); continue
                print("✅", end=" ")
                await ss(page, name[:12])
                all_results.append((name, True, f"✅"))
                for cn, sel, fn in checks:
                    el = page.locator(sel).first
                    if await el.is_visible(timeout=3000):
                        ok, msg = await fn(page, el)
                        all_results.append((f"{name}-{cn}", ok, f"{'✅' if ok else '⚠️'}"))
                        print(f"✅", end=" ")
                    else:
                        all_results.append((f"{name}-{cn}", False, "❌"))
                        print(f"❌", end=" ")
            except Exception as e:
                print(f"❌ {str(e)[:30]}", end=" ")
                all_results.append((name, False, str(e)[:40]))
            await ctx.close()
            print()

        print(f"\n\n{'='*50}")
        ok = sum(1 for _, s, _ in all_results if s)
        total = len(all_results)
        print(f"总: {total} | 通过: {ok} | 失败: {total-ok} | 通过率: {ok*100//total}%")
        for n, s, d in all_results:
            if not s: print(f"  ❌ {n}: {d}")
        print(f"\n截图: {DIR}/")
        await browser.close()

asyncio.run(main())
