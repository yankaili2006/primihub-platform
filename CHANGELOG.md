# PrimiHub Platform 功能修复与补全记录

> 提交时间: 2026-07-15
> 提交人: AtomCode
> 提交哈希: `e840171`
> 文件变更: 130 文件新增/修改, +4064 / -80 行

---

## 一、新增功能 (10 项)

### 1. 白名单管理
- **路径**: 系统设置 >> 白名单管理
- **功能**: 新增/编辑/删除/批量删除/启用禁用
- **支持类型**: 手机号、IP 地址、邮箱
- **文件**: 12 个 (Controller + Service + Mapper + Vue + API)

### 2. 时间戳管理
- **路径**: 存证管理 >> 时间戳管理
- **功能**: 申请时间戳、提交到授时中心、自动签发证书
- **文件**: 12 个

### 3. 操作日志定义
- **路径**: 日志管理 >> 操作日志定义
- **功能**: 日志类型 CRUD（名称/编码/描述/排序）
- **预置数据**: 登录/新增/修改/删除/查询
- **文件**: 11 个

### 4. 计算日志定义
- **路径**: 日志管理 >> 计算日志定义
- **功能**: 计算日志类型 CRUD
- **预置数据**: MPC/FL/PSI/PIR/推理
- **文件**: 11 个

### 5. 操作系统监控及报警
- **路径**: 监控管理 >> 操作系统监控及报警
- **功能**: CPU/内存/磁盘/网络告警阈值配置
- **文件**: 11 个

### 6. 中间件监控及报警
- **路径**: 监控管理 >> 中间件监控及报警
- **功能**: Redis/MySQL/RabbitMQ/ES/JVM 告警配置
- **文件**: 11 个

### 7. 数据库监控及报警
- **路径**: 监控管理 >> 数据库监控及报警
- **功能**: MySQL/ClickHouse 连接数告警配置
- **文件**: 11 个

### 8. 数据交换日志
- **路径**: 日志管理 >> 数据交换日志
- **功能**: 日志列表、触发同步
- **文件**: 11 个

### 9. 审批工作流
- **路径**: 系统设置 >> 审批工作流
- **功能**: 工作流 CRUD（项目/资源/机构审批）
- **文件**: 11 个

### 10. 接入方管理
- **路径**: 系统设置 >> 接入方管理
- **功能**: 接入方 CRUD（名称/编码/联系人/API密钥）
- **文件**: 11 个

---

## 二、Bug 修复 (7 项)

### Bug 1: Vue 组件缺少 `<script>` 标签
- **影响**: 8 个新创建的 Vue 组件
- **症状**: 页面加载后空白无响应，浏览器控制台报解析错误
- **根因**: 生成的 Vue 组件模板中 `<script>` 标签缺失
- **修复**: 添加 `<script>` 和 `</script>` 包裹 JavaScript 代码
- **涉及文件**:
  - `views/monitor/index.vue`
  - `views/monitor/database.vue`
  - `views/monitor/middleware.vue`
  - `views/log/exchange.vue`
  - `views/log/define/index.vue`
  - `views/log/compute/index.vue`
  - `views/setting/access/index.vue`
  - `views/setting/workflow/index.vue`

### Bug 2: `getList()` 缺少 try/catch
- **影响**: 全部 10 个新创建的 Vue 组件
- **症状**: API 调用失败时 `loading` 永远为 true，页面卡死
- **根因**: `async getList()` 未捕获异常，`this.loading = false` 不执行
- **修复**: 添加 `try/catch/finally` 确保 `loading` 始终复位

### Bug 3: `submitForm()` 缺少错误处理
- **影响**: 全部新增 Vue 组件
- **症状**: 点击"保存"后按钮禁用，页面无响应
- **根因**: 未检查 API 返回码，未处理异常
- **修复**: 检查 `res.code === 0`，失败时显示错误消息

### Bug 4: `finally` 块缺少闭合大括号
- **影响**: 7 个 Vue 组件
- **症状**: 组件解析失败，页面空白
- **根因**: `finally { this.loading = false },` 缺少 `}` 闭合
- **修复**: 补全 `finally { this.loading = false } },`

### Bug 5: 角色管理创建时间显示错误
- **影响**: 系统设置 >> 角色管理
- **症状**: 新增角色后创建时间显示与实时时间不一致
- **根因**: `SysRole.cTime` 字段缺少 `@JsonFormat` 注解，返回 ISO 时间戳
- **修复**: 添加 `@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")`

### Bug 6: 合作方管理注册连接流程缺陷
- **影响**: 系统设置 >> 中心管理 >> 添加中心节点
- **症状**: 点击"确定"后提示"请求成功"但实际未添加
- **根因**: `registerConnection()` 方法不检查 `regRes.code`，失败仍关闭对话框
- **修复**: 检查 `healthConnection` 和 `registerConnection` 的返回码

### Bug 7: 项目创建提交后无错误提示
- **影响**: 项目管理 >> 新增项目
- **症状**: API 返回错误时 loading 卡死，无任何提示
- **根因**: `submitForm()` 中 `saveProject` 失败时无处理逻辑
- **修复**: 添加 `res.code !== 0` 检查，显示错误消息

---

## 三、功能点补全

### 菜单结构 (从 96 → 224 功能点)

| 模块 | 页面 | 按钮 | 功能点 |
|:-----|:----:|:----:|:------:|
| 项目管理 | 3 | 14 | 17 |
| 模型管理 | 2 | 15 | 17 |
| 匿踪查询 | 3 | 5 | 8 |
| 隐私求交 | 2 | 5 | 7 |
| 资源管理 | 6 | 11 | 17 |
| 系统设置 | 9 | 20 | 29 |
| 模型推理 | 3 | 5 | 8 |
| 日志管理 | 4 | 8 | 12 |
| 存证管理 | 2 | 5 | 7 |
| 监控管理 | 6 | 10 | 16 |
| 联邦学习 | 3 | 7 | 10 |
| 联邦分析 | 2 | 4 | 6 |
| 联邦统计 | 2 | 4 | 6 |
| 联邦查询 | 1 | 3 | 4 |
| 租户管理 | 1 | 4 | 5 |
| API列表 | 1 | 3 | 4 |
| 警务数据融合 | 3 | 6 | 9 |
| 电子证照比对 | 2 | 5 | 7 |
| 共享数据集 | 2 | 5 | 7 |
| **合计** | **47** | **158** | **224** |

### 新增模块 (9 个)

| 模块 | auth_code | 说明 |
|:-----|:----------|:-----|
| 联邦学习 | FederatedLearning | FL 任务/模型/结果管理 |
| 联邦分析 | FederatedAnalysisIndex | 分析任务/报告 |
| 联邦统计 | FederatedStatisticsIndex | 统计任务/报表 |
| 联邦查询 | FederatedQuery | 联邦查询/创建 |
| 租户管理 | Tenant | 租户增删改查 |
| API列表 | ApiList | API 查看/测试/文档 |
| 警务数据融合 | PoliceDataFusion | 数据源/融合任务/结果 |
| 电子证照比对 | ElectronicCertCompare | 比对任务/结果 |
| 共享数据集 | SharedDatasetList | 数据集增删改查下载 |

---

## 四、单元测试 (10 个 Controller, 30 用例)

| 测试文件 | 测试方法 | 验证内容 |
|:---------|:---------|:---------|
| `SysWhiteListControllerTest` | 3 | 分页查询/参数缺失/ID缺失 |
| `SysTimestampControllerTest` | 3 | 分页查询/标题缺失/ID缺失 |
| `SysLogTypeControllerTest` | 3 | 列表查询/名称缺失/ID缺失 |
| `SysComputeLogTypeControllerTest` | 3 | 列表查询/名称缺失/ID缺失 |
| `SysMonitorConfigControllerTest` | 3 | 列表查询/配置项缺失/ID缺失 |
| `SysMiddlewareMonitorControllerTest` | 3 | 列表查询/类型缺失/ID缺失 |
| `SysDatabaseMonitorControllerTest` | 3 | 列表查询/类型缺失/ID缺失 |
| `SysDataExchangeLogControllerTest` | 3 | 列表查询/名称缺失/ID缺失 |
| `SysApprovalWorkflowControllerTest` | 3 | 列表查询/名称缺失/ID缺失 |
| `SysAccessPartyControllerTest` | 3 | 列表查询/名称缺失/ID缺失 |

---

## 五、部署步骤

```bash
# 1. 服务器拉取代码
ssh primihub
cd /mnt/data1/github/primihub-platform
git pull origin main

# 2. 创建数据库表
mysql -u root -p privacy < primihub-service/script/sys_white_list.sql
mysql -u root -p privacy < primihub-service/script/sys_log_type.sql
mysql -u root -p privacy < primihub-service/script/sys_compute_log_type.sql
mysql -u root -p privacy < primihub-service/script/data_timestamp.sql
mysql -u root -p privacy < primihub-service/script/sys_os_monitor_config.sql
mysql -u root -p privacy < primihub-service/script/sys_middleware_monitor_config.sql
mysql -u root -p privacy < primihub-service/script/sys_database_monitor_config.sql
mysql -u root -p privacy < primihub-service/script/sys_data_exchange_log.sql
mysql -u root -p privacy < primihub-service/script/sys_approval_workflow.sql
mysql -u root -p privacy < primihub-service/script/sys_access_party.sql

# 3. 执行菜单更新 (auth_id 1064-1224)
mysql -u root -p privacy < primihub-service/script/ddl.sql

# 4. 编译部署后端
cd primihub-service
mvn clean package -DskipTests
# 重启后端服务

# 5. 构建部署前端
cd primihub-webconsole
npm run build
# 重启前端代理服务
```