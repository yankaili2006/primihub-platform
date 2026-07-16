#!/usr/bin/env python3
# Functional smoke test for v1.8.0 — runs ON the VM (localhost:30811).
# Logs in as admin, then exercises feature endpoints; flags any SQL-shape failure
# (Table doesn't exist / Unknown column / truncation) and confirms the previously-buggy
# create flows now work.
import json, urllib.request, urllib.parse, base64, subprocess, tempfile, os, time
B="http://127.0.0.1:30811"; USER="admin"; PWD="123456"

def http(path, method="GET", form=None, jb=None, hdr=None):
    h=dict(hdr or {}); data=None
    if form is not None: data=urllib.parse.urlencode(form).encode(); h["Content-Type"]="application/x-www-form-urlencoded"
    elif jb is not None: data=json.dumps(jb).encode(); h["Content-Type"]="application/json"
    try:
        return json.load(urllib.request.urlopen(urllib.request.Request(B+path,data=data,headers=h,method=method),timeout=25))
    except Exception as e:
        return {"code":-1,"msg":str(e)[:160]}

# ---- login ----
pk=http("/prod-api/sys/common/getValidatePublicKey")["result"]
pem="-----BEGIN PUBLIC KEY-----\n"+"\n".join(pk["publicKey"][i:i+64] for i in range(0,len(pk["publicKey"]),64))+"\n-----END PUBLIC KEY-----\n"
with tempfile.NamedTemporaryFile("w",suffix=".pem",delete=False) as f: f.write(pem); pf=f.name
enc=base64.b64encode(subprocess.run(["openssl","pkeyutl","-encrypt","-pubin","-inkey",pf,"-pkeyopt","rsa_padding_mode:pkcs1"],input=PWD.encode(),stdout=subprocess.PIPE).stdout).decode()
os.unlink(pf)
lr=http("/prod-api/sys/user/login","POST",form={"userAccount":USER,"userPassword":enc,"validateKeyName":pk["publicKeyName"]})
assert lr.get("code")==0, "login failed: %s"%lr
TOKEN=lr["result"]["token"]; UID=lr["result"]["sysUser"].get("userId",1)
print("login OK, token len=%d userId=%s"%(len(TOKEN),UID))
HDR={"Authorization":TOKEN,"token":TOKEN}
def bp(extra=None):
    d={"timestamp":str(int(time.time()*1000)),"nonce":"flchk","token":TOKEN}
    if extra: d.update(extra)
    return d

def is_sql_err(r):
    m=(r.get("msg") or "")+json.dumps(r.get("result") or "")
    return any(s in m for s in ["doesn't exist","Unknown column","Data truncation","SQLSyntax","bad SQL","Incorrect integer"])

def _rep(label,r):
    code=r.get("code"); msg=(r.get("msg") or "")[:60]
    if is_sql_err(r): print("  \033[31mSQL-ERR\033[0m %-42s code=%s %s"%(label,code,msg))
    elif code==0:     print("  \033[32mOK    \033[0m %-42s"%label)
    else:             print("  \033[33mbiz   \033[0m %-42s code=%s %s"%(label,code,msg))
    return not is_sql_err(r)

def check(label, path, body=None):   # POST JSON (BaseParam+body in body)
    return _rep(label, http("/prod-api"+path,"POST",jb=bp(body),hdr=HDR))

def checkGet(label, path, params=None): # GET (BaseParam+params in query)
    q=bp(params); return _rep(label, http("/prod-api"+path+"?"+urllib.parse.urlencode(q),"GET",hdr=HDR))

print("\n== [A] list/query endpoints across modules (schema-drift regression) ==")
LISTS=[
 ("data resource",           "/data/resource/getdataresourcelist"),
 ("project list",            "/data/project/getProjectList"),
 ("model list",              "/data/model/getmodellist"),
 ("psi task",                "/data/psi/getPsiTaskList"),
 ("pir task",                "/data/pir/getPirTaskList"),
 ("difference task",         "/data/difference/getDifferenceTaskList"),
 ("union task",              "/data/union/getUnionTaskList"),
 ("reasoning list",          "/data/reasoning/getReasoningList"),
 ("federated analysis task", "/data/federatedAnalysis/task/list"),
 ("federated stats task",    "/data/federatedStatistics/task/list"),
 ("federated learning models","/federatedLearning/getModelList"),
 ("federated billing rule",  "/federatedBilling/rule/list"),
 ("data requirement page",   "/dataRequirement/findDataRequirementPage"),
 ("evidence page",           "/evidence/findEvidencePage"),
 ("evidence chain",          "/evidence/getChainList"),
 ("api manage page",         "/apiManage/findApiPage"),
 ("api log page",            "/apiManage/findApiLogPage"),
 ("data share list",         "/dataShare/list"),
]
okc=badc=0
for lbl,p in LISTS:
    if checkGet(lbl,p,{"pageNo":1,"pageSize":5}): okc+=1
    else: badc+=1

print("\n== [B] previously-buggy CREATE flows (regression) ==")
ts=str(int(time.time()))
b_ok=b_bad=0
# add user (first_login)
if check("add user (first_login)","/sys/user/saveOrUpdateUser",{"userAccount":"flchk_%s"%ts,"userName":"flchk","userPassword":"x","roleIdList":"1","phone":"","email":""}): b_ok+=1
else: b_bad+=1
# add operation log definition (log_type varchar)
if check("add operation-log def (log_type)","/log/addOperationLogDefinition",{"logCode":"FLCHK_%s"%ts,"logName":"flchk","logType":"登出","moduleName":"sys","description":"x","isEnabled":1,"retentionDays":30}): b_ok+=1
else: b_bad+=1
# create approval workflow (workflowTitle)
if check("create approval workflow (title)","/node/approval/createWorkflow",{"workflowTitle":"flchk_%s"%ts,"workflowType":"OTHER","priority":3,"requestDescription":"x","requesterId":UID,"requesterName":"admin"}): b_ok+=1
else: b_bad+=1
# create organ node
if check("create organ node","/organ/createOrganNode",{"organId":"flchk_%s"%ts,"organName":"flchk","gatewayAddress":"1.2.3.4:5","publicKey":"x"}): b_ok+=1
else: b_bad+=1

print("\n== SUMMARY ==")
print("lists: %d clean / %d SQL-error"%(okc,badc))
print("creates: %d no-SQL-error / %d SQL-error"%(b_ok,b_bad))
print("FUNCTIONAL_VERIFY_DONE sql_errors=%d"%(badc+b_bad))

print("\n== [C] create/save endpoints across modules (INSERT-path drift scan) ==")
ts2=str(int(time.time()))
CREATE=[
 ("save data resource",     "/data/resource/saveorupdateresource", {"resourceName":"flc","resourceType":1,"fileId":"x"}),
 ("save project",           "/data/project/saveOrUpdateProject",   {"projectName":"flc_%s"%ts2,"resourceList":[]}),
 ("save model",             "/data/model/savemodel",               {"modelName":"flc","projectId":"1"}),
 ("save psi resource",      "/data/psi/saveOrUpdatePsiResource",   {"resourceId":"x"}),
 ("save difference",        "/data/difference/saveDataDifference", {"taskName":"flc"}),
 ("save union",             "/data/union/saveDataUnion",           {"taskName":"flc"}),
 ("save reasoning",         "/data/reasoning/saveReasoning",       {"reasoningName":"flc"}),
 ("fed-analysis datasource","/data/federatedAnalysis/datasource/create",{"name":"flc","sourceType":1}),
 ("fed-analysis task",      "/data/federatedAnalysis/task/create", {"taskName":"flc"}),
 ("fed-stats task",         "/data/federatedStatistics/task/create",{"taskName":"flc"}),
 ("fed-billing rule",       "/federatedBilling/rule/create",       {"ruleName":"flc"}),
 ("fed-learning task",      "/federatedLearning/createTask",       {"taskName":"flc"}),
 ("fed-learning workflow",  "/federatedLearning/workflow/save",    {"workflowName":"flc"}),
 ("evidence create",        "/evidence/createEvidence",            {"evidenceName":"flc"}),
 ("evidence config",        "/evidence/saveEvidenceConfig",        {"configKey":"flc"}),
 ("monitor alert config",   "/monitor/saveAlertConfig",            {"alertName":"flc","duration":5}),
 ("node access party",      "/node/access/addAccessParty",         {"partyName":"flc"}),
 ("add compute-log def",    "/log/addComputeLogDefinition",        {"logCode":"C_%s"%ts2,"logName":"flc","computeType":"PSI","moduleName":"m","isEnabled":1,"retentionDays":30}),
 ("add schedule-log def",   "/log/addScheduleLogDefinition",       {"logCode":"S_%s"%ts2,"logName":"flc","scheduleType":"CRON","moduleName":"m","isEnabled":1,"retentionDays":30}),
 ("data requirement add",   "/dataRequirement/addDataRequirement", {"requirementName":"flc"}),
 ("project permission add", "/project/permission/add",             {"projectId":"1","permission":"read"}),
 ("police datasource save", "/policeFusion/datasource/save",       {"name":"flc","gatewayAddress":"1.2.3.4"}),
 ("api manage add",         "/apiManage/addApi",                   {"apiName":"flc","apiPath":"/x"}),
]
c_ok=c_sql=0
for lbl,p,body in CREATE:
    if check(lbl,p,body): c_ok+=1
    else: c_sql+=1
print("\ncreate/save: %d no-SQL-error / %d SQL-error"%(c_ok,c_sql))
print("CREATE_BATTERY_DONE sql_errors=%d"%c_sql)
