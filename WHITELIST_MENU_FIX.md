# 白名单菜单调整为一级菜单

## 问题描述

"系统设置"菜单不展示，原因是白名单管理的权限配置存在结构性问题：

- `auth_id=101` (白名单管理) 的 `auth_type=1`（一级菜单类型）
- 但 `p_auth_id=7`（父级指向系统设置）
- 这导致它既是一级菜单又是系统设置的子菜单，结构混乱

## 解决方案

将白名单管理调整为独立的一级菜单，与"系统设置"平级。

## 修改内容

### 1. 数据库权限配置修改

#### data-h2.sql (简化版H2数据库)

**修改前**:
```sql
(101, '白名单管理', 'WhitelistManage', 1, 7, 7, '7.101', '', 'own', 100, 1, 1, 1, 0),
(102, '白名单列表', 'WhitelistList', 2, 101, 7, '7.101.102', '', 'own', 1, 2, 1, 1, 0),
(103, '新增白名单', 'WhitelistAdd', 3, 101, 7, '7.101.103', '', 'own', 2, 2, 1, 1, 0),
(104, '编辑白名单', 'WhitelistEdit', 3, 101, 7, '7.101.104', '', 'own', 3, 2, 1, 1, 0),
(105, '删除白名单', 'WhitelistDelete', 3, 101, 7, '7.101.105', '', 'own', 4, 2, 1, 1, 0);
```

**修改后**:
```sql
(101, '白名单管理', 'WhitelistManage', 1, 0, 101, '101', '', 'own', 9, 0, 1, 1, 0),
(102, '白名单列表', 'WhitelistList', 2, 101, 101, '101,102', '/whitelist/findWhitelistPage', 'own', 1, 1, 1, 1, 0),
(103, '新增白名单', 'WhitelistAdd', 3, 101, 101, '101,102,103', '/whitelist/saveOrUpdateWhitelist', 'own', 2, 2, 1, 1, 0),
(104, '编辑白名单', 'WhitelistEdit', 3, 101, 101, '101,102,104', '/whitelist/saveOrUpdateWhitelist', 'own', 3, 2, 1, 1, 0),
(105, '删除白名单', 'WhitelistDelete', 3, 101, 101, '101,102,105', '/whitelist/deleteWhitelist', 'own', 4, 2, 1, 1, 0);
```

**关键变化**:
- `p_auth_id`: 7 → 0 (父级从"系统设置"改为顶级)
- `r_auth_id`: 7 → 101 (根权限ID改为自身)
- `full_path`: '7.101' → '101' (路径不再包含系统设置)
- `auth_index`: 100 → 9 (菜单排序调整到第9位)
- `auth_depth`: 1 → 0 (深度从二级改为一级)
- 添加了 `auth_url` 字段，指向实际的API路径

#### data-mysql.sql 和 data-complete-h2.sql (完整版数据库)

**修改前**:
```sql
(1030, '白名单管理', 'WhitelistManage', 2, 1029, 1029, '1029,1030', '/setting/whitelist', 'own', 4, 1, 1, 1, 0),
(1031, '白名单列表', 'WhitelistList', 3, 1030, 1030, '1029,1030,1031', '/whitelist/findWhitelistPage', 'own', 1, 2, 1, 1, 0),
(1032, '新增白名单', 'WhitelistCreate', 3, 1030, 1030, '1029,1030,1032', '/whitelist/saveOrUpdateWhitelist', 'own', 2, 2, 1, 1, 0),
(1033, '删除白名单', 'WhitelistDelete', 3, 1030, 1030, '1029,1030,1033', '/whitelist/deleteWhitelist', 'own', 3, 2, 1, 1, 0);
```

**修改后**:
```sql
(1030, '白名单管理', 'WhitelistManage', 1, 0, 1030, '1030', '', 'own', 8, 0, 1, 1, 0),
(1031, '白名单列表', 'WhitelistList', 2, 1030, 1030, '1030,1031', '/whitelist/findWhitelistPage', 'own', 1, 1, 1, 1, 0),
(1032, '新增白名单', 'WhitelistCreate', 3, 1030, 1030, '1030,1031,1032', '/whitelist/saveOrUpdateWhitelist', 'own', 2, 2, 1, 1, 0),
(1033, '删除白名单', 'WhitelistDelete', 3, 1030, 1030, '1030,1031,1033', '/whitelist/deleteWhitelist', 'own', 3, 2, 1, 1, 0);
```

**关键变化**:
- `auth_type`: 2 → 1 (从二级页面改为一级菜单)
- `p_auth_id`: 1029 → 0 (父级从"系统设置"改为顶级)
- `r_auth_id`: 1029 → 1030 (根权限ID改为自身)
- `full_path`: '1029,1030' → '1030' (路径不再包含系统设置)
- `auth_url`: '/setting/whitelist' → '' (一级菜单不需要URL)
- `auth_index`: 4 → 8 (菜单排序调整到第8位)
- `auth_depth`: 1 → 0 (深度从二级改为一级)
- 子权限的 `auth_type`: 3 → 2 (白名单列表从按钮改为页面)

### 2. 前端路由配置修改

**文件**: `primihub-webconsole/src/router/index.js`

**修改前**:
```javascript
{
  path: '/setting',
  component: Layout,
  name: 'Setting',
  redirect: '/setting/user',
  meta: { title: '系统设置', icon: 'el-icon-s-tools' },
  children: [
    {
      path: 'user',
      name: 'UserManage',
      component: () => import('@/views/setting/user'),
      meta: { title: '用户管理' }
    },
    {
      path: 'role',
      name: 'RoleManage',
      component: () => import('@/views/setting/role'),
      meta: { title: '角色管理' }
    },
    {
      path: 'center',
      name: 'CenterManage',
      component: () => import('@/views/setting/center'),
      meta: { title: '节点管理' }
    },
    {
      path: 'whitelist',
      name: 'WhitelistManage',
      component: () => import('@/views/setting/whitelist'),
      meta: { title: '白名单管理' }
    }
  ]
}
```

**修改后**:
```javascript
{
  path: '/setting',
  component: Layout,
  name: 'Setting',
  redirect: '/setting/user',
  meta: { title: '系统设置', icon: 'el-icon-s-tools' },
  children: [
    {
      path: 'user',
      name: 'UserManage',
      component: () => import('@/views/setting/user'),
      meta: { title: '用户管理' }
    },
    {
      path: 'role',
      name: 'RoleManage',
      component: () => import('@/views/setting/role'),
      meta: { title: '角色管理' }
    },
    {
      path: 'center',
      name: 'CenterManage',
      component: () => import('@/views/setting/center'),
      meta: { title: '节点管理' }
    }
  ]
},
{
  path: '/whitelist',
  component: Layout,
  name: 'WhitelistManage',
  redirect: '/whitelist/list',
  meta: { title: '白名单管理', icon: 'el-icon-user' },
  children: [{
    path: 'list',
    name: 'WhitelistList',
    component: () => import('@/views/setting/whitelist'),
    meta: { title: '白名单管理', breadcrumb: false }
  }]
}
```

**关键变化**:
- 将白名单从"系统设置"的 children 中移除
- 创建独立的一级路由 `/whitelist`
- 使用 `el-icon-user` 图标
- 保持组件路径不变 (`@/views/setting/whitelist`)

## 修改后的菜单结构

```
一级菜单列表:
├── 1. 隐匿查询 (PrivateSearch)
├── 2. 隐私求交 (PSI)
├── 3. 项目管理 (Project)
├── 4. 模型管理 (Model)
├── 5. 服务管理 (ModelReasoning)
├── 6. 资源管理 (ResourceMenu)
├── 7. 系统设置 (Setting)
│   ├── 用户管理 (UserManage)
│   ├── 角色管理 (RoleManage)
│   └── 节点管理 (CenterManage)
├── 8. 日志管理 (Log)
└── 9. 白名单管理 (WhitelistManage) ← 新增独立一级菜单
    └── 白名单列表 (WhitelistList)
```

## 权限ID映射

### 简化版 (H2)
- 101: 白名单管理 (一级菜单)
- 102: 白名单列表 (二级页面)
- 103: 新增白名单 (按钮)
- 104: 编辑白名单 (按钮)
- 105: 删除白名单 (按钮)

### 完整版 (MySQL/H2)
- 1030: 白名单管理 (一级菜单)
- 1031: 白名单列表 (二级页面)
- 1032: 新增白名单 (按钮)
- 1033: 删除白名单 (按钮)

## 验证步骤

1. **重新初始化数据库**
   ```bash
   # 删除现有数据库文件（H2模式）
   rm -rf primihub-service/application/db/

   # 或清空MySQL数据库
   mysql -u root -p primihub < schema-mysql.sql
   mysql -u root -p primihub < data-mysql.sql
   ```

2. **重启后端服务**
   ```bash
   cd primihub-service/application
   ./start-simple.sh
   ```

3. **清除前端缓存**
   - 清除浏览器 LocalStorage 中的 `primihubPer` 键
   - 清除 Cookie 中的 token

4. **重新登录验证**
   - 使用 admin/admin 登录
   - 检查菜单栏是否显示"系统设置"和"白名单管理"两个独立菜单
   - 验证"系统设置"下只有3个子菜单（用户、角色、节点）
   - 验证"白名单管理"可以正常访问

## 影响范围

- ✅ 数据库权限表结构
- ✅ 前端路由配置
- ✅ 菜单显示逻辑
- ⚠️ 可能需要更新相关文档和用户手册

## 注意事项

1. 此修改需要重新初始化数据库才能生效
2. 已有系统需要执行数据库迁移脚本
3. 白名单页面组件路径保持不变，无需修改业务代码
4. 权限验证逻辑自动适配新的权限结构

## 日期

2026-01-05
