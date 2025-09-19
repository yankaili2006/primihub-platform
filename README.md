[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# PrimiHub Platform - 多方计算与联邦学习任务调度平台

PrimiHub Platform 是一个面向多方安全计算（MPC）和联邦学习（FL）的点对点服务安全调度平台，提供生产级的服务能力。

## 🚀 核心特性

### 数据安全与隐私保护
- **多方安全计算（MPC）**: 支持安全多方计算协议
- **联邦学习（FL）**: 分布式机器学习框架支持
- **私有集合交集（PSI）**: 安全的数据交集计算
- **私有信息检索（PIR）**: 保护查询隐私的信息检索

### 平台核心功能
- **数据接入管理**: 统一的数据源接入和权限控制
- **多方资源融合**: 跨组织数据资源的安全融合
- **任务调度引擎**: 分布式任务调度和执行管理
- **联邦模型注册**: 多方联邦学习模型管理和版本控制
- **合作权限管理**: 细粒度的多方协作权限控制
- **可视化操作**: 完整的Web控制台界面

## 🏗️ 系统架构

PrimiHub Platform 采用微服务架构，包含三个核心模块：

```
primihub-platform/
├── primihub-fusion/          # 数据融合服务 (Spring Boot)
│   ├── fusion-api/          # 融合API接口
│   └── script/              # 数据库初始化脚本
├── primihub-service/        # 核心业务服务 (Spring Cloud)
│   ├── application/         # 应用主服务
│   ├── biz/                 # 业务逻辑模块
│   ├── gateway/             # API网关服务
│   └── script/              # 配置和数据库脚本
└── primihub-webconsole/     # Web管理控制台 (Vue.js)
    ├── src/
    │   ├── api/             # API接口定义
    │   ├── components/      # 可复用组件
    │   ├── views/           # 页面视图
    │   └── ...
    └── public/              # 静态资源
```

## 📦 技术栈

### 后端技术
- **Java 8**: 主要开发语言
- **Spring Boot 2.3.7**: 应用框架
- **Spring Cloud**: 微服务架构
- **MyBatis**: 数据持久层
- **MySQL**: 关系型数据库
- **Redis**: 缓存和会话管理
- **RabbitMQ**: 消息队列
- **gRPC**: 高性能RPC通信
- **Nacos**: 服务发现和配置管理

### 前端技术
- **Vue.js 2.6**: 前端框架
- **Element UI**: UI组件库
- **Vuex**: 状态管理
- **Vue Router**: 路由管理
- **AntV X6**: 图形可视化
- **ECharts**: 数据图表
- **Axios**: HTTP客户端

## 🚀 快速开始

### 环境要求
- JDK 1.8+
- Maven 3.6+
- Node.js 12+
- MySQL 5.7+
- Redis 5.0+
- Nacos 2.0.3+
- RabbitMQ

### 1. 启动Primihub节点
首先参考 [primihub](https://github.com/primihub/primihub) 项目启动计算节点。

### 2. 部署后端服务

#### primihub-fusion (数据融合服务)
```bash
cd primihub-fusion
mvn clean install -Dmaven.test.skip=true
java -jar -Dfile.encoding=UTF-8 ./fusion-api/target/*-SNAPSHOT.jar --server.port=8090
```

#### primihub-service (核心业务服务)
```bash
cd primihub-service
# Linux
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=linux-x86_64
# Windows/Mac
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=windows-x86_64

# 启动应用服务
java -jar -Dfile.encoding=UTF-8 ./application/target/*-SNAPSHOT.jar --server.port=8090

# 启动网关服务
java -jar -Dfile.encoding=UTF-8 ./gateway/target/*-SNAPSHOT.jar --server.port=8088
```

### 3. 部署前端控制台
```bash
cd primihub-webconsole
npm install
npm run dev
```

访问地址: http://localhost:8080

## 📋 功能模块

### 数据管理
- 数据资源接入和注册
- 数据权限管理
- 数据预览和元数据管理

### 项目管理
- 多方协作项目管理
- 项目成员和权限管理
- 项目生命周期管理

### 任务调度
- PSI任务创建和执行
- PIR任务管理
- 联邦学习任务调度
- 任务状态监控

### 模型管理
- 联邦学习模型注册
- 模型版本管理
- 模型部署和推理

### 组织管理
- 参与方组织管理
- 组织间协作关系
- 组织权限控制

### 系统管理
- 用户和角色管理
- 系统配置管理
- 操作日志审计

## 🔧 配置说明

详细配置请参考各子模块的README文档：
- [primihub-fusion配置](./primihub-fusion/README.md)
- [primihub-service配置](./primihub-service/README.md) 
- [primihub-webconsole配置](./primihub-webconsole/README.md)

## 📄 许可证

[Apache License 2.0](./LICENSE)

## 🤝 贡献

欢迎提交Issue和Pull Request来帮助改进Primihub Platform。

## 📞 支持

如有问题请通过GitHub Issues联系我们。
