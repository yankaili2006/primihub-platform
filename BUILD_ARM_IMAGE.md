# PrimiHub Platform ARM Docker 镜像构建指南

## 概述

本文档介绍如何构建ARM架构（arm64/aarch64）的PrimiHub Platform Docker镜像。支持在Apple Silicon Mac、Raspberry Pi、AWS Graviton等ARM设备上运行。

## 快速开始

### 方法1：快速构建（推荐）

```bash
# 快速构建ARM镜像
./quick-build-arm.sh

# 或指定自定义标签
./quick-build-arm.sh myregistry.com/primihub:arm64-v1.0
```

### 方法2：完整构建

```bash
# 标准构建
./build-arm-image.sh

# 清理后构建
./build-arm-image.sh -c

# 构建并推送镜像
./build-arm-image.sh -p

# 指定自定义配置
./build-arm-image.sh --registry my.registry.com --name myapp -t v1.0.0-arm64
```

## 构建脚本说明

### 1. `build-arm-image.sh` - 完整功能脚本

**特性：**
- 完整的前置环境检查
- 支持清理构建文件
- 支持跳过编译步骤
- 支持镜像推送
- 详细的日志输出
- 时间统计和错误处理

**选项：**
```bash
-h, --help             显示帮助信息
-c, --clean            清理构建文件
-s, --skip-build       跳过编译步骤
-p, --push             推送镜像到仓库
-t, --tag TAG          指定镜像标签
-r, --registry REG     指定Docker仓库
-n, --name NAME        指定镜像名称
-f, --file FILE        指定Dockerfile路径
--context CONTEXT      指定构建上下文
```

### 2. `quick-build-arm.sh` - 快速构建脚本

**特性：**
- 简洁快速的构建流程
- 自动检测系统架构
- 基本的错误检查
- 镜像验证和说明

## 架构支持

### 支持的ARM架构
- **arm64** (Apple Silicon Mac, AWS Graviton)
- **aarch64** (Raspberry Pi 4/5, NVIDIA Jetson)

### 多架构构建（如果需要）
```bash
# 使用Docker Buildx构建多架构镜像
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t primihub/privacy:multi-arch .
```

## 环境要求

### 必需软件
1. **Docker** 20.10+
2. **Maven** 3.6+
3. **Java** 8
4. **Git** (用于克隆代码)

### 验证环境
```bash
# 检查Docker
docker --version

# 检查Maven
mvn --version

# 检查Java
java -version

# 检查系统架构
arch
```

## 构建流程

### 步骤1：准备环境
```bash
# 克隆代码（如果尚未克隆）
git clone <repository-url>
cd primihub-platform

# 确保有执行权限
chmod +x build-arm-image.sh quick-build-arm.sh
```

### 步骤2：构建镜像
```bash
# 使用快速构建
./quick-build-arm.sh

# 或使用完整构建
./build-arm-image.sh -c
```

### 步骤3：验证镜像
```bash
# 查看构建的镜像
docker images | grep primihub

# 检查镜像架构
docker inspect primihub/privacy:arm64-latest --format='{{.Architecture}}'

# 预期输出: arm64 或 aarch64
```

### 步骤4：运行测试
```bash
# 运行容器
docker run -d -p 8080:8080 --name primihub-arm primihub/privacy:arm64-latest

# 检查容器状态
docker ps

# 查看日志
docker logs primihub-arm

# 停止容器
docker stop primihub-arm
docker rm primihub-arm
```

## 常见问题

### Q1: 构建过程中Maven下载依赖慢
```bash
# 设置Maven镜像
export MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true"
```

### Q2: Docker构建时内存不足
```bash
# 增加Docker内存限制（Docker Desktop设置）
# 或使用构建参数
docker build --memory=4g --platform linux/arm64 -t primihub/privacy:arm64-latest .
```

### Q3: 镜像架构显示不正确
```bash
# 确保使用 --platform 参数
docker build --platform linux/arm64 -t your-image .

# 验证构建环境
docker buildx ls
```

### Q4: 在x86系统上构建ARM镜像
```bash
# 安装qemu-user-static支持跨架构构建
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# 使用buildx构建
docker buildx build --platform linux/arm64 -t primihub/privacy:arm64-latest .
```

## 高级用法

### 1. 自定义构建配置
```bash
# 使用环境变量配置
export DOCKER_REGISTRY="my.registry.com"
export IMAGE_NAME="myapp/privacy"
export BUILD_NUMBER="v1.2.3"
./build-arm-image.sh
```

### 2. CI/CD集成
```bash
# Jenkins Pipeline示例
pipeline {
    agent any
    stages {
        stage('Build ARM Image') {
            steps {
                sh './build-arm-image.sh -c -p'
            }
        }
    }
}
```

### 3. 多阶段构建优化
现有的Dockerfile已经是多阶段构建，优化了镜像大小：
- 第一阶段：使用Maven构建
- 第二阶段：使用精简的JRE运行环境

## 镜像管理

### 导出和导入
```bash
# 导出镜像
docker save primihub/privacy:arm64-latest -o primihub-arm64.tar

# 导入镜像
docker load -i primihub-arm64.tar

# 压缩导出
docker save primihub/privacy:arm64-latest | gzip > primihub-arm64.tar.gz
```

### 标签管理
```bash
# 添加新标签
docker tag primihub/privacy:arm64-latest primihub/privacy:arm64-v1.0

# 推送到仓库
docker push primihub/privacy:arm64-v1.0

# 删除本地镜像
docker rmi primihub/privacy:arm64-latest
```

## 性能优化建议

### 构建优化
1. **使用构建缓存**: Docker会自动缓存构建层
2. **并行构建**: Maven支持并行编译
3. **镜像分层**: 将不经常变化的层放在前面

### 运行优化
1. **资源限制**: 为容器设置适当的内存和CPU限制
2. **JVM调优**: 根据ARM架构调整JVM参数
3. **使用Alpine基础镜像**: 减小镜像大小

## 技术支持

### 获取帮助
```bash
# 查看脚本帮助
./build-arm-image.sh --help
./quick-build-arm.sh

# 查看Dockerfile
cat Dockerfile

# 查看构建日志
cat docker-build.log
```

### 问题排查
1. 检查所有必需软件是否安装
2. 确保Docker服务正在运行
3. 检查网络连接（Maven下载依赖）
4. 查看详细的错误日志

## 版本历史

- **v1.0** (2025-01-13): 初始版本，支持ARM64架构构建
- 基于现有Dockerfile的架构检测功能
- 提供快速和完整两种构建方式
- 包含完整的验证和测试流程