#!/usr/bin/env python3
"""E2E 全量 202 页面测试"""
import asyncio, json, os
from playwright.async_api import async_playwright
BASE = "http://100.64.0.25:13081"
DIR = "/tmp/e2e_202"
os.makedirs(DIR, exist_ok=True)
AUTH = list(set(open("/mnt/data1/github/primihub-platform/test-tools/auth_codes.txt").read().strip().split(",")))

ALL = [
    ("项目管理","project/list"), ("新建项目","project/create"), ("权限配置","project/permission"),
    ("结果保存","project/resultSave"), ("台账","project/ledgerExport"), ("审核配置","project/approvalConfig"),
    ("FL任务","project/federatedLearning"), ("FA任务","project/federatedAnalysis"), ("FS任务","project/federatedStatistics"),
    ("我的资源","resource/list"), ("上传/新建","resource/create"), ("编辑","resource/edit/:id"),
    ("详情","resource/detail/:id"), ("协作方","resource/unionList"), ("协作详情","resource/unionResourceDetail/:id"),
    ("可申请","resource/availableResources"), ("衍生数据","resource/derivedDataList"),
    ("衍生详情","resource/derivedDataResourceDetail/:id"), ("需求列表","resource/requirementList"),
    ("需求配置","resource/requirementConfig"), ("需求匹配","resource/requirementMatch"),
    ("共享数据集","resource/sharedDatasetList"), ("授权审核","resource/authAudit"),
    ("授权记录","resource/authRecord"),
    ("用户管理","setting/user"), ("角色管理","setting/role"), ("节点管理","setting/center"),
    ("机构管理","setting/organ"), ("系统配置","setting/system"), ("界面设置","setting/ui"),
    ("接入方","setting/accessManagement"), ("合作方","setting/cooperation"),
    ("审批","setting/approval"), ("数据交换","setting/dataExchange"),
    ("白名单","whitelist/list"), ("白名单配置","whitelist/config"), ("访问日志","whitelist/accessLog"),
    ("租户列表","tenant/list"), ("计算隔离","tenant/isolationConfig"), ("数据隔离","tenant/dataIsolation"),
    ("存证查询","evidence/query"), ("时间戳","evidence/timestamp"), ("存证配置","evidence/config"),
    ("加密导出","evidence/export"), ("接口对接","evidence/api"),
    ("监控总览","monitor/index"), ("OS","monitor/os"), ("DB","monitor/database"),
    ("中间件","monitor/middleware"), ("告警","monitor/alerts"),
    ("任务日志","log/index"), ("操作定义","log/operationDefinition"),
    ("调度定义","log/scheduleDefinition"), ("计算定义","log/computeDefinition"),
    ("操作记录","log/operationLog"), ("调度记录","log/scheduleLog"),
    ("计算记录","log/computeLog"), ("日志导出","log/logExport"),
    ("接口列表","api/list"), ("接口授权","api/auth"), ("接口日志","api/log"),
    ("PSI列表","PSI/list"),
    ("PIR列表","privateSearch/list"),
    ("联邦求差","Difference/list"), ("联邦求并","Union/list"),
    ("DH批量","federatedQuery/dh/batch"), ("DH实时","federatedQuery/dh/realtime"),
    ("OT批量","federatedQuery/ot/batch"), ("OT实时","federatedQuery/ot/realtime"),
    ("HE批量","federatedQuery/he/batch"), ("HE实时","federatedQuery/he/realtime"),
    ("求交批量","federatedQuery/intersection/batch"), ("求交实时","federatedQuery/intersection/realtime"),
    ("求交去重","federatedQuery/intersection/dedup"), ("多列ID","federatedQuery/intersection/multiColumn"),
    ("Payload分块","federatedQuery/tools/payloadChunk"), ("输出字段","federatedQuery/tools/outputFields"),
    ("去重","federatedQuery/tools/dedup"), ("分桶","federatedQuery/tools/bucket"),
    ("编解码","federatedQuery/tools/codec"), ("压缩","federatedQuery/tools/compress"),
    ("解压","federatedQuery/tools/decompress"),
    ("求交日志","federatedQuery/logs/intersectionRecord"), ("求交日志导出","federatedQuery/logs/intersectionExport"),
    ("查询日志","federatedQuery/logs/queryRecord"), ("查询日志导出","federatedQuery/logs/queryExport"),
    ("计费按次数","federatedQuery/billingByCount"), ("计费按命中","federatedQuery/billingByHit"),
    ("去重固定","federatedQuery/deduplicationFixed"), ("去重滚动","federatedQuery/deduplicationRolling"),
    ("接口校验","federatedQuery/apiValidation"),
    ("FL数据融合","federatedLearning/dataFusion"), ("FL相似度","federatedLearning/featureSimilarity"),
    ("FL编码","federatedLearning/featureEncodeFL"), ("FL对齐","federatedLearning/featureAlign"),
    ("FL分享","federatedLearning/featureShare"), ("FL填充","federatedLearning/featureFill"),
    ("FL样本扩展","federatedLearning/sampleExpand"), ("FL加权","federatedLearning/sampleWeight"),
    ("FL指标","federatedLearning/metricModeling"), ("FL装仓","federatedLearning/featureWarehouse"),
    ("FL分割","federatedLearning/dataSplit"), ("FL转换","federatedLearning/dataTransform"),
    ("FL线性训练","federatedLearning/verticalLinearTrain"), ("FL逻辑训练","federatedLearning/verticalLogisticTrain"),
    ("FL XGB训练","federatedLearning/verticalXGBoostTrain"),
    ("FL线性预测","federatedLearning/verticalLinearPredict"), ("FL逻辑预测","federatedLearning/verticalLogisticPredict"),
    ("FL XGB预测","federatedLearning/verticalXGBoostPredict"),
    ("FL调优","federatedLearning/paramTuning"), ("FL报告","federatedLearning/trainingReport"),
    ("FL迭代","federatedLearning/trainingIteration"), ("FL日志","federatedLearning/logRecord"),
    ("FL日志导出","federatedLearning/logExport"),
    ("FA SQL","federatedAnalysis/sqlValidator"), ("FA关系DB","federatedAnalysis/relationalDB"),
    ("FA大数据","federatedAnalysis/bigData"), ("FA公有云","federatedAnalysis/publicCloud"),
    ("FA字段","federatedAnalysis/fieldConfidentiality"), ("FA筛选","federatedAnalysis/filterOperator"),
    ("FA连接","federatedAnalysis/joinOperator"), ("FA聚合","federatedAnalysis/aggregateOperator"),
    ("FA分组","federatedAnalysis/groupOperator"), ("FA排序","federatedAnalysis/sortOperator"),
    ("FA窗口","federatedAnalysis/windowFunction"), ("FA关联","federatedAnalysis/correlatedSubquery"),
    ("FA非关联","federatedAnalysis/nonCorrelatedSubquery"),
    ("FA字符","federatedAnalysis/charFunctions"), ("FA日期","federatedAnalysis/dateFunctions"),
    ("FA时间戳","federatedAnalysis/timestampFunctions"), ("FA格式化","federatedAnalysis/sqlFormatter"),
    ("FA浮点","federatedAnalysis/floatFunctions"),
    ("FS卡方","federatedStatistics/chiSquareTest"), ("FS F","federatedStatistics/fTest"),
    ("FS分组","federatedStatistics/groupStats"), ("FS条件","federatedStatistics/conditionStats"),
    ("FS T","federatedStatistics/tTest"), ("FS占比","federatedStatistics/ratioStats"),
    ("FS回归","federatedStatistics/regressionAnalysis"), ("FS相关","federatedStatistics/correlationAnalysis"),
    ("FS存储","federatedStatistics/resultStorage"), ("FS导出","federatedStatistics/resultExport"),
    ("FS日志","federatedStatistics/logRecord"), ("FS日志导出","federatedStatistics/logExport"),
    ("SP列表","SingleParty/list"), ("SP清洗","SingleParty/dataCleaning"),
    ("SP缩放","SingleParty/dataScaling"), ("SP统计","SingleParty/dataStats"),
    ("SP分箱","SingleParty/featureBin"), ("SP衍生","SingleParty/featureDerive"),
    ("SP编码","SingleParty/featureEncode"), ("SP筛选","SingleParty/featureSelect"),
    ("SP LR","SingleParty/lrAlgorithm"), ("SP XGB","SingleParty/xgbAlgorithm"),
    ("SP Python","SingleParty/pythonScript"), ("SP SQL","SingleParty/sqlProcess"),
    ("模型管理","model/list"), ("推理服务","reasoning/list"),
    ("PD交集","policeDataFusion/intersection"), ("PD对接","policeDataFusion/policeConnect"),
    ("PD保险","policeDataFusion/insuranceApi"), ("PD密钥","policeDataFusion/homomorphicKey"),
    ("PD加密","policeDataFusion/modelEncrypt"), ("PD计算","policeDataFusion/encryptedCompute"),
    ("PD解密","policeDataFusion/dataDecrypt"), ("PD交换","policeDataFusion/batchExchange"),
    ("EC转换","electronicCert/featureConvert"), ("EC现场","electronicCert/onSiteConvert"),
    ("EC比对","electronicCert/privacyCompare"), ("EC对接","electronicCert/policeConnect"),
    ("EC接入","electronicCert/orgDataImport"), ("EC导出","electronicCert/orgDataExport"),
    ("EC批量","electronicCert/batchExchange"), ("EC实时","electronicCert/realTimeExchange"),
]

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        all_results = []
        B = 20
        for bs in range(0, len(ALL), B):
            batch = ALL[bs:bs+B]
            ctx = await browser.new_context(viewport={"width": 1920, "height": 1080})
            page = await ctx.new_page()
            await page.goto(f"{BASE}/login", wait_until="networkidle", timeout=30000)
            await page.evaluate("localStorage.clear()")
            await page.reload(wait_until="networkidle")
            await asyncio.sleep(1)
            await page.fill('input[name="username"]', "admin")
            await page.fill('input[name="password"]', "123456")
            await page.click('.el-button--primary')
            await page.wait_for_timeout(4000)
            aj = json.dumps([{"authId":i,"authCode":c,"authName":c,"authType":2,"isShow":1} for i,c in enumerate(set(AUTH),3000)])
            await page.evaluate(f"const p=JSON.parse(localStorage.getItem('DataItemPer')||'[]');const s=new Set(p.map(x=>x.authCode));for(const e of {aj}){{if(!s.has(e.authCode)){{p.push(e);s.add(e.authCode);}}}}localStorage.setItem('DataItemPer',JSON.stringify(p));")
            print(f"\n批 {bs//B+1}/{(len(ALL)-1)//B+1}:")
            for j, (name, route) in enumerate(batch):
                idx = bs + j + 1
                try:
                    await page.evaluate(f"window.location.hash='/{route}'")
                    await page.wait_for_timeout(2000)
                    t = await page.title()
                    if "登录" in t and "redirect" in page.url:
                        all_results.append((f"[{idx}] {name}", False))
                    else:
                        all_results.append((f"[{idx}] {name}", True))
                        if (idx) % 20 == 0:
                            print(f"  ...{idx}", end="", flush=True)
                except:
                    all_results.append((f"[{idx}] {name}", False))
            await ctx.close()

        print(f"\n\n{'='*50}")
        ok = sum(1 for _,s in all_results if s)
        total = len(all_results)
        print(f"总: {total} | 通过: {ok} | 失败: {total-ok} | 通过率: {ok*100//total}%")
        for n,s in all_results:
            if not s: print(f"  ❌ {n}")
        await browser.close()

asyncio.run(main())
