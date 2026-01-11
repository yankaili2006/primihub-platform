# PrimiHub Platform Docker 构建工具集

本目录包含完整的 Docker 镜像构建工具，基于 Jenkins Pipeline 配置生成。

## 📦 构建脚本概览

### 主要构建脚本

| 脚本 | 说明 | 用途 |
|-----|------|------|
| **build-docker-image.sh** | 后端镜像构建（完整功能） | CI/CD、生产发布 |
| **build-platform-image.sh** | 前端镜像构建（完整功能） | CI/CD、生产发布 |
| **build-all-images.sh** | 同时构建前后端镜像 | 完整发布 |

### 快速构建脚本

| 脚本 | 说明 | 用途 |
|-----|------|------|
| **quick-build.sh** | 后端快速构建（精简版） | 快速测试、开发迭代 |
| **quick-build-platform.sh** | 前端快速构建（精简版） | 快速测试、开发迭代 |

## 📚 文档

| 文档 | 内容 |
|-----|------|
| **BUILD_IMAGES.md** | 完整构建指南（推荐先看） |
| **BUILD_DOCKER.md** | 后端镜像构建详细文档 |
| **BUILD_PLATFORM.md** | 前端镜像构建详细文档 |
| **DOCKER_BUILD_QUICKREF.md** | 快速参考（一页速查） |

## 🚀 快速开始

### 方法 1: 构建单个镜像

```bash
# 后端镜像 (privacy)
./build-docker-image.sh

# 前端镜像 (platform)
./build-platform-image.sh
```

### 方法 2: 构建所有镜像（推荐）

```bash
# 同时构建前后端
./build-all-images.sh

# 指定版本号
./build-all-images.sh --build-number 1.8.0

# 构建并推送到仓库
./build-all-images.sh --build-number 1.8.0 --push
```

### 方法 3: 快速构建

```bash
# 后端快速构建
./quick-build.sh

# 前端快速构建
./quick-build-platform.sh
```

## 📋 构建产物

构建完成后会生成以下 Docker 镜像：

| 镜像 | 大小 | 端口 | 说明 |
|-----|------|------|------|
| **192.168.99.10/primihub/privacy:TAG** | ~1.13GB | 8080 | 后端服务（Java + Spring Boot） |
| **192.168.99.10/primihub/platform:TAG** | ~224MB | 80 | 前端应用（Vue.js + Nginx） |

## 🛠️ 常用命令

### 查看帮助

```bash
./build-docker-image.sh --help      # 后端帮助
./build-platform-image.sh --help    # 前端帮助
./build-all-images.sh --help        # 统一构建帮助
```

### 指定版本构建

```bash
# 后端
./build-docker-image.sh --build-number 1.8.0

# 前端
./build-platform-image.sh --build-number 1.8.0

# 同时构建
./build-all-images.sh --build-number 1.8.0
```

### 构建并推送

```bash
# 后端
./build-docker-image.sh --build-number 1.8.0 --push

# 前端
./build-platform-image.sh --build-number 1.8.0 --push

# 同时构建并推送
./build-all-images.sh --build-number 1.8.0 --push
```

### 跳过编译（仅构建镜像）

```bash
# 后端（适用于已编译的情况）
./build-docker-image.sh --skip-build

# 前端（适用于已有 dist 目录）
./build-platform-image.sh --skip-build
```

### 使用 npm 镜像加速（前端）

```bash
# 使用淘宝镜像
./build-platform-image.sh --npm-registry https://registry.npmmirror.com
```

## 🎯 使用场景

### 场景 1: 本地开发

```bash
# 快速构建测试
./quick-build.sh                  # 后端
./quick-build-platform.sh         # 前端

# 或完整构建
./build-all-images.sh
```

### 场景 2: CI/CD 集成

```bash
# 在 GitLab CI / GitHub Actions 中
export BUILD_NUMBER="${CI_COMMIT_TAG}"
export DOCKER_REGISTRY="registry.example.com"
export PUSH_IMAGE=true

./build-all-images.sh
```

### 场景 3: 生产发布

```bash
# 指定版本号并推送到生产仓库
./build-all-images.sh \
  --build-number $(cat VERSION) \
  --registry registry.example.com \
  --push
```

### 场景 4: 并行构建（更快）

```bash
# 同时构建前后端（日志可能混乱）
./build-all-images.sh --build-number 1.8.0 --parallel
```

## 📊 构建时间参考

| 构建方式 | 后端 | 前端 | 总计 |
|---------|-----|------|------|
| **完整构建（首次）** | 8-10分钟 | 4-6分钟 | 12-16分钟 |
| **增量构建** | 3-5分钟 | 1-2分钟 | 4-7分钟 |
| **快速构建** | 4-6分钟 | 1-3分钟 | 5-9分钟 |
| **仅构建镜像** | 45秒 | 15秒 | 1分钟 |

## 🔧 参数速查

### 通用参数（所有脚本支持）

```bash
-b, --build-number NUM    # 设置构建编号（默认: 时间戳）
-r, --registry ADDR       # 设置 Docker 仓库地址（默认: 192.168.99.10）
-n, --name NAME          # 设置镜像名称
-p, --push               # 构建后自动推送镜像
-s, --skip-build         # 跳过编译阶段
-C, --clean              # 清理后重新构建
-h, --help               # 显示帮助信息
```

### 前端专用参数

```bash
--npm-registry URL       # 设置 npm 镜像源（推荐: https://registry.npmmirror.com）
```

### build-all-images.sh 专用参数

```bash
--backend-only           # 仅构建后端镜像
--frontend-only          # 仅构建前端镜像
--parallel               # 并行构建（更快但日志混乱）
```

## 🐛 故障排查

### 后端构建问题

```bash
# Maven 依赖下载失败
rm -rf ~/.m2/repository/com/primihub
./build-docker-image.sh --clean

# SDK 编译失败（脚本已自动处理 protobuf 问题）
./build-docker-image.sh
```

### 前端构建问题

```bash
# npm 依赖下载慢
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# Node.js 版本过低
nvm install 16 && nvm use 16

# 内存不足
export NODE_OPTIONS="--max-old-space-size=4096"
./build-platform-image.sh

# 依赖冲突
./build-platform-image.sh --clean
```

### Docker 问题

```bash
# Docker daemon 未运行
sudo systemctl start docker          # Linux
# 或启动 Docker Desktop               # macOS/Windows

# 磁盘空间不足
docker system prune -a

# 推送失败（需要登录）
docker login 192.168.99.10
```

## 🚢 运行容器

### 单独运行

```bash
# 后端
docker run -d -p 8080:8080 --name primihub-backend \
  192.168.99.10/primihub/privacy:latest

# 前端
docker run -d -p 80:80 --name primihub-frontend \
  192.168.99.10/primihub/platform:latest
```

### 使用 docker-compose（推荐）

```bash
# 启动完整环境（包括 MySQL、Redis、RabbitMQ、Nacos 等）
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 🔗 与 Jenkins Pipeline 对应关系

### 后端构建

```groovy
// Jenkins Pipeline
stage('Build') {
    sh 'cd primihub-sdk && mvn clean install ...'
    sh 'cd primihub-service && mvn clean install ...'
}
stage('Building app image') {
    docker.build("192.168.99.10/primihub/privacy:${BUILD_NUMBER}", ...)
}

// Shell 等效命令
./build-docker-image.sh --build-number ${BUILD_NUMBER}
```

### 前端构建

```groovy
// Jenkins Pipeline
stage('Build') {
    sh 'cd primihub-webconsole && npm install && npm run build:prod'
}
stage('Building app image') {
    sh 'cd primihub-webconsole && docker build ...'
}

// Shell 等效命令
./build-platform-image.sh --build-number ${BUILD_NUMBER}
```

## 📖 详细文档

- **[BUILD_IMAGES.md](BUILD_IMAGES.md)** - 完整构建指南，包含所有场景和最佳实践
- **[BUILD_DOCKER.md](BUILD_DOCKER.md)** - 后端镜像构建详细说明
- **[BUILD_PLATFORM.md](BUILD_PLATFORM.md)** - 前端镜像构建详细说明
- **[DOCKER_BUILD_QUICKREF.md](DOCKER_BUILD_QUICKREF.md)** - 一页快速参考

## ✅ 验证构建结果

```bash
# 查看生成的镜像
docker images | grep primihub

# 预期输出:
# 192.168.99.10/primihub/privacy    BUILD_NUMBER   IMAGE_ID   1.13GB
# 192.168.99.10/primihub/privacy    latest         IMAGE_ID   1.13GB
# 192.168.99.10/primihub/platform   BUILD_NUMBER   IMAGE_ID   224MB
# 192.168.99.10/primihub/platform   latest         IMAGE_ID   224MB

# 测试后端镜像
docker run --rm 192.168.99.10/primihub/privacy:latest java -version

# 测试前端镜像
docker run --rm 192.168.99.10/primihub/platform:latest nginx -v
```

## 🎓 最佳实践

1. **版本管理**: 使用语义化版本号（如 1.8.0）而不是时间戳
2. **镜像加速**: 使用 npm 淘宝镜像和 Maven 阿里云镜像
3. **缓存利用**: 保留 node_modules 和 ~/.m2 以加速增量构建
4. **并行构建**: 在 CI/CD 中使用 `--parallel` 参数节省时间
5. **定期清理**: 使用 `docker system prune` 清理未使用的镜像

## 📞 获取帮助

```bash
# 查看脚本帮助
./build-docker-image.sh --help
./build-platform-image.sh --help
./build-all-images.sh --help

# 阅读详细文档
cat BUILD_IMAGES.md

# 查看快速参考
cat DOCKER_BUILD_QUICKREF.md
```

## 🌟 快速命令参考

```bash
# 最常用的命令
./build-all-images.sh                               # 构建所有镜像
./build-all-images.sh --build-number 1.8.0          # 指定版本
./build-all-images.sh --build-number 1.8.0 --push   # 构建并推送
./quick-build.sh && ./quick-build-platform.sh       # 快速构建
```

---

**祝您构建顺利！** 🚀

如有问题，请查看详细文档或提交 Issue。
