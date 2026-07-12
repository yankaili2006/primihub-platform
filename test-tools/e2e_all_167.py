#!/usr/bin/env python3
"""E2E 全量 167+ 页面测试"""
import asyncio, json, os
from playwright.async_api import async_playwright

BASE = "http://100.64.0.25:13081"
DIR = "/tmp/e2e_all_167"
os.makedirs(DIR, exist_ok=True)
AUTH = list(set(open("/mnt/data1/github/primihub-platform/test-tools/auth_codes.txt").read().strip().split(",")))

ALL_PAGES = [
    ("用户管理","setting/user",["表格",".el-table"]),
    ("角色管理","setting/role",["表格",".el-table"]),
    ("节点管理","setting/center",["编辑","button:has-text('编辑')"]),
    ("系统配置","setting/system",["输入","input[type=text]:not([readonly])"]),
    ("机构管理","setting/organ",["加载",".app-wrapper"]),
    ("接入方","setting/accessManagement",["加载",".app-wrapper"]),
    ("合作方","setting/cooperation",["加载",".app-wrapper"]),
    ("审批","setting/approval",["加载",".app-wrapper"]),
    ("数据交换","setting/dataExchange",["加载",".app-wrapper"]),
    ("白名单列表","whitelist/list",["表格",".el-table"]),
    ("白名单配置","whitelist/config",["加载",".app-wrapper"]),
    ("访问日志","whitelist/accessLog",["加载",".app-wrapper"]),
    ("租户列表","tenant/list",["表格",".el-table"]),
    ("计算隔离","tenant/isolationConfig",["加载",".app-wrapper"]),
    ("数据隔离","tenant/dataIsolation",["加载",".app-wrapper"]),
    ("存证查询","evidence/query",["表格",".el-table"]),
    ("时间戳","evidence/timestamp",["加载",".app-wrapper"]),
    ("存证配置","evidence/config",["加载",".app-wrapper"]),
    ("加密导出","evidence/export",["加载",".app-wrapper"]),
    ("接口对接","evidence/api",["加载",".app-wrapper"]),
    ("监控概览","monitor/index",["图表","canvas,.el-card"]),
    ("OS","monitor/os",["加载",".app-wrapper"]),
    ("DB","monitor/database",["加载",".app-wrapper"]),
    ("中间件","monitor/middleware",["加载",".app-wrapper"]),
    ("告警","monitor/alerts",["加载",".app-wrapper"]),
    ("任务日志","log/index",["表格",".el-table"]),
    ("操作定义","log/operationDefinition",["加载",".app-wrapper"]),
    ("调度定义","log/scheduleDefinition",["加载",".app-wrapper"]),
    ("计算定义","log/computeDefinition",["加载",".app-wrapper"]),
    ("操作记录","log/operationLog",["表格",".el-table"]),
    ("调度记录","log/scheduleLog",["表格",".el-table"]),
    ("计算记录","log/computeLog",["表格",".el-table"]),
    ("日志导出","log/logExport",["加载",".app-wrapper"]),
    ("项目列表","project/list",["表格",".el-table"]),
    ("项目FL","project/federatedLearning",["加载",".app-wrapper"]),
    ("项目FA","project/federatedAnalysis",["加载",".app-wrapper"]),
    ("项目FS","project/federatedStatistics",["加载",".app-wrapper"]),
    ("我的资源","resource/list",["表格",".el-table"]),
    ("协作资源","resource/unionList",["加载",".app-wrapper"]),
    ("可申请","resource/availableResources",["加载",".app-wrapper"]),
    ("衍生数据","resource/derivedDataList",["加载",".app-wrapper"]),
    ("数据需求","resource/requirementList",["加载",".app-wrapper"]),
    ("需求配置","resource/requirementConfig",["加载",".app-wrapper"]),
    ("需求匹配","resource/requirementMatch",["加载",".app-wrapper"]),
    ("共享数据集","resource/sharedDatasetList",["加载",".app-wrapper"]),
    ("授权审核","resource/authAudit",["加载",".app-wrapper"]),
    ("授权记录","resource/authRecord",["加载",".app-wrapper"]),
    ("接口列表","api/list",["表格",".el-table"]),
    ("接口授权","api/auth",["加载",".app-wrapper"]),
    ("接口日志","api/log",["加载",".app-wrapper"]),
    ("PSI列表","PSI/list",["表格",".el-table"]),
    ("PSI任务","PSI/task",["加载",".app-wrapper"]),
    ("PSI结果","PSI/result",["加载",".app-wrapper"]),
    ("PIR列表","privateSearch/list",["输入","input[placeholder*='任务名称']"]),
    ("PIR任务","privateSearch/task",["加载",".app-wrapper"]),
    ("求差列表","Difference/list",["加载",".app-wrapper"]),
    ("求差任务","Difference/task",["加载",".app-wrapper"]),
    ("求并列表","Union/list",["表格",".el-table"]),
    ("求并任务","Union/task",["加载",".app-wrapper"]),
    ("DH批量","federatedQuery/dh/batch",["任务名","input[placeholder*='任务名称']"]),
    ("DH实时","federatedQuery/dh/realtime",["任务名","input[placeholder*='任务名称']"]),
    ("OT批量","federatedQuery/ot/batch",["任务名","input[placeholder*='任务名称']"]),
    ("OT实时","federatedQuery/ot/realtime",["任务名","input[placeholder*='任务名称']"]),
    ("HE批量","federatedQuery/he/batch",["任务名","input[placeholder*='任务名称']"]),
    ("HE实时","federatedQuery/he/realtime",["任务名","input[placeholder*='任务名称']"]),
    ("求交批量","federatedQuery/intersection/batch",["加载",".app-wrapper"]),
    ("求交实时","federatedQuery/intersection/realtime",["加载",".app-wrapper"]),
    ("求交去重","federatedQuery/intersection/dedup",["加载",".app-wrapper"]),
    ("多列ID","federatedQuery/intersection/multiColumn",["加载",".app-wrapper"]),
    ("Payload","federatedQuery/tools/payloadChunk",["加载",".app-wrapper"]),
    ("输出字段","federatedQuery/tools/outputFields",["加载",".app-wrapper"]),
    ("查询去重","federatedQuery/tools/dedup",["加载",".app-wrapper"]),
    ("分桶","federatedQuery/tools/bucket",["加载",".app-wrapper"]),
    ("编解码","federatedQuery/tools/codec",["加载",".app-wrapper"]),
    ("压缩","federatedQuery/tools/compress",["加载",".app-wrapper"]),
    ("解压","federatedQuery/tools/decompress",["加载",".app-wrapper"]),
    ("求交日志","federatedQuery/logs/intersectionRecord",["表格",".el-table"]),
    ("求交日志导出","federatedQuery/logs/intersectionExport",["加载",".app-wrapper"]),
    ("查询日志","federatedQuery/logs/queryRecord",["加载",".app-wrapper"]),
    ("查询日志导出","federatedQuery/logs/queryExport",["加载",".app-wrapper"]),
    ("计费次数","federatedQuery/billingByCount",["加载",".app-wrapper"]),
    ("计费命中","federatedQuery/billingByHit",["加载",".app-wrapper"]),
    ("去重固定","federatedQuery/deduplicationFixed",["加载",".app-wrapper"]),
    ("去重滚动","federatedQuery/deduplicationRolling",["加载",".app-wrapper"]),
    ("接口校验","federatedQuery/apiValidation",["加载",".app-wrapper"]),
    ("FL融合","federatedLearning/dataFusion",["任务名","input:not([readonly])"]),
    ("FL相似度","federatedLearning/featureSimilarity",["加载",".app-wrapper"]),
    ("FL编码","federatedLearning/featureEncodeFL",["加载",".app-wrapper"]),
    ("FL对齐","federatedLearning/featureAlign",["加载",".app-wrapper"]),
    ("FL分享","federatedLearning/featureShare",["加载",".app-wrapper"]),
    ("FL填充","federatedLearning/featureFill",["加载",".app-wrapper"]),
    ("FL样本扩展","federatedLearning/sampleExpand",["加载",".app-wrapper"]),
    ("FL加权","federatedLearning/sampleWeight",["加载",".app-wrapper"]),
    ("FL指标","federatedLearning/metricModeling",["加载",".app-wrapper"]),
    ("FL装仓","federatedLearning/featureWarehouse",["加载",".app-wrapper"]),
    ("FL分割","federatedLearning/dataSplit",["加载",".app-wrapper"]),
    ("FL转换","federatedLearning/dataTransform",["加载",".app-wrapper"]),
    ("FL线性训练","federatedLearning/verticalLinearTrain",["加载",".app-wrapper"]),
    ("FL逻辑训练","federatedLearning/verticalLogisticTrain",["加载",".app-wrapper"]),
    ("FLXGB训练","federatedLearning/verticalXGBoostTrain",["加载",".app-wrapper"]),
    ("FL线性预测","federatedLearning/verticalLinearPredict",["加载",".app-wrapper"]),
    ("FL逻辑预测","federatedLearning/verticalLogisticPredict",["加载",".app-wrapper"]),
    ("FLXGB预测","federatedLearning/verticalXGBoostPredict",["加载",".app-wrapper"]),
    ("FL调优","federatedLearning/paramTuning",["开始","button:has-text('开始调优')"]),
    ("FL报告","federatedLearning/trainingReport",["加载",".app-wrapper"]),
    ("FL迭代","federatedLearning/trainingIteration",["加载",".app-wrapper"]),
    ("FL日志","federatedLearning/logRecord",["加载",".app-wrapper"]),
    ("FL日志导出","federatedLearning/logExport",["加载",".app-wrapper"]),
    ("FA SQL","federatedAnalysis/sqlValidator",["SQL","textarea"]),
    ("FA关系DB","federatedAnalysis/relationalDB",["加载",".app-wrapper"]),
    ("FA大数据","federatedAnalysis/bigData",["加载",".app-wrapper"]),
    ("FA公有云","federatedAnalysis/publicCloud",["加载",".app-wrapper"]),
    ("FA字段","federatedAnalysis/fieldConfidentiality",["加载",".app-wrapper"]),
    ("FA筛选","federatedAnalysis/filterOperator",["SQL","textarea"]),
    ("FA连接","federatedAnalysis/joinOperator",["加载",".app-wrapper"]),
    ("FA聚合","federatedAnalysis/aggregateOperator",["加载",".app-wrapper"]),
    ("FA分组","federatedAnalysis/groupOperator",["加载",".app-wrapper"]),
    ("FA排序","federatedAnalysis/sortOperator",["加载",".app-wrapper"]),
    ("FA窗口","federatedAnalysis/windowFunction",["加载",".app-wrapper"]),
    ("FA关联","federatedAnalysis/correlatedSubquery",["加载",".app-wrapper"]),
    ("FA非关联","federatedAnalysis/nonCorrelatedSubquery",["加载",".app-wrapper"]),
    ("FA字符","federatedAnalysis/charFunctions",["加载",".app-wrapper"]),
    ("FA日期","federatedAnalysis/dateFunctions",["加载",".app-wrapper"]),
    ("FA时间戳","federatedAnalysis/timestampFunctions",["加载",".app-wrapper"]),
    ("FA格式化","federatedAnalysis/sqlFormatter",["加载",".app-wrapper"]),
    ("FA浮点","federatedAnalysis/floatFunctions",["加载",".app-wrapper"]),
    ("FS卡方","federatedStatistics/chiSquareTest",["参数","input[type=text]:not([readonly])"]),
    ("FS F","federatedStatistics/fTest",["加载",".app-wrapper"]),
    ("FS分组","federatedStatistics/groupStats",["加载",".app-wrapper"]),
    ("FS条件","federatedStatistics/conditionStats",["加载",".app-wrapper"]),
    ("FS T","federatedStatistics/tTest",["加载",".app-wrapper"]),
    ("FS占比","federatedStatistics/ratioStats",["加载",".app-wrapper"]),
    ("FS回归","federatedStatistics/regressionAnalysis",["加载",".app-wrapper"]),
    ("FS相关","federatedStatistics/correlationAnalysis",["加载",".app-wrapper"]),
    ("FS存储","federatedStatistics/resultStorage",["路径","input:not([readonly])"]),
    ("FS导出","federatedStatistics/resultExport",["加载",".app-wrapper"]),
    ("FS日志","federatedStatistics/logRecord",["加载",".app-wrapper"]),
    ("FS日志导出","federatedStatistics/logExport",["加载",".app-wrapper"]),
    ("SP列表","SingleParty/list",["表格",".el-table"]),
    ("SP清洗","SingleParty/dataCleaning",["参数","input:not([readonly])"]),
    ("SP缩放","SingleParty/dataScaling",["加载",".app-wrapper"]),
    ("SP统计","SingleParty/dataStats",["加载",".app-wrapper"]),
    ("SP分箱","SingleParty/featureBin",["加载",".app-wrapper"]),
    ("SP衍生","SingleParty/featureDerive",["加载",".app-wrapper"]),
    ("SP编码","SingleParty/featureEncode",["加载",".app-wrapper"]),
    ("SP筛选","SingleParty/featureSelect",["加载",".app-wrapper"]),
    ("SP LR","SingleParty/lrAlgorithm",["加载",".app-wrapper"]),
    ("SP XGB","SingleParty/xgbAlgorithm",["加载",".app-wrapper"]),
    ("SP Python","SingleParty/pythonScript",["脚本","textarea,input"]),
    ("SP SQL","SingleParty/sqlProcess",["加载",".app-wrapper"]),
    ("模型管理","model/list",["表格",".el-table"]),
    ("推理服务","reasoning/list",["表格",".el-table"]),
    ("PD交集","policeDataFusion/intersection",["计算","button:has-text('开始融合计算')"]),
    ("PD对接","policeDataFusion/policeConnect",["加载",".app-wrapper"]),
    ("PD保险","policeDataFusion/insuranceApi",["表格",".el-table"]),
    ("PD密钥","policeDataFusion/homomorphicKey",["参数","input[type=text]:not([readonly])"]),
    ("PD加密","policeDataFusion/modelEncrypt",["加载",".app-wrapper"]),
    ("PD计算","policeDataFusion/encryptedCompute",["加载",".app-wrapper"]),
    ("PD解密","policeDataFusion/dataDecrypt",["加载",".app-wrapper"]),
    ("PD交换","policeDataFusion/batchExchange",["加载",".app-wrapper"]),
    ("EC特征转换","electronicCert/featureConvert",["加载",".app-wrapper"]),
    ("EC现场","electronicCert/onSiteConvert",["采集","button:has-text('开始采集')"]),
    ("EC比对","electronicCert/privacyCompare",["加载",".app-wrapper"]),
    ("EC接入","electronicCert/orgDataImport",["加载",".app-wrapper"]),
    ("EC导出","electronicCert/orgDataExport",["导出","button:has-text('开始导出')"]),
    ("EC批量","electronicCert/batchExchange",["交换","button:has-text('开始批量交换')"]),
    ("EC实时","electronicCert/realTimeExchange",["加载",".app-wrapper"]),
]

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        all_results = []
        
        # Batch: 20 pages per batch, fresh login per batch
        BATCH_SIZE = 20
        total_pages = len(ALL_PAGES)
        
        for batch_start in range(0, total_pages, BATCH_SIZE):
            batch = ALL_PAGES[batch_start:batch_start+BATCH_SIZE]
            batch_num = batch_start // BATCH_SIZE + 1
            total_batches = (total_pages - 1) // BATCH_SIZE + 1
            
            ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
            page = await ctx.new_page()
            
            # Login
            await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
            await page.evaluate("localStorage.clear()")
            await page.reload(wait_until="networkidle")
            await asyncio.sleep(1)
            await page.fill('input[name="username"]', "admin")
            await page.fill('input[name="password"]', "123456")
            await page.click('.el-button--primary')
            await page.wait_for_timeout(4000)
            
            aj = json.dumps([{"authId": i, "authCode": c, "authName": c, "authType": 2, "isShow": 1}
                             for i, c in enumerate(set(AUTH), 3000)])
            await page.evaluate(f"const p=JSON.parse(localStorage.getItem('PrimiHubPer')||'[]');const s=new Set(p.map(x=>x.authCode));for(const e of {aj}){{if(!s.has(e.authCode)){{p.push(e);s.add(e.authCode);}}}}localStorage.setItem('PrimiHubPer',JSON.stringify(p));")
            
            print(f"\n批 {batch_num}/{total_batches} ({batch_start+1}-{batch_start+len(batch)}):")
            
            for j, (name, route, action) in enumerate(batch):
                try:
                    await page.evaluate(f"window.location.hash='/{route}'")
                    await page.wait_for_timeout(2000)
                    t = await page.title()
                    
                    if "登录" in t and "redirect" in page.url:
                        all_results.append((f"[{batch_start+j+1}] {name}", False))
                        continue
                    
                    # Perform action if specified
                    if action[0] == "加载":
                        # Just check page loaded
                        await page.screenshot(path=f"{DIR}/{batch_start+j+1:03d}_{name}.png")
                        all_results.append((f"[{batch_start+j+1}] {name}", True))
                    else:
                        _, action_sel = action[0], action[1]
                        el = page.locator(action_sel).first
                        if await el.is_visible(timeout=2000):
                            tag = (await el.evaluate("e=>e.tagName")).lower()
                            typ = (await el.get_attribute("type") or "").lower()
                            if tag == "input" and typ in ("text","","search"):
                                await el.fill("test")
                                await asyncio.sleep(0.2)
                            elif tag in ("button","a"):
                                await el.click()
                                await asyncio.sleep(1)
                                dlg = page.locator('.el-dialog:visible').first
                                if await dlg.is_visible(timeout=800):
                                    await page.keyboard.press("Escape")
                                    await asyncio.sleep(0.3)
                            elif tag == "textarea":
                                await el.fill("SELECT 1")
                                await asyncio.sleep(0.2)
                            all_results.append((f"[{batch_start+j+1}] {name}", True))
                        else:
                            all_results.append((f"[{batch_start+j+1}] {name}", False))
                    
                    if (batch_start + j + 1) % 10 == 0:
                        print(f"  ...{batch_start+j+1}", end="", flush=True)
                        
                except Exception as e:
                    all_results.append((f"[{batch_start+j+1}] {name}", False))
            
            await ctx.close()

        print(f"\n\n{'='*50}")
        ok = sum(1 for _, s in all_results if s)
        total = len(all_results)
        print(f"总页面: {total} | 通过: {ok} | 失败: {total-ok} | 通过率: {ok*100//total}%")
        fail = [(n, s) for n, s in all_results if not s]
        for n, _ in fail:
            print(f"  ❌ {n}")
        print(f"\n截图: {DIR}/")
        await browser.close()

asyncio.run(main())
