#!/bin/bash

# Docker 和 Docker Compose 离线安装包下载脚本
# 用途: 下载 Docker 和 Docker Compose 的安装包，用于离线环境部署

set -e

echo "============================================"
echo "Docker 离线安装包下载工具"
echo "============================================"
echo ""

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 配置
DOCKER_VERSION="24.0.7"
DOCKER_COMPOSE_VERSION="2.24.5"
DOWNLOAD_DIR="$SCRIPT_DIR/docker-packages"

# 创建下载目录
mkdir -p "$DOWNLOAD_DIR"

echo "下载配置:"
echo "  Docker 版本: $DOCKER_VERSION"
echo "  Docker Compose 版本: $DOCKER_COMPOSE_VERSION"
echo "  下载目录: $DOWNLOAD_DIR"
echo ""

# 检测当前系统类型（用于提示）
if [ -f /etc/os-release ]; then
    . /etc/os-release
    CURRENT_OS="$ID"
    CURRENT_VERSION="$VERSION_ID"
    echo "当前系统: $NAME $VERSION_ID"
    echo ""
fi

# 询问要下载哪些系统的安装包
echo "============================================"
echo "选择要下载的系统安装包"
echo "============================================"
echo ""
echo "请选择要下载的系统类型（可多选）:"
echo "  1) Ubuntu 20.04 (amd64)"
echo "  2) Ubuntu 22.04 (amd64)"
echo "  3) CentOS 7 (x86_64)"
echo "  4) CentOS 8 / Rocky Linux 8 (x86_64)"
echo "  5) 全部下载"
echo ""
read -p "请选择 (1-5, 多个用逗号分隔): " os_choice

# 解析选择
DOWNLOAD_UBUNTU_20=false
DOWNLOAD_UBUNTU_22=false
DOWNLOAD_CENTOS_7=false
DOWNLOAD_CENTOS_8=false

if [[ "$os_choice" == "5" ]]; then
    DOWNLOAD_UBUNTU_20=true
    DOWNLOAD_UBUNTU_22=true
    DOWNLOAD_CENTOS_7=true
    DOWNLOAD_CENTOS_8=true
else
    IFS=',' read -ra CHOICES <<< "$os_choice"
    for choice in "${CHOICES[@]}"; do
        case $choice in
            1) DOWNLOAD_UBUNTU_20=true ;;
            2) DOWNLOAD_UBUNTU_22=true ;;
            3) DOWNLOAD_CENTOS_7=true ;;
            4) DOWNLOAD_CENTOS_8=true ;;
        esac
    done
fi

echo ""
echo "将下载以下系统的安装包:"
$DOWNLOAD_UBUNTU_20 && echo "  ✓ Ubuntu 20.04"
$DOWNLOAD_UBUNTU_22 && echo "  ✓ Ubuntu 22.04"
$DOWNLOAD_CENTOS_7 && echo "  ✓ CentOS 7"
$DOWNLOAD_CENTOS_8 && echo "  ✓ CentOS 8 / Rocky Linux 8"
echo ""

read -p "确认开始下载? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "取消下载"
    exit 0
fi

echo ""
echo "============================================"
echo "步骤 1/2: 下载 Docker 安装包"
echo "============================================"
echo ""

# 下载 Ubuntu 20.04 Docker 包
if $DOWNLOAD_UBUNTU_20; then
    echo "下载 Ubuntu 20.04 Docker 包..."
    UBUNTU_20_DIR="$DOWNLOAD_DIR/ubuntu-20.04"
    mkdir -p "$UBUNTU_20_DIR"

    cd "$UBUNTU_20_DIR"

    # Docker 依赖包
    echo "  下载依赖包..."
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_1.6.28-1_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.20.04~focal_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_${DOCKER_VERSION}-1~ubuntu.20.04~focal_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-rootless-extras_${DOCKER_VERSION}-1~ubuntu.20.04~focal_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-buildx-plugin_0.12.1-1~ubuntu.20.04~focal_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-compose-plugin_2.24.5-1~ubuntu.20.04~focal_amd64.deb || true

    echo "  ✓ Ubuntu 20.04 Docker 包下载完成"
    echo ""

    cd "$SCRIPT_DIR"
fi

# 下载 Ubuntu 22.04 Docker 包
if $DOWNLOAD_UBUNTU_22; then
    echo "下载 Ubuntu 22.04 Docker 包..."
    UBUNTU_22_DIR="$DOWNLOAD_DIR/ubuntu-22.04"
    mkdir -p "$UBUNTU_22_DIR"

    cd "$UBUNTU_22_DIR"

    echo "  下载依赖包..."
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/containerd.io_1.6.28-1_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-ce_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-ce-rootless-extras_${DOCKER_VERSION}-1~ubuntu.22.04~jammy_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb || true
    wget -q --show-progress -nc https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-compose-plugin_2.24.5-1~ubuntu.22.04~jammy_amd64.deb || true

    echo "  ✓ Ubuntu 22.04 Docker 包下载完成"
    echo ""

    cd "$SCRIPT_DIR"
fi

# 下载 CentOS 7 Docker 包
if $DOWNLOAD_CENTOS_7; then
    echo "下载 CentOS 7 Docker 包..."
    CENTOS_7_DIR="$DOWNLOAD_DIR/centos-7"
    mkdir -p "$CENTOS_7_DIR"

    cd "$CENTOS_7_DIR"

    echo "  下载依赖包..."
    wget -q --show-progress -nc https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.6.28-3.1.el7.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-cli-${DOCKER_VERSION}-1.el7.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-${DOCKER_VERSION}-1.el7.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-rootless-extras-${DOCKER_VERSION}-1.el7.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-buildx-plugin-0.12.1-1.el7.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-compose-plugin-2.24.5-1.el7.x86_64.rpm || true

    echo "  ✓ CentOS 7 Docker 包下载完成"
    echo ""

    cd "$SCRIPT_DIR"
fi

# 下载 CentOS 8 Docker 包
if $DOWNLOAD_CENTOS_8; then
    echo "下载 CentOS 8 / Rocky Linux 8 Docker 包..."
    CENTOS_8_DIR="$DOWNLOAD_DIR/centos-8"
    mkdir -p "$CENTOS_8_DIR"

    cd "$CENTOS_8_DIR"

    echo "  下载依赖包..."
    wget -q --show-progress -nc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.28-3.1.el8.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-cli-${DOCKER_VERSION}-1.el8.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-${DOCKER_VERSION}-1.el8.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-rootless-extras-${DOCKER_VERSION}-1.el8.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-buildx-plugin-0.12.1-1.el8.x86_64.rpm || true
    wget -q --show-progress -nc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-compose-plugin-2.24.5-1.el8.x86_64.rpm || true

    echo "  ✓ CentOS 8 Docker 包下载完成"
    echo ""

    cd "$SCRIPT_DIR"
fi

echo ""
echo "============================================"
echo "步骤 2/2: 下载 Docker Compose 独立版本"
echo "============================================"
echo ""

# 下载 Docker Compose 独立二进制文件（适用于所有系统）
COMPOSE_DIR="$DOWNLOAD_DIR/docker-compose"
mkdir -p "$COMPOSE_DIR"

cd "$COMPOSE_DIR"

echo "下载 Docker Compose v${DOCKER_COMPOSE_VERSION}..."
wget -q --show-progress -nc -O docker-compose-linux-x86_64 \
    "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" || true

if [ -f "docker-compose-linux-x86_64" ]; then
    chmod +x docker-compose-linux-x86_64
    echo "  ✓ Docker Compose 下载完成"
else
    echo "  ✗ Docker Compose 下载失败"
fi

echo ""

cd "$SCRIPT_DIR"

# 创建安装说明文件
cat > "$DOWNLOAD_DIR/README.md" << 'EOF'
# Docker 离线安装包

## 目录结构

```
docker-packages/
├── ubuntu-20.04/          # Ubuntu 20.04 安装包
│   ├── containerd.io_*.deb
│   ├── docker-ce-cli_*.deb
│   ├── docker-ce_*.deb
│   └── docker-compose-plugin_*.deb
├── ubuntu-22.04/          # Ubuntu 22.04 安装包
├── centos-7/              # CentOS 7 安装包
│   ├── containerd.io-*.rpm
│   ├── docker-ce-cli-*.rpm
│   ├── docker-ce-*.rpm
│   └── docker-compose-plugin-*.rpm
├── centos-8/              # CentOS 8 / Rocky Linux 8 安装包
├── docker-compose/        # Docker Compose 独立版本
│   └── docker-compose-linux-x86_64
└── README.md              # 本文件
```

## 手动安装说明

### Ubuntu / Debian 系统

```bash
cd ubuntu-20.04/  # 或 ubuntu-22.04/

# 安装所有包
sudo dpkg -i *.deb

# 如果有依赖问题，运行
sudo apt-get install -f
```

### CentOS / RHEL 系统

```bash
cd centos-7/  # 或 centos-8/

# 安装所有包
sudo yum localinstall -y *.rpm
# 或使用 dnf (CentOS 8+)
sudo dnf localinstall -y *.rpm
```

### 安装 Docker Compose 独立版本

```bash
cd docker-compose/

# 复制到系统路径
sudo cp docker-compose-linux-x86_64 /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

### 启动 Docker 服务

```bash
# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker compose version
```

## 自动安装

使用 `install-docker.sh` 脚本可以自动检测系统并安装：

```bash
bash install-docker.sh
```

## 版本信息

- Docker: 24.0.7
- Docker Compose: 2.24.5

## 注意事项

1. 安装前请确保系统已更新到最新
2. 如果之前安装过旧版本 Docker，建议先卸载
3. 安装后需要将用户添加到 docker 组才能免 sudo 使用：
   ```bash
   sudo usermod -aG docker $USER
   ```
4. 需要重新登录才能使组权限生效

EOF

echo "============================================"
echo "下载完成！"
echo "============================================"
echo ""

# 统计下载结果
echo "下载结果:"
echo "----------------------------------------"
echo "  下载目录: $DOWNLOAD_DIR"
echo ""

if $DOWNLOAD_UBUNTU_20 && [ -d "$DOWNLOAD_DIR/ubuntu-20.04" ]; then
    UBUNTU_20_COUNT=$(find "$DOWNLOAD_DIR/ubuntu-20.04" -name "*.deb" | wc -l)
    echo "  Ubuntu 20.04: $UBUNTU_20_COUNT 个包"
fi

if $DOWNLOAD_UBUNTU_22 && [ -d "$DOWNLOAD_DIR/ubuntu-22.04" ]; then
    UBUNTU_22_COUNT=$(find "$DOWNLOAD_DIR/ubuntu-22.04" -name "*.deb" | wc -l)
    echo "  Ubuntu 22.04: $UBUNTU_22_COUNT 个包"
fi

if $DOWNLOAD_CENTOS_7 && [ -d "$DOWNLOAD_DIR/centos-7" ]; then
    CENTOS_7_COUNT=$(find "$DOWNLOAD_DIR/centos-7" -name "*.rpm" | wc -l)
    echo "  CentOS 7: $CENTOS_7_COUNT 个包"
fi

if $DOWNLOAD_CENTOS_8 && [ -d "$DOWNLOAD_DIR/centos-8" ]; then
    CENTOS_8_COUNT=$(find "$DOWNLOAD_DIR/centos-8" -name "*.rpm" | wc -l)
    echo "  CentOS 8: $CENTOS_8_COUNT 个包"
fi

if [ -f "$DOWNLOAD_DIR/docker-compose/docker-compose-linux-x86_64" ]; then
    COMPOSE_SIZE=$(du -h "$DOWNLOAD_DIR/docker-compose/docker-compose-linux-x86_64" | cut -f1)
    echo "  Docker Compose: $COMPOSE_SIZE"
fi

echo ""
echo "  总大小: $(du -sh "$DOWNLOAD_DIR" | cut -f1)"
echo ""

echo "下一步:"
echo "----------------------------------------"
echo "1. 查看下载的文件:"
echo "   ls -lh $DOWNLOAD_DIR"
echo ""
echo "2. 这些文件将被自动打包到离线部署包中"
echo ""
echo "3. 在离线环境中，部署脚本会自动检测并安装 Docker"
echo ""

echo "============================================"
echo "全部完成！"
echo "============================================"
