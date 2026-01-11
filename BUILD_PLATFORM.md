# PrimiHub Platform 前端镜像构建指南

## 快速开始

### 基本构建

```bash
# 标准构建流程（npm install + build + docker）
./build-platform-image.sh

# 输出示例:
# ========================================
# Stage 1: 编译前端项目
# ========================================
# [SUCCESS] npm 依赖安装成功
# [SUCCESS] 前端构建成功 (耗时: 120s)
#
# ========================================
# Stage 2: 构建 Docker 镜像
# ========================================
# [SUCCESS] Docker 镜像构建成功 (耗时: 15s)
```

## 脚本特性

### 1. 完全对应 Jenkins Pipeline

脚本严格按照 Jenkins Pipeline 的构建流程设计：

```
Jenkins Pipeline                    Shell Script
─────────────────                   ────────────
stage('Build')                  →   build_frontend()
  ├─ cd primihub-webconsole            ├─ cd primihub-webconsole
  ├─ npm install                       ├─ npm install
  └─ npm run build:prod                └─ npm run build:prod

stage('Building app image')     →   build_docker_image()
  └─ docker build                      └─ docker build -t IMAGE_TAG -f Dockerfile.local .
     -t 192.168.99.10/primihub/
     platform:$BUILD_NUMBER
     -f Dockerfile.local
```

### 2. 智能功能

- ✅ **前置检查**: 自动检测 Node.js、npm、Docker 环境
- ✅ **版本验证**: 检查 Node.js 版本是否满足要求（12+）
- ✅ **构建验证**: 验证 dist 目录是否生成
- ✅ **错误处理**: 任何步骤失败立即退出并显示错误信息
- ✅ **时间统计**: 显示各阶段耗时
- ✅ **系统信息**: 显示 PATH、devtoolset、g++、Python 等信息
- ✅ **npm 镜像**: 支持配置淘宝等镜像加速下载

### 3. 灵活配置

支持通过命令行参数或环境变量配置所有选项。

## 使用场景

### 场景 1: 本地开发构建

```bash
# 完整构建（首次构建）
./build-platform-image.sh

# 使用淘宝镜像加速
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# 快速构建
./quick-build-platform.sh
```

### 场景 2: CI/CD 集成

```bash
#!/bin/bash
# 在 GitLab CI / GitHub Actions 中使用

export BUILD_NUMBER="${CI_COMMIT_TAG:-${CI_COMMIT_SHORT_SHA}}"
export DOCKER_REGISTRY="registry.example.com"
export PUSH_IMAGE=true
export NPM_REGISTRY="https://registry.npmmirror.com"

./build-platform-image.sh
```

**GitLab CI 示例**:
```yaml
# .gitlab-ci.yml
build-platform:
  stage: build
  script:
    - ./build-platform-image.sh
        --build-number $CI_COMMIT_TAG
        --npm-registry https://registry.npmmirror.com
        --push
  only:
    - tags
```

**GitHub Actions 示例**:
```yaml
# .github/workflows/platform-build.yml
name: Build Platform Image
on:
  push:
    tags:
      - 'v*'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Platform Image
        run: |
          ./build-platform-image.sh \
            --build-number ${GITHUB_REF##*/} \
            --push
```

### 场景 3: 生产发布

```bash
# 指定版本号构建并推送到生产仓库
./build-platform-image.sh \
  --build-number 1.8.0 \
  --registry registry.example.com \
  --name primihub/web \
  --push
```

### 场景 4: 仅构建镜像（已有编译产物）

```bash
# 如果 dist 目录已存在，可以快速构建镜像
./build-platform-image.sh --skip-build

# 适用于:
# - 调试 Dockerfile
# - 快速重建镜像
# - 微调 Nginx 配置
```

### 场景 5: 清理后重新构建

```bash
# 删除 node_modules 和 dist，完全重新构建
./build-platform-image.sh --clean

# 适用于:
# - 依赖冲突
# - 构建缓存问题
# - 版本更新后
```

## 命令行参数详解

### 基础参数

| 参数 | 说明 | 默认值 | 示例 |
|-----|------|-------|------|
| `-h, --help` | 显示帮助信息 | - | `--help` |
| `-b, --build-number` | 构建编号 | 时间戳 | `--build-number 1.8.0` |
| `-r, --registry` | Docker 仓库地址 | 192.168.99.10 | `--registry registry.example.com` |
| `-n, --name` | 镜像名称 | primihub/platform | `--name myapp/web` |

### 高级参数

| 参数 | 说明 | 默认值 | 示例 |
|-----|------|-------|------|
| `-f, --dockerfile` | Dockerfile 路径 | Dockerfile.local | `--dockerfile Dockerfile` |
| `-p, --push` | 自动推送镜像 | false | `--push` |
| `-s, --skip-build` | 跳过 npm 编译 | false | `--skip-build` |
| `-C, --clean` | 清理后构建 | false | `--clean` |
| `--npm-registry` | npm 镜像源 | 默认源 | `--npm-registry https://registry.npmmirror.com` |
| `--no-cleanup` | 不清理悬空镜像 | false | `--no-cleanup` |

## 环境变量

所有参数都可以通过环境变量配置：

```bash
# 设置环境变量
export BUILD_NUMBER="1.8.0"
export DOCKER_REGISTRY="registry.example.com"
export IMAGE_NAME="primihub/web"
export PUSH_IMAGE="true"
export SKIP_BUILD="false"
export CLEAN_BUILD="true"
export NPM_REGISTRY="https://registry.npmmirror.com"

# 运行脚本（使用环境变量）
./build-platform-image.sh
```

## npm 镜像加速

### 淘宝镜像（推荐）

```bash
# 临时使用
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# 永久配置
npm config set registry https://registry.npmmirror.com

# 验证
npm config get registry
```

### 其他镜像源

```bash
# 官方源
--npm-registry https://registry.npmjs.org

# 腾讯云
--npm-registry https://mirrors.cloud.tencent.com/npm/

# 华为云
--npm-registry https://repo.huaweicloud.com/repository/npm/
```

## 构建输出

### 构建阶段

```
========================================
PrimiHub Platform 前端镜像构建
========================================

构建配置:
  开始时间:    2026-01-08 10:30:00
  构建目录:    /home/primihub/github/primihub-platform
  前端目录:    /home/primihub/github/primihub-platform/primihub-webconsole
  构建编号:    20260108103000
  镜像标签:    192.168.99.10/primihub/platform:20260108103000
  npm 镜像:    https://registry.npmmirror.com

========================================
检查前置条件
========================================

[SUCCESS] Node.js: v16.14.0
[SUCCESS] npm: 8.15.1
[SUCCESS] Docker: Docker version 24.0.5
[SUCCESS] Docker daemon 运行中
[SUCCESS] 所有前置条件满足

========================================
系统信息
========================================

[INFO] PATH: /usr/local/bin:/usr/bin:/bin
[INFO] SCL 不可用 (非 CentOS/RHEL 系统)
[SUCCESS] g++: g++ (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
[SUCCESS] Python3: Python 3.10.12

========================================
Stage 1: 编译前端项目
========================================

[INFO] 当前目录: /home/primihub/github/primihub-platform/primihub-webconsole
[步骤] 配置 npm 镜像...
[SUCCESS] npm 镜像已设置: https://registry.npmmirror.com
[步骤] 安装 npm 依赖...
[SUCCESS] npm 依赖安装成功
[INFO] node_modules 大小: 450M
[步骤] 构建生产版本...
[SUCCESS] 前端构建成功 (耗时: 120s)
[步骤] 验证构建产物...
[SUCCESS] dist 目录大小: 12M
[INFO] dist 目录结构:
  drwxr-xr-x  css/
  drwxr-xr-x  fonts/
  -rw-r--r--  index.html
  drwxr-xr-x  img/
  drwxr-xr-x  js/

========================================
Stage 2: 构建 Docker 镜像
========================================

[INFO] 当前目录: /home/primihub/github/primihub-platform/primihub-webconsole
[INFO] 构建配置:
  Registry:    192.168.99.10
  Image Name:  primihub/platform
  Image Tag:   192.168.99.10/primihub/platform:20260108103000
  Build Number: 20260108103000
  Dockerfile:  Dockerfile.local

[步骤] 开始构建 Docker 镜像...
Step 1/2 : FROM nginx:1.20
Step 2/2 : COPY dist/ /usr/local/nginx/html/
[SUCCESS] Docker 镜像构建成功 (耗时: 15s)

[步骤] 镜像信息:
REPOSITORY                         TAG              IMAGE ID       SIZE
192.168.99.10/primihub/platform   20260108103000   a1b2c3d4e5f6   224MB

[步骤] 添加 latest 标签...
[SUCCESS] 已添加标签: 192.168.99.10/primihub/platform:latest
```

### 构建总结

```
========================================
构建总结
========================================

✓ 构建完成！

构建信息:
  Build Number: 20260108103000
  Image Tag:    192.168.99.10/primihub/platform:20260108103000
  Latest Tag:   192.168.99.10/primihub/platform:latest

构建产物:
  Dist:        primihub-webconsole/dist/
  Size:        12M

Docker 镜像:
  192.168.99.10/primihub/platform:20260108103000 (224MB)
  192.168.99.10/primihub/platform:latest (224MB)

下一步操作:
  1. 运行容器:
     docker run -d -p 80:80 --name primihub-web 192.168.99.10/primihub/platform:20260108103000

  2. 推送到仓库:
     docker push 192.168.99.10/primihub/platform:20260108103000

  3. 访问前端:
     http://localhost

  4. 查看 Nginx 日志:
     docker logs -f primihub-web

! 镜像未推送 (使用 --push 参数启用自动推送)

[SUCCESS] 总耗时: 135s (00:02:15)
[SUCCESS] 构建流程完成！
```

## 故障排查

### 问题 1: npm install 失败

**错误**:
```
npm ERR! network timeout
```

**解决方案**:
```bash
# 使用淘宝镜像
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# 或永久配置
npm config set registry https://registry.npmmirror.com
npm config set timeout 60000
```

### 问题 2: Node.js 版本过低

**错误**:
```
[WARNING] Node.js 版本过低，建议使用 12.x 或更高版本
```

**解决方案**:
```bash
# 使用 nvm 升级 Node.js
nvm install 16
nvm use 16

# 或使用系统包管理器
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs
```

### 问题 3: npm 依赖编译失败

**错误**:
```
gyp ERR! build error
node-gyp: No C++ compiler found
```

**解决方案**:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential python3

# CentOS/RHEL 7
sudo yum install centos-release-scl
sudo yum install devtoolset-7
scl enable devtoolset-7 bash

# CentOS/RHEL 8+
sudo dnf install gcc-c++ make python3
```

### 问题 4: 内存不足

**错误**:
```
FATAL ERROR: Ineffective mark-compacts near heap limit
```

**解决方案**:
```bash
# 增加 Node.js 内存限制
export NODE_OPTIONS="--max-old-space-size=4096"
./build-platform-image.sh

# 或修改 package.json
# "build:prod": "node --max-old-space-size=4096 node_modules/@vue/cli-service/bin/vue-cli-service.js build"
```

### 问题 5: dist 目录不存在

**错误**:
```
[ERROR] dist 目录不存在，构建可能失败
```

**解决方案**:
```bash
# 检查构建日志
npm run build:prod

# 手动构建
cd primihub-webconsole
npm install
npm run build:prod
ls -la dist/

# 然后构建镜像
cd ..
./build-platform-image.sh --skip-build
```

## 与其他构建方法对比

| 特性 | build-platform-image.sh | quick-build-platform.sh | 直接 npm | docker-compose |
|-----|------------------------|------------------------|----------|----------------|
| **安装依赖** | ✅ 自动 | ✅ 自动 | ✅ 手动 | ❌ 需手动 |
| **构建前端** | ✅ 自动 | ✅ 自动 | ✅ 手动 | ❌ 需手动 |
| **构建镜像** | ✅ 自动 | ✅ 自动 | ❌ 手动 | ✅ 自动 |
| **推送镜像** | ✅ 可选 | ❌ 手动 | ❌ 手动 | ❌ 不支持 |
| **前置检查** | ✅ 完整 | ❌ 无 | ❌ 无 | ❌ 无 |
| **错误处理** | ✅ 详细 | ⚠️ 基础 | ❌ 无 | ❌ 无 |
| **构建报告** | ✅ 详细 | ⚠️ 简单 | ❌ 无 | ❌ 无 |
| **Jenkins 对应** | ✅ 完全 | ⚠️ 部分 | ❌ 无 | ❌ 无 |
| **npm 镜像** | ✅ 支持 | ❌ 不支持 | ⚠️ 手动 | ❌ 不支持 |

## 最佳实践

### 1. 使用 npm 镜像加速

```bash
# 中国大陆用户推荐
./build-platform-image.sh --npm-registry https://registry.npmmirror.com
```

### 2. 版本号规范

```bash
# 语义化版本
./build-platform-image.sh --build-number 1.8.0

# 基于 Git 标签
./build-platform-image.sh --build-number $(git describe --tags --abbrev=0)

# 包含日期
./build-platform-image.sh --build-number "1.8.0-$(date +%Y%m%d)"
```

### 3. 多环境构建

```bash
# 开发环境
./build-platform-image.sh \
  --build-number dev-$(git branch --show-current) \
  --registry registry-dev.example.com

# 测试环境
./build-platform-image.sh \
  --build-number test-$(date +%Y%m%d) \
  --registry registry-test.example.com \
  --push

# 生产环境
./build-platform-image.sh \
  --build-number $(cat VERSION) \
  --registry registry.example.com \
  --push
```

### 4. 缓存优化

```bash
# 保留 node_modules 缓存（增量构建）
./build-platform-image.sh

# 完全清理后构建（解决依赖问题）
./build-platform-image.sh --clean
```

### 5. 自定义 Nginx 配置

```bash
# 修改 primihub-webconsole/Dockerfile.local
FROM nginx:1.20

# 复制前端文件
COPY dist/ /usr/local/nginx/html/

# 复制自定义 Nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80
```

## 同时构建后端和前端

使用 `build-all-images.sh` 脚本可以同时构建两个镜像：

```bash
# 串行构建（推荐，日志清晰）
./build-all-images.sh --build-number 1.8.0

# 并行构建（更快，日志混乱）
./build-all-images.sh --build-number 1.8.0 --parallel

# 仅构建后端
./build-all-images.sh --backend-only

# 仅构建前端
./build-all-images.sh --frontend-only

# 构建并推送
./build-all-images.sh --build-number 1.8.0 --push
```

## 运行容器

```bash
# 基本运行
docker run -d \
  --name primihub-web \
  -p 80:80 \
  192.168.99.10/primihub/platform:latest

# 自定义 Nginx 配置
docker run -d \
  --name primihub-web \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  192.168.99.10/primihub/platform:latest

# 查看日志
docker logs -f primihub-web

# 进入容器
docker exec -it primihub-web bash

# 查看 Nginx 配置
docker exec primihub-web cat /etc/nginx/conf.d/default.conf
```

## 完整部署

```bash
# 使用 docker-compose 部署完整环境
# 包括后端、前端、数据库、Redis 等
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 性能数据

| 操作 | 时间 | 说明 |
|-----|------|------|
| npm install (首次) | 2-5 分钟 | 取决于网络速度 |
| npm install (缓存) | 10-30 秒 | 使用 node_modules 缓存 |
| npm run build:prod | 1-2 分钟 | Vue CLI 生产构建 |
| docker build | 10-20 秒 | 仅复制 dist 文件 |
| **总计（首次）** | **3-7 分钟** | 完整构建 |
| **总计（增量）** | **1-3 分钟** | 有缓存时 |

## 总结

`build-platform-image.sh` 是一个功能完整的前端镜像构建脚本：

✅ **完全对应 Jenkins Pipeline** - 保持与 CI/CD 流程一致
✅ **智能化构建** - 自动检查、验证、报错
✅ **npm 镜像支持** - 可配置淘宝镜像加速
✅ **高度可配置** - 支持命令行参数和环境变量
✅ **详细输出** - 清晰的构建日志和总结报告
✅ **生产就绪** - 支持推送、标签管理、清理

立即开始使用：

```bash
# 标准构建
./build-platform-image.sh

# 使用镜像加速
./build-platform-image.sh --npm-registry https://registry.npmmirror.com

# 查看帮助
./build-platform-image.sh --help
```
