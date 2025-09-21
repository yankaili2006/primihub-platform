# FL (Federated Learning) Service

一个基于 Django 的联邦学习服务，提供机器学习工作流管理和树模型训练功能。

## 项目概述

该项目是一个联邦学习服务平台，包含两个主要模块：
- **job_api**: 机器学习工作流管理，支持多种ML组件和任务调度
- **tree_api**: 基于 FedLearner 的联邦树模型训练服务

## 功能特性

### job_api 功能
- 支持深度优先搜索（DFS）遍历模型组件
- 多种机器学习组件支持：
  - 模型训练 (model)
  - 数据对齐 (dataAlignment)
  - 特征工程 (features)
  - 采样处理 (sample)
  - 异常处理 (exception)
  - 特征编码 (featureCoding)
  - 模型评估 (assessment)
- 异步任务执行（ThreadPoolExecutor）
- 训练结果可视化（matplotlib图表生成）
- 训练指标存储和查询

### tree_api 功能
- 基于 FedLearner 的联邦树模型训练
- 支持 leader-follower 架构
- 多种树模型参数配置
- 训练结果输出和指标计算

## 技术栈

- **后端框架**: Django 4.0.4
- **数据库**: MySQL (通过 pymysql 连接)
- **服务发现**: Nacos (nacos-sdk-python)
- **机器学习**: FedLearner (tree model trainer)
- **数据可视化**: matplotlib
- **并发处理**: concurrent.futures.ThreadPoolExecutor

## 项目结构

```
fl/
├── manage.py                 # Django 管理脚本
├── requirements.txt          # 项目依赖
├── config/                   # 配置模块
│   ├── __init__.py
│   └── mysql_util.py        # MySQL 数据库工具类
├── fl/                      # Django 项目配置
│   ├── __init__.py
│   ├── settings.py          # 项目设置
│   ├── urls.py             # 主路由配置
│   ├── asgi.py
│   └── wsgi.py
├── job_api/                 # 工作流API应用
│   ├── __init__.py
│   ├── urls.py             # API路由
│   └── views.py            # 业务逻辑
└── tree_api/               # 树模型API应用
    ├── __init__.py
    ├── urls.py             # API路由
    └── views.py            # 业务逻辑
```

## API 接口

### job_api 接口

**POST /job_api/run**
- 功能：执行机器学习工作流
- 请求体：JSON格式的工作流配置
- 响应：执行状态

示例请求体：
```json
{
  "modelId": "模型ID",
  "modelComponents": [
    {
      "componentId": "组件ID",
      "componentCode": "组件类型",
      "componentValues": [{"key": "参数名", "val": "参数值"}],
      "input": [{"componentId": "输入组件ID"}],
      "output": [{"componentId": "输出组件ID"}]
    }
  ],
  "resources": [
    {
      "filePath": "数据文件路径"
    }
  ]
}
```

### tree_api 接口

**GET /tree_api/**
- 功能：测试接口
- 响应：简单的测试数据

**GET /tree_api/run**
- 功能：执行树模型训练
- 参数：
  - `role`: 角色 (leader/follower)
  - `local_addr`: 本地地址
  - `peer_addr`: 对端地址
  - `data_path`: 数据路径
  - `output_path`: 输出路径

## 数据库配置

项目使用 MySQL 数据库，配置信息在 `config/mysql_util.py` 中：

```python
MYSQL_HOST_NAME = '192.168.0.109'
MYSQL_PORT = 3306
MYSQL_USER = 'root'
MYSQL_PASSWD = '1qazmko0'
MYSQL_DB = 'privacy'
```

数据库表结构包括：
- `data_component`: 存储组件执行状态和时间
- `data_model_quota`: 存储模型评估指标

## 安装和运行

### 环境要求
- Python 3.8+
- MySQL 5.7+
- Nacos 服务（可选）

### 安装步骤

1. 克隆项目
2. 安装依赖：
   ```bash
   pip install -r requirements.txt
   ```

3. 配置数据库：
   - 修改 `config/mysql_util.py` 中的数据库连接信息
   - 创建数据库 `privacy` 和相关表

4. 运行项目：
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

### 数据库初始化

需要创建以下表结构：

```sql
CREATE TABLE data_component (
    component_id INT PRIMARY KEY,
    component_state INT,
    start_time BIGINT,
    end_time BIGINT
);

CREATE TABLE data_model_quota (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quota_type INT,
    quota_images VARCHAR(255),
    model_id INT,
    component_id INT,
    auc DECIMAL(10,4),
    ks DECIMAL(10,4),
    gini DECIMAL(10,4),
    precision DECIMAL(10,4),
    recall DECIMAL(10,4),
    f1_score DECIMAL(10,4),
    is_del TINYINT DEFAULT 0
);
```

## 配置说明

### 文件路径配置
在 `job_api/views.py` 中配置：
```python
train_img_url = '/data/fileimages'    # 训练图片存储路径
train_exp_url = '/data/result'        # 训练结果存储路径
```

### 服务地址配置
在 `job_api/views.py` 中配置：
```python
task_follower_addr = 'localhost:50051'  # Follower 服务地址
task_leader_addr = 'localhost:50052'    # Leader 服务地址
```

## 使用示例

### 启动工作流
```bash
curl -X POST http://localhost:8000/job_api/run \
  -H "Content-Type: application/json" \
  -d '{
    "modelId": 1,
    "modelComponents": [...],
    "resources": [...]
  }'
```

### 执行树模型训练
```bash
curl "http://localhost:8000/tree_api/run?role=leader&local_addr=localhost:50052&peer_addr=localhost:50051&data_path=/data/leader.csv&output_path=/output/leader.out"
```

## 注意事项

1. 确保 MySQL 服务正常运行并已创建所需数据库
2. 确保文件存储路径存在且有写入权限
3. FedLearner 相关服务需要单独部署和配置
4. 生产环境建议修改 SECRET_KEY 和关闭 DEBUG 模式

## 开发说明

- 项目使用 Django 4.0.4 开发
- 数据库操作通过自定义的 MySqlConnection 类实现
- 异步任务处理使用 ThreadPoolExecutor
- 图表生成使用 matplotlib

## 许可证

Apache License 2.0
