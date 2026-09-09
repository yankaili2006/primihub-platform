# PrimiHub 服务器(Server)模块 — 实现规格

目标：在 primihub-platform 新增一个「服务器(server)」模块，把**数据资源、模型（含模型产物）、
智能体、节点**关联到服务器上。严格遵循本仓库现有的 Spring Boot + MyBatis + MySQL 后端
与 Vue 2.6 + Element UI 前端的既有范式（照抄现有资源/节点模块的写法，不要引入新框架）。

## 后端分层约定（务必照此落点）

- Controller: `primihub-service/application/src/main/java/com/primihub/application/controller/sys/ServerController.java`
  （参考 `controller/data/ResourceController.java`、`controller/sys/NodeEnhancedController.java`）
- Service: `primihub-service/biz/src/main/java/com/primihub/biz/service/sys/ServerService.java`
  （参考 `service/data/DataResourceService.java`，`@Service @Slf4j`，直接依赖 Repository）
- Repository 接口（读，二级库）: `primihub-service/biz/src/main/java/com/primihub/biz/repository/secondarydb/sys/ServerRepository.java`
- Repository 接口（写，主库）: `primihub-service/biz/src/main/java/com/primihub/biz/repository/primarydb/sys/ServerPrRepository.java`
  （参考 DataResourceRepository / DataResourcePrRepository 的读写分离）
- Mapper XML: `primihub-service/biz/src/main/resources/mybatis/mapper/{secondarydb,primarydb}/sys/Server*Mapper.xml`
- Entity PO: `primihub-service/biz/src/main/java/com/primihub/biz/entity/sys/po/`（`@Data` Lombok，字段小驼峰）
- Entity VO/Req/Resp: `.../entity/sys/vo/`、`.../entity/sys/req/`、`.../entity/sys/resp/`
- 统一返回包装：`BaseResultEntity`（`BaseResultEntity.success(data)` / `.failure(...)`）；分页用 `PageDataEntity`
- 鉴权：网关 `SysAuthGatewayFilterFactory` 注入 `userId` 到请求头；Controller 用
  `@RequestHeader(value="userId", required=false, defaultValue="0") Long userId` 取当前用户
- 多租户隔离：所有主表带 `organId`（机构）+ `userId`（创建人）+ `isDel`（软删）+ `createDate`/`updateDate`

## 数据模型

### 主表 server（服务器）
字段：serverId(PK, BIGINT auto) / serverName / serverDesc / serverIp / serverPort(INT) /
serverType(VARCHAR: compute/storage/gateway/tee) / serverStatus(TINYINT: 0离线 1在线 2维护) /
organId(BIGINT) / userId(BIGINT) / cpuCores(DOUBLE) / memoryGb(BIGINT) / storageGb(BIGINT) /
config(JSON 文本) / lastHeartbeat(DATETIME) / isDel(TINYINT default 0) /
createDate/updateDate(DATETIME(3) default CURRENT_TIMESTAMP(3))。表名 `server`，comment。

### 关联表（都软删+时间戳+唯一键+索引）
- `server_resource`：server_id ↔ resource_id(data_resource.resource_id)，字段
  allocation_status(TINYINT: 0待分配 1已分配 2已卸载)；唯一键(server_id,resource_id)。
- `server_model`：server_id ↔ model_id(data_model.model_id)，字段 model_version、
  deployment_status(TINYINT: 0待部署 1已部署 2运行中 3已停止)；唯一键(server_id,model_id)。
- `server_artifact`：server_id ↔ artifact_id(data_model_artifact.artifact_id)，字段
  artifact_status(TINYINT: 0未部署 1已部署 2运行中)；唯一键(server_id,artifact_id)。
- `server_node`：server_id ↔ node_id(node_cooperation_party.id)，字段
  access_type(VARCHAR: project/compute/data_exchange)、is_primary(TINYINT)；唯一键(server_id,node_id)。
- `server_agent`：server_id ↔ agent_id。**智能体(agent)当前平台无实体** —— 需**新建最小 agent 主表**
  `agent`(agentId PK / agentName / agentType / agentDesc / endpoint / status(TINYINT) /
  organId / userId / isDel / createDate/updateDate)，再建 `server_agent` 关联
  (server_id, agent_id, run_status TINYINT)；唯一键(server_id,agent_id)。

### SQL 迁移
新增文件 `arm64-deploy/data/initsql/server_module.sql`（风格照 `privacy1.sql`：MySQL utf8mb4、
带 COMMENT、`IF NOT EXISTS`）。包含 server、agent、及五张关联表的建表语句。

## 后端 API（ServerController，路径 `/server`；返回 BaseResultEntity）

服务器 CRUD：
- GET `/server/findServerPage`（keyword/serverType/serverStatus/pageNum/pageSize，按 userId+organId 过滤，软删排除）
- GET `/server/getServerById`（serverId）
- POST `/server/addServer`（@RequestBody ServerReq）
- POST `/server/updateServer`
- POST `/server/deleteServer`（serverId，软删）

关联管理（每类都给 attach / detach / list 三件套，落到对应关联表）：
- 数据资源：POST `/server/resource/allocate`、POST `/server/resource/unallocate`、GET `/server/resource/list?serverId=`
- 模型：POST `/server/model/deploy`、POST `/server/model/undeploy`、GET `/server/model/list?serverId=`
- 模型产物：POST `/server/artifact/attach`、POST `/server/artifact/detach`、GET `/server/artifact/list?serverId=`
- 节点：POST `/server/node/authorize`、POST `/server/node/revoke`、GET `/server/node/list?serverId=`
- 智能体：POST `/server/agent/bind`、POST `/server/agent/unbind`、GET `/server/agent/list?serverId=`
- 汇总：GET `/server/getServerAssociations?serverId=`（一次返回该服务器下 resource/model/artifact/node/agent 计数+列表）

list 类接口应 JOIN 出被关联对象的名称（如 resource_name / model_name / organ_name），不要只返回 id。

## 前端（primihub-webconsole，Vue 2.6 + Element UI）

- API 封装：`src/api/server.js`（照 `src/api/resource.js` 的 request 封装风格，url 对齐后端路径）
- 路由：在 `src/router/index.js` 的 `asyncRoutes` 增加 `/server` 菜单（title「服务器管理」，
  icon `el-icon-cpu`），children：list（服务器列表）、detail/:serverId（详情，含关联 Tab）、
  hidden 的关联管理页。
- 页面：`src/views/server/list.vue`（搜索+分页表格+增删改，照 `views/resource/list.vue`）、
  `src/views/server/create.vue`（新建/编辑表单）、`src/views/server/detail.vue`
  （基本信息 + 用 el-tabs 展示 数据资源/模型/模型产物/节点/智能体 五个关联 Tab，每个 Tab 可
  「添加关联」弹窗选择已有对象 + 表格列出已关联 + 移除）。

## 交付要求

1. 后端能编译通过（`mvn -q -pl primihub-service/biz,primihub-service/application -am compile`
   或仓库既有的构建脚本；若环境缺依赖无法联网构建，则至少保证代码结构、import、注解、
   MyBatis namespace 与现有模块一致，XML 的 resultType/parameterType 全类名正确）。
2. 前端文件结构、路由、API 封装齐全，语法正确。
3. 所有新文件遵循现有命名/注解/包路径；不改动无关文件；不引入新依赖。
4. 在仓库根写一份 `docs/server-module-design.md` 说明数据模型、API、关联关系与前端页面。
5. 全部改动提交到当前分支 `feature/server-module`，commit message 说明清楚。

## 参考现有文件（照抄范式）
- 实体：`entity/data/po/DataResource.java`、`entity/data/po/DataModelArtifact.java`、
  `entity/sys/po/NodeCooperationParty.java`、`entity/data/po/DataModelResource.java`（关联表范式）
- Controller：`controller/data/ResourceController.java`、`controller/sys/NodeEnhancedController.java`
- Service：`service/data/DataResourceService.java`
- Mapper：`resources/mybatis/mapper/secondarydb/data/DataResourceRepositoryMapper.xml`
- 前端：`src/api/resource.js`、`src/views/resource/list.vue`、`src/views/resource/create.vue`、
  `src/router/index.js`
