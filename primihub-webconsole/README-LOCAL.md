# PrimiHub WebConsole 本地开发环境

本文档介绍如何使用本地编译和启动脚本来运行 PrimiHub WebConsole 项目。

## 脚本说明

我们提供了本地启动脚本：

- `start-local.sh` - Shell 脚本 (适用于 Linux/macOS)

## 系统要求

- Node.js >= 8.9
- npm >= 3.0.0

## 快速开始

```bash
# 进入项目目录
cd primihub-webconsole

# 启动开发服务器 (默认命令)
./start-local.sh

# 或者明确指定命令
./start-local.sh dev
```

## 可用命令

### 开发相关

| 命令 | 描述 | 示例 |
|------|------|------|
| `dev` | 启动开发服务器 (默认) | `./start-local.sh dev` |
| `install` | 仅安装依赖 | `./start-local.sh install` |
| `lint` | 运行代码检查 | `./start-local.sh lint` |

### 构建相关

| 命令 | 描述 | 示例 |
|------|------|------|
| `build` | 构建生产版本 | `./start-local.sh build` |
| `build:stage` | 构建预发布版本 | `./start-local.sh build:stage` |
| `preview` | 预览构建结果 | `./start-local.sh preview` |

### 帮助

| 命令 | 描述 | 示例 |
|------|------|------|
| `help` | 显示帮助信息 | `./start-local.sh help` |

## 详细使用说明

### 1. 启动开发服务器

```bash
# 启动开发服务器，自动检查依赖并安装
./start-local.sh dev
```

开发服务器将在 `http://localhost:8080` 启动，支持热重载。

### 2. 构建项目

```bash
# 构建生产版本
./start-local.sh build

# 构建预发布版本
./start-local.sh build:stage
```

构建输出将保存在 `dist` 目录中。

### 3. 预览构建结果

```bash
# 预览构建结果
./start-local.sh preview
```

这将在 `http://localhost:8080` 启动一个静态文件服务器来预览构建结果。

### 4. 仅安装依赖

```bash
# 仅安装项目依赖
./start-local.sh install
```

### 5. 代码检查

```bash
# 运行 ESLint 代码检查
./start-local.sh lint
```

## 环境配置

### 端口配置

默认端口为 `8080`，可以通过环境变量修改：

```bash
export PORT=3000
./start-local.sh dev
```

### 代理配置

开发服务器的代理配置在 `vue.config.js` 中定义，默认指向测试环境 API。

## 故障排除

### 1. 权限问题

```bash
# 如果脚本没有执行权限
chmod +x start-local.sh
```

### 2. Node.js 版本问题

确保 Node.js 版本 >= 8.9：

```bash
node --version
```

### 3. 依赖安装失败

```bash
# 清除缓存并重新安装
rm -rf node_modules package-lock.json
./start-local.sh install
```

### 4. 端口被占用

```bash
# 使用其他端口
PORT=3000 ./start-local.sh dev
```

## 开发建议

1. **开发环境**: 使用 `dev` 命令启动开发服务器，支持热重载
2. **代码质量**: 在提交前运行 `lint` 命令检查代码规范
3. **构建测试**: 在部署前使用 `build` 和 `preview` 命令测试构建结果
4. **依赖管理**: 使用 `install` 命令确保依赖正确安装

## 相关文件

- `package.json` - 项目配置和依赖
- `vue.config.js` - Vue CLI 配置
- `start-local.sh` - 启动脚本

## 技术支持

如有问题，请联系 PrimiHub 前端团队。
