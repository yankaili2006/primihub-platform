# PrimiHub 全新部署完整验证指南

## 前置条件

| 资源 | 要求 |
|------|------|
| PVE VM | Ubuntu 22.04+, 4核/8GB+/30GB |
| Docker | 20.10+ |
| 网络 | 可访问 GitHub (构建) 或离线镜像包 |

---

## 一、生成离线包

### 1. 构建代码

```bash
# 拉取最新代码
git clone https://github.com/yankaili2006/primihub-platform.git
cd primihub-platform
git checkout develop

# 构建 JAR
cd primihub-service
mvn clean package -DskipTests -Dmaven.test.skip=true -q
cd ..

# 构建 Docker 镜像
docker build -f Dockerfile -t primihub-platform:2.0.0 .
docker tag primihub-platform:2.0.0 primihub-platform:latest

# 构建其他镜像
docker build -f primihub-service/Dockerfile.ubuntu -t primihub-node:2.0.0 .
docker build -f primihub-webconsole/Dockerfile.local -t primihub-web:2.0.0 .
```

### 2. 打包离线包

```bash
cd /tmp
mkdir -p primihub-offline-v2.0.0/{images,scripts,config,initsql}

# 导出镜像
docker save primihub-platform:2.0.0 -o images/primihub-platform.tar
docker save primihub-node:2.0.0 -o images/primihub-node.tar
docker save primihub-web:2.0.0 -o images/primihub-web.tar
docker save primihub-meta:2.0.0 -o images/primihub-meta.tar
# 基础设施镜像
docker save registry.cn-beijing.aliyuncs.com/primihub/nacos-server:v2.0.4 -o images/nacos.tar
docker save registry.cn-beijing.aliyuncs.com/primihub/mysql:5.7 -o images/mysql.tar
docker save registry.cn-beijing.aliyuncs.com/primihub/redis:7 -o images/redis.tar
docker save registry.cn-beijing.aliyuncs.com/primihub/rabbitmq:3.6.15-management -o images/rabbitmq.tar
docker save registry.cn-beijing.aliyuncs.com/primihub/loki:latest -o images/loki.tar

# 复制部署脚本
cp primihub-platform/deploy-offline.sh scripts/
cp primihub-platform/docker-compose.yaml config/
cp -r primihub-platform/data/initsql/ initsql/

# 复制修复工具
cp primihub-platform/test-tools/fix-all.sh scripts/
cp primihub-platform/test-tools/init-privacy-db-tables.sql initsql/
cp primihub-platform/test-tools/setup-python-algorithms.sh scripts/
cp primihub-platform/test-tools/version-manager.sh scripts/

# 打包
tar czf primihub-offline-v2.0.0.tar.gz primihub-offline-v2.0.0/
```

---

## 二、新环境部署

### 1. 复制到新车

```bash
scp primihub-offline-v2.0.0.tar.gz root@<新VM_IP>:/root/
ssh root@<新VM_IP>
tar xzf primihub-offline-v2.0.0.tar.gz
cd primihub-offline-v2.0.0
```

### 2. 导入镜像

```bash
# 逐个导入
for img in images/*.tar; do
  docker load -i "$img"
done
```

### 3. 部署

```bash
# 执行官方部署脚本
bash scripts/deploy-offline.sh

# 执行一键修复脚本
bash scripts/fix-all.sh
```

---

## 三、完整验证 (223 功能点)

### 1. 基础验证

```bash
# 验证所有容器
docker ps --format "table {{.Names}}\t{{.Status}}"

# 验证数据库连接
docker logs application0 2>&1 | grep "Init Primary"
# 预期: URL: jdbc:mysql://mysql:3306/privacy0?...

# 测试登录
TOKEN=$(curl -s -m 10 http://127.0.0.1:30811/prod-api/user/login \
  -d "userAccount=admin&userPassword=123456" \
  | sed 's/.*"token":"\([^"]*\)".*/\1/')
echo "Token: ${TOKEN:0:20}..."
```

### 2. 核心模块验证

```bash
HDR="-H token: $TOKEN -H userId: 1"
BASE="http://127.0.0.1:30811/prod-api"

# 用户管理
curl -s $BASE/user/findUserPage?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'
# 预期: "code":0

# 系统配置
curl -s $BASE/systemConfig/getFtpConfig $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/systemConfig/getNetworkConfig $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/systemConfig/getTimeConfig $HDR | grep -o '"code":[0-9,-]*'

# PSI
curl -s $BASE/psi/getPsiTaskList?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'

# PIR
curl -s $BASE/pir/getPirTaskList?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'

# 联邦统计
curl -s $BASE/federatedStatistics/types $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/federatedStatistics/task/list?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'

# 联邦分析
curl -s -X POST $BASE/federatedAnalysis/sql/validate $HDR \
  -H "Content-Type: application/json" -d '{"sql":"SELECT 1"}' | grep -o '"code":[0-9,-]*'
curl -s $BASE/federatedAnalysis/sql/functions $HDR | grep -o '"code":[0-9,-]*'

# 联邦学习
curl -s $BASE/federatedLearning/getTaskList?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'

# 新模块验证
curl -s $BASE/tenant/findTenantPage?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/log/findScheduleLogPage?pageNo=1\&pageSize=5 $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/apiManage/findApiPage?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/evidence/findEvidencePage?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/node/approval/getAllConfigs $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/dataRequirement/findDataRequirementPage?pageNo=1\&pageSize=10 $HDR | grep -o '"code":[0-9,-]*'

# 监控
curl -s $BASE/monitor/getCpuMonitor $HDR | grep -o '"code":[0-9,-]*'
curl -s $BASE/monitor/getMemoryMonitor $HDR | grep -o '"code":[0-9,-]*'
```

### 3. 功能任务验证

```bash
# 创建 PSI 任务
curl -s -X POST $BASE/psi/saveDataPsi $HDR \
  -d "ownOrganId=<orgId>&ownResourceId=<resId>&ownKeyword=id&otherOrganId=<orgId>&otherResourceId=<resId>&otherKeyword=id&psiTag=0&resultName=verify-test&outputContent=0&resultOrganIds=<orgId>"

# 创建统计任务
curl -s -X POST $BASE/federatedStatistics/task/create $HDR \
  -H "Content-Type: application/json" \
  -d '{"taskName":"verify-stats","projectId":1,"statsType":"descriptive","taskParam":"{}"}'

# 等待执行
sleep 15
curl -s $BASE/federatedStatistics/task/list?pageNo=1\&pageSize=10 $HDR | grep -o '"taskState":[0-9]'
# 预期: 2 (已完成)
```

### 4. 预期结果

| 测试项 | 预期 | 错误排查 |
|--------|------|---------|
| 所有 API 返回 code:0 | `"code":0` | 检查 `privacy0` 表是否存在 |
| Init Primary 日志 | `privacy0` | 设置 `SPRING_DATASOURCE_DRUID_PRIMARY_URL` 环境变量 |
| 223 功能点 | 全部通过 | 执行 `bash test-tools/fix-all.sh` |

## 四、运维命令

```bash
# 版本管理
bash scripts/version-manager.sh show

# 验证镜像
bash scripts/version-manager.sh verify

# 创建新版本
bash scripts/version-manager.sh tag 2.1.0
bash scripts/version-manager.sh docker-tag
```

---

## 五、已知问题速查

| 现象 | 原因 | 解决 |
|------|------|------|
| `Unknown database 'privacy'` | 未设环境变量 | `docker update -e SPRING_DATASOURCE_DRUID_PRIMARY_URL=...` |
| `Table ... doesn't exist` | 缺表 | `bash fix-all.sh` |
| Login 401 | Token 过期 | 重新 login |
| PSI 返回 102 | 机构未配置 | 先 `POST /organ/changeLocalOrganInfo` |
