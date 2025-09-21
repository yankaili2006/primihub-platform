# Primihub Service Biz Module

## 概述

primihub-service/biz 模块是 Primihub 平台的核心业务逻辑模块，负责处理数据资源管理、隐私计算任务执行、多方安全计算等核心业务功能。

## 模块结构

### 主要包结构

```
src/main/java/com/primihub/biz/
├── config/          # 配置类
│   ├── base/        # 基础配置
│   ├── database/    # 数据库配置
│   ├── grpc/        # gRPC配置
│   ├── mq/          # 消息队列配置
│   ├── redis/       # Redis配置
│   └── thread/      # 线程池配置
├── constant/        # 常量定义
├── convert/         # 数据转换器
├── entity/          # 实体类
│   ├── base/        # 基础实体
│   ├── data/        # 数据相关实体
│   ├── feign/       # Feign客户端实体
│   └── sys/         # 系统实体
├── grpc/            # gRPC客户端和服务端
├── repository/      # 数据访问层
│   ├── primarydb/   # 主数据库访问
│   ├── primaryredis/# 主Redis访问
│   ├── resourceprimarydb/    # 资源主数据库访问
│   ├── resourcesecondarydb/  # 资源从数据库访问
│   └── secondarydb/ # 从数据库访问
├── service/         # 服务层
│   ├── data/        # 数据服务
│   ├── schedule/    # 调度服务
│   ├── sys/         # 系统服务
│   └── test/        # 测试服务
└── util/            # 工具类
```

## 核心功能

### 1. 数据资源管理 (DataResourceService)

- **资源上传**: 支持CSV文件上传和解析
- **资源查询**: 支持按条件查询数据资源列表
- **资源编辑**: 修改资源信息和权限设置
- **资源删除**: 删除资源及相关数据
- **字段管理**: 管理数据资源的字段信息
- **权限控制**: 支持公开和私有资源权限管理

### 2. PSI隐私集合求交服务 (DataPsiService)

- **PSI任务创建**: 创建隐私集合求交任务
- **任务管理**: 查询、取消、重试PSI任务
- **结果处理**: 处理PSI任务结果文件
- **跨组织协作**: 支持多组织间的PSI计算

### 3. MPC多方安全计算服务 (DataMpcService)

- **MPC任务管理**: 创建和管理多方安全计算任务
- **算法支持**: 支持多种安全计算算法
- **任务调度**: 异步执行MPC计算任务

### 4. 项目管理 (DataProjectService)

- **项目创建**: 创建数据项目
- **资源关联**: 关联数据资源到项目
- **权限管理**: 管理项目参与方权限
- **状态跟踪**: 跟踪项目执行状态

### 5. 数据融合服务 (FusionResourceService)

- **跨组织资源访问**: 访问其他组织的资源
- **资源同步**: 同步资源信息到融合节点
- **权限验证**: 验证资源访问权限

## 技术栈

### 后端框架
- **Spring Boot**: 基础框架
- **Spring Data JDBC**: 数据库访问
- **MyBatis**: ORM框架
- **Spring Cloud Stream**: 消息队列
- **gRPC**: 服务间通信

### 数据库
- **MySQL**: 主数据库
- **Redis**: 缓存和会话管理

### 消息队列
- **RabbitMQ**: 异步任务处理

### 其他技术
- **Protobuf**: 数据序列化
- **FreeMarker**: 模板引擎
- **Lombok**: 代码简化
- **FastJSON**: JSON处理

## 配置说明

### 数据库配置
支持多数据源配置：
- 主数据库 (primarydb)
- 从数据库 (secondarydb) 
- 资源主数据库 (resourceprimarydb)
- 资源从数据库 (resourcesecondarydb)

### gRPC配置
- 客户端地址和端口配置
- 服务端端口配置
- 数据集服务配置

### Redis配置
- 主Redis连接池配置
- Redis模板配置

## 核心实体

### DataResource (数据资源)
- 资源基本信息
- 文件相关信息
- 权限设置
- 组织关联

### DataPsi (PSI任务)
- PSI任务配置
- 参与方信息
- 任务状态

### DataMpcTask (MPC任务)
- MPC任务配置
- 算法参数
- 执行状态

### DataProject (数据项目)
- 项目基本信息
- 参与组织
- 关联资源

## 使用示例

### 创建数据资源
```java
DataResourceReq req = new DataResourceReq();
req.setResourceName("示例数据");
req.setFileId(123L);
// 设置其他参数...

BaseResultEntity result = dataResourceService.saveDataResource(req, userId);
```

### 创建PSI任务
```java
DataPsiReq req = new DataPsiReq();
req.setOwnResourceId(ownResourceId);
req.setOtherResourceId(otherResourceId);
req.setServerAddress(serverAddress);
// 设置其他参数...

BaseResultEntity result = dataPsiService.saveDataPsi(req, userId);
```

## 部署说明

### 依赖服务
- MySQL数据库
- Redis服务器
- RabbitMQ消息队列
- gRPC服务端

### 配置要求
- Java 8+
- Maven 3.6+
- 足够的堆内存配置

## 注意事项

1. 文件上传需要配置正确的文件存储路径
2. gRPC服务需要正确配置客户端地址
3. 多数据源配置需要确保数据库连接正确
4. Redis配置需要确保连接池参数合理

## 扩展开发

### 添加新服务
1. 在service包下创建新的服务类
2. 添加对应的实体类和Repository
3. 配置必要的依赖注入

### 添加新算法
1. 实现算法逻辑
2. 添加任务处理服务
3. 配置任务调度

## 版本信息

- 当前版本: 1.0-SNAPSHOT
- 基于Spring Boot 2.x
- 使用gRPC 1.60.2
