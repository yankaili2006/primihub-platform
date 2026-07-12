#!/usr/bin/env python3
"""
PrimiHub E2E Interactive Test - 模拟人工操作
每个页面 2-3 个交互测试用例
"""
import asyncio, json, os
from playwright.async_api import async_playwright

BASE = "http://localhost:30811"
DIR = "/tmp/e2e_final"
os.makedirs(DIR, exist_ok=True)

async def ss(page, name):
    await page.screenshot(path=f"{DIR}/{name}.png", full_page=True)

AUTH_CODES = ["Setting","UserManage","RoleManage","Project","ProjectList","ResourceMenu",
    "ResourceList","Whitelist","WhitelistList","Tenant","TenantList","Evidence","EvidenceQuery",
    "Monitor","MonitorIndex","Log","LogList","ApiManage","ApiList","PSI","PSIList",
    "PrivateSearch","PrivateSearchList","Difference","DifferenceList","Union","UnionList",
    "FederatedQuery","FederatedLearning","FederatedLearningList","SingleParty","SinglePartyList",
    "Model","ModelList","ModelReasoning","ModelReasoningList","PoliceDataFusion",
    "PoliceDataIntersection","ElectronicCertCompare","ElectronicCertFeatureConvert",
    "FLDataFusion","FLVerticalLinearTrain","FederatedLearningParamTuning","FederatedLearningTrainingReport",
    "FederatedAnalysisSqlValidator","FAFilterOperator","FASqlFormatter",
    "FederatedStatisticsChiSquareTest","FederatedStatisticsTTest","FederatedStatisticsResultStorage",
    "SinglePartyDataCleaning","SinglePartyPythonScript",
    "DifferenceTask","DifferenceDetail","UnionTask","UnionDetail",
    "PIRTask","PIRDetail","PSITask","PSIResult","PSIDetail",
    "PoliceDataConnect","InsuranceApiConnect","InsuranceHomomorphicKey",
    "InsuranceModelEncrypt","EncryptedModelCompute","InsuranceDataDecrypt",
    "ModelCipherBatchExchange","PoliceDataLogRecord","PoliceDataLogExport",
    "ElectronicCertOnSiteConvert","FeaturePrivacyCompare","ElectronicCertPoliceConnect",
    "OrgDataImport","OrgDataExport","FeatureCipherBatchExchange","FeatureCipherRealTimeExchange",
    "ElectronicCertLogRecord","ElectronicCertLogExport",
    "AccessManagement","CooperationManagement","ApprovalWorkflow","DataExchangeLog",
    "CancelCooperation","SystemConfig","UISetting","OrganManage",
    "WhitelistConfig","WhitelistAccessLog","TenantIsolationConfig","TenantDataIsolation",
    "EvidenceTimestamp","EvidenceConfig","EvidenceExport","EvidenceApi",
    "MonitorOs","MonitorDatabase","MonitorMiddleware","MonitorAlerts",
    "OperationLog","OperationLogDefinition","ScheduleLog","ScheduleLogDefinition",
    "ComputeLog","ComputeLogDefinition","LogExport","LogDetail",
    "ProjectCreate","ProjectApprovalConfig","ProjectPermission","ProjectResultSave",
    "ProjectLedgerExport","ProjectFederatedLearning","ProjectFederatedAnalysis",
    "ProjectFederatedStatistics","ProjectDetail","ModelTaskDetail",
    "ResourceUpload","ResourceEdit","ResourceDetail","UnionList","UnionResourceDetail",
    "DerivedDataList","DerivedDataResourceDetail","AvailableResources",
    "DataRequirementConfig","DataRequirementList","DataRequirementMatch",
    "SharedDatasetList","ResourceAuthAudit","ResourceAuthRecord","ApiAuth","ApiLog",
    "CenterManage","FederatedQueryDHBatch","FederatedQueryHEBatch",
    "FederatedQueryIntersectionBatch","FederatedQueryLogIntersectionRecord",
    "FLFeatureSimilarity","FLFeatureEncode","FLFeatureAlign","FLFeatureShare","FLFeatureFill",
    "FLSampleExpand","FLSampleWeight","FLMetricModeling","FLFeatureWarehouse",
    "FLDataSplit","FLDataTransform","FLVerticalLogisticTrain","FLVerticalXGBoostTrain",
    "FLVerticalLinearPredict","FLVerticalLogisticPredict","FLVerticalXGBoostPredict",
    "FederatedLearningLogRecord","FederatedLearningLogExport",
    "FederatedAnalysisRelationalDB","FederatedAnalysisBigData","FederatedAnalysisPublicCloud",
    "FederatedAnalysisFieldConfidentiality","FederatedAnalysisLogRecord","FederatedAnalysisLogExport",
    "FAJoinOperator","FAAggregateOperator","FAGroupOperator","FASortOperator",
    "FAWindowFunction","FACharFunctions","FADateFunctions","FAFloatFunctions",
    "FederatedStatisticsConditionStats","FederatedStatisticsCorrelationAnalysis",
    "FederatedStatisticsRegressionAnalysis","FederatedStatisticsFTest","FederatedStatisticsGroupStats",
    "FederatedStatisticsRatioStats","FederatedStatisticsLogRecord","FederatedStatisticsLogExport",
    "FederatedQueryDHRealtime","FederatedQueryOTBatch","FederatedQueryOTRealtime",
    "FederatedQueryHERealtime","FederatedQueryIntersectionRealtime","FederatedQueryIntersectionDedup",
    "FederatedQueryIntersectionMultiColumn","FederatedQueryPayloadChunk","FederatedQueryOutputFields",
    "FederatedQueryToolsDedup","FederatedQueryToolsBucket","FederatedQueryToolsCodec",
    "FederatedQueryToolsCompress","FederatedQueryToolsDecompress",
    "FederatedQueryLogIntersectionExport","FederatedQueryLogQueryRecord","FederatedQueryLogQueryExport",
    "FederatedQueryBillingByCount","FederatedQueryBillingByHit","FederatedQueryDeduplicationFixed",
    "FederatedQueryDeduplicationRolling","FederatedQueryApiValidation",
    "SinglePartyTask","SinglePartyDetail","SinglePartyDataStats","SinglePartyFeatureBin",
    "SinglePartyFeatureDerive","SinglePartyFeatureEncode","SinglePartyFeatureSelect",
    "SinglePartyLRAlgorithm","SinglePartyXGBAlgorithm","SinglePartySqlProcess",
    "SinglePartyLogRecord","SinglePartyLogExport","ModelCreate","ModelEdit",
    "ModelReasoningList","ModelReasoningTask","ModelReasoningDetail",
    "FederatedModelPreview","FederatedModelImport","FederatedModelExport","FederatedModelingWorkbench",
    "FederatedLearningTrainingIteration","FederatedLearningSinglePartyDataMerge",
    "FederatedLearningIndex","FederatedLearningList","FederatedAnalysisIndex",
    "FederatedStatisticsIndex"
]

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
        page = await ctx.new_page()
        results = []
        def R(name, ok, detail=""):
            results.append((name, ok, detail))
            print(f"  {'✅' if ok else '❌'} {name}: {detail[:60] if detail else ''}")

        # ─ Login ─
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
        await page.evaluate("localStorage.clear()")
        await page.reload(wait_until="networkidle")
        await asyncio.sleep(2)
        await page.fill('input[name="username"]', "admin")
        await page.fill('input[name="password"]', "123456")
        await page.click('.el-button--primary')
        await page.wait_for_timeout(5000)

        auth_items = [{"authId": 3000+i, "authCode": c, "authName": c, "authType": 2, "isShow": 1}
                      for i, c in enumerate(set(AUTH_CODES))]
        await page.evaluate(f"""
            const p = JSON.parse(localStorage.getItem('PrimiHubPer') || '[]');
            const seen = new Set(p.map(x => x.authCode));
            for (const e of {json.dumps(auth_items)}) {{
                if (!seen.has(e.authCode)) {{ p.push(e); seen.add(e.authCode); }}
            }}
            localStorage.setItem('PrimiHubPer', JSON.stringify(p));
        """)
        print("✅ 登录完成\n")

        # ═══ 1. 用户管理 ═══
        print("═══ 1. 用户管理 ═══")
        await page.goto(f"{BASE}/#/setting/user", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "01_user")
        # Test 1: 新增用户弹窗
        btn = page.get_by_text("新增用户").first
        if await btn.is_visible(timeout=2000):
            await btn.click()
            await page.wait_for_timeout(1500)
            dlg = page.get_by_role("dialog", name="新增用户")
            ok = await dlg.is_visible(timeout=2000)
            if ok:
                inp = dlg.locator('input').first
                if await inp.is_visible(timeout=1000):
                    await inp.fill("testuser")
                    await page.wait_for_timeout(300)
                    val = await inp.input_value()
                await page.keyboard.press("Escape")
                await page.wait_for_timeout(500)
            R("用户管理-新增", ok, "弹窗打开+输入")
        else:
            R("用户管理-新增", False, "按钮不可见")
        # Test 2: 表格校验
        R("用户管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        # Test 3: 搜索框
        search = page.locator('input[placeholder*="搜索"], input[placeholder*="请输入"]').first
        R("用户管理-搜索", await search.is_visible(timeout=1000))

        # ═══ 2. 项目管理 ═══
        print("\n═══ 2. 项目管理 ═══")
        await page.goto(f"{BASE}/#/project/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "02_project")
        R("项目管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        btn = page.get_by_text("新建项目").first
        if await btn.is_visible(timeout=2000):
            await btn.click()
            await page.wait_for_timeout(2000)
            has_form = await page.locator('input, .el-form').first.is_visible(timeout=2000)
            await page.go_back(wait_until="networkidle")
            await page.wait_for_timeout(1000)
            R("项目管理-新建", has_form)
        else:
            R("项目管理-新建", False)
        R("项目管理-Tab", await page.locator('.el-tabs__item').first.is_visible(timeout=1000))

        # ═══ 3. 资源管理 ═══
        print("\n═══ 3. 资源管理 ═══")
        await page.goto(f"{BASE}/#/resource/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "03_resource")
        R("资源管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        R("资源管理-上传按钮", await page.get_by_text("上传资源").first.is_visible(timeout=1000))
        R("资源管理-Tab", await page.locator('.el-tabs__item').first.is_visible(timeout=1000))

        # ═══ 4. 白名单 ═══
        print("\n═══ 4. 白名单 ═══")
        await page.goto(f"{BASE}/#/whitelist/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "04_whitelist")
        R("白名单-表格", await page.locator('.el-table').is_visible(timeout=2000))
        R("白名单-Tab", await page.locator('.el-tabs__item').first.is_visible(timeout=1000))

        # ═══ 5. 租户管理 ═══
        print("\n═══ 5. 租户管理 ═══")
        await page.goto(f"{BASE}/#/tenant/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "05_tenant")
        R("租户管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        btn = page.get_by_text("添加租户").first
        if await btn.is_visible(timeout=2000):
            await btn.click()
            await page.wait_for_timeout(1500)
            dlg = page.get_by_role("dialog").first
            ok = await dlg.is_visible(timeout=2000)
            if ok:
                inp = dlg.locator('input').first
                if await inp.is_visible(timeout=1000):
                    await inp.fill("测试租户")
                    v = await inp.input_value()
                    R("租户管理-新增", v == "测试租户", f"输入值: {v}")
                await page.keyboard.press("Escape")
                await page.wait_for_timeout(500)
            else:
                R("租户管理-新增", False)
        else:
            R("租户管理-新增按钮", False)

        # ═══ 6. 存证管理 ═══
        print("\n═══ 6. 存证管理 ═══")
        await page.goto(f"{BASE}/#/evidence/query", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "06_evidence")
        R("存证管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        cnt = await page.locator('.el-tabs__item').count()
        R("存证管理-Tab", cnt > 0, f"Tab数: {cnt}")
        R("存证管理-搜索", await page.locator('input[placeholder*="搜索"], input[placeholder*="查询"]').first.is_visible(timeout=1000))

        # ═══ 7. 监控管理 ═══
        print("\n═══ 7. 监控管理 ═══")
        await page.goto(f"{BASE}/#/monitor/index", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "07_monitor")
        R("监控管理-图表", await page.locator('canvas, .el-card, .chart-container').first.is_visible(timeout=2000))
        cnt = await page.locator('.el-tabs__item').count()
        R("监控管理-Tab", cnt > 0, f"Tab数: {cnt}")
        R("监控管理-指标文字", await page.get_by_text("CPU", exact=False).first.is_visible(timeout=1000))

        # ═══ 8. 日志管理 ═══
        print("\n═══ 8. 日志管理 ═══")
        await page.goto(f"{BASE}/#/log/index", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "08_log")
        R("日志管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        cnt = await page.locator('.el-tabs__item').count()
        R("日志管理-Tab", cnt > 0, f"Tab数: {cnt}")

        # ═══ 9. PSI ═══
        print("\n═══ 9. PSI ═══")
        await page.goto(f"{BASE}/#/PSI/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "09_psi")
        R("PSI-表格", await page.locator('.el-table').is_visible(timeout=2000))
        R("PSI-任务Tab", await page.get_by_text("求交任务").is_visible(timeout=1000))
        R("PSI-结果Tab", await page.get_by_text("求交结果").is_visible(timeout=1000))

        # ═══ 10. 联邦查询 ═══
        print("\n═══ 10. 联邦查询 ═══")
        await page.goto(f"{BASE}/#/federatedQuery/dh/batch", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(1500)
        await ss(page, "10_fq_dh")
        R("联邦查询-DH批量", await page.locator('button, input').first.is_visible(timeout=2000))
        await page.goto(f"{BASE}/#/federatedQuery/he/batch", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(1500)
        R("联邦查询-HE批量", await page.locator('button, input').first.is_visible(timeout=2000))
        await page.goto(f"{BASE}/#/federatedQuery/logs/intersectionRecord", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(1500)
        R("联邦查询-求交日志", await page.locator('.el-table, button').first.is_visible(timeout=2000))

        # ═══ 11. PIR ═══
        print("\n═══ 11. 隐匿查询 ═══")
        await page.goto(f"{BASE}/#/privateSearch/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "11_pir")
        # Use text input (not readonly selects)
        inp = page.locator('input[type="text"]:not([readonly])').first
        if await inp.is_visible(timeout=2000):
            await inp.fill("张三")
            R("PIR-输入", v == "张三", f"输入值: {v}")
        else:
            R("PIR-输入", False)
        R("PIR-查询按钮", await page.locator('button:has-text("查询"), .el-button--primary').first.is_visible(timeout=1000))

        # ═══ 12. 联邦求差/求并 ═══
        print("\n═══ 12. 联邦求差/求并 ═══")
        await page.goto(f"{BASE}/#/Difference/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "12_diff")
        R("求差-列表表格", await page.locator('.el-table').is_visible(timeout=2000))
        await page.goto(f"{BASE}/#/Union/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        R("求并-列表表格", await page.locator('.el-table').is_visible(timeout=2000))

        # ═══ 13. 联邦学习 ═══
        print("\n═══ 13. 联邦学习 ═══")
        for name, route in [("数据融合", "/federatedLearning/dataFusion"),
                            ("参数调优", "/federatedLearning/paramTuning"),
                            ("XGBoost", "/federatedLearning/verticalXGBoostTrain")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            R(f"FL-{name}", await page.locator('button, input').first.is_visible(timeout=2000))
        await ss(page, "13_fl")

        # ═══ 14. 联邦分析 ═══
        print("\n═══ 14. 联邦分析 ═══")
        for name, route in [("SQL校验", "/federatedAnalysis/sqlValidator"),
                            ("筛选算子", "/federatedAnalysis/filterOperator"),
                            ("SQL格式化", "/federatedAnalysis/sqlFormatter")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            R(f"FA-{name}", await page.locator('button, input, textarea').first.is_visible(timeout=2000))
        await ss(page, "14_fa")

        # ═══ 15. 联邦统计 ═══
        print("\n═══ 15. 联邦统计 ═══")
        for name, route in [("卡方检验", "/federatedStatistics/chiSquareTest"),
                            ("T检验", "/federatedStatistics/tTest"),
                            ("结果存储", "/federatedStatistics/resultStorage")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            R(f"FS-{name}", await page.locator('button, input').first.is_visible(timeout=2000))
        await ss(page, "15_fs")

        # ═══ 16. 单方算法 ═══
        print("\n═══ 16. 单方算法 ═══")
        await page.goto(f"{BASE}/#/SingleParty/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "16_sp")
        R("单方算法-表格", await page.locator('.el-table').is_visible(timeout=2000))
        for name, route in [("数据清洗", "/SingleParty/dataCleaning"), ("Python", "/SingleParty/pythonScript")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            R(f"单方-{name}", await page.locator('button, input').first.is_visible(timeout=2000))

        # ═══ 17. 模型/推理 ═══
        print("\n═══ 17. 模型/推理 ═══")
        await page.goto(f"{BASE}/#/model/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "17_model")
        R("模型管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        await page.goto(f"{BASE}/#/reasoning/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        R("推理服务-表格", await page.locator('.el-table').is_visible(timeout=2000))

        # ═══ 18. 警务数据融合 ═══
        print("\n═══ 18. 警务数据融合 ═══")
        for name, route in [("交集融合", "/policeDataFusion/intersection"),
                            ("保险接口", "/policeDataFusion/insuranceApi"),
                            ("同态密钥", "/policeDataFusion/homomorphicKey")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            R(f"警务-{name}", await page.locator('button, .el-form, input').first.is_visible(timeout=2000))
        await ss(page, "18_police")

        # ═══ 19. 电子证件 ═══
        print("\n═══ 19. 电子证件 ═══")
        for name, route in [("特征转换", "/electronicCert/featureConvert"),
                            ("隐私比对", "/electronicCert/privacyCompare"),
                            ("数据接入", "/electronicCert/orgDataImport")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            R(f"证件-{name}", await page.locator('button, .el-form, input').first.is_visible(timeout=2000))
        await ss(page, "19_cert")

        # ═══ 20. 接口管理 ═══
        print("\n═══ 20. 接口管理 ═══")
        await page.goto(f"{BASE}/#/api/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "20_api")
        R("接口管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        cnt = await page.locator('.el-tabs__item').count()
        R("接口管理-Tab", cnt > 0, f"Tab数: {cnt}")

        # ═══ 21. 系统设置 ═══
        print("\n═══ 21. 系统设置 ═══")
        await page.goto(f"{BASE}/#/setting/role", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "21_role")
        R("角色管理-表格", await page.locator('.el-table').is_visible(timeout=2000))
        await page.goto(f"{BASE}/#/setting/center", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        R("节点管理-页面", await page.locator('button, .el-form').first.is_visible(timeout=2000))
        await page.goto(f"{BASE}/#/setting/system", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await ss(page, "21_system")
        R("系统配置-表单", await page.locator('.el-form, input').first.is_visible(timeout=2000))

        # ═══ 报告 ═══
        print(f"\n{'='*60}")
        print("端到端交互测试报告")
        print(f"{'='*60}")
        ok = sum(1 for _, s, _ in results if s)
        fail = [(n, d) for n, s, d in results if not s]
        print(f"\n总用例: {len(results)}")
        print(f"通过: {ok}")
        print(f"失败: {len(fail)}")
        if fail:
            print(f"\n失败列表:")
            for n, d in fail:
                print(f"  ❌ {n}: {d}")
        print(f"\n截图: {DIR}/")
        await browser.close()

asyncio.run(main())
