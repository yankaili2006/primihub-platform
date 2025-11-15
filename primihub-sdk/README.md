# PrimiHub SDK

PrimiHub SDK 是一个用于与 PrimiHub 联邦学习平台交互的 Java SDK，支持多种隐私计算任务的提交和管理。

## 功能特性

- **多任务类型支持**: 支持模型训练、PSI、PIR、推理、联合统计、数据集注册等多种任务类型
- **gRPC通信**: 基于 gRPC 协议与 PrimiHub 平台进行高效通信
- **TLS支持**: 支持 TLS 加密通信，保障数据传输安全
- **缓存机制**: 内置缓存服务，支持任务状态管理
- **异步任务管理**: 支持任务状态轮询和任务取消功能
- **模板化配置**: 使用 Freemarker 模板引擎进行任务配置

## 支持的算法类型

### 机器学习算法
- **异构逻辑回归** (hetero_lr)
- **异构XGBoost** (hetero_xgb) 
- **同构逻辑回归** (homo_lr)
- **同构神经网络** (homo_nn_binary)
- **数据对齐** (data_align)

### 隐私计算算法
- **隐私集合求交** (PSI)
  - ECDH 算法
  - KKRT 算法  
  - TEE 算法
- **隐私信息检索** (PIR)
- **多方安全计算** (MPC)

## 快速开始

### 添加依赖

```xml
<dependency>
    <groupId>com.primihub</groupId>
    <artifactId>primihub-sdk</artifactId>
    <version>1.0.1</version>
</dependency>
```

### 基本使用

#### 1. 初始化 SDK

```java
import com.primihub.sdk.config.GrpcClientConfig;
import com.primihub.sdk.task.TaskHelper;

// 配置 gRPC 客户端
GrpcClientConfig config = new GrpcClientConfig();
config.setAddress("localhost");  // PrimiHub 服务地址
config.setPort(50050);           // PrimiHub 服务端口

// 初始化 TaskHelper
TaskHelper taskHelper = TaskHelper.getInstance(config);
```

#### 2. 提交 PSI 任务

```java
import com.primihub.sdk.task.param.TaskPSIParam;
import com.primihub.sdk.task.param.TaskParam;

// 创建 PSI 任务参数
TaskPSIParam psiParam = new TaskPSIParam();
psiParam.setClientData("client_dataset_id");  // 发起方数据集ID
psiParam.setServerData("server_dataset_id");  // 协作方数据集ID
psiParam.setPsiType(0);                       // 0:交集, 1:差集
psiParam.setPsiTag(0);                        // 0:ECDH, 1:KKRT, 2:TEE
psiParam.setClientIndex(new Integer[]{0});    // 发起方数据列索引
psiParam.setServerIndex(new Integer[]{0});    // 协作方数据列索引
psiParam.setOutputFullFilename("/path/to/output"); // 输出文件路径

// 创建任务参数
TaskParam<TaskPSIParam> taskParam = new TaskParam<>(psiParam);

// 提交任务
taskHelper.submit(taskParam);
```

#### 3. 提交机器学习任务

```java
import com.primihub.sdk.task.param.TaskComponentParam;

// 创建组件任务参数
TaskComponentParam componentParam = new TaskComponentParam();
componentParam.setModel("hetero_lr");         // 模型类型
componentParam.setProcess("train");           // 训练过程
componentParam.setLearningRate(0.1);          // 学习率
componentParam.setEpoch(10);                  // 训练轮数
componentParam.setBatchSize(100);             // 批次大小

// 设置角色和数据
componentParam.setGuestDataset("guest_dataset_id");
componentParam.setHostDataset("host_dataset_id");
componentParam.setArbiterDataset("arbiter_dataset_id");

TaskParam<TaskComponentParam> taskParam = new TaskParam<>(componentParam);
taskHelper.submit(taskParam);
```

#### 4. 轮询任务状态

```java
// 持续获取任务状态
taskHelper.continuouslyObtainTaskStatus(taskParam);

// 检查任务状态
if (taskParam.getEnd()) {
    if (taskParam.getSuccess()) {
        System.out.println("任务执行成功");
    } else {
        System.out.println("任务执行失败: " + taskParam.getError());
    }
}
```

#### 5. 取消任务

```java
// 取消指定任务
TaskParam result = taskHelper.killTask("task_id");
```

## 配置说明

### GrpcClientConfig 配置项

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| address | String | - | PrimiHub 服务地址 |
| port | Integer | - | PrimiHub 服务端口 |
| useTls | boolean | false | 是否启用 TLS 加密 |
| trustCertFilePath | String | - | 信任证书文件路径 |
| keyCertChainFile | String | - | 客户端证书链文件路径 |
| keyFile | String | - | 客户端私钥文件路径 |
| cacheType | String | "CaffeineCacheService" | 缓存服务类型 |

### 任务类型枚举

| 任务类型 | 枚举值 | 说明 |
|----------|--------|------|
| MODEL | 1 | 模型训练任务 |
| PSI | 2 | 隐私集合求交任务 |
| PIR | 3 | 隐私信息检索任务 |
| REASONING | 4 | 模型推理任务 |
| JOINT_STATISTICAL | 5 | 联合统计任务 |
| DATA_SET | 6 | 数据集注册任务 |

## 高级功能

### TLS 加密通信

```java
GrpcClientConfig config = new GrpcClientConfig();
config.setAddress("localhost");
config.setPort(50050);
config.setUseTls(true);
config.setTrustCertFilePath("/path/to/trust.crt");
config.setKeyCertChainFile("/path/to/client.crt");
config.setKeyFile("/path/to/client.key");
```

### 自定义缓存服务

SDK 使用 SPI 机制支持自定义缓存服务实现，默认使用 Caffeine 缓存。

## 项目结构

```
primihub-sdk/
├── src/main/java/com/primihub/sdk/
│   ├── config/              # 配置类
│   │   └── GrpcClientConfig.java
│   ├── constant/            # 常量定义
│   │   └── TaskConstant.java
│   ├── grpc/               # gRPC 相关
│   │   └── channel/
│   │       └── GrpcChannel.java
│   ├── task/               # 任务相关核心类
│   │   ├── Functional.java
│   │   ├── TaskHelper.java
│   │   ├── annotation/     # 注解
│   │   ├── cache/          # 缓存服务
│   │   ├── dataenum/       # 枚举类型
│   │   ├── factory/        # 工厂类
│   │   └── param/          # 参数类
│   └── util/               # 工具类
│       ├── FreemarkerTemplate.java
│       └── TemplatesHelper.java
├── src/main/resources/
│   ├── META-INF/services/  # SPI 配置
│   ├── proto/              # gRPC proto 文件
│   └── templates/          # 任务模板
└── pom.xml
```

## 依赖说明

- **gRPC**: 用于与 PrimiHub 平台通信
- **Caffeine**: 提供高性能缓存功能
- **Freemarker**: 模板引擎，用于任务配置生成
- **Fastjson**: JSON 处理库
- **SLF4J**: 日志门面

## 开发指南

### 扩展新的任务类型

1. 在 `TaskTypeEnum` 中添加新的任务类型
2. 创建对应的参数类，使用 `@TaskTypeExample` 注解指定执行工厂
3. 实现对应的 `AbstractGRPCExecuteFactory` 子类
4. 在 `META-INF/services` 中注册工厂类

### 自定义缓存服务

1. 实现 `CacheService` 接口
2. 在 `META-INF/services/com.primihub.sdk.task.cache.CacheService` 中注册实现类
3. 在 `GrpcClientConfig` 中设置对应的缓存类型

## 许可证

Apache License 2.0

## 相关链接

- [PrimiHub 官网](https://primihub.com)
- [GitHub 仓库](https://github.com/primihub/primihub-platform)
