# 日志管理模块功能说明

## 功能概述

在日志管理一级菜单下新增了7个子功能模块，实现了完整的日志定义和日志记录管理功能。

## 一、功能列表

### 1. 操作日志定义
- **路由路径**: `/log/operationDefinition`
- **功能说明**: 管理操作日志的定义规则
- **主要功能**:
  - 查询操作日志定义列表（支持分页）
  - 新增操作日志定义
  - 编辑操作日志定义
  - 删除操作日志定义
  - 启用/禁用操作日志定义
  - 按日志代码、名称、类型、模块搜索

### 2. 调度日志定义
- **路由路径**: `/log/scheduleDefinition`
- **功能说明**: 管理调度任务日志的定义规则
- **主要功能**:
  - 查询调度日志定义列表（支持分页）
  - 新增调度日志定义
  - 编辑调度日志定义
  - 删除调度日志定义
  - 按日志代码、名称、调度类型、模块搜索

### 3. 计算日志定义
- **路由路径**: `/log/computeDefinition`
- **功能说明**: 管理计算任务日志的定义规则
- **主要功能**:
  - 查询计算日志定义列表（支持分页）
  - 新增计算日志定义
  - 编辑计算日志定义
  - 删除计算日志定义
  - 按日志代码、名称、计算类型、模块搜索

### 4. 操作日志记录
- **路由路径**: `/log/operationLog`
- **功能说明**: 查看和导出用户操作日志
- **主要功能**:
  - 查询操作日志记录列表（支持分页）
  - 按用户名、操作类型、状态、时间范围搜索
  - 导出操作日志为Excel文件
  - 显示用户名、机构、操作类型、模块、描述、IP地址、状态、执行时长等信息

### 5. 调度日志记录
- **路由路径**: `/log/scheduleLog`
- **功能说明**: 查看和导出调度任务日志
- **主要功能**:
  - 查询调度日志记录列表（支持分页）
  - 按任务名称、调度类型、状态、时间范围搜索
  - 导出调度日志为Excel文件
  - 显示任务名称、调度类型、Cron表达式、执行服务器、状态、执行时长、重试次数等信息

### 6. 计算日志记录
- **路由路径**: `/log/computeLog`
- **功能说明**: 查看和导出计算任务日志
- **主要功能**:
  - 查询计算日志记录列表（支持分页）
  - 按任务ID、任务名称、计算类型、状态、时间范围搜索
  - 导出计算日志为Excel文件
  - 显示任务ID、任务名称、计算类型、项目名称、用户名、机构、状态、执行时长等信息

### 7. 日志导出
- **功能说明**: 所有日志记录页面都支持导出功能
- **支持格式**: Excel (.xlsx)
- **导出范围**: 根据当前搜索条件导出符合条件的所有日志

## 二、技术实现

### 后端实现

#### 1. 数据库表结构
已创建6个数据库表：
- `sys_operation_log_definition` - 操作日志定义表
- `sys_schedule_log_definition` - 调度日志定义表
- `sys_compute_log_definition` - 计算日志定义表
- `sys_operation_log` - 操作日志记录表
- `sys_schedule_log` - 调度日志记录表
- `sys_compute_log` - 计算日志记录表

SQL脚本位置: `primihub-service/script/log_management.sql`

#### 2. 实体类
创建6个实体类（Entity/PO）：
- `OperationLogDefinition.java`
- `ScheduleLogDefinition.java`
- `ComputeLogDefinition.java`
- `OperationLog.java`
- `ScheduleLog.java`
- `ComputeLog.java`

位置: `primihub-service/biz/src/main/java/com/primihub/biz/entity/sys/po/`

#### 3. Repository层
创建Repository接口和Mapper XML：
- `LogManagementPrimarydbRepository.java` - 数据访问接口
- `LogManagementPrimarydbRepositoryMapper.xml` - MyBatis映射文件

位置:
- `primihub-service/biz/src/main/java/com/primihub/biz/repository/primarydb/sys/`
- `primihub-service/biz/src/main/resources/mybatis/mapper/primarydb/sys/`

#### 4. Service层
创建Service类：
- `LogManagementService.java` - 业务逻辑层，包含所有日志管理业务方法

位置: `primihub-service/biz/src/main/java/com/primihub/biz/service/sys/`

主要方法：
- 日志定义的增删改查
- 日志记录的查询和分页
- 日志导出为Excel

#### 5. Controller层
创建Controller类：
- `LogManagementController.java` - 控制器，提供RESTful API接口

位置: `primihub-service/application/src/main/java/com/primihub/application/controller/sys/`

API接口路径前缀: `/log`

### 前端实现

#### 1. API接口
创建API接口文件：
- `logManagement.js` - 封装所有日志管理相关的API调用

位置: `primihub-webconsole/src/api/`

#### 2. 页面组件
创建6个Vue页面组件：
- `operationDefinition.vue` - 操作日志定义页面
- `scheduleDefinition.vue` - 调度日志定义页面
- `computeDefinition.vue` - 计算日志定义页面
- `operationLog.vue` - 操作日志记录页面
- `scheduleLog.vue` - 调度日志记录页面
- `computeLog.vue` - 计算日志记录页面

位置: `primihub-webconsole/src/views/logManagement/`

#### 3. 路由配置
已在 `primihub-webconsole/src/router/index.js` 中配置路由：

```javascript
{
  path: '/log',
  component: Layout,
  name: 'Log',
  redirect: '/log/index',
  meta: { title: '日志管理', icon: 'el-icon-warning-outline' },
  children: [
    { path: 'index', name: 'LogList', meta: { title: '任务日志' } },
    { path: 'operationDefinition', name: 'OperationLogDefinition', meta: { title: '操作日志定义' } },
    { path: 'scheduleDefinition', name: 'ScheduleLogDefinition', meta: { title: '调度日志定义' } },
    { path: 'computeDefinition', name: 'ComputeLogDefinition', meta: { title: '计算日志定义' } },
    { path: 'operationLog', name: 'OperationLog', meta: { title: '操作日志记录' } },
    { path: 'scheduleLog', name: 'ScheduleLog', meta: { title: '调度日志记录' } },
    { path: 'computeLog', name: 'ComputeLog', meta: { title: '计算日志记录' } }
  ]
}
```

## 三、部署说明

### 1. 数据库初始化
执行SQL脚本创建表和初始数据：

```bash
mysql -u<username> -p<password> <database> < primihub-service/script/log_management.sql
```

该脚本会：
- 创建6个日志管理相关的表
- 插入初始的操作日志定义数据（登录、登出、增删改查、导入导出等）
- 插入初始的调度日志定义数据（数据同步、报表生成、日志清理、数据备份等）
- 插入初始的计算日志定义数据（联合建模、安全求交、隐匿查询、联合预测等）

### 2. 构建和部署
使用1.8.0版本构建镜像（已包含所有功能）：

```bash
BUILD_NUMBER=1.8.0 ./quick-build.sh
```

## 四、主要特性

1. **完整的CRUD操作**: 所有日志定义都支持新增、编辑、删除、查询操作
2. **灵活的搜索功能**: 支持多条件组合搜索
3. **分页支持**: 所有列表页面都支持分页显示
4. **导出功能**: 日志记录支持导出为Excel文件
5. **状态管理**: 日志定义支持启用/禁用状态切换
6. **保留天数配置**: 每个日志定义可以设置数据保留天数
7. **详细的字段信息**: 记录用户、机构、IP地址、执行时长等详细信息

## 五、使用建议

1. **日志定义配置**: 先在日志定义页面配置需要记录的日志类型和规则
2. **日志记录查看**: 在日志记录页面查看实际产生的日志数据
3. **定期导出**: 可以定期导出日志数据进行归档
4. **清理策略**: 根据保留天数设置，定期清理过期日志数据

## 六、文件清单

### 后端文件
```
primihub-service/
├── script/
│   └── log_management.sql                                    # 数据库脚本
├── biz/src/main/java/com/primihub/biz/
│   ├── entity/sys/po/
│   │   ├── OperationLogDefinition.java                       # 操作日志定义实体
│   │   ├── ScheduleLogDefinition.java                        # 调度日志定义实体
│   │   ├── ComputeLogDefinition.java                         # 计算日志定义实体
│   │   ├── OperationLog.java                                 # 操作日志实体
│   │   ├── ScheduleLog.java                                  # 调度日志实体
│   │   └── ComputeLog.java                                   # 计算日志实体
│   ├── repository/primarydb/sys/
│   │   └── LogManagementPrimarydbRepository.java             # Repository接口
│   └── service/sys/
│       └── LogManagementService.java                         # Service层
├── biz/src/main/resources/mybatis/mapper/primarydb/sys/
│   └── LogManagementPrimarydbRepositoryMapper.xml            # MyBatis映射
└── application/src/main/java/com/primihub/application/controller/sys/
    └── LogManagementController.java                          # Controller层
```

### 前端文件
```
primihub-webconsole/
├── src/api/
│   └── logManagement.js                                      # API接口
└── src/views/logManagement/
    ├── operationDefinition.vue                               # 操作日志定义页面
    ├── scheduleDefinition.vue                                # 调度日志定义页面
    ├── computeDefinition.vue                                 # 计算日志定义页面
    ├── operationLog.vue                                      # 操作日志记录页面
    ├── scheduleLog.vue                                       # 调度日志记录页面
    └── computeLog.vue                                        # 计算日志记录页面
```

## 七、后续扩展建议

1. **权限控制**: 可以为每个功能添加权限控制
2. **日志自动记录**: 可以通过AOP方式自动记录操作日志
3. **日志分析**: 可以增加日志统计和分析功能
4. **告警功能**: 可以根据日志配置告警规则
5. **日志清理任务**: 可以添加定时任务自动清理过期日志
