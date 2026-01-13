# PrimiHub Management Platform Service

PrimiHub Management Platform 是一个基于 Spring Cloud 的联邦学习管理平台，提供多方安全计算、隐私保护数据协作等功能。

## 系统架构

PrimiHub-service 采用微服务架构，包含以下核心模块：

### 1. 应用模块 (application)
- **主要功能**: 提供业务逻辑处理和数据服务
- **核心控制器**:
  - 数据管理: `ResourceController`, `ProjectController`, `ModelController`
  - 隐私计算: `PirController`, `PsiController`, `ReasoningController`
  - 任务管理: `TaskController`, `ScheduleController`
  - 系统管理: `UserController`, `RoleController`, `OrganController`

### 2. 业务模块 (biz)
- **主要功能**: 核心业务逻辑实现和数据处理
- **核心服务**:
  - 数据服务: `DataResourceService`, `DataModelService`, `DataTaskService`
  - 隐私计算服务: `PirService`, `PsiService`, `DataReasoningService`
  - 系统服务: `SysUserService`, `SysAuthService`, `SysOrganService`
- **数据访问层**: 支持多数据源配置 (primarydb, secondarydb)
- **缓存层**: Redis 缓存支持

### 3. 网关模块 (gateway)
- **主要功能**: API 网关，提供统一入口和认证授权
- **核心功能**:
  - 路由转发
  - 认证授权 (`SysAuthGatewayFilterFactory`)
  - 日志记录 (`SysLogGatewayFilterFactory`)
  - Swagger 文档集成

## 核心功能

### 1. 项目管理
- 项目创建、协作、审核
- 多机构协作项目管理
- 项目资源授权管理

### 2. 联邦学习模型
- 支持多种联邦学习算法:
  - 纵向联邦学习: XGBoost, 逻辑回归, 线性回归
  - 横向联邦学习: 逻辑回归, 神经网络, 线性回归
  - MPC 安全计算: 逻辑回归
- 可视化模型构建和组件编排
- 模型训练、推理和预测

### 3. 隐私计算
- **隐私集合求交 (PSI)**: 支持多方数据安全交集计算
- **匿踪查询 (PIR)**: 支持隐私保护的数据检索
- **联邦推理**: 支持已训练模型的联邦推理

### 4. 数据资源管理
- 数据资源上传和管理
- 数据源连接配置 (数据库、文件等)
- 数据字段管理和权限控制
- 联邦资源共享和发现

### 5. 系统管理
- 用户管理和权限控制
- 角色权限配置
- 机构管理和协作
- 系统配置和监控

## 技术栈

- **后端框架**: Spring Cloud, Spring Boot
- **服务注册与发现**: Nacos
- **数据库**: MySQL 5.0+
- **缓存**: Redis 5.0+
- **消息队列**: RabbitMQ
- **构建工具**: Maven
- **Java版本**: JDK 1.8

## 快速开始

### 环境要求

在运行项目前，需要安装以下依赖服务:

- [JDK 1.8](https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html)
- [Maven](https://maven.apache.org/download.cgi)
- [Nacos 2.0.3](https://github.com/alibaba/nacos/releases/tag/2.0.3) 或 [2.0.4](https://github.com/alibaba/nacos/releases/tag/2.0.4)
- [MySQL 5.0+](https://dev.mysql.com/downloads/mysql)
- [Redis 5.0+](https://redis.io/download/)
- [RabbitMQ](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.10.6)

### 配置修改

#### 1. 应用配置

定位到以下路径修改配置文件:

```
./application/src/main/resources/
./gateway/src/main/resources/
```

编辑 `application.yaml` 文件，修改服务依赖配置:

```yaml
server:
  port: 
spring:
  profiles:
    active: 
...
  nacos:
    discovery:
      server-addr: 
      namespace:
...
nacos:
  config:
    server-addr:
```

#### 2. Nacos 配置

定位到 `./script` 目录，包含以下配置文件:
- `base.json` - 基础配置
- `components.json` - 组件配置
- `database.yaml` - 数据库配置
- `redis.yaml` - Redis配置

进入 Nacos 管理界面 (通常为 http://localhost:8848/nacos)，在目标命名空间中创建上述配置文件并修改相应配置。

#### 3. 数据库初始化

执行数据库初始化脚本:

```bash
cd ./script
sh init.sh [your mysql username] [your mysql password]
```

或者手动执行 `ddl.sql` 文件到 MySQL 管理界面。

### 编译打包

运行以下命令进行编译打包:

```bash
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true
```

当显示完成信息时，表示项目已成功编译打包。

### 运行服务

确保所有依赖服务可用且配置正确后，运行以下命令:

```bash
# 启动应用服务
java -jar -Dfile.encoding=UTF-8 ./application/target/*-SNAPSHOT.jar --server.port=8090

# 启动网关服务 (新终端)
java -jar -Dfile.encoding=UTF-8 ./gateway/target/*-SNAPSHOT.jar --server.port=8088
```

服务启动后，可以通过以下地址访问:
```
http://localhost:8088/sys/user/login
```

## 默认账户

- **用户名**: admin
- **密码**: admin

## 数据库表结构

系统包含以下主要数据表:

### 数据相关表
- `data_resource` - 资源表
- `data_project` - 项目表
- `data_model` - 模型表
- `data_task` - 任务表
- `data_psi` - PSI任务表
- `data_pir_task` - PIR任务表
- `data_reasoning` - 推理表

### 系统相关表
- `sys_user` - 用户表
- `sys_role` - 角色表
- `sys_auth` - 权限表
- `sys_organ` - 机构表
- `sys_file` - 文件表

## 组件配置

系统支持多种联邦学习组件，包括:
- 数据对齐
- 异常值处理
- 联合统计
- 多种机器学习模型 (XGBoost, 逻辑回归, 神经网络等)
- 多种加密方式 (Paillier, CKKS, DPSGD等)

详细组件配置见 `script/components.json` 文件。

## 开发说明

### 项目结构
```
primihub-service/
├── application/     # 应用服务模块
├── biz/            # 业务逻辑模块
├── gateway/        # API网关模块
└── script/         # 配置和初始化脚本
```

### 代码规范
- 使用标准的 Java 编码规范
- 遵循 Spring Cloud 微服务最佳实践
- 支持多数据源和分布式事务

## 故障排除

1. **服务启动失败**: 检查 Nacos、MySQL、Redis、RabbitMQ 服务是否正常运行
2. **数据库连接失败**: 检查 database.yaml 配置中的数据库连接信息
3. **权限认证失败**: 检查用户角色和权限配置
4. **任务执行失败**: 检查组件配置和资源权限

## 许可证

本项目基于相应的开源许可证发布，详见 LICENSE 文件。

## 联系我们

如有问题或建议，请通过项目 Issue 或相关渠道联系我们。
