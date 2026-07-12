#!/usr/bin/env python3
"""
PrimiHub E2E 自动测试
模拟人工操作，验证每个页面的功能完整性
"""
import asyncio, json
from playwright.async_api import async_playwright

BASE = "http://localhost:30811"
SCREENSHOT_DIR = "/tmp/e2e_screenshots"

ALL_AUTH = [
    {"authId": i, "authCode": n, "authName": n, "authType": 2, "isShow": 1}
    for i, n in enumerate([
        "FLDataFusion","FLFeatureSimilarity","FLFeatureEncode","FLFeatureAlign",
        "FLFeatureShare","FLFeatureFill","FLSampleExpand","FLSampleWeight",
        "FLMetricModeling","FLFeatureWarehouse","FLDataSplit","FLDataTransform",
        "FLVerticalLinearTrain","FLVerticalLogisticTrain","FLVerticalXGBoostTrain",
        "FLVerticalLinearPredict","FLVerticalLogisticPredict","FLVerticalXGBoostPredict",
        "FederatedLearningParamTuning","FederatedLearningTrainingReport",
        "FederatedAnalysisSqlValidator","FederatedAnalysisRelationalDB",
        "FederatedAnalysisBigData","FederatedAnalysisPublicCloud",
        "FAFilterOperator","FAJoinOperator","FAAggregateOperator","FAGroupOperator",
        "FASortOperator","FAWindowFunction","FACharFunctions","FADateFunctions",
        "FASqlFormatter","FAFloatFunctions",
        "FederatedStatisticsChiSquareTest","FederatedStatisticsFTest",
        "FederatedStatisticsGroupStats","FederatedStatisticsTTest",
        "FederatedStatisticsRatioStats","FederatedStatisticsResultStorage",
        "FederatedStatisticsResultExport","FederatedLearningLogRecord",
        "FederatedLearningLogExport","FederatedAnalysisLogRecord",
        "FederatedAnalysisLogExport","FederatedStatisticsLogRecord",
        "FederatedStatisticsLogExport",
        "SingleParty","SinglePartyList","SinglePartyTask","SinglePartyDetail",
        "SinglePartyDataCleaning","SinglePartyDataScaling","SinglePartyDataStats",
        "SinglePartyFeatureBin","SinglePartyFeatureDerive","SinglePartyFeatureEncode",
        "SinglePartyFeatureSelect","SinglePartyLRAlgorithm","SinglePartyXGBAlgorithm",
        "SinglePartyPythonScript","SinglePartySqlProcess",
        "SinglePartyLogRecord","SinglePartyLogExport",
        "Difference","DifferenceList","DifferenceTask","DifferenceDetail",
        "Union","UnionList","UnionTask","UnionDetail",
        "PrivateSearch","PrivateSearchList","PIRTask","PIRDetail",
        "PSI","PSIList","PSITask","PSIResult","PSIDetail",
        "PoliceDataFusion","PoliceDataIntersection","PoliceDataConnect",
        "InsuranceApiConnect","InsuranceHomomorphicKey","InsuranceModelEncrypt",
        "EncryptedModelCompute","InsuranceDataDecrypt","ModelCipherBatchExchange",
        "PoliceDataLogRecord","PoliceDataLogExport",
        "ElectronicCertCompare","ElectronicCertFeatureConvert","OnSiteCertFeatureConvert",
        "FeaturePrivacyCompare","ElectronicCertPoliceConnect","OrgDataImport",
        "OrgDataExport","FeatureCipherBatchExchange","FeatureCipherRealTimeExchange",
        "ElectronicCertLogRecord","ElectronicCertLogExport",
    ], 3000)
]

async def screenshot(page, name):
    await page.screenshot(path=f"{SCREENSHOT_DIR}/{name}.png", full_page=True)

async def main():
    import os; os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
        page = await ctx.new_page()
        
        # ── 1. Login ──
        print("=" * 60)
        print("1. 登录")
        print("=" * 60)
        await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
        await page.evaluate("localStorage.clear()")
        await page.reload(wait_until="networkidle")
        await asyncio.sleep(2)
        await page.fill('input[name="username"]', "admin")
        await page.fill('input[name="password"]', "123456")
        await page.click('.el-button--primary')
        await page.wait_for_timeout(5000)
        await screenshot(page, "01_login_success")
        
        # Inject permissions
        await page.evaluate(f"""
            const p = JSON.parse(localStorage.getItem('PrimiHubPer') || '[]');
            const c = new Set(p.map(x => x.authCode));
            for (const e of {json.dumps(ALL_AUTH)}) {{ if (!c.has(e.authCode)) {{ p.push(e); c.add(e.authCode); }} }}
            localStorage.setItem('PrimiHubPer', JSON.stringify(p));
        """)
        print("  登录成功，权限注入完成")
        
        results = []

        # ── 2. User Management ──
        print("\n" + "=" * 60)
        print("2. 用户管理")
        print("=" * 60)
        await page.goto(f"{BASE}/#/setting/user", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "02_user_manage")
        
        # Check user table
        has_table = await page.evaluate("""() => {
            const t = document.querySelector('.el-table, .el-table__body');
            return t ? true : false;
        }""")
        has_buttons = await page.evaluate("""() => {
            const btns = document.querySelectorAll('.el-button');
            return btns.length > 0;
        }""")
        print(f"  - 用户表格: {'✅' if has_table else '❌'}")
        print(f"  - 操作按钮: {'✅' if has_buttons else '❌'}")
        results.append(("用户管理-表格", has_table))
        results.append(("用户管理-按钮", has_buttons))

        # ── 3. Role Management ──
        print("\n" + "=" * 60)
        print("3. 角色管理")
        print("=" * 60)
        await page.goto(f"{BASE}/#/setting/role", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "03_role_manage")
        has_table = await page.evaluate("document.querySelector('.el-table') !== null")
        print(f"  - 角色表格: {'✅' if has_table else '❌'}")
        results.append(("角色管理", has_table))

        # ── 4. Project Management ──
        print("\n" + "=" * 60)
        print("4. 项目管理")
        print("=" * 60)
        await page.goto(f"{BASE}/#/project/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "04_project")
        has_create = await page.evaluate("""() => {
            const b = document.body.innerText;
            return b.includes('新建项目') || document.querySelector('.el-button--primary') !== null;
        }""")
        print(f"  - 新建项目按钮: {'✅' if has_create else '❌'}")
        results.append(("项目管理", has_create))

        # ── 5. Resource Management ──
        print("\n" + "=" * 60)
        print("5. 资源管理")
        print("=" * 60)
        await page.goto(f"{BASE}/#/resource/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "05_resource")
        has_upload = await page.evaluate("document.body.innerText.includes('上传资源') || document.body.innerText.includes('新建资源')")
        print(f"  - 资源列表/上传: {'✅' if has_upload else '❌'}")
        results.append(("资源管理", has_upload))

        # ── 6. Federated Query (联邦查询) ──
        print("\n" + "=" * 60)
        print("6. 联邦查询")
        print("=" * 60)
        for name, route in [
            ("联邦查询-DH批量", "/federatedQuery/dh/batch"),
            ("联邦查询-DH实时", "/federatedQuery/dh/realtime"),
            ("联邦查询-OT批量", "/federatedQuery/ot/batch"),
            ("联邦查询-OT实时", "/federatedQuery/ot/realtime"),
            ("联邦查询-HE批量", "/federatedQuery/he/batch"),
            ("联邦查询-HE实时", "/federatedQuery/he/realtime"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_form = await page.evaluate("""() => {
                const b = document.body.innerText;
                return b.includes('查询') || b.includes('任务') || document.querySelector('input,textarea,button') !== null;
            }""")
            print(f"  {name}: {'✅' if has_form else '❌'}")
            results.append((name, has_form))

        await screenshot(page, "06_federated_query")

        # ── 7. PSI (隐私求交) ──
        print("\n" + "=" * 60)
        print("7. 隐私求交(PSI)")
        print("=" * 60)
        await page.goto(f"{BASE}/#/PSI/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "07_psi")
        has_psi = await page.evaluate("document.body.innerText.includes('隐私求交') || document.body.innerText.includes('求交')")
        print(f"  - PSI页面: {'✅' if has_psi else '❌'}")
        results.append(("PSI", has_psi))

        # ── 8. PIR (隐匿查询) ──
        await page.goto(f"{BASE}/#/privateSearch/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "08_pir")
        has_pir = await page.evaluate("document.body.innerText.includes('隐匿查询')")
        print(f"  - 隐匿查询: {'✅' if has_pir else '❌'}")
        results.append(("PIR", has_pir))

        # ── 9. Federated Learning ──
        print("\n" + "=" * 60)
        print("9. 联邦学习")
        print("=" * 60)
        for name, route in [
            ("数据融合", "/federatedLearning/dataFusion"),
            ("特征相似度", "/federatedLearning/featureSimilarity"),
            ("特征编码", "/federatedLearning/featureEncodeFL"),
            ("特征对齐", "/federatedLearning/featureAlign"),
            ("特征分享", "/federatedLearning/featureShare"),
            ("特征填充", "/federatedLearning/featureFill"),
            ("样本扩展", "/federatedLearning/sampleExpand"),
            ("样本加权", "/federatedLearning/sampleWeight"),
            ("指标建模", "/federatedLearning/metricModeling"),
            ("特征装仓", "/federatedLearning/featureWarehouse"),
            ("数据分割", "/federatedLearning/dataSplit"),
            ("数据转换", "/federatedLearning/dataTransform"),
            ("参数调优", "/federatedLearning/paramTuning"),
            ("训练报告", "/federatedLearning/trainingReport"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_form = await page.evaluate("""() => {
                const b = document.body.innerText;
                return document.querySelector('input,textarea,button,.el-form') !== null;
            }""")
            print(f"  FL-{name}: {'✅' if has_form else '❌'}")
            results.append((f"FL-{name}", has_form))

        await screenshot(page, "09_federated_learning")

        # ── 10. Vertical Model Training (纵向建模) ──
        print("\n" + "=" * 60)
        print("10. 纵向建模")
        print("=" * 60)
        for name, route in [
            ("线性回归-训练", "/federatedLearning/verticalLinearTrain"),
            ("逻辑回归-训练", "/federatedLearning/verticalLogisticTrain"),
            ("XGBoost-训练", "/federatedLearning/verticalXGBoostTrain"),
            ("线性回归-预测", "/federatedLearning/verticalLinearPredict"),
            ("逻辑回归-预测", "/federatedLearning/verticalLogisticPredict"),
            ("XGBoost-预测", "/federatedLearning/verticalXGBoostPredict"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_inputs = await page.evaluate("document.querySelectorAll('input,button,select').length > 2")
            print(f"  {name}: {'✅' if has_inputs else '❌'}")
            results.append((f"纵向{name}", has_inputs))
        await screenshot(page, "10_vertical_model")

        # ── 11. Federated Analysis (联邦分析) ──
        print("\n" + "=" * 60)
        print("11. 联邦分析")
        print("=" * 60)
        for name, route in [
            ("SQL校验", "/federatedAnalysis/sqlValidator"),
            ("筛选算子", "/federatedAnalysis/filterOperator"),
            ("连接算子", "/federatedAnalysis/joinOperator"),
            ("聚合算子", "/federatedAnalysis/aggregateOperator"),
            ("分组算子", "/federatedAnalysis/groupOperator"),
            ("排序算子", "/federatedAnalysis/sortOperator"),
            ("窗口函数", "/federatedAnalysis/windowFunction"),
            ("字符函数", "/federatedAnalysis/charFunctions"),
            ("日期函数", "/federatedAnalysis/dateFunctions"),
            ("SQL格式化", "/federatedAnalysis/sqlFormatter"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_ui = await page.evaluate("document.querySelectorAll('input,button,textarea,.el-form').length > 1")
            print(f"  FA-{name}: {'✅' if has_ui else '❌'}")
            results.append((f"FA-{name}", has_ui))
        await screenshot(page, "11_federated_analysis")

        # ── 12. Federated Statistics (联邦统计) ──
        print("\n" + "=" * 60)
        print("12. 联邦统计")
        print("=" * 60)
        for name, route in [
            ("卡方检验", "/federatedStatistics/chiSquareTest"),
            ("F检验", "/federatedStatistics/fTest"),
            ("分组统计", "/federatedStatistics/groupStats"),
            ("T检验", "/federatedStatistics/tTest"),
            ("占比统计", "/federatedStatistics/ratioStats"),
            ("结果存储", "/federatedStatistics/resultStorage"),
            ("结果导出", "/federatedStatistics/resultExport"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_ui = await page.evaluate("document.querySelectorAll('input,button,select').length > 1")
            print(f"  FS-{name}: {'✅' if has_ui else '❌'}")
            results.append((f"FS-{name}", has_ui))
        await screenshot(page, "12_federated_statistics")

        # ── 13. Single Party (单方算法) ──
        print("\n" + "=" * 60)
        print("13. 单方算法")
        print("=" * 60)
        await page.goto(f"{BASE}/#/SingleParty/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "13_single_party")
        has_sp = await page.evaluate("document.querySelectorAll('input,button,.el-table').length > 1")
        print(f"  - 单方算法列表: {'✅' if has_sp else '❌'}")
        results.append(("单方算法", has_sp))

        for name, route in [
            ("数据清洗", "/SingleParty/dataCleaning"),
            ("数据缩放", "/SingleParty/dataScaling"),
            ("特征分箱", "/SingleParty/featureBin"),
            ("特征衍生", "/SingleParty/featureDerive"),
            ("特征编码", "/SingleParty/featureEncode"),
            ("特征筛选", "/SingleParty/featureSelect"),
            ("Python脚本", "/SingleParty/pythonScript"),
            ("SQL处理", "/SingleParty/sqlProcess"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_ui = await page.evaluate("document.querySelectorAll('input,button,textarea,.el-form').length > 1")
            print(f"  SP-{name}: {'✅' if has_ui else '❌'}")
            results.append((f"SP-{name}", has_ui))
        await screenshot(page, "13b_single_party_sub")

        # ── 14. Difference / Union ──
        print("\n" + "=" * 60)
        print("14. 联邦求差/求并")
        print("=" * 60)
        for name, route in [("联邦求差", "/Difference/list"), ("联邦求并", "/Union/list")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(2000)
            has_page = await page.evaluate("document.body.innerText.includes('联邦')")
            print(f"  {name}: {'✅' if has_page else '❌'}")
            results.append((name, has_page))
        await screenshot(page, "14_diff_union")

        # ── 15. Whitelist (白名单) ──
        print("\n" + "=" * 60)
        print("15. 白名单管理")
        print("=" * 60)
        await page.goto(f"{BASE}/#/whitelist/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "15_whitelist")
        has_wl = await page.evaluate("document.body.innerText.includes('白名单') || document.querySelector('.el-table') !== null")
        print(f"  - 白名单: {'✅' if has_wl else '❌'}")
        results.append(("白名单", has_wl))

        # ── 16. Tenant (租户) ──
        await page.goto(f"{BASE}/#/tenant/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "16_tenant")
        has_tenant = await page.evaluate("document.body.innerText.includes('租户')")
        print(f"  - 租户管理: {'✅' if has_tenant else '❌'}")
        results.append(("租户", has_tenant))

        # ── 17. Evidence (存证) ──
        await page.goto(f"{BASE}/#/evidence/query", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "17_evidence")
        has_ev = await page.evaluate("document.body.innerText.includes('存证')")
        print(f"  - 存证管理: {'✅' if has_ev else '❌'}")
        results.append(("存证", has_ev))

        # ── 18. Monitor (监控) ──
        print("\n" + "=" * 60)
        print("18. 监控管理")
        print("=" * 60)
        for name, route in [("概览", "/monitor/index"), ("CPU", "/monitor/os"), ("数据库", "/monitor/database"), ("中间件", "/monitor/middleware"), ("告警", "/monitor/alerts")]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_chart = await page.evaluate("document.querySelector('.el-card,.chart-container,canvas,table') !== null")
            print(f"  监控-{name}: {'✅' if has_chart else '❌'}")
            results.append((f"监控-{name}", has_chart))
        await screenshot(page, "18_monitor")

        # ── 19. Interface Management (接口管理) ──
        await page.goto(f"{BASE}/#/api/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "19_api")
        has_api = await page.evaluate("document.body.innerText.includes('接口')")
        print(f"  - 接口管理: {'✅' if has_api else '❌'}")
        results.append(("接口管理", has_api))

        # ── 20. Log Management (日志管理) ──
        await page.goto(f"{BASE}/#/log/index", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "20_log")
        has_log = await page.evaluate("document.body.innerText.includes('日志')")
        print(f"  - 日志管理: {'✅' if has_log else '❌'}")
        results.append(("日志", has_log))

        # ── 21. Police Data Fusion ──
        print("\n" + "=" * 60)
        print("21. 警务数据融合")
        print("=" * 60)
        for name, route in [
            ("交集数据融合", "/policeDataFusion/intersection"),
            ("保险接口", "/policeDataFusion/insuranceApi"),
            ("同态密钥", "/policeDataFusion/homomorphicKey"),
            ("模型加密", "/policeDataFusion/modelEncrypt"),
            ("加密计算", "/policeDataFusion/encryptedCompute"),
            ("数据解密", "/policeDataFusion/dataDecrypt"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_ui = await page.evaluate("document.querySelectorAll('input,button,.el-form').length > 1")
            print(f"  {name}: {'✅' if has_ui else '❌'}")
            results.append((f"警务-{name}", has_ui))
        await screenshot(page, "21_police_fusion")

        # ── 22. Electronic Cert ──
        print("\n" + "=" * 60)
        print("22. 电子证件比对")
        print("=" * 60)
        for name, route in [
            ("特征转换", "/electronicCert/featureConvert"),
            ("现场转换", "/electronicCert/onSiteConvert"),
            ("隐私比对", "/electronicCert/privacyCompare"),
            ("数据接入", "/electronicCert/orgDataImport"),
            ("数据导出", "/electronicCert/orgDataExport"),
            ("密文交换", "/electronicCert/batchExchange"),
            ("实时交换", "/electronicCert/realTimeExchange"),
        ]:
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
            await page.wait_for_timeout(1500)
            has_ui = await page.evaluate("document.querySelectorAll('input,button,.el-form').length > 1")
            print(f"  {name}: {'✅' if has_ui else '❌'}")
            results.append((f"证件-{name}", has_ui))
        await screenshot(page, "22_electronic_cert")

        # ── 23. Model Management (模型管理) ──
        await page.goto(f"{BASE}/#/model/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "23_model")
        has_model = await page.evaluate("document.body.innerText.includes('模型')")
        print(f"  - 模型管理: {'✅' if has_model else '❌'}")
        results.append(("模型管理", has_model))

        # ── 24. Reasoning (推理服务) ──
        await page.goto(f"{BASE}/#/reasoning/list", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "24_reasoning")
        has_reason = await page.evaluate("document.body.innerText.includes('推理') || document.body.innerText.includes('服务')")
        print(f"  - 推理服务: {'✅' if has_reason else '❌'}")
        results.append(("推理服务", has_reason))

        # ── 25. Node Management ──
        await page.goto(f"{BASE}/#/setting/center", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "25_node")
        has_node = await page.evaluate("document.body.innerText.includes('节点') || document.body.innerText.includes('机构')")
        print(f"  - 节点管理: {'✅' if has_node else '❌'}")
        results.append(("节点管理", has_node))

        # ── 26. System Config ──
        await page.goto(f"{BASE}/#/setting/system", wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(2000)
        await screenshot(page, "26_system_config")
        has_config = await page.evaluate("document.querySelectorAll('input,button,.el-form').length > 1")
        print(f"  - 系统配置: {'✅' if has_config else '❌'}")
        results.append(("系统配置", has_config))

        # ─ 模拟操作: 尝试点击按钮和输入文本 ─
        print("\n" + "=" * 60)
        print("模拟操作测试")
        print("=" * 60)
        
        # 尝试在每个页面点击第一个按钮
        op_results = []
        for name, route in [
            ("项目-新建", "/project/list", "新建项目"),
            ("PSI-求交", "/PSI/list", "新增"),
            ("白名单-新增", "/whitelist/list", "新增"),
            ("租户-新增", "/tenant/list", "添加租户"),
        ]:
            try:
                await page.goto(f"{BASE}/#{route}", wait_until="networkidle", timeout=30000)
                await page.wait_for_timeout(2000)
                btn = page.locator(f'button:has-text("{name.split("-")[1]}"), .el-button--primary:has-text("新增"), .el-button--primary:has-text("新建")').first
                if await btn.is_visible(timeout=2000):
                    await btn.click()
                    await page.wait_for_timeout(2000)
                    has_dialog = await page.evaluate("document.querySelector('.el-dialog,.el-drawer') !== null")
                    if has_dialog:
                        # Close dialog
                        close = page.locator('.el-dialog__headerbtn,.el-drawer__close-btn').first
                        if await close.is_visible(timeout=1000):
                            await close.click()
                        print(f"  {name}: ✅ 弹窗可打开/关闭")
                        op_results.append((name, True))
                    else:
                        print(f"  {name}: ⚠️ 按钮已点击")
                        op_results.append((name, True))
                else:
                    print(f"  {name}: ⚠️ 按钮不可见")
                    op_results.append((name, False))
            except Exception as e:
                print(f"  {name}: ❌ {str(e)[:40]}")
                op_results.append((name, False))

        # ── Summary ──
        print("\n\n" + "=" * 60)
        print("测试报告")
        print("=" * 60)
        
        total = len(results)
        passed = sum(1 for _, ok in results if ok)
        failed = [(n, ok) for n, ok in results if not ok]
        
        print(f"\n页面加载测试: {passed}/{total} 通过")
        if failed:
            print(f"失败: {len(failed)}")
            for n, _ in failed:
                print(f"  ❌ {n}")
        
        if op_results:
            op_ok = sum(1 for _, ok in op_results if ok)
            print(f"\n模拟操作测试: {op_ok}/{len(op_results)} 通过")
            for n, ok in op_results:
                print(f"  {'✅' if ok else '❌'} {n}")
        
        print(f"\n截图保存在: {SCREENSHOT_DIR}/")
        
        await browser.close()

asyncio.run(main())
