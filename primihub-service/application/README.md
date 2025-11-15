# PrimiHub Service Application

## 项目概述

PrimiHub Service Application 是基于 Spring Boot 构建的隐私计算平台后端服务，提供数据资源管理、隐私计算任务执行、系统管理等功能。该项目是 PrimiHub 平台的核心服务模块。

## 技术架构

### 技术栈
- **框架**: Spring Boot 2.3.12.RELEASE
- **服务发现**: Spring Cloud Alibaba Nacos
- **消息队列**: Spring Cloud Stream + RabbitMQ
- **数据库**: MySQL (通过 Druid 连接池)
- **缓存**: Redis
- **构建工具**: Maven
- **Java版本**: 1.8

### 项目结构
```
primihub-service/application/
├── src/main/java/com/primihub/application/
│   ├── PlatformApplication.java          # 应用启动类
│   ├── controller/                       # 控制器层
│   │   ├── data/                         # 数据相关接口
│   │   │   ├── ResourceController.java   # 资源管理
│   │   │   ├── PsiController.java        # 隐私求交
│   │   │   ├── PirController.java        # 隐私信息检索
│   │   │   ├── ModelController.java      # 模型管理
│   │   │   ├── ProjectController.java    # 项目管理
│   │   │   ├── TaskController.java       # 任务管理
│   │   │   ├── ReasoningController.java  # 推理任务
│   │   │   ├── FusionResourceController.java # 融合资源
│   │   │   ├── MarketController.java     # 市场管理
│   │   │   └── SourceController.java     # 数据源管理
│   │   ├── sys/                          # 系统管理接口
│   │   │   ├── AuthController.java       # 权限管理
│   │   │   ├── UserController.java       # 用户管理
│   │   │   ├── OrganController.java      # 机构管理
│   │   │   ├── RoleController.java       # 角色管理
│   │   │   ├── FileController.java       # 文件管理
│   │   │   ├── CaptchaController.java    # 验证码
│   │   │   ├── OauthController.java      # OAuth认证
│   │   │   └── CommonController.java     # 通用接口
│   │   ├── schedule/                     # 调度接口
│   │   ├── share/                        # 数据共享接口
│   │   ├── stream/                       # 流处理接口
│   │   └── test/                         # 测试接口
│   └── resources/                        # 配置文件
│       ├── application.yaml              # 主配置文件
│       ├── bootstrap.yaml                # 启动配置
│       ├── hazelcast-client.yaml         # 缓存配置
│       └── logback-privacy.xml           # 日志配置
└── pom.xml                               # Maven配置
```

## 功能模块

### 1. 数据资源管理 (ResourceController)
- **资源管理**: 创建、查询、更新、删除数据资源
- **资源类型**: 支持文件上传和数据库连接两种数据源
- **字段管理**: 资源字段的增删改查
- **权限控制**: 资源访问权限管理
- **文件预览**: 资源文件内容预览
- **数据下载**: 资源文件下载

### 2. 隐私计算任务

#### 隐私求交 (PSI - PsiController)
- **任务创建**: 创建隐私求交任务
- **任务管理**: 查询、取消、重启、删除任务
- **结果下载**: 下载求交结果文件
- **TEE支持**: 支持可信执行环境

#### 隐私信息检索 (PIR - PirController)
- 隐私信息检索任务管理
- 支持多种检索算法

#### 模型推理 (ReasoningController)
- 机器学习模型推理任务
- 支持联邦学习场景

### 3. 系统管理

#### 权限管理 (AuthController)
- **权限节点**: 创建、修改、删除权限节点
- **权限树**: 获取完整的权限树结构
- **权限生成**: 自动生成系统权限

#### 用户管理 (UserController)
- 用户注册、登录、信息管理
- 角色分配和权限控制

#### 机构管理 (OrganController)
- 参与方机构管理
- 机构间协作关系管理

### 4. 项目管理 (ProjectController)
- 多方协作项目管理
- 项目资源分配和权限控制
- 项目进度跟踪

### 5. 文件管理 (FileController)
- 文件上传、下载
- 文件存储管理
- 支持大文件分片上传

## 配置说明

### 主要配置文件

#### application.yaml
```yaml
server:
  port: 8090
spring:
  profiles:
    active: dev
  application:
    name: platform
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB
  datasource:
    druid:
      filter:
        config:
          enabled: true
  rabbitmq:
    host: localhost
    port: 5672
  cloud:
    stream:
      bindings:
        singleTaskOutput:
          destination: singlTaskChannel
        singleTaskInput:
          destination: singlTaskChannel
    nacos:
      discovery:
        server-addr: localhost:8848
        namespace: dev
```

#### Nacos 配置 (base.json)
- 令牌验证黑名单
- 邮件配置
- gRPC 客户端配置
- 文件存储路径配置
- OAuth 认证配置

## 启动配置

### 应用启动类
```java
@SpringBootApplication(scanBasePackages="com.primihub")
@EnableAsync
@ServletComponentScan(basePackages = {"com.primihub.biz.filter"})
@EnableBinding({SingleTaskChannel.class})
@EnableFeignClients(basePackages = {"com.primihub"})
@EnableScheduling
public class PlatformApplication {
    // 启动方法
}
```

### 启用的功能
- **异步处理**: @EnableAsync
- **过滤器扫描**: @ServletComponentScan
- **消息绑定**: @EnableBinding
- **Feign客户端**: @EnableFeignClients
- **定时任务**: @EnableScheduling

## 依赖关系

### 主要依赖
- `primihub-service/biz`: 业务逻辑模块
- `spring-boot-starter-web`: Web服务
- `spring-cloud-starter-alibaba-nacos`: 服务发现和配置管理
- `spring-cloud-stream`: 消息驱动
- `spring-boot-starter-data-redis`: Redis缓存
- `mybatis-spring-boot-starter`: 数据访问
- `druid-spring-boot-starter`: 数据库连接池

## 部署运行

### 环境要求
- Java 8+
- MySQL 5.7+
- Redis
- RabbitMQ
- Nacos Server

### 启动步骤
1. 启动依赖服务 (Nacos, Redis, RabbitMQ, MySQL)
2. 导入数据库脚本 (`script/ddl.sql`)
3. 配置 Nacos 配置中心
4. 运行应用:
```bash
mvn spring-boot:run
```

### Docker 部署
```bash
docker build -t primihub-application .
docker run -p 8090:8090 primihub-application
```

## API 文档

项目使用 Swagger 生成 API 文档，启动后访问:
```
http://localhost:8090/swagger-ui.html
```

## 开发规范

### 代码结构
- 控制器层: 处理 HTTP 请求和响应
- 业务逻辑: 在 biz 模块中实现
- 数据访问: 通过 MyBatis 实现
- 配置管理: 通过 Nacos 动态配置

### 异常处理
- 统一使用 `BaseResultEntity` 返回结果
- 使用 `BaseResultEnum` 定义错误码
- 全局异常处理机制

### 日志管理
- 使用 Logback 配置日志
- 隐私数据脱敏处理
- 结构化日志输出

## 安全特性

- 令牌验证机制
- 接口签名验证
- 数据权限控制
- OAuth 2.0 认证支持
- 隐私数据保护

## 监控和运维

- Spring Boot Actuator 健康检查
- 日志聚合 (Loki)
- 性能监控
- 任务状态跟踪

## 扩展性设计

- 微服务架构支持
- 插件化业务模块
- 可配置的数据源
- 多租户支持

---

*注意: 本文档基于代码分析生成，具体实现细节请参考源代码。*
