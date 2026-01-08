# PrimiHub Scripts 使用说明

本目录包含 PrimiHub 平台的自动化脚本，用于简化部署、测试和管理流程。

## 📚 脚本清单

### 1. check_environment.sh - 环境检查
**功能**: 检查服务器是否满足 PrimiHub 部署要求

**用法**:
```bash
./check_environment.sh
```

**检查项目**:
- ✅ 系统资源 (磁盘、内存、端口)
- ✅ 必需软件 (Java、Python、Node.js、Maven)
- ✅ Python 环境和依赖
- ✅ 网络连接

**输出**: 环境检查报告，标识通过/警告/失败项

---

### 2. build.sh - 自动编译
**功能**: 自动编译 primihub-platform 后端和前端

**用法**:
```bash
./build.sh [选项]

选项:
  --skip-tests    跳过单元测试
  --clean         清理后重新编译
```

**示例**:
```bash
# 完整编译
./build.sh

# 跳过测试
./build.sh --skip-tests

# 清理后编译
./build.sh --clean
```

**产物**:
- 后端: `primihub-service/application/target/application.jar`
- 前端: `primihub-webconsole/node_modules/`
- 启动脚本: `start-simple.sh` 和 `start.sh`

---

### 3. deploy.sh - 自动部署
**功能**: 自动部署所有 PrimiHub 组件

**用法**:
```bash
./deploy.sh [选项]

选项:
  --mode MODE         部署模式: minimal (默认) 或 full
  --skip-python       跳过 Python 环境配置
  --primihub-dir DIR  指定 primihub 计算节点目录
  --meta-dir DIR      指定 primihub-meta 目录
```

**示例**:
```bash
# 默认部署
./deploy.sh

# 指定目录
./deploy.sh --primihub-dir /opt/primihub --meta-dir /opt/primihub-meta

# 跳过Python配置
./deploy.sh --skip-python
```

**部署组件**:
- ✅ 平台后端 (8090)
- ✅ 平台前端 (8080)
- ✅ Meta Service (7977-7979)
- ✅ Python 环境 (torch 2.6.0+cpu)

---

### 4. test.sh - 集成测试
**功能**: 自动测试 PSI、PIR、FL 三大核心功能

**用法**:
```bash
./test.sh [选项]

选项:
  --quick            快速测试模式 (只测试基本功能)
  --skip-fl          跳过FL测试
  --primihub-dir DIR 指定 primihub 目录
```

**示例**:
```bash
# 完整测试
./test.sh

# 快速测试
./test.sh --quick

# 跳过FL
./test.sh --skip-fl
```

**测试项目**:
- ✅ 服务可用性 (后端、前端、Meta、计算节点)
- ✅ PSI (隐私集合求交)
- ✅ PIR (隐匿查询)
- ✅ FL (联邦学习)
- ✅ API 接口

**结果**: 测试报告保存在 `/tmp/primihub-test-results/`

---

### 5. install.sh - 一键安装
**功能**: 自动执行检查、编译、部署、测试全流程

**用法**:
```bash
./install.sh [选项]

选项:
  --skip-check    跳过环境检查
  --skip-test     跳过功能测试
```

**示例**:
```bash
# 完整安装
./install.sh

# 快速安装（跳过检查和测试）
./install.sh --skip-check --skip-test
```

**执行步骤**:
1. 🔍 环境检查
2. 🔨 编译项目
3. 🚀 部署服务
4. ✅ 功能测试

**耗时**: 约 5-10 分钟

---

### 6. stop.sh - 停止服务
**功能**: 停止所有 PrimiHub 服务

**用法**:
```bash
./stop.sh [选项]

选项:
  --force    强制停止所有进程
```

**示例**:
```bash
# 正常停止
./stop.sh

# 强制停止
./stop.sh --force
```

---

## 🚀 快速开始

### 新服务器部署

```bash
# 1. 克隆项目
git clone https://github.com/primihub/primihub-platform.git
cd primihub-platform

# 2. 赋予脚本执行权限
chmod +x scripts/*.sh

# 3. 一键安装
./scripts/install.sh
```

### 已有环境重新部署

```bash
# 1. 停止服务
./scripts/stop.sh

# 2. 重新编译和部署
./scripts/build.sh --clean
./scripts/deploy.sh

# 3. 运行测试
./scripts/test.sh
```

---

## 📝 典型使用场景

### 场景1: 开发环境搭建
```bash
# 检查环境
./scripts/check_environment.sh

# 如果环境OK，一键安装
./scripts/install.sh
```

### 场景2: 代码更新后重新部署
```bash
# 拉取最新代码
git pull

# 停止服务
./scripts/stop.sh

# 重新编译部署
./scripts/build.sh --clean
./scripts/deploy.sh
```

### 场景3: 只测试功能
```bash
# 确保服务运行中
curl http://localhost:8090/actuator/health

# 运行测试
./scripts/test.sh
```

### 场景4: 生产环境部署
```bash
# 1. 严格检查环境
./scripts/check_environment.sh

# 2. 编译（包含测试）
./scripts/build.sh

# 3. 手动部署
./scripts/deploy.sh --mode full

# 4. 完整测试
./scripts/test.sh
```

---

## 📊 日志和输出

### 日志位置
```
/tmp/primihub-backend.log       - 后端日志
/tmp/primihub-frontend.log      - 前端日志
/tmp/primihub-meta{0,1,2}.log   - Meta Service 日志
/tmp/primihub-test-results/     - 测试结果
```

### PID 文件
```
/tmp/primihub/backend.pid
/tmp/primihub/frontend.pid
/tmp/primihub/meta{0,1,2}.pid
```

### 查看日志
```bash
# 实时查看后端日志
tail -f /tmp/primihub-backend.log

# 查看测试结果
cat /tmp/primihub-test-results/test_report.txt
```

---

## 🔧 故障排查

### 环境检查失败
```bash
# 查看详细输出
./scripts/check_environment.sh

# 根据提示安装缺失软件
# 例如: sudo apt install openjdk-17-jdk maven nodejs npm
```

### 编译失败
```bash
# 查看详细错误
./scripts/build.sh 2>&1 | tee build.log

# 常见问题:
# - Java 版本过低 → 安装 JDK 17+
# - Maven 依赖下载失败 → 配置镜像源
# - npm 安装失败 → 清理 node_modules 重试
```

### 部署失败
```bash
# 检查端口占用
netstat -tlnp | grep -E "8080|8090|7977"

# 查看服务日志
tail -f /tmp/primihub-*.log

# 手动停止冲突进程
./scripts/stop.sh --force
```

### 测试失败
```bash
# 查看测试日志
ls -l /tmp/primihub-test-results/

# 单独测试某个功能
cd /path/to/primihub
./primihub-cli --task_config_file=example/psi_ecdh_task_conf.json
```

---

## ⚙️ 配置

### 自定义 primihub 目录
```bash
./scripts/deploy.sh --primihub-dir /custom/path/to/primihub
./scripts/test.sh --primihub-dir /custom/path/to/primihub
```

### 环境变量
```bash
# 设置 Java Home
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# 设置 Node 版本
export NODE_OPTIONS="--max_old_space_size=4096"
```

---

## 📖 相关文档

- [快速参考](../QUICKREF.md) - 一页纸速查
- [部署指南](../DEPLOYMENT.md) - 详细部署步骤
- [故障排查](../TROUBLESHOOTING.md) - 问题解决方案
- [Python配置](../../primihub/python/SETUP.md) - Python环境配置

---

## 🆘 获取帮助

所有脚本都支持 `-h` 或 `--help` 参数查看详细帮助:

```bash
./scripts/install.sh --help
./scripts/build.sh --help
./scripts/test.sh --help
```

---

## 📋 脚本维护

### 添加新脚本
1. 创建脚本文件
2. 添加脚本头部说明
3. 实现主要功能
4. 添加错误处理
5. 更新本 README

### 脚本规范
- ✅ 使用 `set -e` 错误即退出
- ✅ 提供 `--help` 帮助信息
- ✅ 使用颜色输出增强可读性
- ✅ 记录详细日志
- ✅ 提供错误处理和恢复机制

---

**脚本版本**: v1.0
**最后更新**: 2026-01-02
**维护者**: PrimiHub Team
