# 服务器(Server)模块 设计说明

将**数据资源、模型、模型产物、节点、智能体**关联到「服务器」上的平台模块。
后端 Spring Boot + MyBatis + MySQL，前端 Vue 2.6 + Element UI，完全沿用 primihub-platform
既有分层与命名范式。

## 1. 数据模型

主表 `server` 与新增 `agent`（平台此前无智能体实体），外加五张多对多关联表。所有表带
`organ_id`(机构) + `user_id`(创建人) + `is_del`(软删) + `create_date`/`update_date`，与
`data_resource` / `node_cooperation_party` 一致。建表脚本：`arm64-deploy/data/initsql/server_module.sql`。

| 表 | 说明 | 关键字段 |
|---|---|---|
| `server` | 服务器主表 | server_id(PK) / server_name / server_ip / server_port / server_type(compute/storage/gateway/tee) / server_status(0离线 1在线 2维护) / cpu_cores / memory_gb / storage_gb / config(JSON) / last_heartbeat |
| `agent` | 智能体主表 | agent_id(PK) / agent_name / agent_type / agent_desc / endpoint / status |
| `server_resource` | 服务器↔数据资源 | server_id, resource_id(→data_resource), allocation_status(0待分配 1已分配 2已卸载) |
| `server_model` | 服务器↔模型 | server_id, model_id(→data_model), model_version, deployment_status(0待部署 1已部署 2运行中 3已停止) |
| `server_artifact` | 服务器↔模型产物 | server_id, artifact_id(→data_model_artifact), artifact_status(0未部署 1已部署 2运行中) |
| `server_node` | 服务器↔节点 | server_id, node_id(→node_cooperation_party.id), access_type(project/compute/data_exchange), is_primary |
| `server_agent` | 服务器↔智能体 | server_id, agent_id, run_status |

每张关联表有唯一键 `(server_id, 对端id)` 防重复关联，并对两端各建索引。

## 2. 关联关系

服务器与五类对象均为**多对多**（一台服务器可承载多个资源/模型/…；同一资源/模型也可分配到
多台服务器）。关联在关联表上带业务状态字段（分配/部署/运行状态、接入类型、是否主节点），
以承载"在这台服务器上"的具体语义，而非纯连接。

## 3. 后端分层与落点

- Entity PO：`biz/.../entity/sys/po/{Server,Agent,ServerResource,ServerModel,ServerArtifact,ServerNode,ServerAgent}.java`
- VO：`.../entity/sys/vo/{ServerVO,AgentVO,Server*VO}.java`（`ServerVO` 内嵌五类关联列表，关联 VO 冗余出对端名称如 resource_name/model_name/organ_name/agent_name）
- 查询参数：`.../entity/sys/param/{ServerParam,AgentParam}.java`（继承 `PageReq`）
- Repository：读走 `secondarydb/sys/ServerSecondarydbRepository`，写走 `primarydb/sys/ServerPrimarydbRepository`
- Mapper XML：`resources/mybatis/mapper/{secondarydb,primarydb}/sys/Server*Mapper.xml`
- Service：`biz/.../service/sys/ServerService.java`（19 方法，`BaseResultEntity` 包装，`PageParam` 分页）
- Controller：`application/.../controller/sys/ServerController.java`（`@RequestMapping("/server")`）

## 4. API（前端经网关 `/sys/**` 访问，StripPrefix 后打到 `/server/**`）

服务器 CRUD：`/sys/server/findServerPage`、`getServerDetail`、`addServer`、`updateServer`、`deleteServer`
智能体 CRUD：`/sys/server/findAgentPage`、`addAgent`、`updateAgent`、`deleteAgent`
关联（每类 bind/unbind）：`bindResource`/`unbindResource`、`bindModel`/`unbindModel`、
`bindArtifact`/`unbindArtifact`、`bindNode`/`unbindNode`、`bindAgent`/`unbindAgent`。
`getServerDetail` 一次性返回服务器基本信息 + 五类关联列表（含对端名称）。

> 路由说明：controller 挂 `/server`，前端调 `/sys/server/...`；网关 `/sys/**` 路由 `StripPrefix=1`
> 去掉 `/sys` 后转发给 platform 服务，命中 controller。与 `data/resource` 走 `/data/**` 同理，
> 无需新增网关路由；新端点未在 SysAuth 授权表登记，默认放行（仅 token 鉴权）。

## 5. 前端

- API 封装：`primihub-webconsole/src/api/server.js`
- 路由/菜单：`src/router/index.js` 的 `asyncRoutes` 新增 `/server`（icon `el-icon-cpu`，标题「服务器管理」）
- 页面：
  - `views/server/list.vue`：搜索(名称/类型/状态) + 分页表格 + 新增/编辑/删除/详情
  - `views/server/create.vue`：新建/编辑表单（query 带 serverId 即编辑）
  - `views/server/detail.vue`：基本信息 + `el-tabs` 五个关联页（数据资源/模型/模型产物/节点/智能体），
    每页可「关联」（弹窗选/填对端 + 业务字段）与「移除」

## 6. 多租户与鉴权

沿用平台既有机制：网关 `SysAuthGatewayFilterFactory` 校验 token 并注入 `userId` 请求头；
主表 `organ_id`/`user_id` 承载机构/用户隔离；软删 `is_del`。

## 7. 验证状态

- 后端 `biz` 与 `application` 两模块 `mvn -o compile` 均通过（Java 8, 离线）。
- Mapper XML 的 namespace 全部对应存在的 Repository 接口；所有 resultType/parameterType 类均存在。
- 前端文件结构/路由/API 齐全，router 语法检查通过。
- 未做：数据库实跑建表 + 端到端联调（需起平台环境）；SysAuth 授权表登记（如需按钮级权限）。
