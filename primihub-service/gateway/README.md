# PrimiHub Gateway

## 概述

PrimiHub Gateway是基于Spring Cloud Gateway构建的API网关服务，作为PrimiHub平台的前端入口，负责请求路由、认证授权、参数验证等核心功能。

## 架构设计

### 核心组件

#### 1. 网关过滤器 (Gateway Filters)

网关采用过滤器链模式处理请求，按执行顺序包括：

- **BaseParamGatewayFilterFactory** (Order: 10)
  - 基础参数验证：timestamp、nonce、token、sign
  - 支持多种Content-Type：表单、JSON、查询参数、multipart/form-data
  - 智能参数提取：根据Content-Type自动从不同位置提取参数
  - 请求耗时统计
  - IP地址获取并添加到请求头

- **SysAuthGatewayFilterFactory** (Order: 11)
  - 用户身份认证和权限验证
  - Token有效性检查（支持特殊Token绕过认证）
  - 接口访问权限控制（基于用户角色和权限列表）
  - 用户信息传递：认证通过后将userId和token添加到请求头

- **SysLogGatewayFilterFactory** (Order: 20)
  - 系统日志记录（当前为空实现，预留扩展）

- **SwaggerGatewayFilterFactory** (Order: 200)
  - Swagger文档访问控制（支持配置开关）
  - 请求耗时统计
  - 特定URL模式匹配检查

#### 2. 路由配置

网关配置了多个路由规则：

```yaml
routes:
  - id: test-url-proxy
    uri: lb://platform
    predicates:
      - Path=/test/**
    filters:
      - StripPrefix=1
      - BaseParam
      - SysAuth
      - SysLog

  - id: sys-url-proxy
    uri: lb://platform
    predicates:
      - Path=/sys/**
    filters:
      - StripPrefix=1
      - BaseParam
      - SysAuth
      - SysLog

  - id: data-url-proxy
    uri: lb://platform
    predicates:
      - Path=/data/**
    filters:
      - StripPrefix=1
      - BaseParam
      - SysAuth
      - SysLog

  - id: share-url-proxy
    uri: lb://platform
    predicates:
      - Path=/share/**
    filters:
      - StripPrefix=1
      - BaseParam
      - SysAuth
      - SysLog

  - id: swagger-url-proxy
    uri: lb://platform
    predicates:
      - Path=/platform/**
    filters:
      - StripPrefix=1
      - Swagger
      - SysAuth
```

#### 3. Swagger集成

- **SwaggerResourceConfig**: 动态聚合所有微服务的Swagger文档
- **SwaggerHandlerController**: 处理Swagger相关请求
- 支持通过配置开关控制Swagger访问权限

## 核心功能

### 1. 认证授权

- **Token验证**: 验证用户登录状态和Token有效性
- **权限控制**: 基于用户角色和权限列表进行接口访问控制
- **特殊Token**: 支持配置特殊Token绕过认证
- **用户信息传递**: 认证通过后将userId和token添加到请求头中传递给后端服务

### 2. 参数验证

- **必填参数**: timestamp、nonce
- **条件参数**: token、sign（根据配置决定是否必需）
- **多格式支持**: 支持查询参数、表单数据、JSON格式、multipart/form-data
- **智能参数提取**: 根据Content-Type自动从不同位置提取参数
- **IP地址获取**: 自动获取客户端IP地址并添加到请求头

### 3. 路由转发

- **负载均衡**: 使用服务发现进行负载均衡
- **路径重写**: 支持StripPrefix过滤器去除前缀
- **跨域支持**: 配置全局CORS策略
- **服务代理**: 将所有请求代理到platform服务

### 4. 监控统计

- **请求耗时**: 记录每个请求的处理时间
- **日志记录**: 记录请求路径和处理时间
- **性能监控**: 支持请求处理时间统计和性能分析

### 5. Swagger文档聚合

- **动态聚合**: 自动发现并聚合所有微服务的Swagger文档
- **访问控制**: 支持通过配置开关控制Swagger访问权限
- **文档排序**: 自动对服务文档进行排序，避免混乱

## 配置说明

### 主要配置文件

- `application.yaml`: 主配置文件
- `application-dev.yaml`: 开发环境配置
- `application-test*.yaml`: 测试环境配置
- `application-demo*.yaml`: 演示环境配置
- `application-dc*.yaml`: 数据中心配置

### 关键配置项

```yaml
server:
  port: 8080

spring:
  application:
    name: gateway
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          '[/**]':
            allowedOrigins: "*"
            allowedHeaders: "*"
            allowedMethods: "*"
```

## 依赖关系

### 主要依赖

- `spring-cloud-starter-gateway`: Spring Cloud Gateway核心
- `primihub-biz`: 业务逻辑模块
- `nacos-config`: 配置中心集成
- `nacos-discovery`: 服务发现

### 排除的组件

网关排除了以下不必要的组件：
- Web相关组件（使用WebFlux）
- 任务调度相关
- 数据库连接池
- 消息队列消费者
- 缓存服务

## 部署运行

### 1. 环境要求

- Java 8+
- Spring Boot 2.3.7+
- Nacos配置中心

### 2. 启动命令

```bash
mvn spring-boot:run
```

或

```bash
java -jar gateway-1.0-SNAPSHOT.jar
```

### 3. 配置中心

网关从Nacos配置中心读取以下配置：
- `base.json`: 基础配置
- `database.yaml`: 数据库配置
- `redis.yaml`: Redis配置

## 开发指南

### 1. 添加新的过滤器

1. 继承`AbstractGatewayFilterFactory`
2. 使用`@Component`注解注册
3. 使用`@Order`指定执行顺序
4. 在配置文件中添加过滤器到路由

### 2. 添加新的路由

在`application.yaml`中添加路由配置：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: new-route
          uri: lb://service-name
          predicates:
            - Path=/new-path/**
          filters:
            - StripPrefix=1
            - BaseParam
            - SysAuth
```

### 3. 自定义配置

在Nacos配置中心添加自定义配置项，通过`@Value`或配置类注入使用。

## 故障排除

### 常见问题

1. **Token验证失败**
   - 检查Redis连接状态
   - 验证Token格式和有效期

2. **路由转发失败**
   - 检查服务发现状态
   - 验证目标服务健康状态

3. **参数验证失败**
   - 检查请求参数格式
   - 验证必填参数是否完整

### 日志配置

日志配置使用`logback-privacy.xml`，支持隐私数据脱敏。

## 性能优化建议

1. **过滤器优化**: 合理设置过滤器执行顺序，避免不必要的处理
2. **缓存策略**: 对权限数据等频繁访问的数据进行缓存
3. **连接池**: 配置合适的HTTP连接池参数
4. **监控告警**: 集成监控系统，设置关键指标告警

## 安全考虑

1. **Token安全**: 使用安全的Token生成和验证机制
2. **权限控制**: 严格限制接口访问权限
3. **参数验证**: 防止参数注入攻击
4. **IP地址验证**: 自动获取并验证客户端IP地址
5. **请求签名**: 支持请求签名验证，防止请求篡改

## 技术实现细节

### 1. 参数验证机制

BaseParam过滤器支持多种Content-Type的参数提取：

- **查询参数**: 从URL查询字符串中提取
- **表单数据**: 从application/x-www-form-urlencoded中提取
- **JSON数据**: 从application/json请求体中提取
- **文件上传**: 从multipart/form-data中提取

### 2. 认证流程

SysAuth过滤器执行以下认证流程：

1. **Token提取**: 从请求参数或请求头中提取token
2. **特殊Token检查**: 检查是否为配置的特殊Token
3. **用户状态验证**: 从Redis中查询用户登录状态
4. **权限验证**: 根据用户角色和权限列表验证接口访问权限
5. **用户信息传递**: 将userId和token添加到请求头传递给后端

### 3. Swagger文档聚合

SwaggerResourceConfig自动发现所有注册的服务：

- 从网关路由中获取所有服务名称
- 排除gateway自身服务
- 动态生成Swagger文档URL
- 支持服务文档排序和去重

### 4. 性能监控

所有过滤器都支持请求耗时统计：

- 记录请求开始时间
- 在请求完成后计算处理时间
- 输出格式：`请求路径:处理时间ms`
- 便于性能分析和问题排查

### 5. 配置管理

网关使用Nacos配置中心管理配置：

- 支持配置动态刷新
- 多环境配置支持
- 配置项包括：基础配置、数据库配置、Redis配置
