# Logo和品牌文字修改总结

修改日期: 2026-02-20

## 修改概述

在管理平台前端添加了logo图片，并将所有品牌文字从"PrimiHub"和"原语科技"替换为"DataItem"和"海会科技"。

## Logo图片修改

### 1. 图片准备
- 源图片: `/mnt/data1/github/primihub-platform/haihui1.png`
- 原始尺寸: 716 x 232 像素
- 调整后尺寸: 154 x 50 像素 (保持宽高比)

### 2. 图片复制位置
```bash
# 复制到public目录供生产环境使用
/mnt/data1/github/primihub-platform/primihub-webconsole/public/images/logo-primihub.png

# 复制到src/assets目录供开发环境使用
/mnt/data1/github/primihub-platform/primihub-webconsole/src/assets/logo-primihub.png
```

## 源码修改清单

### 1. 侧边栏Logo组件 - Logo.vue

**文件**: `src/layout/components/Sidebar/Logo.vue`

**修改内容**:
- 标题从 "Vue Admin Template" 改为 "DataItem"
- Logo路径从外部URL改为本地图片 `require('@/assets/logo-primihub.png')`
- Logo样式调整为横向图片 (height: 40px, width: auto, max-width: 120px)

```vue
data() {
  return {
    title: 'DataItem',
    logo: require('@/assets/logo-primihub.png')
  }
}
```

### 2. 全局设置 - settings.js

**文件**: `src/settings.js`

**修改内容**:
- `isShowLogo`: false → true (启用顶部导航栏logo显示)
- `logoUrl`: '/images/logo1.png' → '/images/logo-primihub.png'
- `logoTitle`: '原语隐私计算平台' → 'DataItem'
- `showLogoTitle`: 新增为 true
- `footerText`: '北京原语科技有限公司 V1.5.5' → '海会科技 V1.5.5'

### 3. 路由配置 - router/index.js

**文件**: `src/router/index.js` (第64行)

**修改内容**:
```javascript
// 修改前
meta: { title: 'PrimiHub隐私计算大模型' }

// 修改后
meta: { title: 'DataItem隐私计算大模型' }
```

### 4. 导航栏组件 - Navbar.vue

**文件**: `src/layout/components/Navbar.vue` (第13行)

**修改内容**:
```vue
<!-- 修改前 -->
<el-link>PrimiHub隐私计算大模型</el-link>

<!-- 修改后 -->
<el-link>DataItem隐私计算大模型</el-link>
```

### 5. 系统设置 - system.vue

**文件**: `src/views/setting/system.vue` (第399-402行)

**修改内容**:
```javascript
personalizationConfig: {
  platformName: 'DataItem隐私计算平台',      // 原: PrimiHub隐私计算平台
  platformShortName: 'DataItem',             // 原: PrimiHub
  platformDescription: '基于隐私保护的分布式计算平台',
  copyright: 'Copyright © 2026 海会科技. All rights reserved.',  // 原: PrimiHub
}
```

### 6. 公司介绍组件 - CompanyIntro/index.vue

**文件**: `src/components/CompanyIntro/index.vue` (第17行)

**修改内容**:
```javascript
// 修改前
return this.loginDescription !== '' ? this.loginDescription : `<p>PrimiHub是基于多方安全计算、联邦学习、同态加密等主流隐私计算技术自主研发的分布式隐私计算平台。</p>...`

// 修改后
return this.loginDescription !== '' ? this.loginDescription : `<p>DataItem是基于多方安全计算、联邦学习、同态加密等主流隐私计算技术自主研发的分布式隐私计算平台。</p>...`
```

### 7. 主布局组件 - AppMain.vue

**文件**: `src/layout/components/AppMain.vue` (第32行)

**修改内容**:
```vue
<!-- 修改前 -->
<img src="/static/img/assitant.001dc94b.png" alt="原语科技">

<!-- 修改后 -->
<img src="/static/img/assitant.001dc94b.png" alt="海会科技">
```

### 8. 反馈组件 - FadeBack.vue

**文件**: `src/layout/components/FadeBack.vue` (第10行)

**修改内容**:
```vue
<!-- 修改前 -->
<p>原语科技小助手</p>

<!-- 修改后 -->
<p>海会科技小助手</p>
```

### 9. 埋点追踪 - webTracing.js

**文件**: `src/utils/webTracing.js` (第13行)

**修改内容**:
```javascript
// 修改前
appName: '原语隐私计算平台',

// 修改后
appName: 'DataItem隐私计算平台',
```

## 构建结果

前端应用已成功构建：
- 构建时间: 2026-02-20T07:45:54.775Z
- 构建哈希: 6628c0251656dc7f
- 耗时: 39385ms
- 输出目录: `dist/`
- 构建状态: ✅ 成功

## 验证清单

部署后需要验证以下位置的logo和文字是否正确显示：

- [ ] 登录页面 - 公司介绍文字
- [ ] 侧边栏 - Logo图片和"DataItem"标题
- [ ] 顶部导航栏 - Logo图片和"DataItem"标题
- [ ] 页面标题 - "DataItem隐私计算大模型"
- [ ] 系统设置页面 - 平台名称和版权信息
- [ ] 页面底部 - "海会科技 V1.5.5"
- [ ] 联系我们二维码 - "海会科技"alt文字
- [ ] 帮助反馈 - "海会科技小助手"文字

## 部署说明

### 方式一: 使用构建好的dist目录
```bash
# dist目录可以直接部署到Web服务器
cp -r /mnt/data1/github/primihub-platform/primihub-webconsole/dist/* /path/to/web/root/
```

### 方式二: 重新构建Docker镜像
```bash
cd /mnt/data1/github/primihub-platform/primihub-webconsole

# 构建新的前端镜像
docker build -t primihub/web-manage:dataitem -f Dockerfile .
```

### 方式三: 更新现有容器
```bash
# 停止现有容器
docker stop manage-web0 manage-web1 manage-web2

# 复制新的dist到容器内
docker cp /mnt/data1/github/primihub-platform/primihub-webconsole/dist/. manage-web0:/usr/share/nginx/html/

# 重启容器
docker restart manage-web0 manage-web1 manage-web2
```

## 文件更改统计

- 图片文件: 2个 (public/images/, src/assets/)
- Vue组件文件: 6个
- JavaScript配置文件: 3个
- **总计修改**: 11个文件

## 注意事项

1. 所有修改已在源码中完成，确保版本控制系统中提交这些更改
2. logo图片使用的是haihui1.png，如需更换其他logo，只需替换对应位置的图片文件
3. 构建后的dist目录可直接部署，无需额外配置
4. 如果需要调整logo大小，修改Logo.vue中的CSS样式即可
