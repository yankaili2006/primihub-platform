# PrimiHub Service Biz 模块

## 概述

PrimiHub Service Biz 模块是 PrimiHub 平台的核心业务逻辑模块，负责处理联邦学习、隐私计算相关的业务功能，包括数据资源管理、隐私求交(PSI)、模型训练、任务调度等核心功能。

## 模块结构

```
primihub-service/biz/
├── src/main/java/com/primihub/biz/
│   ├── config/           # 配置类
│   │   ├── base/         # 基础配置
│   │   └── mq/           # 消息队列配置
│   ├── constant/         # 常量定义
│   ├── convert/          # 数据转换器
│   ├── entity/           # 实体类
│   │   ├── base/         # 基础实体
│   │   ├── data/         # 数据相关实体
│   │   ├── event/        # 事件实体
│   │   ├── fusion/       # 融合相关实体
│   │   └── sys/          # 系统实体
│   ├── filter/           # 过滤器
│   ├── repository/       # 数据访问层
│   │   ├── primarydb/    # 主数据库访问
│   │   └── secondarydb/  # 从数据库访问
│   ├── service/          # 业务服务层
│   │   ├── data/         # 数据服务
│   │   ├── feign/        # Feign客户端
│   │   ├── schedule/     # 定时任务
│   │   ├── share/        # 共享服务
│   │   ├── sys/          # 系统服务
│   │   └── test/         # 测试服务
│   ├── tool/             # 工具类
│   └── util/             # 工具类
├── src/main/resources/
│   ├── images/           # 图片资源
│   ├── mybatis/          # MyBatis映射文件
│   └── templates/        # 模板文件
└── bin/                  # 二进制文件
    └── seatunnel-client.jar
```

## 核心功能

### 1. 数据资源管理 (DataResourceService)

- **资源创建**: 支持文件上传和数据库连接两种方式创建数据资源
- **资源查询**: 支持按条件分页查询资源列表
- **资源编辑**: 修改资源信息和标签
- **资源删除**: 软删除资源记录
- **资源预览**: 预览CSV文件或数据库表数据
- **资源同步**: 将资源同步到数据集中

### 2. 隐私求交 (PSI) 服务 (DataPsiService)

- **PSI任务创建**: 创建隐私求交任务
- **任务管理**: 查询、取消、重试PSI任务
- **资源分配**: 获取可用于PSI的资源列表
- **结果处理**: 处理PSI任务结果

### 3. 数据源管理 (DataSourceService)

- **数据库连接**: 支持多种数据库类型连接
- **表结构分析**: 分析数据库表结构
- **数据统计**: 统计表数据量和Y值分布

### 4. 模型服务 (DataModelService)

- **模型创建**: 创建联邦学习模型
- **模型训练**: 执行模型训练任务
- **模型评估**: 评估模型性能
- **模型部署**: 部署训练好的模型

### 5. 项目服务 (DataProjectService)

- **项目管理**: 创建和管理联邦学习项目
- **资源关联**: 关联项目与数据资源
- **权限控制**: 控制项目访问权限

### 6. 任务调度 (DataAsyncService)

- **异步任务**: 异步执行计算密集型任务
- **任务状态**: 跟踪任务执行状态
- **结果处理**: 处理任务执行结果

## 技术栈

- **框架**: Spring Boot 2.x
- **数据库**: MySQL + SQLite
- **ORM**: MyBatis
- **缓存**: Redis
- **消息队列**: RabbitMQ
- **服务调用**: Feign Client
- **配置中心**: Nacos
- **文档**: Swagger
- **构建工具**: Maven

## 核心依赖

```xml
<dependencies>
    <!-- PrimiHub SDK -->
    <dependency>
        <groupId>com.primihub</groupId>
        <artifactId>primihub-sdk</artifactId>
        <version>1.0.1</version>
    </dependency>
    
    <!-- 数据库相关 -->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
    </dependency>
    <dependency>
        <groupId>org.xerial</groupId>
        <artifactId>sqlite-jdbc</artifactId>
    </dependency>
    
    <!-- 缓存 -->
    <dependency>
        <groupId>redis.clients</groupId>
        <artifactId>jedis</artifactId>
    </dependency>
    
    <!-- 消息队列 -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-stream-rabbit</artifactId>
    </dependency>
    
    <!-- 验证码 -->
    <dependency>
        <groupId>com.anji-plus</groupId>
        <artifactId>captcha</artifactId>
    </dependency>
</dependencies>
```

## 配置说明

### 基础配置 (base.json)

```json
{
    "grpcClient": {
        "address": "192.168.99.20",
        "port": 50050,
        "useTls": false
    },
    "uploadUrlDirPrefix": "/data/upload/",
    "resultUrlDirPrefix": "/data/result/",
    "tokenValidateUriBlackList": [
        "/user/login",
        "/user/register"
    ]
}
```

### 数据库配置

支持多数据源配置：
- **主数据库**: 用于写操作
- **从数据库**: 用于读操作

## 核心实体

### DataResource (数据资源)
```java
public class DataResource {
    private Long resourceId;           // 资源ID
    private String resourceName;       // 资源名称
    private Integer resourceAuthType;  // 授权类型 (1:公开, 2:私有)
    private Integer resourceSource;    // 资源来源 (1:文件, 2:数据库)
    private String resourceFusionId;   // 融合资源ID
    private Integer resourceState;     // 资源状态 (0:上线, 1:下线)
}
```

### DataPsi (隐私求交)
```java
public class DataPsi {
    private Long id;                   // PSI ID
    private String ownResourceId;      // 自有资源ID
    private String otherResourceId;    // 对方资源ID
    private String otherOrganId;       // 对方机构ID
    private Integer outputContent;     // 输出内容 (0:交集, 1:差集)
}
```

### DataSource (数据源)
```java
public class DataSource {
    private Long id;                   // 数据源ID
    private String dbType;             // 数据库类型
    private String dbUrl;              // 数据库URL
    private String dbTableName;        // 表名
    private String dbUsername;         // 用户名
    private String dbPassword;         // 密码
}
```

## 使用示例

### 创建数据资源
```java
@DataResourceReq req = new DataResourceReq();
req.setResourceName("测试资源");
req.setResourceSource(1); // 文件上传
req.setFileId(123L);

BaseResultEntity result = dataResourceService.saveDataResource(req, userId);
```

### 创建PSI任务
```java
@DataPsiReq req = new DataPsiReq();
req.setOwnResourceId("resource_123");
req.setOtherResourceId("resource_456");
req.setOutputContent(0); // 交集

BaseResultEntity result = dataPsiService.saveDataPsi(req, userId);
```

## 部署说明

1. **环境要求**:
   - Java 8+
   - MySQL 5.7+
   - Redis
   - RabbitMQ

2. **配置修改**:
   - 修改数据库连接配置
   - 配置Redis连接
   - 配置RabbitMQ连接
   - 配置Nacos地址

3. **启动命令**:
   ```bash
   mvn spring-boot:run
   ```

## 注意事项

1. **文件上传**: 确保上传目录有写权限
2. **数据库连接**: 配置正确的数据库连接信息
3. **资源同步**: 资源创建后会同步到数据集中
4. **任务状态**: 异步任务状态需要定期轮询

## 故障排除

1. **资源创建失败**: 检查文件路径和数据库连接
2. **PSI任务失败**: 检查资源ID和机构配置
3. **数据库连接失败**: 检查数据库配置和网络连接
4. **消息队列异常**: 检查RabbitMQ服务状态

## 扩展开发

### 添加新的数据源类型
1. 在 `SourceEnum` 中添加新的数据源类型
2. 在 `DataSourceService` 中添加对应的处理逻辑
3. 更新数据库配置

### 添加新的计算任务
1. 创建对应的Service类
2. 在 `DataAsyncService` 中添加异步执行逻辑
3. 添加任务状态跟踪

## 联系支持

如有问题请联系开发团队或查看项目文档。
