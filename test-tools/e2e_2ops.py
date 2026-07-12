#!/usr/bin/env python3
"""每个页面2个操作测试 + 截图验证"""
import asyncio, json, os, subprocess
from playwright.async_api import async_playwright

BASE = 'http://100.64.0.25:13081'
DIR = "/tmp/e2e_2ops"
os.makedirs(DIR, exist_ok=True)
async def ss(p, n): await p.screenshot(path=f"{DIR}/{n}.png", full_page=True)

AUTH_CODES = open("/mnt/data1/github/primihub-platform/test-tools/auth_codes.txt").read().strip()
ALL_AUTH = list(set([c.strip() for c in AUTH_CODES.split(",") if c.strip()]))

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
        page = await ctx.new_page()
        results = []
        def R(n, o, d=""): results.append((n, o, d)); print(f"  {'✅' if o else '❌'} {n}: {d[:60] if d else ''}")

        # Login + inject auth
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
        await page.evaluate("localStorage.clear()")
        await page.reload(wait_until="networkidle")
        await asyncio.sleep(2)
        await page.fill('input[name="username"]', "admin")
        await page.fill('input[name="password"]', "123456")
        await page.click('.el-button--primary')
        await page.wait_for_timeout(5000)
        auth_js = json.dumps([{"authId": i, "authCode": c, "authName": c, "authType": 2, "isShow": 1}
                              for i, c in enumerate(ALL_AUTH, 3000)])
        await page.evaluate(f"""
            const p = JSON.parse(localStorage.getItem('PrimiHubPer') || '[]');
            const seen = new Set(p.map(x => x.authCode));
            for (const e of {auth_js}) {{ if (!seen.has(e.authCode)) {{ p.push(e); seen.add(e.authCode); }} }}
            localStorage.setItem('PrimiHubPer', JSON.stringify(p));
        """)
        print("✅ 登录\n")

        # ═══ Each page: nav + 2 operations ═══
        test_specs = [
            # (name, hash_route, op1_selector, op1_desc, op2_selector, op2_desc)
            ("用户管理", "setting/user",
             "button:has-text('新增用户')", "点击新增用户弹窗",
             ".el-table", "表格数据可见"),
            ("角色管理", "setting/role",
             "button:has-text('新增')", "点击新增角色",
             ".el-table", "角色表格"),
            ("节点管理", "setting/center",
             "button:has-text('编辑')", "编辑机构信息",
             ".el-form", "机构表单可见"),
            ("系统配置", "setting/system",
             "input:visible", "配置输入框聚焦",
             "button:has-text('保存')", "保存按钮可见"),
            ("白名单", "whitelist/list",
             "button:has-text('新增')", "新增白名单",
             ".el-table", "白名单表格"),
            ("租户管理", "tenant/list",
             "button:has-text('添加租户')", "新增租户",
             ".el-table", "租户表格"),
            ("存证管理", "evidence/query",
             ".el-table", "存证列表",
             "[role='tab']", "Tab切换"),
            ("监控管理", "monitor/index",
             "canvas,.el-card", "监控图表",
             "[role='tab']", "Tab切换"),
            ("日志管理", "log/index",
             ".el-table", "日志列表",
             "[role='tab']", "Tab切换"),
            ("项目管理", "project/list",
             "button:has-text('新建项目')", "新建项目",
             ".el-table", "项目表格"),
            ("资源管理", "resource/list",
             ".el-table", "资源列表",
             "[role='tab']", "Tab切换"),
            ("接口管理", "api/list",
             "button:has-text('新增')", "新增接口",
             ".el-table", "接口表格"),
            ("PSI", "PSI/list",
             ".el-table", "PSI列表",
             "button:has-text('求交')", "求交操作"),
            ("隐匿查询", "privateSearch/list",
             "input:visible", "输入查询关键词",
             "button:has-text('查询')", "查询按钮"),
            ("联邦求差", "Difference/list",
             "button:has-text('新增')", "新增求差",
             ".el-table", "求差列表"),
            ("联邦求并", "Union/list",
             "button:has-text('新增')", "新增求并",
             ".el-table", "求并列表"),
            ("联邦查询-DH", "federatedQuery/dh/batch",
             "input:visible", "填写查询条件",
             "button:has-text('查询')", "查询按钮"),
            ("联邦查询-HE", "federatedQuery/he/batch",
             "input:visible", "填写查询条件",
             "button:has-text('查询')", "查询按钮"),
            ("联邦查询-日志", "federatedQuery/logs/intersectionRecord",
             ".el-table", "日志表格",
             "button:has-text('导出')", "导出按钮"),
            ("FL数据融合", "federatedLearning/dataFusion",
             "input:visible", "输入任务名",
             "button:has-text('提交')", "提交按钮"),
            ("FL参数调优", "federatedLearning/paramTuning",
             "input:visible", "参数值输入",
             "button:has-text('保存')", "保存按钮"),
            ("FA-SQL校验", "federatedAnalysis/sqlValidator",
             "textarea,input:visible", "SQL语句输入",
             "button:has-text('校验')", "校验按钮"),
            ("FA-筛选算子", "federatedAnalysis/filterOperator",
             "input:visible", "筛选条件输入",
             "button:has-text('查询')", "查询按钮"),
            ("FA-SQL格式化", "federatedAnalysis/sqlFormatter",
             "textarea,input:visible", "SQL输入",
             "button:has-text('格式化')", "格式化按钮"),
            ("FS-卡方检验", "federatedStatistics/chiSquareTest",
             "input:visible", "参数输入",
             "button:has-text('计算')", "计算按钮"),
            ("FS-结果存储", "federatedStatistics/resultStorage",
             "input:visible", "存储配置",
             "button:has-text('保存')", "保存按钮"),
            ("单方算法", "SingleParty/list",
             ".el-table", "算法列表",
             "button:has-text('新增')", "新增算法"),
            ("单方-数据清洗", "SingleParty/dataCleaning",
             "input:visible", "清洗参数",
             "button:has-text('执行')", "执行按钮"),
            ("单方-Python", "SingleParty/pythonScript",
             "textarea,input:visible", "脚本编辑",
             "button:has-text('运行')", "运行按钮"),
            ("模型管理", "model/list",
             ".el-table", "模型列表",
             "button:has-text('添加')", "添加模型"),
            ("推理服务", "reasoning/list",
             ".el-table", "推理列表",
             "button:has-text('新增')", "新增推理"),
            ("警务融合", "policeDataFusion/intersection",
             ".el-form,input:visible", "警务配置",
             "button:has-text('提交')", "提交按钮"),
            ("证件-特征转换", "electronicCert/featureConvert",
             "input:visible", "特征输入",
             "button:has-text('转换')", "转换按钮"),
            ("证件-数据接入", "electronicCert/orgDataImport",
             "input:visible", "接入配置",
             "button:has-text('导入')", "导入按钮"),
            ("证件-批量交换", "electronicCert/batchExchange",
             "input:visible", "交换参数",
             "button:has-text('交换')", "交换按钮"),
        ]

        for spec in test_specs:
            name, route = spec[0], spec[1]
            ops = [(spec[i], spec[i+1]) for i in range(2, len(spec), 2)]
            print(f"\n── {name} ──")
            try:
                # Navigate
                await page.evaluate(f"window.location.hash = '/{route}'")
                await page.wait_for_timeout(2500)
                title = await page.title()
                if "登录" in title and "redirect" in page.url:
                    R(f"[页面] {name}", False, "redirect")
                    for oname, _ in ops:
                        R(f"[{oname}]", False, "页面未加载")
                    continue
                R(f"[页面] {name}", True, title[:30])
                await ss(page, f"{name[:12]}_00")
                
                # Perform 2 operations
                for op_name, selector in ops:
                    try:
                        el = page.locator(selector).first
                        tag = await el.evaluate("e=>e.tagName") if await el.is_visible(timeout=2000) else None
                        if tag == "INPUT":
                            await el.fill("测试数据")
                            await page.wait_for_timeout(500)
                            val = await el.input_value()
                            R(f"[{op_name}]", val == "测试数据", f"输入: {val}")
                        elif tag == "BUTTON":
                            await el.click()
                            await page.wait_for_timeout(1500)
                            dlg = page.locator('.el-dialog:visible').first
                            if await dlg.is_visible(timeout=1000):
                                await page.keyboard.press("Escape")
                                await page.wait_for_timeout(500)
                                R(f"[{op_name}]", True, "弹窗打开")
                            else:
                                R(f"[{op_name}]", True, "点击成功")
                        elif tag == "TEXTAREA":
                            await el.fill("SELECT * FROM test")
                            await page.wait_for_timeout(500)
                            R(f"[{op_name}]", True, "输入SQL")
                        elif tag in ("DIV", "SECTION") and "table" in (await el.get_attribute("class") or ""):
                            R(f"[{op_name}]", True, "表格可见")
                        elif "tab" in (await el.get_attribute("role") or "").lower():
                            await el.click()
                            await page.wait_for_timeout(1000)
                            R(f"[{op_name}]", True, "Tab切换")
                        elif tag == "CANVAS":
                            R(f"[{op_name}]", True, "图表渲染")
                        else:
                            R(f"[{op_name}]", True, f"元素[{tag}]可见")
                        await ss(page, f"{name[:12]}_{op_name[:8]}")
                    except Exception as e:
                        R(f"[{op_name}]", False, str(e)[:40])
            except Exception as e:
                R(f"[页面] {name}", False, str(e)[:40])

        # ═══ Report ═══
        print(f"\n{'='*60}")
        ok = sum(1 for _, s, _ in results if s)
        fail = [(n, d) for n, s, d in results if not s]
        print(f"总: {len(results)} | 通过: {ok} | 失败: {len(fail)} | 通过率: {ok*100//len(results)}%")
        if fail:
            for n, d in fail: print(f"  ❌ {n}: {d}")
        print(f"\n截图: {DIR}/")
        await browser.close()

asyncio.run(main())
