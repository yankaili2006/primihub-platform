# Docker 镜像构建完整指南

## 镜像概览

PrimiHub Platform 包含两个 Docker 镜像：

| 镜像 | 用途 | 技术栈 | 大小 | 端口 |
|-----|------|--------|------|------|
| **primihub/privacy** | 后端服务 | Java 8 + Spring Boot | ~1.13GB | 8080 |
| **primihub/platform** | 前端应用 | Vue.js 2 + Nginx | ~224MB | 80 |

---

## 快速开始

### 方法 1: 构建单个镜像

```bash
# 构建后端镜像
./build-docker-image.sh

# 构建前端镜像
./build-platform-image.sh
```

### 方法 2: 构建所有镜像

```bash
# 同时构建后端和前端
./build-all-images.sh

# 或使用快速构建脚本
./quick-build.sh          # 后端
./quick-build-platform.sh # 前端
```

---

## 构建脚本对比

### 后端 (Privacy) 镜像

| 脚本 | 特点 | 构建时间 | 适用场景 |
|-----|------|---------|---------|
| **build-docker-image.sh** | 完整功能，对应 Jenkins | 6-10 分钟 | CI/CD、生产发布 |
| **quick-build.sh** | 精简版，静默输出 | 4-6 分钟 | 快速测试、开发 |

### 前端 (Platform) 镜像

| 脚本 | 特点 | 构建时间 | 适用场景 |
|-----|------|---------|---------|
| **build-platform-image.sh** | 完整功能，对应 Jenkins | 3-7 分钟 | CI/CD、生产发布 |
| **quick-build-platform.sh** | 精简版，静默输出 | 1-3 分钟 | 快速测试、开发 |

### 统一构建

| 脚本 | 特点 | 构建时间 | 适用场景 |
|-----|------|---------|---------|
| **build-all-images.sh** | 同时构建两个镜像 | 9-17 分钟 | 完整发布 |

---

## 常用命令速查

### 后端镜像

```bash
# 标准构建
./build-docker-image.sh

# 指定版本并推送
./build-docker-image.sh --build-number 1.8.0 --push

# 跳过编译（仅构建镜像）
./build-docker-image.sh --skip-build

# 快速构建
./quick-build.sh
```

### 前端镜像

```bash
# 标准构建
./build-platform-image.sh

# 使用淘宝镜像加速
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# 指定版本并推送
./build-platform-image.sh --build-number 1.8.0 --push

# 快速构建
./quick-build-platform.sh
```

### 同时构建

```bash
# 串行构建（日志清晰）
./build-all-images.sh --build-number 1.8.0

# 并行构建（速度更快）
./build-all-images.sh --build-number 1.8.0 --parallel

# 仅构建后端
./build-all-images.sh --backend-only

# 仅构建前端
./build-all-images.sh --frontend-only
```

---

## Jenkins Pipeline 对应关系

### 后端 (Privacy) 构建

```groovy
// Jenkins Pipeline
stage('Build') {
    sh 'cd primihub-sdk && mvn clean install -Dos.detected.classifier=linux-x86_64'
    sh 'cd primihub-service && mvn clean install'
}
stage('Building app image') {
    docker.build("192.168.99.10/primihub/privacy:${BUILD_NUMBER}",
                 "-f ./primihub-service/Dockerfile.local ./primihub-service")
}

// Shell 等效命令
./build-docker-image.sh --build-number ${BUILD_NUMBER}
```

### 前端 (Platform) 构建

```groovy
// Jenkins Pipeline
stage('Build') {
    sh 'cd primihub-webconsole && npm install && npm run build:prod'
}
stage('Building app image') {
    sh 'cd primihub-webconsole && docker build -t 192.168.99.10/primihub/platform:$BUILD_NUMBER . -f Dockerfile.local'
}

// Shell 等效命令
./build-platform-image.sh --build-number ${BUILD_NUMBER}
```

---

## 参数速查表

### 通用参数

```bash
-b, --build-number NUM    # 设置构建编号
-r, --registry ADDR       # 设置仓库地址
-n, --name NAME          # 设置镜像名称
-p, --push               # 自动推送镜像
-s, --skip-build         # 跳过编译阶段
-C, --clean              # 清理后构建
-h, --help               # 显示帮助
```

### 前端专用参数

```bash
--npm-registry URL       # 设置 npm 镜像源
```

### build-all-images.sh 专用

```bash
--backend-only           # 仅构建后端
--frontend-only          # 仅构建前端
--parallel               # 并行构建
```

---

## 使用场景

### 场景 1: 本地开发

```bash
# 快速构建测试
./quick-build.sh                  # 后端
./quick-build-platform.sh         # 前端

# 或完整构建
./build-all-images.sh
```

### 场景 2: 生产发布

```bash
# 指定版本号
./build-all-images.sh \
  --build-number $(cat VERSION) \
  --registry registry.example.com \
  --push
```

### 场景 3: CI/CD

```bash
# GitLab CI / GitHub Actions
export BUILD_NUMBER="${CI_COMMIT_TAG}"
export DOCKER_REGISTRY="registry.example.com"
export PUSH_IMAGE=true

./build-all-images.sh
```

### 场景 4: 多仓库发布

```bash
# 构建一次
./build-all-images.sh --build-number 1.8.0

# 推送到不同仓库
docker tag 192.168.99.10/primihub/privacy:1.8.0 \
  registry.cn-beijing.aliyuncs.com/primihub/primihub-platform:1.8.0
docker push registry.cn-beijing.aliyuncs.com/primihub/primihub-platform:1.8.0
```

---

## 运行容器

### 后端容器

```bash
docker run -d \
  --name primihub-backend \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=test \
  192.168.99.10/primihub/privacy:latest
```

### 前端容器

```bash
docker run -d \
  --name primihub-frontend \
  -p 80:80 \
  192.168.99.10/primihub/platform:latest
```

### 使用 docker-compose

```bash
# 启动完整环境
docker-compose up -d

# 服务列表:
# - MySQL (3306)
# - Redis (6379)
# - RabbitMQ (5672, 15672)
# - Nacos (8848)
# - Backend (8080)
# - Frontend (80)
```

---

## 故障排查

### 后端构建问题

```bash
# Maven 依赖问题
rm -rf ~/.m2/repository/com/primihub
./build-docker-image.sh --clean

# protobuf 编译失败
./build-docker-image.sh  # 脚本已自动处理
```

### 前端构建问题

```bash
# npm 下载慢
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# Node.js 版本低
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
sudo systemctl start docker  # Linux
# 或启动 Docker Desktop      # macOS/Windows

# 磁盘空间不足
docker system prune -a

# 推送失败
docker login 192.168.99.10
```

---

## 构建时间对比

| 构建方式 | 后端 | 前端 | 总计 | 说明 |
|---------|-----|------|------|------|
| **首次完整构建** | 8-10分钟 | 4-6分钟 | 12-16分钟 | 下载所有依赖 |
| **增量构建** | 3-5分钟 | 1-2分钟 | 4-7分钟 | 使用缓存 |
| **仅构建镜像** | 45秒 | 15秒 | 1分钟 | 跳过编译 |
| **并行构建** | - | - | 8-12分钟 | 同时构建 |

---

## 镜像大小对比

| 镜像 | 未压缩 | 压缩后 | 优化建议 |
|-----|--------|--------|---------|
| **primihub/privacy** | 1.13GB | 473MB | 使用 Alpine JRE |
| **primihub/platform** | 224MB | 60MB | 已优化 |
| **总计** | 1.35GB | 533MB | - |

---

## 最佳实践

### 1. 版本管理

```bash
# 使用语义化版本
./build-all-images.sh --build-number 1.8.0

# 基于 Git 标签
./build-all-images.sh --build-number $(git describe --tags)

# 包含日期
./build-all-images.sh --build-number "1.8.0-$(date +%Y%m%d)"
```

### 2. 多环境构建

```bash
# 开发
BUILD_NUMBER=dev ./build-all-images.sh

# 测试
BUILD_NUMBER=test-$(date +%Y%m%d) ./build-all-images.sh --push

# 生产
BUILD_NUMBER=$(cat VERSION) ./build-all-images.sh --push
```

### 3. 缓存优化

```bash
# 使用 BuildKit 加速
export DOCKER_BUILDKIT=1
./build-all-images.sh

# Maven 本地仓库
# 确保 ~/.m2/repository 有写权限

# npm 缓存
# 确保 ~/.npm 有写权限
```

### 4. 清理策略

```bash
# 定期清理悬空镜像
docker image prune -f

# 清理所有未使用的镜像
docker image prune -a

# 查看磁盘使用
docker system df
```

---

## 集成到 CI/CD

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - push

build:
  stage: build
  script:
    - ./build-all-images.sh --build-number $CI_COMMIT_TAG
  only:
    - tags

push:
  stage: push
  script:
    - ./build-all-images.sh --build-number $CI_COMMIT_TAG --push
  only:
    - tags
```

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build Images
on:
  push:
    tags:
      - 'v*'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build All Images
        run: |
          ./build-all-images.sh \
            --build-number ${GITHUB_REF##*/} \
            --push
```

### Makefile

```makefile
# Makefile
.PHONY: build push clean

VERSION := $(shell cat VERSION)

build:
	./build-all-images.sh --build-number $(VERSION)

push:
	./build-all-images.sh --build-number $(VERSION) --push

clean:
	docker system prune -af
```

---

## 生成的文件列表

```
primihub-platform/
├── build-docker-image.sh        # 后端镜像构建（完整）
├── build-platform-image.sh      # 前端镜像构建（完整）
├── build-all-images.sh          # 同时构建两个镜像
├── quick-build.sh               # 后端快速构建
├── quick-build-platform.sh      # 前端快速构建
├── BUILD_DOCKER.md              # 后端构建详细文档
├── BUILD_PLATFORM.md            # 前端构建详细文档
├── BUILD_IMAGES.md              # 完整构建指南（本文件）
└── DOCKER_BUILD_QUICKREF.md     # 快速参考
```

---

## 获取帮助

```bash
# 查看帮助信息
./build-docker-image.sh --help
./build-platform-image.sh --help
./build-all-images.sh --help

# 查看详细文档
cat BUILD_DOCKER.md          # 后端详细文档
cat BUILD_PLATFORM.md        # 前端详细文档
cat BUILD_IMAGES.md          # 完整构建指南
cat DOCKER_BUILD_QUICKREF.md # 快速参考
```

---

## 立即开始

```bash
# 1. 构建所有镜像
./build-all-images.sh

# 2. 查看镜像
docker images | grep primihub

# 3. 运行容器
docker-compose up -d

# 4. 访问服务
# 前端: http://localhost
# 后端: http://localhost:8080
# API文档: http://localhost:8080/doc.html
```

---

**祝您构建顺利！** 🚀
