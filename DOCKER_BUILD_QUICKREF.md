# Docker 镜像构建快速参考

## 三种构建脚本对比

| 脚本 | 特点 | 适用场景 | 构建时间 |
|-----|------|---------|---------|
| **build-docker-image.sh** | 功能完整，Jenkins 对应 | CI/CD、生产发布 | ~6-10 分钟 |
| **quick-build.sh** | 精简快速，静默输出 | 快速测试、开发迭代 | ~4-6 分钟 |
| **build.sh** | 通用构建，多功能 | 本地开发、完整构建 | ~8-12 分钟 |

---

## 快速命令

### 1. 标准构建（推荐）

```bash
# 使用完整功能的构建脚本
./build-docker-image.sh

# 指定版本号
./build-docker-image.sh --build-number 1.8.0

# 构建并推送
./build-docker-image.sh --build-number 1.8.0 --push
```

### 2. 快速构建（最快）

```bash
# 使用精简脚本（静默模式）
./quick-build.sh

# 自定义构建号
BUILD_NUMBER=1.8.0 ./quick-build.sh
```

### 3. 仅构建镜像（跳过编译）

```bash
# 适合已编译的情况
./build-docker-image.sh --skip-build
```

### 4. 清理后重新构建

```bash
# 完全清理后构建
./build-docker-image.sh --clean
```

---

## 常用参数速查

```bash
# 基础参数
-b, --build-number NUM    # 设置构建编号
-r, --registry ADDR       # 设置仓库地址
-n, --name NAME          # 设置镜像名称
-p, --push               # 自动推送镜像
-s, --skip-build         # 跳过编译阶段
-C, --clean              # 清理后构建
-h, --help               # 显示帮助
```

---

## Jenkins Pipeline 对应关系

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

---

## 使用示例

### 场景 1: 本地开发

```bash
# 第一次构建
./build-docker-image.sh

# 后续快速构建
./quick-build.sh
```

### 场景 2: CI/CD

```bash
# GitLab CI / GitHub Actions
./build-docker-image.sh \
  --build-number $CI_COMMIT_TAG \
  --registry registry.example.com \
  --push
```

### 场景 3: 生产发布

```bash
# 带版本号的生产构建
./build-docker-image.sh \
  --build-number $(cat VERSION) \
  --registry prod-registry.example.com \
  --name primihub/platform \
  --push
```

### 场景 4: 多仓库推送

```bash
# 构建一次
./build-docker-image.sh --build-number 1.8.0

# 推送到多个仓库
docker tag 192.168.99.10/primihub/privacy:1.8.0 \
  registry.cn-beijing.aliyuncs.com/primihub/primihub-platform:1.8.0
docker push registry.cn-beijing.aliyuncs.com/primihub/primihub-platform:1.8.0

docker tag 192.168.99.10/primihub/privacy:1.8.0 \
  docker.io/primihub/platform:1.8.0
docker push docker.io/primihub/platform:1.8.0
```

---

## 环境变量

```bash
# 设置环境变量
export BUILD_NUMBER="1.8.0"
export DOCKER_REGISTRY="registry.example.com"
export IMAGE_NAME="primihub/platform"
export PUSH_IMAGE="true"

# 运行
./build-docker-image.sh
```

---

## 故障排查

### Maven 构建失败
```bash
# 清理 Maven 缓存
rm -rf ~/.m2/repository/com/primihub

# 重新构建
./build-docker-image.sh --clean
```

### Docker 构建失败
```bash
# 检查 Docker 状态
docker info

# 清理 Docker 缓存
docker system prune -a
```

### 镜像推送失败
```bash
# 登录仓库
docker login 192.168.99.10

# 重新推送
docker push 192.168.99.10/primihub/privacy:TAG
```

---

## 构建产物

构建完成后会生成：

```
编译产物:
├── primihub-sdk/target/primihub-sdk-1.0.1.jar              (~15MB)
├── primihub-service/application/target/application-1.0-SNAPSHOT.jar  (~172MB)
└── primihub-service/gateway/target/gateway-1.0-SNAPSHOT.jar          (~129MB)

Docker 镜像:
├── 192.168.99.10/primihub/privacy:BUILD_NUMBER             (~1.13GB)
└── 192.168.99.10/primihub/privacy:latest                   (~1.13GB)
```

---

## 运行容器

```bash
# 运行 Application
docker run -d \
  --name primihub-platform \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=test \
  192.168.99.10/primihub/privacy:latest

# 查看日志
docker logs -f primihub-platform

# 进入容器
docker exec -it primihub-platform bash
```

---

## 完整部署

```bash
# 使用 docker-compose 部署完整环境
docker-compose up -d

# 服务列表:
# - MySQL (3306)
# - Redis (6379)
# - RabbitMQ (5672, 15672)
# - Nacos (8848)
# - Application (8090)
# - Gateway (8088)
```

---

## 性能优化建议

```bash
# 1. 使用 BuildKit 加速
export DOCKER_BUILDKIT=1
./build-docker-image.sh

# 2. 使用阿里云 Maven 镜像
# 编辑 ~/.m2/settings.xml

# 3. 并行构建（如果有多个项目）
./build-docker-image.sh &
./build-other-image.sh &
wait
```

---

## 获取帮助

```bash
# 查看完整帮助
./build-docker-image.sh --help

# 查看详细文档
cat BUILD_DOCKER.md

# 在线文档
# https://github.com/primihub/primihub-platform
```
