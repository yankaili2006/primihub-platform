# PrimiHub Platform Docker 镜像构建指南

## 快速开始

### 基本构建

```bash
# 标准构建流程（编译 + 构建镜像）
./build-docker-image.sh

# 输出示例:
# ========================================
# Stage 1.1: 编译 primihub-sdk
# ========================================
# [SUCCESS] primihub-sdk 编译成功 (耗时: 180s)
#
# ========================================
# Stage 1.2: 编译 primihub-service
# ========================================
# [SUCCESS] primihub-service 编译成功 (耗时: 120s)
#
# ========================================
# Stage 2: 构建 Docker 镜像
# ========================================
# [SUCCESS] Docker 镜像构建成功 (耗时: 45s)
```

## 脚本特性

### 1. 完全对应 Jenkins Pipeline

脚本严格按照 Jenkins Pipeline 的构建流程设计：

```
Jenkins Pipeline                    Shell Script
─────────────────                   ────────────
stage('Build')                  →   build_sdk() + build_service()
  ├─ primihub-sdk                      ├─ mvn clean install -Dos.detected.classifier=linux-x86_64
  └─ primihub-service                  └─ mvn clean install -Dasciidoctor.skip=true

stage('Building app image')     →   build_docker_image()
  └─ docker.build()                    └─ docker build -t IMAGE_TAG -f Dockerfile.local
```

### 2. 智能功能

- ✅ **前置检查**: 自动检测 Maven、Docker、Java 环境
- ✅ **构建验证**: 验证 JAR 文件是否生成
- ✅ **错误处理**: 任何步骤失败立即退出并显示错误信息
- ✅ **时间统计**: 显示各阶段耗时
- ✅ **自动清理**: 清理悬空的 Docker 镜像
- ✅ **双标签**: 自动创建 `BUILD_NUMBER` 和 `latest` 标签

### 3. 灵活配置

支持通过命令行参数或环境变量配置所有选项。

## 使用场景

### 场景 1: 本地开发构建

```bash
# 完整构建（首次构建）
./build-docker-image.sh

# 快速构建（跳过 SDK 编译，仅重新构建 Service）
cd primihub-service
mvn clean install -Dmaven.test.skip=true
cd ..
./build-docker-image.sh --skip-build
```

### 场景 2: CI/CD 集成

```bash
#!/bin/bash
# 在 GitLab CI / GitHub Actions 中使用

export BUILD_NUMBER="${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}}"
export DOCKER_REGISTRY="registry.example.com"
export PUSH_IMAGE=true

./build-docker-image.sh
```

**GitLab CI 示例**:
```yaml
# .gitlab-ci.yml
build-docker:
  stage: build
  script:
    - ./build-docker-image.sh --build-number $CI_COMMIT_TAG --push
  only:
    - tags
```

**GitHub Actions 示例**:
```yaml
# .github/workflows/docker-build.yml
name: Build Docker Image
on:
  push:
    tags:
      - 'v*'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker Image
        run: |
          ./build-docker-image.sh \
            --build-number ${GITHUB_REF##*/} \
            --push
```

### 场景 3: 生产发布

```bash
# 指定版本号构建并推送到生产仓库
./build-docker-image.sh \
  --build-number 1.8.0 \
  --registry registry.example.com \
  --name primihub/platform \
  --push

# 结果:
# ✓ registry.example.com/primihub/platform:1.8.0
# ✓ registry.example.com/primihub/platform:latest
```

### 场景 4: 多仓库发布

```bash
# 构建一次，推送到多个仓库
./build-docker-image.sh --build-number 1.8.0

# 手动推送到不同仓库
docker tag 192.168.99.10/primihub/privacy:1.8.0 \
  registry.cn-beijing.aliyuncs.com/primihub/primihub-platform:1.8.0

docker push registry.cn-beijing.aliyuncs.com/primihub/primihub-platform:1.8.0
```

### 场景 5: 仅构建镜像（已有编译产物）

```bash
# 如果已经编译过，可以快速构建镜像
./build-docker-image.sh --skip-build

# 适用于:
# - 调试 Dockerfile
# - 快速重建镜像
# - 微调镜像配置
```

## 命令行参数详解

### 基础参数

| 参数 | 说明 | 默认值 | 示例 |
|-----|------|-------|------|
| `-h, --help` | 显示帮助信息 | - | `--help` |
| `-b, --build-number` | 构建编号 | 时间戳 | `--build-number 1.8.0` |
| `-r, --registry` | Docker 仓库地址 | 192.168.99.10 | `--registry registry.example.com` |
| `-n, --name` | 镜像名称 | primihub/privacy | `--name myapp/platform` |

### 高级参数

| 参数 | 说明 | 默认值 | 示例 |
|-----|------|-------|------|
| `-f, --dockerfile` | Dockerfile 路径 | ./primihub-service/Dockerfile.local | `--dockerfile ./Dockerfile` |
| `-c, --context` | 构建上下文 | ./primihub-service | `--context .` |
| `-p, --push` | 自动推送镜像 | false | `--push` |
| `-s, --skip-build` | 跳过编译 | false | `--skip-build` |
| `-C, --clean` | 清理后构建 | false | `--clean` |
| `--no-cleanup` | 不清理悬空镜像 | false | `--no-cleanup` |

## 环境变量

所有参数都可以通过环境变量配置：

```bash
# 设置环境变量
export BUILD_NUMBER="1.8.0"
export DOCKER_REGISTRY="registry.example.com"
export IMAGE_NAME="primihub/platform"
export PUSH_IMAGE="true"
export SKIP_BUILD="false"
export CLEAN_BUILD="true"

# 运行脚本（使用环境变量）
./build-docker-image.sh
```

**优先级**: 命令行参数 > 环境变量 > 默认值

## 构建输出

### 构建阶段

```
========================================
PrimiHub Platform Docker 镜像构建
========================================

构建配置:
  开始时间:    2026-01-08 10:30:00
  构建目录:    /home/primihub/github/primihub-platform
  构建编号:    20260108103000
  镜像标签:    192.168.99.10/primihub/privacy:20260108103000
  跳过编译:    false
  清理构建:    false
  推送镜像:    false

========================================
检查前置条件
========================================

[SUCCESS] Maven: Apache Maven 3.8.6
[SUCCESS] Docker: Docker version 24.0.5
[SUCCESS] Docker daemon 运行中
[SUCCESS] Java: openjdk version "1.8.0_392"
[SUCCESS] 所有前置条件满足

========================================
Stage 1.1: 编译 primihub-sdk
========================================

[INFO] 当前目录: /home/primihub/github/primihub-platform/primihub-sdk
[步骤] 开始编译 primihub-sdk...
[BUILD INFO] ... (Maven 构建日志)
[SUCCESS] primihub-sdk 编译成功 (耗时: 180s)
[SUCCESS] SDK JAR 文件: target/primihub-sdk-1.0.1.jar (15M)

========================================
Stage 1.2: 编译 primihub-service
========================================

[INFO] 当前目录: /home/primihub/github/primihub-platform/primihub-service
[步骤] 开始编译 primihub-service...
[BUILD INFO] ... (Maven 构建日志)
[SUCCESS] primihub-service 编译成功 (耗时: 120s)
[步骤] 验证编译产物...
[SUCCESS] Application JAR: application/target/application-1.0-SNAPSHOT.jar (172M)
[SUCCESS] Gateway JAR: gateway/target/gateway-1.0-SNAPSHOT.jar (129M)

========================================
Stage 2: 构建 Docker 镜像
========================================

[INFO] 构建配置:
  Registry:    192.168.99.10
  Image Name:  primihub/privacy
  Image Tag:   192.168.99.10/primihub/privacy:20260108103000
  Build Number: 20260108103000
  Dockerfile:  ./primihub-service/Dockerfile.local
  Context:     ./primihub-service

[步骤] 开始构建 Docker 镜像...
[INFO] 执行命令: docker build -t 192.168.99.10/primihub/privacy:20260108103000 -f ./primihub-service/Dockerfile.local ./primihub-service
Step 1/5 : FROM ibmjava:8-jre
Step 2/5 : ENV DEBIAN_FRONTEND=noninteractive
Step 3/5 : RUN apt update && apt install tzdata...
Step 4/5 : ADD application/target/*-SNAPSHOT.jar...
Step 5/5 : ENTRYPOINT ["/bin/sh","-c"...
[SUCCESS] Docker 镜像构建成功 (耗时: 45s)

[步骤] 镜像信息:
REPOSITORY                         TAG              IMAGE ID       SIZE
192.168.99.10/primihub/privacy    20260108103000   a1b2c3d4e5f6   1.13GB

[步骤] 添加 latest 标签...
[SUCCESS] 已添加标签: 192.168.99.10/primihub/privacy:latest
```

### 构建总结

```
========================================
构建总结
========================================

✓ 构建完成！

构建信息:
  Build Number: 20260108103000
  Image Tag:    192.168.99.10/primihub/privacy:20260108103000
  Latest Tag:   192.168.99.10/primihub/privacy:latest

编译产物:
  SDK:         primihub-sdk/target/primihub-sdk-1.0.1.jar
  Application: primihub-service/application/target/application-1.0-SNAPSHOT.jar
  Gateway:     primihub-service/gateway/target/gateway-1.0-SNAPSHOT.jar

Docker 镜像:
  192.168.99.10/primihub/privacy:20260108103000 (1.13GB)
  192.168.99.10/primihub/privacy:latest (1.13GB)

下一步操作:
  1. 运行容器:
     docker run -d -p 8080:8080 --name primihub-platform 192.168.99.10/primihub/privacy:20260108103000

  2. 推送到仓库:
     docker push 192.168.99.10/primihub/privacy:20260108103000

  3. 使用 docker-compose 部署:
     docker-compose up -d

! 镜像未推送 (使用 --push 参数启用自动推送)

[SUCCESS] 总耗时: 345s (00:05:45)
[SUCCESS] 构建流程完成！
```

## 故障排查

### 问题 1: SDK 编译失败

**错误**:
```
[ERROR] Failed to execute goal org.xolstice.maven.plugins:protobuf-maven-plugin
```

**解决方案**:
```bash
# 方法 1: 确保指定正确的 classifier
./build-docker-image.sh  # 脚本已默认使用 linux-x86_64

# 方法 2: 如果是 ARM 架构
# 修改脚本中的 -Dos.detected.classifier=linux-aarch_64
```

### 问题 2: Docker 构建失败

**错误**:
```
[ERROR] Cannot connect to the Docker daemon
```

**解决方案**:
```bash
# 启动 Docker daemon
sudo systemctl start docker

# 或在 macOS 上
open -a Docker
```

### 问题 3: 推送失败

**错误**:
```
denied: requested access to the resource is denied
```

**解决方案**:
```bash
# 登录 Docker 仓库
docker login 192.168.99.10

# 或使用其他仓库
docker login registry.example.com
```

### 问题 4: 磁盘空间不足

**错误**:
```
no space left on device
```

**解决方案**:
```bash
# 清理 Docker 缓存
docker system prune -a

# 查看磁盘使用
docker system df

# 清理悬空镜像
docker image prune
```

### 问题 5: Maven 依赖下载慢

**解决方案**:
```bash
# 方法 1: 使用阿里云镜像
# 在 ~/.m2/settings.xml 添加:
<mirror>
  <id>aliyun</id>
  <mirrorOf>central</mirrorOf>
  <url>https://maven.aliyun.com/repository/public</url>
</mirror>

# 方法 2: 使用本地仓库缓存
# 脚本会自动使用 ~/.m2/repository
```

## 与其他构建方法对比

| 特性 | build-docker-image.sh | build.sh | 直接 Docker | docker-compose |
|-----|---------------------|---------|------------|----------------|
| **编译代码** | ✅ 自动 | ✅ 自动 | ❌ 需手动 | ❌ 需手动 |
| **构建镜像** | ✅ 自动 | ✅ 自动 | ✅ 手动 | ✅ 自动 |
| **推送镜像** | ✅ 可选 | ❌ 注释 | ✅ 手动 | ❌ 不支持 |
| **前置检查** | ✅ 完整 | ✅ 完整 | ❌ 无 | ❌ 无 |
| **错误处理** | ✅ 详细 | ✅ 详细 | ❌ 基础 | ❌ 基础 |
| **构建报告** | ✅ 详细 | ✅ 详细 | ❌ 无 | ❌ 无 |
| **Jenkins 对应** | ✅ 完全 | ⚠️ 部分 | ❌ 无 | ❌ 无 |
| **灵活配置** | ✅ 高 | ⚠️ 中 | ⚠️ 中 | ⚠️ 中 |

**推荐使用场景**:
- **build-docker-image.sh**: ⭐⭐⭐⭐⭐ CI/CD 流水线、生产发布
- **build.sh**: ⭐⭐⭐⭐ 本地开发、快速构建
- **直接 Docker**: ⭐⭐⭐ 简单场景、学习测试
- **docker-compose**: ⭐⭐⭐⭐ 完整环境部署、服务编排

## 最佳实践

### 1. 版本号规范

```bash
# 语义化版本
./build-docker-image.sh --build-number 1.8.0

# 基于 Git 标签
./build-docker-image.sh --build-number $(git describe --tags --abbrev=0)

# 基于 Git 提交
./build-docker-image.sh --build-number $(git rev-parse --short HEAD)

# 包含日期
./build-docker-image.sh --build-number "1.8.0-$(date +%Y%m%d)"
```

### 2. 多环境构建

```bash
# 开发环境
./build-docker-image.sh \
  --build-number dev-$(git branch --show-current) \
  --registry registry-dev.example.com

# 测试环境
./build-docker-image.sh \
  --build-number test-$(date +%Y%m%d) \
  --registry registry-test.example.com \
  --push

# 生产环境
./build-docker-image.sh \
  --build-number $(cat VERSION) \
  --registry registry.example.com \
  --push
```

### 3. 构建缓存优化

```bash
# 使用 BuildKit 加速
export DOCKER_BUILDKIT=1
./build-docker-image.sh

# 使用构建缓存
docker build --cache-from 192.168.99.10/primihub/privacy:latest ...
```

### 4. 并行构建（高级）

```bash
#!/bin/bash
# 如果有多个独立项目，可以并行构建

# 构建 Platform
./build-docker-image.sh --build-number 1.8.0 &
PID1=$!

# 构建 Web Console (假设有单独脚本)
./build-web-image.sh --build-number 1.8.0 &
PID2=$!

# 等待所有构建完成
wait $PID1 $PID2
echo "所有镜像构建完成"
```

## 集成到现有工作流

### Jenkins Groovy 脚本调用

```groovy
// Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        chmod +x build-docker-image.sh
                        ./build-docker-image.sh \
                            --build-number ${env.BUILD_NUMBER} \
                            --push
                    """
                }
            }
        }
    }
}
```

### Makefile 集成

```makefile
# Makefile
.PHONY: docker-build docker-push docker-clean

docker-build:
	./build-docker-image.sh --build-number $(VERSION)

docker-push:
	./build-docker-image.sh --build-number $(VERSION) --push

docker-clean:
	docker rmi $$(docker images -f "dangling=true" -q)

docker-dev:
	./build-docker-image.sh --skip-build
```

## 总结

`build-docker-image.sh` 是一个功能完整、易于使用的 Docker 镜像构建脚本：

✅ **完全对应 Jenkins Pipeline** - 保持与现有 CI/CD 流程一致
✅ **智能化构建** - 自动检查、验证、报错
✅ **高度可配置** - 支持命令行参数和环境变量
✅ **详细输出** - 清晰的构建日志和总结报告
✅ **生产就绪** - 支持推送、标签管理、清理

立即开始使用：

```bash
# 标准构建
./build-docker-image.sh

# 查看帮助
./build-docker-image.sh --help
```
