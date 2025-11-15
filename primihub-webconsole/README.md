# PrimiHub WebConsole

PrimiHub WebConsole 是 PrimiHub 隐私计算平台的前端管理控制台，基于 Vue.js 和 Element UI 构建，提供直观的图形化界面来管理和操作隐私计算任务。

## 项目概述

PrimiHub WebConsole 是一个现代化的隐私计算平台前端应用，支持多种隐私计算场景，包括隐私求交(PSI)、隐匿查询(PIR)、模型推理、资源管理等核心功能。

## 技术栈

### 核心框架
- **Vue.js 2.6.14** - 渐进式JavaScript框架
- **Vue Router 3.0.6** - 官方路由管理器
- **Vuex 3.1.0** - 状态管理模式
- **Element UI 2.15.7** - 基于Vue的组件库

### 可视化与图表
- **AntV X6 1.35.0** - 流程图和图形编辑器
- **ECharts 5.5.0** - 数据可视化图表库
- **Mapbox GL 2.15.0** - 地图可视化

### 工具库
- **Axios 1.6.8** - HTTP客户端
- **Lodash 4.17.21** - JavaScript工具库
- **Crypto-JS 4.2.0** - 加密算法库
- **JSEncrypt 3.3.2** - RSA加密

### 构建工具
- **Vue CLI 5.0.8** - Vue.js开发工具链
- **Webpack 5** - 模块打包工具
- **Babel** - JavaScript编译器
- **ESLint** - 代码质量检查

## 项目结构

```
primihub-webconsole/
├── public/                 # 静态资源
│   ├── index.html         # HTML模板
│   └── images/            # 图片资源
├── src/                   # 源代码目录
│   ├── api/               # API接口
│   │   ├── project.js     # 项目管理API
│   │   ├── PSI.js         # 隐私求交API
│   │   ├── PIR.js         # 隐匿查询API
│   │   ├── model.js       # 模型管理API
│   │   ├── resource.js    # 资源管理API
│   │   └── ...
│   ├── assets/            # 静态资源
│   ├── components/        # 公共组件
│   │   ├── Breadcrumb/    # 面包屑导航
│   │   ├── Charts/        # 图表组件
│   │   ├── ConnectTree/   # 连接树组件
│   │   ├── FlowStep/      # 流程步骤组件
│   │   ├── TaskCanvas/    # 任务画布组件
│   │   └── ...
│   ├── const/             # 常量定义
│   ├── filters/           # 过滤器
│   ├── icons/             # 图标资源
│   ├── layout/            # 布局组件
│   ├── router/            # 路由配置
│   ├── store/             # 状态管理
│   ├── styles/            # 样式文件
│   ├── utils/             # 工具函数
│   │   ├── request.js     # HTTP请求封装
│   │   ├── auth.js        # 认证工具
│   │   ├── validate.js    # 验证工具
│   │   └── ...
│   └── views/             # 页面视图
│       ├── login/         # 登录页
│       ├── project/       # 项目管理
│       ├── PSI/           # 隐私求交
│       ├── privateSearch/ # 隐匿查询
│       ├── model/         # 模型管理
│       ├── reasoning/     # 服务管理
│       ├── resource/      # 资源管理
│       ├── setting/       # 系统设置
│       └── ...
├── package.json           # 项目配置
├── vue.config.js          # Vue配置
├── Dockerfile             # Docker构建文件
└── README.md              # 项目说明
```

## 核心功能模块

### 1. 项目管理
- 项目创建与编辑
- 项目成员管理
- 项目资源分配
- 项目审批流程

### 2. 隐私求交 (PSI)
- 隐私求交任务创建
- 多方数据求交
- 任务执行监控
- 结果下载与管理

### 3. 隐匿查询 (PIR)
- 隐匿查询任务管理
- 隐私数据查询
- 查询结果保护
- 任务详情查看

### 4. 模型管理
- 机器学习模型管理
- 模型训练与部署
- 模型推理服务
- 模型版本控制

### 5. 资源管理
- 数据资源上传
- 资源权限管理
- 协作方资源
- 衍生数据资源

### 6. 系统设置
- 用户管理
- 角色权限
- 节点管理
- 界面配置

## 快速开始

### 环境要求
- Node.js >= 16.14.0
- npm >= 8.3.1

### 安装依赖
```bash
cd primihub-webconsole
npm install
```

### 开发环境配置
修改 `vue.config.js` 中的代理配置，指向您的后端服务：
```javascript
proxy: {
  '/dev-api': {
    target: 'http://your-gateway-url',
    ws: true,
    changeOrigin: true,
    pathRewrite: {
      '^/dev-api': ''
    }
  }
}
```

### 启动开发服务器
```bash
npm run dev
```
访问 http://localhost:8080

### 使用本地启动脚本
```bash
# 启动开发服务器
./start-local.sh dev

# 构建生产版本
./start-local.sh build

# 查看帮助信息
./start-local.sh help
```

## 构建部署

### 构建测试环境
```bash
npm run build:stage
```

### 构建生产环境
```bash
npm run build:prod
```

### Docker 部署
```bash
# 构建镜像
docker build -t primihub-webconsole .

# 运行容器
docker run -p 80:80 primihub-webconsole
```

## 环境配置

### 环境变量
项目支持多种环境配置：
- `.env.development` - 开发环境
- `.env.staging` - 测试环境  
- `.env.production` - 生产环境

### 应用设置
在 `src/settings.js` 中配置应用基本信息：
```javascript
module.exports = {
  title: '隐私计算平台',
  fixedHeader: true,
  sidebarLogo: true,
  logoUrl: '/images/logo1.png',
  logoTitle: '原语隐私计算平台'
}
```

## 开发指南

### 代码规范
- 使用 ESLint 进行代码检查
- 遵循 Vue.js 官方风格指南
- 使用 Prettier 格式化代码

### 组件开发
- 组件统一放在 `src/components` 目录
- 使用 PascalCase 命名组件
- 遵循单一职责原则

### API 开发
- API 接口统一放在 `src/api` 目录
- 使用统一的请求封装 `utils/request.js`
- 错误处理统一在拦截器中实现

## 浏览器支持

支持现代浏览器和 Internet Explorer 10+：

| [<img src="./src/assets/browsers-icon/edge_48x48.png" alt="IE / Edge" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>IE / Edge | [<img src="./src/assets/browsers-icon/firefox_48x48.png" alt="Firefox" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Firefox | [<img src="./src/assets/browsers-icon/chrome_48x48.png" alt="Chrome" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Chrome | [<img src="./src/assets/browsers-icon/safari_48x48.png" alt="Safari" width="24px" height="24px" />](http://godban.github.io/browsers-support-badges/)<br/>Safari |
| --------- | --------- | --------- | --------- |
| IE10, IE11, Edge| last 2 versions| last 2 versions| last 2 versions

## 故障排除

### 常见问题
1. **依赖安装失败**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **端口被占用**
   ```bash
   PORT=3000 npm run dev
   ```

3. **权限问题**
   ```bash
   chmod +x start-local.sh
   ```

### 获取帮助
- 查看详细文档：`README-LOCAL.md`
- 联系 PrimiHub 前端团队

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进项目。

## 更新日志

- **v1.0.0** - 初始版本发布
- 支持隐私求交(PSI)功能
- 支持隐匿查询(PIR)功能
- 支持模型管理和推理服务
- 完整的资源管理系统
