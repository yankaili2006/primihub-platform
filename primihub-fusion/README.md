# Primihub Fusion Platform

Primihub Fusion 是一个基于 Spring Boot 构建的数据融合平台，提供机构注册、资源管理和群组协作功能。该平台支持多方安全计算环境下的数据资源共享与协作。

## 功能特性

- **机构管理**: 支持机构注册、连接状态检查和信息更新
- **资源管理**: 提供数据资源的上传、查询、标签管理和权限控制
- **群组协作**: 支持创建群组并管理机构成员
- **RESTful API**: 提供完整的 REST API 接口
- **MySQL 存储**: 使用 MySQL 数据库进行数据持久化

## 技术栈

- **后端框架**: Spring Boot 2.3.8.RELEASE
- **数据库**: MySQL 8.0+
- **ORM**: MyBatis 3.4.1
- **连接池**: Druid 1.1.21
- **JSON 处理**: FastJSON 1.2.70
- **构建工具**: Maven
- **JDK 版本**: 1.8

## 快速开始

### 环境要求

- JDK 1.8+
- Maven 3.6+
- MySQL 5.7+ 或 8.0+

### 数据库配置

1. 创建 MySQL 数据库:
   ```sql
   CREATE DATABASE fusion CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. 执行初始化脚本:
   ```bash
   mysql -u root -p fusion < ./script/init.sql
   ```

### 配置文件修改

编辑 `./fusion-api/src/main/resources/application.yaml` 文件，修改数据库连接配置:

```yaml
spring:
  datasource:
    druid:
      username: your_username
      url: jdbc:mysql://your_host:3306/fusion?characterEncoding=UTF-8&serverTimezone=Asia/Shanghai
      password: your_password
```

### 编译和打包

```bash
mvn clean install -Dmaven.test.skip=true
```

### 运行应用

```bash
java -jar -Dfile.encoding=UTF-8 ./fusion-api/target/fusion-api-1.0-SNAPSHOT.jar
```

默认服务端口为 8099，可以通过 `--server.port` 参数指定其他端口。

### 健康检查

应用启动后，可以通过以下接口检查服务状态:

```bash
curl http://localhost:8099/fusion/healthConnection
```

## API 接口

### 机构管理接口

- `POST /fusion/registerConnection` - 注册机构连接
- `POST /fusion/changeConnection` - 更新机构信息  
- `GET /fusion/findOrganByGlobalId` - 根据机构ID查询机构信息
- `GET /fusion/healthConnection` - 健康检查

### 资源管理接口

- `GET /fusionResource/getResourceList` - 获取资源列表
- `GET /fusionResource/getResourceListById` - 根据ID获取资源列表
- `GET /fusionResource/getResourceTagList` - 获取资源标签列表
- `GET /fusionResource/getDataResource` - 获取具体资源详情

### 群组管理接口

- `POST /group/createGroup` - 创建群组
- `POST /group/joinGroup` - 加入群组
- `GET /group/getGroupList` - 获取群组列表

## 数据库表结构

### 核心表

- `fusion_organ` - 机构信息表
- `fusion_resource` - 资源信息表
- `fusion_resource_tag` - 资源标签表
- `fusion_group` - 群组信息表
- `fusion_go` - 群组成员关系表
- `fusion_resource_visibility_auth` - 资源可见性权限表

## Docker 部署

项目提供了 Docker 支持，可以使用以下命令构建和运行:

```bash
# 构建镜像
docker build -t primihub-fusion .

# 运行容器
docker run -d -p 8099:8099 --name primihub-fusion primihub-fusion
```

## 开发指南

### 项目结构

```
primihub-fusion/
├── fusion-api/                 # 主应用模块
│   ├── src/main/java/
│   │   └── com/primihub/
│   │       ├── controller/     # 控制器层
│   │       ├── service/        # 服务层
│   │       ├── repository/     # 数据访问层
│   │       ├── entity/         # 实体类
│   │       └── util/           # 工具类
│   └── src/main/resources/     # 配置文件
├── script/                     # 数据库脚本
└── pom.xml                     # Maven 配置
```

### 代码规范

- 使用 Lombok 简化代码
- 统一的异常处理机制
- RESTful API 设计规范
- 数据库表字段使用下划线命名法

## 故障排除

### 常见问题

1. **数据库连接失败**: 检查 application.yaml 中的数据库配置
2. **端口冲突**: 修改 server.port 配置或使用 --server.port 参数
3. **编码问题**: 确保使用 UTF-8 编码运行应用

### 日志查看

应用日志默认输出到控制台，可以通过修改 `application.yaml` 中的日志配置来调整日志级别和输出位置。

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 许可证

本项目基于 Apache 2.0 许可证开源。
