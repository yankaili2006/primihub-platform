# Docker 离线安装完整指南

本指南说明如何在完全离线的环境中部署 PrimiHub，包括 Docker 和 Docker Compose 的离线安装。

## 📋 目录

- [概述](#概述)
- [准备工作](#准备工作)
- [步骤 1: 下载 Docker 安装包](#步骤-1-下载-docker-安装包)
- [步骤 2: 打包完整部署包](#步骤-2-打包完整部署包)
- [步骤 3: 传输到离线环境](#步骤-3-传输到离线环境)
- [步骤 4: 离线环境部署](#步骤-4-离线环境部署)
- [常见问题](#常见问题)

## 概述

完整的离线部署包包含：
- ✅ Docker 安装包（支持 Ubuntu/CentOS）
- ✅ Docker Compose 安装包
- ✅ PrimiHub 所有 Docker 镜像
- ✅ 配置文件和数据
- ✅ 自动化部署脚本

## 准备工作

### 联网环境要求

在有网络的机器上准备部署包：
- 操作系统：Linux（任意发行版）
- 磁盘空间：至少 30GB 可用空间
- 网络：能够访问 Docker 官方源和阿里云镜像仓库

### 离线环境要求

目标离线服务器：
- 操作系统：Ubuntu 20.04/22.04 或 CentOS 7/8
- CPU：4 核以上（推荐 8 核）
- 内存：8GB 以上（推荐 16GB）
- 磁盘：20GB 以上可用空间
- 不需要预装 Docker（会自动安装）

## 步骤 1: 下载 Docker 安装包

在有网络的机器上执行：

```bash
cd docker-all-in-one/

# 运行下载脚本
bash download-docker-packages.sh
```

### 交互式选择

脚本会询问要下载哪些系统的安装包：

```
请选择要下载的系统类型（可多选）:
  1) Ubuntu 20.04 (amd64)
  2) Ubuntu 22.04 (amd64)
  3) CentOS 7 (x86_64)
  4) CentOS 8 / Rocky Linux 8 (x86_64)
  5) 全部下载

请选择 (1-5, 多个用逗号分隔):
```

**建议**：
- 如果知道目标系统类型，选择对应的选项
- 如果不确定，选择 `5` 下载全部

### 下载内容

下载完成后，会在 `docker-packages/` 目录下生成：

```
docker-packages/
├── ubuntu-20.04/          # Ubuntu 20.04 安装包
│   ├── containerd.io_*.deb
│   ├── docker-ce-cli_*.deb
│   ├── docker-ce_*.deb
│   ├── docker-buildx-plugin_*.deb
│   ├── docker-compose-plugin_*.deb
│   └── docker-ce-rootless-extras_*.deb
├── ubuntu-22.04/          # Ubuntu 22.04 安装包
├── centos-7/              # CentOS 7 安装包
│   ├── containerd.io-*.rpm
│   ├── docker-ce-cli-*.rpm
│   ├── docker-ce-*.rpm
│   ├── docker-buildx-plugin-*.rpm
│   ├── docker-compose-plugin-*.rpm
│   └── docker-ce-rootless-extras-*.rpm
├── centos-8/              # CentOS 8 安装包
├── docker-compose/        # Docker Compose 独立版本
│   └── docker-compose-linux-x86_64
└── README.md
```

### 验证下载

```bash
# 查看下载的文件
ls -lh docker-packages/

# 查看总大小
du -sh docker-packages/
```

## 步骤 2: 打包完整部署包

下载 Docker 安装包后，打包完整的离线部署包：

```bash
# 运行打包脚本
bash package-offline-deploy.sh
```

### 打包流程

脚本会引导你完成以下步骤：

#### 1. 选择镜像来源

```
请选择镜像获取方式:
  1) 从阿里云镜像仓库下载 (需要网络连接)
  2) 从本地Docker导出 (使用当前已有镜像)
  3) 使用已有的镜像tar文件

请选择 (1/2/3):
```

**推荐**：选择 `1` 从阿里云下载最新镜像

#### 2. 自动打包

脚本会自动完成：
- ✅ 下载/导出 Docker 镜像
- ✅ 复制配置文件和数据
- ✅ 复制 Docker 安装包
- ✅ 复制部署脚本
- ✅ 生成部署文档
- ✅ 创建压缩包

#### 3. 打包结果

```
离线部署包信息:
----------------------------------------
  文件位置: offline-packages/primihub-offline-complete-20260113_120000.tar.gz
  文件大小: 8.5G
  包含内容:
    - Docker 镜像
    - Docker 安装包 (ubuntu-20.04, ubuntu-22.04, centos-7, centos-8)
    - 配置文件
    - 配置目录
    - 数据目录
    - 部署脚本
    - 部署文档
```

### 验证打包

```bash
# 查看生成的部署包
ls -lh offline-packages/

# 验证 MD5 校验和
cd offline-packages/
md5sum -c primihub-offline-complete-*.tar.gz.md5
```

## 步骤 3: 传输到离线环境

### 方法 1: 使用自动传输脚本

```bash
cd offline-packages/

# 使用生成的传输脚本
bash transfer-to-server.sh <目标服务器IP> <目标路径>

# 示例
bash transfer-to-server.sh 192.168.1.100 /opt/primihub/
```

### 方法 2: 手动传输

```bash
# 使用 scp
scp primihub-offline-complete-*.tar.gz user@target-server:/path/to/destination/

# 或使用 U盘/移动硬盘
cp primihub-offline-complete-*.tar.gz /media/usb/
```

### 方法 3: 通过跳板机

```bash
# 先传到跳板机
scp primihub-offline-complete-*.tar.gz user@jumphost:/tmp/

# 再从跳板机传到目标服务器
ssh user@jumphost
scp /tmp/primihub-offline-complete-*.tar.gz user@target-server:/opt/
```

## 步骤 4: 离线环境部署

在离线目标服务器上执行：

### 1. 解压部署包

```bash
# 解压
tar -xzf primihub-offline-complete-*.tar.gz

# 进入目录
cd primihub-offline-complete-*/
```

### 2. 查看部署包内容

```bash
# 查看文件列表
ls -lh

# 查看部署清单
cat MANIFEST.txt

# 查看快速部署指南
cat QUICK_DEPLOY.md
```

### 3. 一键部署（推荐）

```bash
# 执行一键部署脚本
bash deploy-offline.sh primihub-images-*.tar*
```

#### 自动安装 Docker

如果系统未安装 Docker，脚本会自动检测并询问：

```
检测到 Docker 或 Docker Compose 未安装

发现 Docker 自动安装脚本

是否自动安装 Docker 和 Docker Compose? (y/n):
```

输入 `y` 后，脚本会：
- ✅ 自动检测操作系统类型
- ✅ 选择对应的安装包
- ✅ 安装 Docker 和 Docker Compose
- ✅ 配置 Docker 服务
- ✅ 启动 Docker 服务
- ✅ 验证安装

#### 部署流程

脚本会自动完成：
1. ✅ 检查/安装 Docker 环境
2. ✅ 导入 Docker 镜像
3. ✅ 配置环境变量
4. ✅ 启动所有服务
5. ✅ 验证服务状态

### 4. 手动分步部署（可选）

如果需要更多控制，可以手动执行：

#### 步骤 4.1: 安装 Docker

```bash
# 安装 Docker 和 Docker Compose
sudo bash install-docker.sh
```

#### 步骤 4.2: 导入镜像

```bash
# 导入 Docker 镜像
bash import-images.sh primihub-images-*.tar*
```

#### 步骤 4.3: 配置环境

```bash
# 根据需要修改配置
vim .env
vim docker-compose.yaml
```

#### 步骤 4.4: 启动服务

```bash
# 启动所有服务
docker compose up -d

# 查看服务状态
docker compose ps
```

#### 步骤 4.5: 健康检查

```bash
# 运行健康检查
bash health_check.sh
```

### 5. 访问服务

部署完成后，通过浏览器访问：

- **机构 0 管理平台**: http://服务器IP:30811
- **机构 1 管理平台**: http://服务器IP:30812
- **机构 2 管理平台**: http://服务器IP:30813
- **Nacos 控制台**: http://服务器IP:8848/nacos
  - 用户名: `nacos`
  - 密码: `nacos`

## 常见问题

### Q1: Docker 安装失败怎么办？

**A**: 检查以下几点：

1. 确认操作系统类型和版本：
```bash
cat /etc/os-release
```

2. 查看安装日志：
```bash
sudo bash install-docker.sh 2>&1 | tee install.log
```

3. 手动安装：
```bash
cd docker-packages/ubuntu-20.04/  # 或对应的系统目录
sudo dpkg -i *.deb  # Ubuntu/Debian
# 或
sudo yum localinstall -y *.rpm  # CentOS/RHEL
```

### Q2: 镜像导入很慢怎么办？

**A**: 这是正常现象，镜像文件通常有几个 GB。可以：

1. 查看导入进度：
```bash
# 另开一个终端
docker images | wc -l
```

2. 使用 pv 查看进度：
```bash
pv primihub-images-*.tar | docker load
```

### Q3: 服务启动失败怎么办？

**A**: 按以下步骤排查：

1. 查看服务状态：
```bash
docker compose ps
```

2. 查看失败服务的日志：
```bash
docker compose logs <服务名>
```

3. 检查端口占用：
```bash
netstat -tlnp | grep -E "3306|8848|30811"
```

4. 检查磁盘空间：
```bash
df -h
```

### Q4: 如何更新 Docker 版本？

**A**:

1. 下载新版本的安装包：
```bash
# 修改 download-docker-packages.sh 中的版本号
vim download-docker-packages.sh
# 修改 DOCKER_VERSION 和 DOCKER_COMPOSE_VERSION

# 重新下载
bash download-docker-packages.sh
```

2. 重新打包部署包

### Q5: 支持哪些操作系统？

**A**: 当前支持：

- ✅ Ubuntu 20.04 LTS (amd64)
- ✅ Ubuntu 22.04 LTS (amd64)
- ✅ CentOS 7 (x86_64)
- ✅ CentOS 8 / Rocky Linux 8 / AlmaLinux 8 (x86_64)
- ✅ Debian 10/11 (使用 Ubuntu 包)

### Q6: 如何在多台服务器上部署？

**A**:

1. 只需下载一次 Docker 安装包和镜像
2. 打包一次部署包
3. 将部署包复制到多台服务器
4. 在每台服务器上执行部署脚本

### Q7: 部署包太大，如何减小？

**A**:

1. 只下载需要的系统的 Docker 安装包：
```bash
# 在 download-docker-packages.sh 中只选择需要的系统
```

2. 使用 gzip 压缩：
```bash
# 部署包已经使用 gzip 压缩
# 如需更高压缩率，可以使用 xz
tar -cJf package.tar.xz primihub-offline-complete-*/
```

### Q8: 如何验证部署包完整性？

**A**:

```bash
# 验证 MD5 校验和
md5sum -c primihub-offline-complete-*.tar.gz.md5

# 测试解压
tar -tzf primihub-offline-complete-*.tar.gz | head -20
```

### Q9: 离线环境无法访问管理界面？

**A**: 检查防火墙设置：

```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 30811:30813/tcp
sudo ufw allow 8848/tcp

# CentOS/RHEL
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=30811-30813/tcp --permanent
sudo firewall-cmd --add-port=8848/tcp --permanent
sudo firewall-cmd --reload
```

### Q10: 如何卸载 Docker？

**A**:

```bash
# Ubuntu/Debian
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# CentOS/RHEL
sudo yum remove -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## 完整工作流程图

```
联网环境                              离线环境
┌─────────────────────┐              ┌─────────────────────┐
│                     │              │                     │
│ 1. 下载 Docker 包   │              │                     │
│    ↓                │              │                     │
│ 2. 下载/导出镜像    │              │                     │
│    ↓                │              │                     │
│ 3. 打包部署包       │              │                     │
│    ↓                │              │                     │
│ 4. 生成校验和       │              │                     │
│                     │              │                     │
└──────────┬──────────┘              └──────────┬──────────┘
           │                                    │
           │  传输部署包                        │
           │  (scp/U盘/跳板机)                  │
           └────────────────────────────────────┤
                                                │
                                                ↓
                                    ┌─────────────────────┐
                                    │ 5. 解压部署包       │
                                    │    ↓                │
                                    │ 6. 执行部署脚本     │
                                    │    ↓                │
                                    │ 7. 自动安装 Docker  │
                                    │    ↓                │
                                    │ 8. 导入镜像         │
                                    │    ↓                │
                                    │ 9. 启动服务         │
                                    │    ↓                │
                                    │ 10. 访问管理界面    │
                                    └─────────────────────┘
```

## 脚本说明

### download-docker-packages.sh
- 功能：下载 Docker 和 Docker Compose 安装包
- 支持：Ubuntu 20.04/22.04, CentOS 7/8
- 输出：docker-packages/ 目录

### install-docker.sh
- 功能：自动检测系统并安装 Docker
- 要求：需要 root 权限
- 支持：自动选择对应系统的安装包

### package-offline-deploy.sh
- 功能：打包完整的离线部署包
- 包含：镜像 + Docker 安装包 + 配置 + 脚本
- 输出：offline-packages/ 目录

### deploy-offline.sh
- 功能：一键部署 PrimiHub
- 特性：自动检测并安装 Docker
- 流程：安装 Docker → 导入镜像 → 启动服务

### import-images.sh
- 功能：导入 Docker 镜像
- 支持：tar 和 tar.gz 格式

### health_check.sh
- 功能：检查服务健康状态
- 输出：各服务的运行状态

## 技术支持

如有问题，请：
1. 查看部署日志：`deployment-report-*.txt`
2. 查看服务日志：`docker compose logs -f`
3. 访问官方文档：https://docs.primihub.com
4. 提交 Issue：https://github.com/primihub/primihub/issues

---

**版本**: 1.0.0
**更新时间**: 2026-01-13
**适用于**: PrimiHub 1.8.0
