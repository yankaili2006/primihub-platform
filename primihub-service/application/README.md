# PrimiHub Application Service

PrimiHub Application Service 是 PrimiHub 管理平台的核心业务应用服务，基于 Spring Boot 和 Spring Cloud 构建，提供完整的隐私计算管理功能。

## 🏗️ 架构概述

Application Service 是 PrimiHub 管理平台的主要业务服务，包含以下核心功能模块：

- **数据管理**: 数据资源注册、管理和同步
- **模型管理**: 机器学习模型部署和训练
- **项目管理**: 多方协作项目管理
- **安全认证**: JWT 认证和权限控制
- **任务调度**: 异步任务处理和调度

## 📋 技术栈

- **Java 8**: 主要开发语言
- **Spring Boot 2.3.7**: 应用框架
- **Spring Cloud**: 微服务架构
- **Nacos**: 服务发现和配置管理
- **MySQL**: 数据库存储
- **Redis**: 缓存和会话管理
- **RabbitMQ**: 消息队列
- **Spring REST Docs**: API 文档生成

## 🚀 快速开始

### 环境要求

- JDK 1.8+
- Maven 3.6+
- Nacos 2.0.3+
- MySQL 5.7+
- Redis 5.0+

### 构建项目

```bash
# Linux/macOS
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=osx-x86_64

# Windows
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=windows-x86_64
```

### 运行应用

```bash
java -jar -Dfile.encoding=UTF-8 target/application-1.0-SNAPSHOT.jar --server.port=8090
```

## 📊 API 接口

### 数据管理接口

| 端点 | 方法 | 描述 |
|------|------|------|
| `/resource/*` | GET/POST | 数据资源管理 |
| `/fusionResource/*` | GET/POST | 联邦数据资源管理 |
| `/project/*` | GET/POST | 项目管理 |

### 隐私计算接口

| 端点 | 方法 | 描述 |
|------|------|------|
| `/psi/*` | POST | PSI（隐私集合求交）任务 |
| `/pir/*` | POST | PIR（隐私信息检索）任务 |
| `/mpc/*` | POST | 安全多方计算任务 |

### 系统管理接口

| 端点 | 方法 | 描述 |
|------|------|------|
| `/user/*` | GET/POST | 用户管理 |
| `/role/*` | GET/POST | 角色管理 |
| `/auth/*` | GET/POST | 权限管理 |
| `/organ/*` | GET/POST | 机构管理 |

### 文件管理接口

| 端点 | 方法 | 描述 |
|------|------|------|
| `/file/*` | GET/POST | 文件上传和管理 |

## ⚙️ 配置说明

### 应用配置

主要配置文件位于 `src/main/resources/`:

- `application.yaml`: 主配置文件
- `application-dev.yaml`: 开发环境配置
- `application-prod.yaml`: 生产环境配置
- `bootstrap.yaml`: 启动配置

### Nacos 配置依赖

应用依赖以下 Nacos 配置：

- `base.json`: 基础配置
- `database.yaml`: 数据库配置
- `redis.yaml`: Redis 配置

## 🧪 测试

### 单元测试

运行所有单元测试：

```bash
mvn test
```

### API 测试

项目包含完整的控制器测试：

```bash
# 运行特定测试类
mvn test -Dtest=DataResourceControllerTest
```

## 📁 项目结构

```
src/main/java/com/primihub/application/
├── PlatformApplication.java      # 应用启动类
├── controller/                   # 控制器层
│   ├── data/                    # 数据相关控制器
│   │   ├── FusionResourceController.java
│   │   ├── ModelController.java
│   │   ├── MpcController.java
│   │   ├── PirController.java
│   │   ├── ProjectController.java
│   │   ├── PsiController.java
│   │   └── ResourceController.java
│   ├── schedule/                # 调度控制器
│   │   └── ScheduleController.java
│   ├── share/                   # 数据共享控制器
│   │   └── ShareDataController.java
│   ├── sys/                     # 系统管理控制器
│   │   ├── AuthController.java
│   │   ├── CommonController.java
│   │   ├── FileController.java
│   │   ├── FusionController.java
│   │   ├── OrganController.java
│   │   ├── RoleController.java
│   │   └── UserController.java
│   └── test/                    # 测试控制器
│       └── TestController.java
└── resources/                   # 资源文件
    ├── asciidoc/               # API 文档源文件
    └── application-*.yaml      # 配置文件
```

## 🔧 开发指南

### 添加新功能

1. 在 `controller` 包下创建新的控制器类
2. 使用 `@RestController` 和 `@RequestMapping` 注解
3. 实现相应的业务逻辑
4. 添加单元测试
5. 更新 API 文档

### API 文档生成

项目使用 Spring REST Docs 生成 API 文档：

```bash
mvn clean install -Dasciidoctor.skip=false
```

生成的文档位于 `target/generated-docs/` 目录。

## 🐛 故障排除

### 常见问题

1. **Nacos 连接失败**
   - 检查 Nacos 服务是否运行
   - 验证命名空间配置

2. **数据库连接问题**
   - 检查 MySQL 服务状态
   - 验证数据库配置

3. **端口冲突**
   - 修改 `server.port` 配置

### 日志查看

应用日志默认输出到控制台，可通过以下配置调整日志级别：

```yaml
logging:
  level:
    com.primihub: DEBUG
```

## 🤝 贡献指南

1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/新功能`)
3. 提交更改 (`git commit -m '添加新功能'`)
4. 推送到分支 (`git push origin feature/新功能`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 Apache License 2.0 许可证 - 详见 LICENSE 文件。

## 🆘 支持

如需技术支持：
- 查看故障排除章节
- 检查应用日志获取错误详情
- 确保所有依赖服务正常运行
- 验证配置文件正确设置

---

**注意**: 这是 PrimiHub 管理平台的应用服务组件。如需完整功能，请确保网关服务和其他组件正确配置和运行。
