# PrimiHub Platform 故障排查指南

本文档记录了在部署和使用PrimiHub平台过程中遇到的常见问题及解决方案。

## 目录

- [部署问题](#部署问题)
- [数据库问题](#数据库问题)
- [联邦学习(FL)问题](#联邦学习fl问题)
- [网络通信问题](#网络通信问题)

---

## 部署问题

### 1. Docker镜像拉取超时

**问题描述**:
```
failed to resolve reference "docker.io/library/rabbitmq:3-management":
dial tcp 199.59.150.12:443: i/o timeout
```

**原因**: Docker Hub连接超时，网络问题导致无法拉取镜像。

**解决方案**:

#### 方案1: 使用简化部署（推荐）
使用H2内存数据库代替MySQL，避免Docker依赖：

```bash
cd primihub-service/application
./start-minimal.sh
```

#### 方案2: 配置Docker镜像加速
```bash
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com"
  ]
}

# 重启Docker
sudo systemctl restart docker
```

#### 方案3: 使用国内镜像
修改 `docker-compose.yml` 使用国内镜像源（参考 `docker-compose-cn.yml`）。

---

### 2. RabbitMQ连接失败

**问题描述**:
```
org.springframework.amqp.AmqpConnectException:
java.net.ConnectException: Connection refused (Connection refused)
```

**原因**: RabbitMQ服务未启动，但应用尝试连接。

**解决方案**:

#### 方案1: 禁用RabbitMQ自动配置（开发环境）
```bash
java -jar application.jar \
  --spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration
```

在 `start-minimal.sh` 中已包含此配置。

#### 方案2: 启动RabbitMQ服务（生产环境）
```bash
docker run -d --name rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3-management
```

---

## 数据库问题

### 1. 字段缺失错误

**问题描述**:
```
org.h2.jdbc.JdbcSQLSyntaxErrorException: Column "ip" not found
```

**原因**: H2数据库schema定义中缺少某些字段。

**解决方案**:

修改 `primihub-service/application/src/main/resources/schema-complete-h2.sql`，添加缺失字段：

```sql
CREATE TABLE IF NOT EXISTS sys_user (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_account VARCHAR(64) NOT NULL,
    user_password VARCHAR(128) NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    role_id_list VARCHAR(255) NOT NULL,
    is_forbid TINYINT NOT NULL,
    is_editable TINYINT NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    auth_uuid VARCHAR(255),
    ip VARCHAR(255),  -- 添加此字段
    register_type TINYINT NOT NULL,
    UNIQUE KEY ix_unique_user_account (user_account)
);
```

**配置文件更新**:

确保 `application-simple.yaml` 使用完整schema：
```yaml
spring:
  sql:
    init:
      schema-locations: classpath:schema-complete-h2.sql
      data-locations: classpath:data-complete-h2.sql
```

---

## 联邦学习(FL)问题

### 1. ERROR: 265 - Python依赖缺失

**问题描述**:
```
E20260102 06:13:07.618520 1075049 worker.cc:184] ERROR: 265
ModuleNotFoundError: No module named 'sklearn'
ModuleNotFoundError: No module named 'loguru'
ModuleNotFoundError: No module named 'phe'
ModuleNotFoundError: No module named 'opacus'
```

**原因**: FL训练需要的Python包未安装。

**解决方案**:

在primihub虚拟环境中安装依赖：

```bash
cd /home/primihub/github/primihub
source venv/bin/activate  # 如果使用虚拟环境

pip install --no-cache-dir \
  loguru \
  scikit-learn \
  phe \
  opacus
```

---

### 2. PyTorch版本不兼容

**问题描述**:
```
AttributeError: module 'torch.nn' has no attribute 'RMSNorm'
```
或
```
ImportError: cannot import name 'DiagnosticOptions' from 'torch.onnx._internal.exporter'
```

**原因**: PyTorch版本过旧或不兼容。

**解决方案**:

#### ✅ 推荐配置（已验证）

```bash
# 升级到PyTorch 2.6.0 CPU版本
pip install --no-cache-dir \
  torch==2.6.0+cpu \
  torchvision==0.21.0+cpu \
  --index-url https://download.pytorch.org/whl/cpu
```

#### 完整依赖列表

| 包 | 推荐版本 | 说明 |
|---|---------|------|
| Python | 3.10-3.12 | 3.12.3已验证 |
| torch | 2.6.0+cpu | ✅ 必须2.6+ |
| torchvision | 0.21.0+cpu | 匹配torch版本 |
| opacus | 1.4.0+ | 差分隐私 |
| scikit-learn | 1.8.0+ | 机器学习 |
| loguru | 0.7.3+ | 日志 |
| phe | 1.5.0+ | 同态加密 |
| numpy | 1.26.4+ | 数值计算 |

#### 验证安装

```bash
python -c "
import torch
import opacus
import sklearn
import loguru
import phe

print('✅ 依赖验证成功')
print(f'torch: {torch.__version__}')
print(f'opacus: {opacus.__version__}')
print(f'sklearn: {sklearn.__version__}')
print(f'torch.nn.RMSNorm存在: {hasattr(torch.nn, \"RMSNorm\")}')
"
```

**预期输出**:
```
✅ 依赖验证成功
torch: 2.6.0+cpu
opacus: 1.4.0
sklearn: 1.8.0
torch.nn.RMSNorm存在: True
```

---

### 3. 磁盘空间不足

**问题描述**:
```
ERROR: Could not install packages due to an OSError: [Errno 28] No space left on device
```

**原因**: 安装PyTorch CUDA版本或缓存占用过多空间。

**解决方案**:

#### 使用CPU版本（推荐）
```bash
# CPU版本体积小得多（~200MB vs >2GB）
pip install --no-cache-dir \
  torch==2.6.0+cpu \
  --index-url https://download.pytorch.org/whl/cpu
```

#### 清理pip缓存
```bash
pip cache purge
```

#### 清理临时文件
```bash
# 清理系统临时文件
sudo rm -rf /tmp/*

# 清理Docker缓存
docker system prune -af
```

---

### 4. 数据集路径问题

**问题描述**: FL任务提示找不到数据集。

**解决方案**:

确认数据集存在：
```bash
cd /home/primihub/github/primihub

# 检查HFL数据集
ls -l data/FL/binclass/hfl/train/client*.csv

# 应该看到
# data/FL/binclass/hfl/train/client1.csv
# data/FL/binclass/hfl/train/client2.csv
```

如果数据集不存在，从示例数据复制：
```bash
# 查找可用数据集
find data/FL -name "*.csv" -type f
```

---

## 网络通信问题

### 1. PSI任务party count为0

**问题描述**:
```
E20260102 06:04:03.852171 1049994 cli.cc:519] party count from reply is: 0
```

**原因**: Meta Service未启动，节点无法协调。

**解决方案**:

启动Meta Service（至少3个节点）：

```bash
cd /home/primihub/github/primihub-meta

# 启动Meta Service节点0
java -jar fusion-simple.jar \
  --server.port=7977 \
  --grpc.server.port=9090 &

# 启动Meta Service节点1
java -jar fusion-simple.jar \
  --server.port=7978 \
  --grpc.server.port=9091 &

# 启动Meta Service节点2
java -jar fusion-simple.jar \
  --server.port=7979 \
  --grpc.server.port=9092 &

# 验证启动
curl http://localhost:7977/health
curl http://localhost:7978/health
curl http://localhost:7979/health
```

---

### 2. 计算节点无法连接

**问题描述**: gRPC连接失败。

**解决方案**:

检查计算节点状态：
```bash
# 检查节点进程
ps aux | grep "bazel-bin/node"

# 应该看到3个节点进程
# node0: 127.0.0.1:50050
# node1: 127.0.0.1:50051
# node2: 127.0.0.1:50052

# 检查端口监听
netstat -tlnp | grep -E "50050|50051|50052"
```

如果节点未运行，启动计算节点：
```bash
cd /home/primihub/github/primihub

# 启动3个节点（示例）
./bazel-bin/node --config=config/node0.yaml &
./bazel-bin/node --config=config/node1.yaml &
./bazel-bin/node --config=config/node2.yaml &
```

---

## 快速诊断命令

### 检查所有服务状态

```bash
#!/bin/bash

echo "=== 平台服务检查 ==="
echo "前端(8080): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)"
echo "后端(8090): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090)"

echo ""
echo "=== Meta Service检查 ==="
echo "Meta0(7977): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:7977/health)"
echo "Meta1(7978): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:7978/health)"
echo "Meta2(7979): $(curl -s -o /dev/null -w "%{http_code}" http://localhost:7979/health)"

echo ""
echo "=== 计算节点检查 ==="
NODE_COUNT=$(ps aux | grep "bazel-bin/node" | grep -v grep | wc -l)
echo "运行中的节点数: $NODE_COUNT (应该为3)"

echo ""
echo "=== Python环境检查 ==="
/home/primihub/github/primihub/venv/bin/python -c "
import sys
try:
    import torch, sklearn, loguru, phe, opacus
    print('✅ Python依赖: 正常')
    print(f'   torch: {torch.__version__}')
except ImportError as e:
    print(f'❌ Python依赖: 缺失 - {e}')
"

echo ""
echo "=== 磁盘空间检查 ==="
df -h / | tail -1 | awk '{print "根分区使用: "$5" (剩余: "$4")"}'
```

保存为 `check_services.sh` 并运行：
```bash
chmod +x check_services.sh
./check_services.sh
```

---

## 常见问题FAQ

### Q1: 如何重置开发环境？

**A**: 停止所有服务，清理数据，重新启动：

```bash
# 停止服务
pkill -f "application.jar"
pkill -f "fusion-simple.jar"
pkill -f "npm run serve"

# 清理H2数据库（如果需要）
rm -rf ~/primihub*.db

# 重新启动
cd primihub-service/application
./start-minimal.sh
```

### Q2: 如何查看详细日志？

**A**:
```bash
# 平台服务日志
tail -f /tmp/test-service.log

# 计算节点日志
tail -f /home/primihub/github/primihub/log_node0
tail -f /home/primihub/github/primihub/log_node1
tail -f /home/primihub/github/primihub/log_node2

# FL训练日志
tail -f /tmp/fl_training*.log
```

### Q3: 如何测试各个功能？

**A**:
```bash
cd /home/primihub/github/primihub

# PSI测试 (307ms)
./primihub-cli --task_config_file=example/psi_ecdh_task_conf.json

# PIR测试 (429ms)
./primihub-cli --task_config_file=example/keyword_pir_task_conf.json

# FL测试 (~8s)
./primihub-cli --task_config_file=example/FL/neural_network/hfl_binclass_plaintext.json
```

---

## 已知问题

### 1. Python 3.12兼容性

- **状态**: ✅ 已解决
- **问题**: 旧版requirements.txt针对Python 3.7-3.10设计
- **解决**: 升级torch到2.6.0+cpu

### 2. PyTorch 1.13.1不可用

- **状态**: ⚠️ 已知限制
- **问题**: PyTorch官方镜像不再提供1.13.1版本
- **解决**: 使用torch 2.6.0+cpu替代

### 3. Docker镜像拉取慢

- **状态**: ⚠️ 网络问题
- **问题**: Docker Hub在国内访问慢
- **解决**: 使用镜像加速或简化部署模式

---

## 获取帮助

如果遇到本文档未覆盖的问题，可以：

1. **查看日志**: 检查 `/tmp/*.log` 和节点日志
2. **提交Issue**: https://github.com/primihub/primihub-platform/issues
3. **社区支持**: 加入PrimiHub Slack频道

---

**文档更新日期**: 2026-01-02
**适用版本**: PrimiHub v0.1.0+
