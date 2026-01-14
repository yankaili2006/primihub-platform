# PrimiHub Docker-All-In-One 离线部署指南

## 概述

本指南介绍如何在**无互联网连接**的环境中部署 PrimiHub Docker-All-In-One 系统。

---

## 离线部署包内容

离线部署需要准备以下文件和目录:

```
primihub-offline-deploy/
├── primihub-images-YYYYMMDD_HHMMSS.tar    # Docker镜像包 (~2.4GB)
├── import-images.sh                        # 镜像导入脚本
├── export-images.sh                        # 镜像导出脚本（可选）
├── docker-compose.yaml                     # Docker Compose配置文件
├── .env                                    # 环境变量配置
├── deploy.sh                               # 部署脚本（可选）
├── health_check.sh                         # 健康检查脚本（可选）
├── config/                                 # 配置文件目录
│   ├── my.cnf                             # MySQL配置
│   ├── redis.conf                         # Redis配置
│   ├── default0.conf                      # Nginx配置（机构1）
│   ├── default1.conf                      # Nginx配置（机构2）
│   └── default2.conf                      # Nginx配置（机构3）
└── data/
    ├── env/                                # 环境变量文件
    │   ├── mysql.env                      # MySQL环境变量
    │   └── nacos-mysql.env                # Nacos数据库配置
    └── initsql/                            # 数据库初始化SQL
        └── *.sql                           # SQL脚本文件
```

---

## 前提条件

### 目标服务器要求

- **操作系统**: Linux (推荐 Ubuntu 20.04+, CentOS 7+)
- **CPU**: 8核或更多
- **内存**: 32GB或更多
- **磁盘空间**:
  - 系统盘: 至少50GB可用空间
  - 数据盘: 建议500GB+（用于存储数据和日志）
- **网络**: 服务器之间可互通（如果多机部署）

### 必需软件

目标服务器必须预先安装:

1. **Docker** (版本 20.10+)
2. **Docker Compose** (版本 2.0+)

如果未安装，请参考[附录A: 离线安装Docker](#附录a离线安装docker)

---

## 第一步：制作离线部署包（在有网络的机器上）

### 1.1 导出Docker镜像

在**有网络连接**的服务器上执行:

```bash
cd /path/to/primihub-deploy/docker-all-in-one

# 运行导出脚本
./export-images.sh
```

脚本会:
- 检查所有需要的镜像是否存在
- 如果镜像不存在，询问是否拉取
- 导出所有镜像到 tar 文件
- 可选择压缩文件以减小体积

**导出结果**:
- 文件位置: `offline-deploy/primihub-images-YYYYMMDD_HHMMSS.tar`
- 文件大小: ~2.4GB（未压缩）或 ~1.5GB（压缩后）
- 镜像清单: `offline-deploy/image-manifest-YYYYMMDD_HHMMSS.txt`

### 1.2 准备配置文件

确保以下文件和目录完整:

```bash
# 检查必需文件
ls -lh docker-compose.yaml .env
ls -lh config/
ls -lh data/env/
ls -lh data/initsql/
```

### 1.3 打包所有文件

将所有需要的文件打包:

```bash
cd /path/to/primihub-deploy/docker-all-in-one

# 创建打包目录
mkdir -p /tmp/primihub-offline-package

# 复制必需文件
cp docker-compose.yaml /tmp/primihub-offline-package/
cp .env /tmp/primihub-offline-package/
cp import-images.sh /tmp/primihub-offline-package/
cp export-images.sh /tmp/primihub-offline-package/
cp deploy.sh /tmp/primihub-offline-package/
cp health_check.sh /tmp/primihub-offline-package/
cp -r config /tmp/primihub-offline-package/
cp -r data/env /tmp/primihub-offline-package/data/
cp -r data/initsql /tmp/primihub-offline-package/data/

# 复制镜像文件
cp offline-deploy/primihub-images-*.tar* /tmp/primihub-offline-package/

# 打包
cd /tmp
tar -czf primihub-offline-deploy-$(date +%Y%m%d).tar.gz primihub-offline-package/

echo "离线部署包已创建: /tmp/primihub-offline-deploy-$(date +%Y%m%d).tar.gz"
```

---

## 第二步：传输文件到目标服务器

将打包文件传输到离线服务器:

### 方法1: USB存储设备

```bash
# 在源机器上
cp /tmp/primihub-offline-deploy-*.tar.gz /mnt/usb/

# 在目标机器上
cp /mnt/usb/primihub-offline-deploy-*.tar.gz ~/
```

### 方法2: SCP（如果有内网连接）

```bash
scp /tmp/primihub-offline-deploy-*.tar.gz user@target-server:~/
```

### 方法3: 其他传输方式

- FTP/SFTP
- 网络共享
- 物理介质（光盘、硬盘等）

---

## 第三步：在目标服务器上部署

### 3.1 解压部署包

```bash
cd ~
tar -xzf primihub-offline-deploy-*.tar.gz
cd primihub-offline-package
```

### 3.2 验证文件完整性

```bash
# 检查关键文件
ls -lh primihub-images-*.tar*
ls -lh docker-compose.yaml .env import-images.sh
ls -lh config/ data/
```

### 3.3 导入Docker镜像

```bash
# 给脚本添加执行权限
chmod +x import-images.sh

# 导入镜像（根据实际文件名）
./import-images.sh primihub-images-YYYYMMDD_HHMMSS.tar

# 如果是压缩文件
./import-images.sh primihub-images-YYYYMMDD_HHMMSS.tar.gz
```

**导入过程**:
- 显示文件大小和导入进度
- 验证Docker环境
- 导入所有镜像
- 验证关键镜像是否完整

**预期输出**:
```
============================================
PrimiHub 镜像离线导入工具
============================================

镜像文件: primihub-images-20260113_013554.tar
文件大小: 2.4G

Docker环境检查通过！

导入前镜像数量: 5

============================================
开始导入镜像...
============================================

提示: 导入过程可能需要几分钟，请耐心等待...

[导入进度...]

============================================
导入完成！
============================================

导入后镜像数量: 14
新增镜像数量: 9
导入耗时: 95 秒

✓ 所有关键镜像验证通过！
```

### 3.4 验证镜像导入

```bash
# 查看所有导入的镜像
docker images | grep -E "primihub|nacos|rabbitmq|redis|mysql|loki"

# 应该看到9个镜像:
# registry.cn-beijing.aliyuncs.com/primihub/primihub-meta:1.7.0
# 192.168.99.10/primihub/privacy:1.8.0
# 192.168.99.10/primihub/platform:1.8.0
# registry.cn-beijing.aliyuncs.com/primihub/primihub-node:1.7.0
# registry.cn-beijing.aliyuncs.com/primihub/nacos-server:v2.0.4
# registry.cn-beijing.aliyuncs.com/primihub/rabbitmq:3.6.15-management
# registry.cn-beijing.aliyuncs.com/primihub/redis:7
# registry.cn-beijing.aliyuncs.com/primihub/mysql:5.7
# registry.cn-beijing.aliyuncs.com/primihub/loki:latest
```

### 3.5 配置环境变量

根据实际环境修改 `.env` 文件:

```bash
vim .env
```

主要配置项:
```ini
# 镜像配置（通常不需要修改）
PRIMIHUB_META=registry.cn-beijing.aliyuncs.com/primihub/primihub-meta:1.7.0
PRIMIHUB_PLATFORM=192.168.99.10/primihub/privacy:1.8.0
PRIMIHUB_WEB_MANAGE=192.168.99.10/primihub/platform:1.8.0
PRIMIHUB_NODE=registry.cn-beijing.aliyuncs.com/primihub/primihub-node:1.7.0
NACOS_IMAGE=registry.cn-beijing.aliyuncs.com/primihub/nacos-server:v2.0.4
RABBITMQ_IMAGE=registry.cn-beijing.aliyuncs.com/primihub/rabbitmq:3.6.15-management
REDIS_IMAGE=registry.cn-beijing.aliyuncs.com/primihub/redis:7
MYSQL_IMAGE=registry.cn-beijing.aliyuncs.com/primihub/mysql:5.7
LOKI_IMAGE=registry.cn-beijing.aliyuncs.com/primihub/loki:latest
```

### 3.6 创建数据目录

```bash
# 创建必需的数据目录
mkdir -p data/mysql
mkdir -p data/log
mkdir -p data/upload

# 设置权限（如果需要）
chmod -R 755 data/
```

### 3.7 启动服务

```bash
# 启动所有服务
docker compose up -d

# 查看启动状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 3.8 验证服务状态

等待所有服务启动完成（约2-5分钟），然后检查:

```bash
# 检查所有容器状态
docker compose ps

# 应该看到所有容器状态为 "Up" 或 "healthy"

# 运行健康检查脚本（如果有）
./health_check.sh
```

---

## 第四步：访问服务

### Web管理界面

服务启动后，可以通过以下地址访问:

- **机构1管理界面**: `http://<服务器IP>:30811`
- **机构2管理界面**: `http://<服务器IP>:30812`
- **机构3管理界面**: `http://<服务器IP>:30813`

### Nacos控制台

- **地址**: `http://<服务器IP>:8848/nacos`
- **默认账号**: nacos / nacos

---

## 常见问题

### Q1: 导入镜像时提示权限错误

**问题**:
```
permission denied while trying to connect to the Docker daemon socket
```

**解决方案**:
```bash
# 方法1: 使用sudo
sudo ./import-images.sh primihub-images-*.tar

# 方法2: 将用户添加到docker组
sudo usermod -aG docker $USER
newgrp docker

# 然后重新运行
./import-images.sh primihub-images-*.tar
```

### Q2: 容器启动失败

**问题**: 某些容器无法启动

**排查步骤**:
```bash
# 查看容器日志
docker compose logs <容器名>

# 查看所有容器状态
docker compose ps -a

# 重启特定容器
docker compose restart <容器名>

# 重启所有容器
docker compose restart
```

### Q3: 端口冲突

**问题**: 端口已被占用

**解决方案**:
```bash
# 检查端口占用
netstat -tulpn | grep -E "3306|6379|8848|30811|30812|30813|50050|50051|50052"

# 停止占用端口的服务，或修改 docker-compose.yaml 中的端口映射
```

### Q4: 磁盘空间不足

**问题**: 导入镜像或运行时磁盘空间不足

**解决方案**:
```bash
# 清理Docker未使用的资源
docker system prune -a

# 查看磁盘使用情况
df -h
docker system df

# 如果需要，可以修改Docker的数据目录
# 编辑 /etc/docker/daemon.json
{
  "data-root": "/mnt/data1/docker"
}

# 重启Docker
sudo systemctl restart docker
```

### Q5: 镜像导入不完整

**问题**: 导入后缺少某些镜像

**解决方案**:
```bash
# 重新导入镜像
./import-images.sh primihub-images-*.tar

# 手动验证镜像
docker images | grep primihub | wc -l
# 应该显示至少4个primihub相关镜像

# 如果还是缺失，检查tar文件是否完整
tar -tzf primihub-images-*.tar.gz | grep -E "manifest|layer"
```

---

## 附录A: 离线安装Docker

如果目标服务器没有安装Docker，需要离线安装:

### Ubuntu/Debian

1. **在有网络的机器上下载Docker包**:

```bash
# 下载Docker Engine包
mkdir ~/docker-packages
cd ~/docker-packages

# 对于Ubuntu 20.04
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_1.6.9-1_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_24.0.7-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_24.0.7-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-buildx-plugin_0.11.2-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-compose-plugin_2.21.0-1~ubuntu.20.04~focal_amd64.deb

# 打包
tar -czf docker-offline-packages.tar.gz *.deb
```

2. **传输到目标服务器并安装**:

```bash
# 解压
tar -xzf docker-offline-packages.tar.gz

# 安装
sudo dpkg -i containerd.io_*.deb
sudo dpkg -i docker-ce-cli_*.deb
sudo dpkg -i docker-ce_*.deb
sudo dpkg -i docker-buildx-plugin_*.deb
sudo dpkg -i docker-compose-plugin_*.deb

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证
docker --version
docker compose version
```

### CentOS/RHEL

1. **在有网络的机器上下载Docker包**:

```bash
mkdir ~/docker-packages
cd ~/docker-packages

# 使用yumdownloader下载所有依赖
sudo yum install -y yum-utils
sudo yumdownloader --resolve docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 打包
tar -czf docker-offline-packages.tar.gz *.rpm
```

2. **传输到目标服务器并安装**:

```bash
# 解压
tar -xzf docker-offline-packages.tar.gz

# 安装
sudo yum localinstall -y *.rpm

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证
docker --version
docker compose version
```

---

## 附录B: 完整部署检查清单

- [ ] 目标服务器满足硬件要求（CPU、内存、磁盘）
- [ ] Docker和Docker Compose已安装
- [ ] 离线部署包已传输到目标服务器
- [ ] 解压部署包到工作目录
- [ ] 验证所有必需文件存在
- [ ] 导入Docker镜像
- [ ] 验证9个镜像全部导入成功
- [ ] 根据环境修改.env配置
- [ ] 创建必要的数据目录
- [ ] 启动Docker Compose服务
- [ ] 等待所有容器健康检查通过
- [ ] 验证Web界面可访问（端口30811、30812、30813）
- [ ] 验证Nacos控制台可访问（端口8848）
- [ ] 运行健康检查脚本
- [ ] 检查容器日志无错误

---

## 附录C: 服务端口清单

| 服务 | 端口 | 用途 | 访问方式 |
|------|------|------|----------|
| MySQL | 3306 | 数据库 | 内部访问 |
| Redis | 6379 | 缓存 | 内部访问 |
| Nacos | 8848 | 配置中心 | http://IP:8848/nacos |
| Nacos | 9848, 9849 | Nacos集群通信 | 内部访问 |
| Loki | 3100 | 日志聚合 | 内部访问 |
| Web管理界面1 | 30811 | 机构1管理界面 | http://IP:30811 |
| Web管理界面2 | 30812 | 机构2管理界面 | http://IP:30812 |
| Web管理界面3 | 30813 | 机构3管理界面 | http://IP:30813 |
| PrimiHub Node 1 | 50050 | 计算节点1 | gRPC |
| PrimiHub Node 2 | 50051 | 计算节点2 | gRPC |
| PrimiHub Node 3 | 50052 | 计算节点3 | gRPC |

---

## 附录D: 目录结构说明

```
primihub-deploy/docker-all-in-one/
├── config/                      # 配置文件目录
│   ├── my.cnf                  # MySQL配置
│   ├── redis.conf              # Redis配置
│   ├── default0.conf           # Nginx配置（机构1）
│   ├── default1.conf           # Nginx配置（机构2）
│   └── default2.conf           # Nginx配置（机构3）
├── data/                        # 数据目录
│   ├── env/                    # 环境变量文件
│   │   ├── mysql.env          # MySQL环境变量
│   │   └── nacos-mysql.env    # Nacos环境变量
│   ├── initsql/                # 数据库初始化SQL
│   ├── mysql/                  # MySQL数据文件（运行时生成）
│   ├── log/                    # 日志目录（运行时生成）
│   └── upload/                 # 上传文件目录（运行时生成）
├── offline-deploy/              # 离线部署文件
│   ├── primihub-images-*.tar   # Docker镜像包
│   └── image-manifest-*.txt    # 镜像清单
├── docker-compose.yaml          # Docker Compose配置
├── .env                         # 环境变量
├── export-images.sh             # 镜像导出脚本
├── import-images.sh             # 镜像导入脚本
├── deploy.sh                    # 部署脚本
└── health_check.sh              # 健康检查脚本
```

---

## 技术支持

如有问题，请联系:
- GitHub Issues: https://github.com/primihub/primihub-deploy/issues
- 文档: https://docs.primihub.com

---

**文档版本**: v1.0
**更新时间**: 2026-01-13
**适用版本**: PrimiHub 1.7.0 / 1.8.0
