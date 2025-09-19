# PrimiHub Web Console

原语隐私计算平台前端控制台

## 项目介绍

PrimiHub Web Console 是基于 Vue.js 开发的隐私计算平台前端控制台，提供友好的用户界面来管理和操作隐私计算任务。该平台支持多方安全计算、联邦学习、隐私求交等隐私计算功能。

## 功能特性

- 🛡️ **隐私计算任务管理**: 支持多方安全计算、联邦学习、隐私求交等任务
- 📊 **数据资源管理**: 统一管理数据资源，支持数据预览和权限控制
- 🤝 **组织协作**: 多组织协作模式，支持组织间数据共享和计算
- 📈 **可视化建模**: 基于 antv-x6 的可视化建模界面
- 🔐 **安全认证**: 完善的用户认证和权限管理系统
- 📱 **响应式设计**: 支持多种设备和浏览器

## 技术栈

- **前端框架**: Vue.js 2.6.x
- **UI组件库**: Element UI 2.15.x
- **路由管理**: Vue Router 3.0.x
- **状态管理**: Vuex 3.1.x
- **可视化**: AntV X6 1.31.x
- **图表**: ECharts 4.2.x
- **HTTP客户端**: Axios 0.18.x
- **构建工具**: Vue CLI 4.4.x

## 环境要求

- Node.js >= 8.9
- npm >= 3.0.0
- Git

## 快速开始

### 安装依赖

```bash
# 进入项目目录
cd primihub-webconsole

# 安装依赖
npm install
```

### 开发环境运行

```bash
# 启动开发服务器
npm run dev
```

开发服务器将在 http://localhost:8080 启动，并自动打开浏览器。

### 构建部署

```bash
# 构建测试环境
npm run build:stage

# 构建生产环境
npm run build:prod
```

构建产物将输出到 `dist` 目录。

## 项目结构

```
primihub-webconsole/
├── public/                 # 静态资源
│   ├── index.html         # HTML模板
│   └── favicon.ico        # 网站图标
├── src/                   # 源代码
│   ├── api/               # API接口
│   │   ├── center.js      # 中心服务API
│   │   ├── fusionResource.js # 融合资源API
│   │   ├── model.js       # 模型API
│   │   ├── organ.js       # 组织API
│   │   ├── PIR.js         # 隐私信息检索API
│   │   ├── project.js     # 项目API
│   │   ├── PSI.js         # 隐私集合求交API
│   │   ├── resource.js    # 资源API
│   │   ├── role.js        # 角色API
│   │   ├── user.js        # 用户API
│   │   └── userAdmin.js   # 用户管理API
│   ├── assets/            # 静态资源
│   ├── components/        # 公共组件
│   ├── filters/           # 过滤器
│   ├── icons/             # SVG图标
│   ├── layout/            # 布局组件
│   ├── router/            # 路由配置
│   ├── store/             # 状态管理
│   ├── styles/            # 样式文件
│   ├── utils/             # 工具函数
│   └── views/             # 页面组件
│       ├── dag/           # 可视化建模
│       ├── login/         # 登录页面
│       ├── model/         # 模型管理
│       ├── privateSearch/ # 隐私搜索
│       ├── project/       # 项目管理
│       ├── PSI/           # 隐私集合求交
│       ├── resource/      # 资源管理
│       ├── setting/       # 系统设置
│       └── welcome/       # 欢迎页面
├── tests/                 # 测试文件
├── package.json           # 项目配置
├── vue.config.js          # Vue配置
└── README.md              # 项目说明
```

## 开发指南

### 代码规范

项目使用 ESLint 进行代码规范检查：

```bash
# 代码检查
npm run lint
```

### 单元测试

```bash
# 运行单元测试
npm run test:unit

# 运行CI测试（包含代码检查和单元测试）
npm run test:ci
```

### SVG图标优化

```bash
# 优化SVG图标
npm run svgo
```

## 配置说明

### 环境变量

项目支持多环境配置：

- `.env.development` - 开发环境配置
- `.env.staging` - 测试环境配置  
- `.env.production` - 生产环境配置

### Vue配置

主要配置在 `vue.config.js` 文件中，包括：
- 开发服务器配置
- 构建配置
- 代理配置
- Webpack配置

## 浏览器支持

支持现代浏览器和 Internet Explorer 10+。

| [<img src="./src/assets/browsers-icon/edge_48x48.png" alt="IE / Edge" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>IE / Edge | [<img src="./src/assets/browsers-icon/firefox_48x48.png" alt="Firefox" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Firefox | [<img src="./src/assets/browsers-icon/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome | [<img src="./src/assets/browsers-icon/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari |
| --------- | --------- | --------- | --------- |
| IE10, IE11, Edge| last 2 versions| last 2 versions| last 2 versions

## Docker部署

项目提供 Docker 支持，可以使用以下方式进行容器化部署：

```bash
# 构建Docker镜像
docker build -t primihub-webconsole .

# 运行容器
docker run -p 8080:80 primihub-webconsole
```

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进项目。

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [../LICENSE](../LICENSE) 文件了解详情。

## 联系方式

- 项目主页: [https://github.com/primihub/primihub-platform](https://github.com/primihub/primihub-platform)
- 问题反馈: [GitHub Issues](https://github.com/primihub/primihub-platform/issues)

## 更新日志

### v1.0.0
- 初始版本发布
- 支持基本的隐私计算功能
- 提供可视化建模界面
- 完善的组织和用户管理系统
