# Primihub Gateway Service

基于Spring Cloud Gateway的API网关服务，为Primihub平台提供统一的API入口、认证授权、请求路由等功能。

## 功能特性

- ✅ **API路由**: 统一的路由管理，支持路径匹配和负载均衡
- ✅ **认证授权**: Token验证和权限控制
- ✅ **参数验证**: 基础参数(timestamp, nonce, token, sign)校验
- ✅ **请求日志**: 请求处理时间记录
- ✅ **跨域支持**: 全局CORS配置
- ✅ **配置中心**: 集成Nacos配置管理
- ✅ **服务发现**: 集成Nacos服务注册发现

## 技术栈

- **框架**: Spring Boot 2.3.7 + Spring Cloud Gateway
- **配置中心**: Nacos
- **认证**: 基于Token的权限验证
- **日志**: Logback + Slf4j

## 项目结构

```
src/main/java/com/primihub/gateway/
├── GatewayApplication.java      # 应用启动类
├── config/
│   └── GatewayConfig.java       # 网关配置类
└── filter/
    ├── BaseParamGatewayFilterFactory.java    # 基础参数验证过滤器
    ├── SysAuthGatewayFilterFactory.java      # 权限验证过滤器
    ├── SysLogGatewayFilterFactory.java       # 日志记录过滤器
    └── GatewayFilterFactoryTool.java         # 过滤器工具类
```

## 路由配置

网关配置了以下路由规则：

| 路由ID | 路径模式 | 目标服务 | 过滤器 |
|--------|----------|----------|--------|
| test-url-proxy | `/test/**` | platform服务 | StripPrefix=1, BaseParam, SysAuth, SysLog |
| sys-url-proxy | `/sys/**` | platform服务 | StripPrefix=1, BaseParam, SysAuth, SysLog |
| data-url-proxy | `/data/**` | platform服务 | StripPrefix=1, BaseParam, SysAuth, SysLog |
| share-url-proxy | `/share/**` | platform服务 | StripPrefix=1, BaseParam, SysAuth, SysLog |

## 过滤器说明

### 1. BaseParamGatewayFilterFactory (Order=10)
基础参数验证过滤器，验证以下参数：
- `timestamp`: 时间戳（必填）
- `nonce`: 随机数（必填）
- `token`: 访问令牌（可选，根据配置）
- `sign`: 签名（可选，根据配置）

支持多种Content-Type：
- 表单数据 (multipart/form-data)
- JSON (application/json)
- 查询参数

### 2. SysAuthGatewayFilterFactory (Order=11)
权限验证过滤器：
- 验证Token有效性
- 检查用户访问权限
- 将userId和token添加到请求头传递给下游服务

### 3. SysLogGatewayFilterFactory (Order=20)
日志记录过滤器（当前为空实现）

## 配置说明

### 主要配置文件
- `application.yaml`: 主配置文件，包含路由规则和基本配置
- `application-dev.yaml`: 开发环境配置
- `application-test*.yaml`: 测试环境配置
- `application-demo*.yaml`: 演示环境配置
- `application-dc*.yaml`: 数据中心环境配置

### Nacos配置
网关使用Nacos作为配置中心，主要配置项：
- `base.json`: 基础配置
- `database.yaml`: 数据库配置
- `redis.yaml`: Redis配置

## 启动方式

### 1. Maven启动
```bash
cd primihub-service/gateway
mvn spring-boot:run
```

### 2. 打包运行
```bash
mvn clean package
java -jar target/gateway-1.0-SNAPSHOT.jar
```

### 3. Docker运行
```bash
# 构建镜像
docker build -t primihub-gateway .

# 运行容器
docker run -d -p 8080:8080 --name primihub-gateway primihub-gateway
```

## 环境要求

- JDK 1.8+
- Maven 3.6+
- Nacos Server 1.4+
- Redis (用于Token存储)

## 部署说明

### 开发环境
1. 启动Nacos服务（localhost:8848）
2. 启动Redis服务
3. 运行网关应用
4. 访问地址：http://localhost:8080

### 生产环境
1. 配置Nacos集群
2. 配置Redis集群
3. 使用Docker或Kubernetes部署
4. 配置负载均衡和健康检查

## 注意事项

1. **Token验证**: 部分URL路径可以配置免Token验证（通过`tokenValidateUriBlackList`配置）
2. **签名验证**: 特定URL路径需要签名验证（通过`needSignUriList`配置）
3. **文件上传**: 支持最大10MB的文件上传
4. **性能监控**: 记录每个请求的处理时间

## 相关依赖

- `primihub-service/biz`: 业务模块，提供权限服务和配置管理
- `spring-cloud-starter-gateway`: Spring Cloud Gateway核心依赖
- `nacos-config-spring-boot-starter`: Nacos配置中心客户端

## 版本信息

- 当前版本: 1.0-SNAPSHOT
- Spring Boot: 2.3.7.RELEASE
- Spring Cloud: Hoxton.SR9

## 开发指南

### 添加新的路由
在`application.yaml`的`spring.cloud.gateway.routes`下添加新的路由配置。

### 自定义过滤器
继承`AbstractGatewayFilterFactory`类实现自定义过滤器，并在配置中引用。

### 配置管理
通过Nacos配置中心动态修改网关配置，支持热更新。

## 问题排查

1. **路由不生效**: 检查Nacos配置是否正确加载
2. **权限验证失败**: 检查Redis连接和Token状态
3. **参数验证失败**: 检查请求参数是否符合要求

## 贡献指南

欢迎提交Issue和Pull Request来改进网关功能。
