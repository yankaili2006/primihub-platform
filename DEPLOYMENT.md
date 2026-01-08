# PrimiHub Platform 快速部署指南

本文档提供PrimiHub平台的快速部署方法，适用于开发和测试环境。

## 目录

- [最小化部署（推荐）](#最小化部署推荐)
- [完整部署](#完整部署)
- [验证部署](#验证部署)

---

## 最小化部署（推荐）

### 系统要求

- **操作系统**: Linux (Ubuntu 20.04+推荐)
- **Java**: JDK 17+
- **Node.js**: v16+
- **Maven**: 3.6+
- **Python**: 3.10-3.12
- **磁盘空间**: 至少10GB可用空间

### 1. 部署平台服务

#### 1.1 启动后端服务

```bash
cd /path/to/primihub-platform/primihub-service/application

# 使用简化启动脚本（H2数据库）
./start-minimal.sh
```

**说明**:
- 使用H2内存数据库，无需MySQL
- 自动禁用RabbitMQ依赖
- 监听端口: 8090

#### 1.2 启动前端服务

```bash
cd /path/to/primihub-platform/primihub-webconsole

# 安装依赖（首次）
npm install

# 启动开发服务器
npm run serve
```

**访问地址**: http://localhost:8080
**默认账号**: admin / admin

---

### 2. 部署计算节点

#### 2.1 准备Python环境

```bash
cd /path/to/primihub

# 创建虚拟环境（推荐）
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install --no-cache-dir \
  torch==2.6.0+cpu \
  torchvision==0.21.0+cpu \
  --index-url https://download.pytorch.org/whl/cpu

pip install --no-cache-dir \
  loguru \
  scikit-learn \
  phe \
  opacus \
  numpy \
  pandas \
  grpcio \
  protobuf
```

**重要**: 必须使用 `torch 2.6.0+cpu` 或更高版本，否则FL功能会失败。

#### 2.2 验证Python依赖

```bash
python -c "
import torch
import sklearn
import loguru
import phe
import opacus

print('✅ 所有依赖已安装')
print(f'torch: {torch.__version__}')
print(f'sklearn: {sklearn.__version__}')
print(f'torch.nn.RMSNorm: {hasattr(torch.nn, \"RMSNorm\")}')
"
```

**预期输出**:
```
✅ 所有依赖已安装
torch: 2.6.0+cpu
sklearn: 1.8.0
torch.nn.RMSNorm: True
```

#### 2.3 启动计算节点（如果未运行）

计算节点通常已经在运行。检查状态：

```bash
ps aux | grep "bazel-bin/node"
```

如果需要启动：
```bash
cd /path/to/primihub

# 启动3个节点
./bazel-bin/node --config=config/node0.yaml &
./bazel-bin/node --config=config/node1.yaml &
./bazel-bin/node --config=config/node2.yaml &
```

---

### 3. 部署Meta Service

Meta Service用于任务协调和节点发现。

```bash
cd /path/to/primihub-meta

# 启动3个Meta Service节点
java -jar fusion-simple.jar --server.port=7977 --grpc.server.port=9090 &
java -jar fusion-simple.jar --server.port=7978 --grpc.server.port=9091 &
java -jar fusion-simple.jar --server.port=7979 --grpc.server.port=9092 &
```

**验证启动**:
```bash
curl http://localhost:7977/health
curl http://localhost:7978/health
curl http://localhost:7979/health
```

---

## 验证部署

### 1. 检查服务状态

```bash
# 平台服务
curl http://localhost:8090/actuator/health
curl http://localhost:8080

# Meta Service
curl http://localhost:7977/health

# 计算节点
ps aux | grep "bazel-bin/node" | grep -v grep | wc -l
# 应该输出: 3
```

### 2. 运行功能测试

#### 测试PSI (隐私集合求交)

```bash
cd /path/to/primihub

./primihub-cli --task_config_file=example/psi_ecdh_task_conf.json
```

**预期结果**:
```
✅ party count: 2
✅ all node has finished
✅ party name: CLIENT msg: task finished
✅ party name: SERVER msg: task finished
✅ 执行时间: ~300ms
```

#### 测试PIR (隐匿查询)

```bash
./primihub-cli --task_config_file=example/keyword_pir_task_conf.json
```

**预期结果**:
```
✅ party count: 2
✅ all node has finished
✅ 执行时间: ~400ms
```

#### 测试FL (联邦学习)

```bash
./primihub-cli --task_config_file=example/FL/neural_network/hfl_binclass_plaintext.json
```

**预期结果**:
```
✅ party count: 3
✅ party name: Alice msg: task finished
✅ party name: Bob msg: task finished
✅ party name: Charlie msg: task finished
✅ 执行时间: ~8s
✅ 准确率: ~98%
```

查看训练结果：
```bash
cat data/result/Bob_metrics.json
ls -lh data/result/*_model.pkl
```

---

## 完整部署

如果需要使用完整的生产环境配置（MySQL + RabbitMQ + Redis）：

### 1. 准备依赖服务

```bash
# MySQL
docker run -d --name mysql \
  -e MYSQL_ROOT_PASSWORD=primihub \
  -e MYSQL_DATABASE=primihub \
  -p 3306:3306 \
  mysql:8.0

# RabbitMQ
docker run -d --name rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3-management

# Redis
docker run -d --name redis \
  -p 6379:6379 \
  redis:7
```

### 2. 配置应用

修改 `application.yaml`:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/primihub
    username: root
    password: primihub

  rabbitmq:
    host: localhost
    port: 5672
    username: guest
    password: guest

  redis:
    host: localhost
    port: 6379
```

### 3. 初始化数据库

```bash
cd primihub-service/application

# 执行SQL脚本
mysql -uroot -pprimihub primihub < src/main/resources/schema-complete-h2.sql
mysql -uroot -pprimihub primihub < src/main/resources/data-complete-h2.sql
```

### 4. 启动服务

```bash
cd primihub-service/application

# 使用完整配置启动
mvn clean package -DskipTests
java -jar target/application.jar
```

---

## 架构说明

```
┌─────────────────────────────────────────────────────────┐
│                    Web前端 (Vue.js)                      │
│                       :8080                              │
└─────────────────────────────────────────────────────────┘
                           │
                           │
┌─────────────────────────────────────────────────────────┐
│               平台后端 (Spring Boot)                     │
│                       :8090                              │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
┌───────────────────┐              ┌──────────────────────┐
│  Meta Service     │              │   计算节点集群        │
│   (3节点集群)      │              │   (3节点)            │
│  :7977-7979       │              │   :50050-50052       │
└───────────────────┘              └──────────────────────┘
        │                                     │
        └──────────────────┬──────────────────┘
                           │
                 ┌─────────────────┐
                 │  隐私计算任务     │
                 │  PSI/PIR/FL/MPC  │
                 └─────────────────┘
```

---

## 端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端 | 8080 | Vue.js开发服务器 |
| 后端 | 8090 | Spring Boot应用 |
| Meta Service | 7977-7979 | HTTP端口 |
| Meta Service | 9090-9092 | gRPC端口 |
| 计算节点 | 50050-50052 | gRPC端口 |
| MySQL | 3306 | 数据库（可选） |
| RabbitMQ | 5672/15672 | 消息队列（可选） |
| Redis | 6379 | 缓存（可选） |

---

## 环境变量配置

创建 `.env` 文件（可选）：

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=primihub
DB_USER=root
DB_PASSWORD=primihub

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379

# RabbitMQ配置
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# 应用配置
SERVER_PORT=8090
FRONTEND_PORT=8080
```

---

## 常见启动脚本

### start-all.sh - 启动所有服务

```bash
#!/bin/bash

echo "启动Meta Service..."
cd /path/to/primihub-meta
java -jar fusion-simple.jar --server.port=7977 --grpc.server.port=9090 > /tmp/meta0.log 2>&1 &
java -jar fusion-simple.jar --server.port=7978 --grpc.server.port=9091 > /tmp/meta1.log 2>&1 &
java -jar fusion-simple.jar --server.port=7979 --grpc.server.port=9092 > /tmp/meta2.log 2>&1 &

echo "启动平台后端..."
cd /path/to/primihub-platform/primihub-service/application
./start-minimal.sh > /tmp/backend.log 2>&1 &

echo "启动平台前端..."
cd /path/to/primihub-platform/primihub-webconsole
npm run serve > /tmp/frontend.log 2>&1 &

echo "等待服务启动..."
sleep 10

echo "检查服务状态..."
curl -s http://localhost:8090/actuator/health || echo "❌ 后端未就绪"
curl -s http://localhost:7977/health || echo "❌ Meta Service未就绪"

echo "✅ 所有服务已启动"
echo "前端: http://localhost:8080"
echo "后端: http://localhost:8090"
```

### stop-all.sh - 停止所有服务

```bash
#!/bin/bash

echo "停止服务..."
pkill -f "application.jar"
pkill -f "fusion-simple.jar"
pkill -f "npm run serve"

echo "✅ 所有服务已停止"
```

---

## 故障排查

遇到问题请参考 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

常见问题：
- [Docker镜像拉取超时](./TROUBLESHOOTING.md#1-docker镜像拉取超时)
- [数据库字段缺失](./TROUBLESHOOTING.md#1-字段缺失错误)
- [FL依赖问题](./TROUBLESHOOTING.md#1-error-265---python依赖缺失)
- [PyTorch版本不兼容](./TROUBLESHOOTING.md#2-pytorch版本不兼容)

---

## 下一步

部署完成后，您可以：

1. **使用Web界面**: 访问 http://localhost:8080 创建项目和任务
2. **使用命令行**: 运行 `primihub-cli` 执行隐私计算任务
3. **查看文档**: https://docs.primihub.com
4. **运行示例**: 参考 `example/` 目录中的配置文件

---

**文档更新日期**: 2026-01-02
**适用版本**: PrimiHub v0.1.0+
