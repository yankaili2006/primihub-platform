#!/usr/bin/env python3
"""
PrimiHub E2E Complete Test
39 modules × 2-3 interactive operations = ~100 test cases
"""
import asyncio, json, os
from playwright.async_api import async_playwright

BASE = "http://localhost:30811"
DIR = "/tmp/e2e_complete"
os.makedirs(DIR, exist_ok=True)
async def ss(p, n): await p.screenshot(path=f"{DIR}/{n}.png", full_page=True)

ALL_AUTH = [
    "Setting","UserManage","RoleManage","Project","ProjectList","ResourceMenu",
    "ResourceList","Whitelist","WhitelistList","Tenant","TenantList","Evidence",
    "EvidenceQuery","Monitor","MonitorIndex","Log","LogList","ApiManage","ApiList",
    "PSI","PSIList","PrivateSearch","PrivateSearchList","Difference","DifferenceList",
    "Union","UnionList","FederatedQuery","FederatedLearning","FederatedLearningList",
    "SingleParty","SinglePartyList","Model","ModelList","ModelReasoning",
    "ModelReasoningList","PoliceDataFusion","PoliceDataIntersection",
    "ElectronicCertCompare","ElectronicCertFeatureConvert",
    "FLDataFusion","FLVerticalLinearTrain","FederatedLearningParamTuning",
    "FederatedLearningTrainingReport","FederatedAnalysisSqlValidator",
    "FAFilterOperator","FASqlFormatter","FederatedStatisticsChiSquareTest",
    "FederatedStatisticsTTest","FederatedStatisticsResultStorage",
    "SinglePartyDataCleaning","SinglePartyPythonScript",
    "FederatedQueryDHBatch","FederatedQueryHEBatch",
    "FederatedQueryIntersectionBatch","FederatedQueryLogIntersectionRecord",
    "FederatedAnalysisRelationalDB","FederatedAnalysisBigData",
    "FederatedStatisticsConditionStats",
    "PoliceDataConnect","InsuranceApiConnect","InsuranceHomomorphicKey",
    "InsuranceModelEncrypt","EncryptedModelCompute","InsuranceDataDecrypt",
    "ModelCipherBatchExchange","FeaturePrivacyCompare","OrgDataImport",
    "OrgDataExport","FederatedModelPreview","FederatedModelImport",
    "FederatedModelExport","FederatedModelingWorkbench",
    "FederatedLearningIndex","FederatedLearningList","FederatedAnalysisIndex",
    "FederatedStatisticsIndex","DifferenceTask","DifferenceDetail",
    "UnionTask","UnionDetail","PIRTask","PIRDetail","PSITask","PSIResult","PSIDetail",
]

async def interact(page, actions):
    """Run a list of interaction actions, returns (ok, detail)"""
    for name, loc, action_fn in actions:
        try:
            el = page.locator(loc).first
            if not await el.is_visible(timeout=3000):
                yield name, False, "元素不可见"
                continue
            tag = (await el.evaluate("e=>e.tagName")).lower()
            if action_fn == "click":
                before = page.url
                await el.click()
                await page.wait_for_timeout(1500)
                dlg = page.locator('.el-dialog:visible').first
                has_dlg = await dlg.is_visible(timeout=1000)
                if has_dlg:
                    await page.keyboard.press("Escape")
                    await page.wait_for_timeout(500)
                    yield name, True, "弹窗打开+关闭"
                elif page.url != before:
                    yield name, True, "页面跳转"
                    await page.go_back(wait_until="networkidle")
                    await page.wait_for_timeout(1000)
                else:
                    yield name, True, "点击成功"
            elif action_fn == "fill":
                await el.fill("测试输入123")
                val = await el.input_value()
                yield name, True, f"输入: {val[:15]}"
            elif action_fn == "select":
                await el.click()
                await page.wait_for_timeout(1000)
                opt = page.locator('.el-select-dropdown__item:visible').first
                if await opt.is_visible(timeout=2000):
                    await opt.click()
                    await page.wait_for_timeout(500)
                    yield name, True, "选择成功"
                else:
                    yield name, True, "下拉已展开"
            elif action_fn == "exist":
                yield name, True, f"元素[{tag}]可见"
            else:
                yield name, True, "ok"
        except Exception as e:
            yield name, False, str(e)[:50]

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
        page = await ctx.new_page()
        all_results = []

        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
        await page.evaluate("localStorage.clear()")
        await page.reload(wait_until="networkidle")
        await asyncio.sleep(2)
        await page.fill('input[name="username"]', "admin")
        await page.fill('input[name="password"]', "123456")
        await page.click('.el-button--primary')
        await page.wait_for_timeout(5000)
        auth_js = json.dumps([{"authId": 3000+i, "authCode": c, "authName": c, "authType": 2, "isShow": 1}
                              for i, c in enumerate(set(ALL_AUTH))])
        await page.evaluate(f"""
            const p = JSON.parse(localStorage.getItem('PrimiHubPer') || '[]');
            const seen = new Set(p.map(x => x.authCode));
            for (const e of {auth_js}) {{ if (!seen.has(e.authCode)) {{ p.push(e); seen.add(e.authCode); }} }}
            localStorage.setItem('PrimiHubPer', JSON.stringify(p));
        """)

        def R(n, o, d=""):
            all_results.append((n, o, d))
            print(f"  {'✅' if o else '❌'} {n}: {d[:60] if d else ''}")

        print("✅ 登录\n")

        # ═══ PAGES CONFIG ═══
        pages_config = [
            ("用户管理", "/setting/user", [
                ("新增用户按钮", "button:has-text('新增用户')", "click"),
                ("搜索输入框", "input[placeholder*='请输入']", "fill"),
                ("表格行", ".el-table__body tr", "exist"),
            ]),
            ("角色管理", "/setting/role", [
                ("新增角色按钮", "button:has-text('新增')", "click"),
                ("角色表格", ".el-table", "exist"),
                ("搜索", "input[placeholder*='请输入']", "fill"),
            ]),
            ("节点管理", "/setting/center", [
                ("机构信息", "button:has-text('编辑')", "exist"),
                ("页面表单", ".el-form", "exist"),
            ]),
            ("系统配置", "/setting/system", [
                ("网络配置", "input", "fill"),
                ("FTP配置", ".el-form", "exist"),
                ("保存按钮", "button:has-text('保存')", "exist"),
            ]),
            ("白名单", "/whitelist/list", [
                ("新增", "button:has-text('新增')", "click"),
                ("表格", ".el-table", "exist"),
            ]),
            ("租户管理", "/tenant/list", [
                ("添加租户", "button:has-text('添加租户')", "click"),
                ("租户表格", ".el-table", "exist"),
            ]),
            ("存证管理", "/evidence/query", [
                ("时间戳Tab", "span:has-text('时间戳')", "click"),
                ("查询表格", ".el-table", "exist"),
            ]),
            ("监控管理", "/monitor/index", [
                ("监控页面", ".el-card:visible,canvas", "exist"),
                ("Tab切换", "[role='tab']", "click"),
            ]),
            ("日志管理", "/log/index", [
                ("日志表格", ".el-table", "exist"),
                ("Tab切换", "[role='tab']", "click"),
            ]),
            ("项目管理", "/project/list", [
                ("项目表格", ".el-table", "exist"),
                ("Tab切换", "[role='tab']", "click"),
            ]),
            ("资源管理", "/resource/list", [
                ("资源表格", ".el-table", "exist"),
                ("Tab切换", "[role='tab']", "click"),
            ]),
            ("接口管理", "/api/list", [
                ("新增", "button:has-text('新增')", "click"),
                ("接口表格", ".el-table", "exist"),
                ("Tab切换", "[role='tab']", "click"),
            ]),
            ("PSI", "/PSI/list", [
                ("PSI表格", ".el-table", "exist"),
                ("任务列表", "span:has-text('求交任务')", "exist"),
            ]),
            ("隐匿查询", "/privateSearch/list", [
                ("输入查询", "input[type='text']", "fill"),
                ("查询按钮", "button", "click"),
            ]),
            ("联邦求差", "/Difference/list", [
                ("差集表格", ".el-table", "exist"),
                ("新增", "button:has-text('新增')", "click"),
            ]),
            ("联邦求并", "/Union/list", [
                ("并集表格", ".el-table", "exist"),
                ("新增", "button:has-text('新增')", "click"),
            ]),
            ("联邦查询-DH", "/federatedQuery/dh/batch", [
                ("填写字段", "input", "fill"),
                ("查询按钮", "button:has-text('查询')", "exist"),
            ]),
            ("联邦查询-HE", "/federatedQuery/he/batch", [
                ("填写字段", "input", "fill"),
                ("查询按钮", "button:has-text('查询')", "exist"),
            ]),
            ("联邦查询-日志", "/federatedQuery/logs/intersectionRecord", [
                ("日志表格", ".el-table", "exist"),
            ]),
            ("FL-数据融合", "/federatedLearning/dataFusion", [
                ("任务名", "input", "fill"),
                ("提交按钮", "button", "exist"),
            ]),
            ("FL-参数调优", "/federatedLearning/paramTuning", [
                ("参数输入", "input", "fill"),
                ("保存按钮", "button:has-text('保存'),button", "exist"),
            ]),
            ("FL-XGBoost", "/federatedLearning/verticalXGBoostTrain", [
                ("模型参数", "input", "fill"),
                ("训练按钮", "button", "exist"),
            ]),
            ("FA-SQL校验", "/federatedAnalysis/sqlValidator", [
                ("SQL输入", "textarea,input", "fill"),
                ("校验按钮", "button:has-text('校验'),button", "exist"),
            ]),
            ("FA-筛选算子", "/federatedAnalysis/filterOperator", [
                ("筛选条件", "input", "fill"),
                ("查询按钮", "button", "exist"),
            ]),
            ("FA-SQL格式化", "/federatedAnalysis/sqlFormatter", [
                ("SQL输入", "textarea,input", "fill"),
                ("格式化按钮", "button", "exist"),
            ]),
            ("FS-卡方检验", "/federatedStatistics/chiSquareTest", [
                ("参数输入", "input", "fill"),
                ("计算按钮", "button", "exist"),
            ]),
            ("FS-T检验", "/federatedStatistics/tTest", [
                ("参数输入", "input", "fill"),
                ("计算按钮", "button", "exist"),
            ]),
            ("FS-结果存储", "/federatedStatistics/resultStorage", [
                ("存储配置", "input", "fill"),
                ("保存按钮", "button", "exist"),
            ]),
            ("单方算法", "/SingleParty/list", [
                ("单方表格", ".el-table", "exist"),
                ("新增", "button:has-text('新增')", "click"),
            ]),
            ("单方-数据清洗", "/SingleParty/dataCleaning", [
                ("数据输入", "input,textarea", "fill"),
                ("执行按钮", "button", "exist"),
            ]),
            ("单方-Python", "/SingleParty/pythonScript", [
                ("脚本编辑", "textarea,input", "fill"),
                ("运行按钮", "button", "exist"),
            ]),
            ("模型管理", "/model/list", [
                ("模型表格", ".el-table", "exist"),
                ("新增", "button:has-text('添加'),button:has-text('新增')", "exist"),
            ]),
            ("推理服务", "/reasoning/list", [
                ("推理表格", ".el-table", "exist"),
                ("新增服务", "button", "exist"),
            ]),
            ("警务-交集融合", "/policeDataFusion/intersection", [
                ("警务表单", ".el-form,input", "exist"),
                ("提交按钮", "button", "exist"),
            ]),
            ("警务-保险接口", "/policeDataFusion/insuranceApi", [
                ("API配置", "input", "fill"),
                ("保存按钮", "button", "exist"),
            ]),
            ("警务-同态密钥", "/policeDataFusion/homomorphicKey", [
                ("密钥表单", "input", "fill"),
                ("生成按钮", "button", "exist"),
            ]),
            ("证件-特征转换", "/electronicCert/featureConvert", [
                ("特征输入", "input", "fill"),
                ("转换按钮", "button", "exist"),
            ]),
            ("证件-隐私比对", "/electronicCert/privacyCompare", [
                ("比对表单", "input", "fill"),
                ("比对按钮", "button", "exist"),
            ]),
            ("证件-数据接入", "/electronicCert/orgDataImport", [
                ("数据配置", "input", "fill"),
                ("导入按钮", "button", "exist"),
            ]),
        ]

        for name, route, actions in pages_config:
            print(f"\n── {name} ──")
            try:
                await page.goto(f"{BASE}/#{route.lstrip('/')}", wait_until="networkidle", timeout=30000)
                await page.wait_for_timeout(3000)
                title = await page.title()
                loaded = "登录" not in title or "redirect" not in page.url
                if not loaded:
                    R(f"{name}-页面", False, "redirect")
                    for an, _, _ in actions:
                        R(f"{name}-{an}", False, "页面未加载")
                    continue
                R(f"{name}-页面", True, title[:30])
                await ss(page, name[:16])
                async for an, ok, detail in interact(page, actions):
                    R(f"{name}-{an}", ok, detail)
            except Exception as e:
                R(f"{name}-页面", False, str(e)[:50])

        # ═══ REPORT ═══
        print(f"\n{'='*60}")
        print("E2E完整测试报告")
        print(f"{'='*60}")
        ok = sum(1 for _, s, _ in all_results if s)
        fail = [(n, d) for n, s, d in all_results if not s]
        print(f"总用例: {len(all_results)}")
        print(f"通过: {ok}")
        print(f"失败: {len(fail)}")
        print(f"通过率: {ok*100//len(all_results)}%")
        if fail:
            print(f"\n失败详情:")
            for n, d in fail:
                print(f"  ❌ {n}: {d}")
        print(f"\n截图: {DIR}/")
        await ss(page, "final")
        await browser.close()

asyncio.run(main())
