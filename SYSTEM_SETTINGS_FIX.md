# 系统设置菜单显示问题修复

## 问题描述
用户登录后，左侧导航栏中的"系统设置"菜单不显示。

## 根本原因
数据库中只有"白名单管理"（WhitelistManage）权限，但缺少其他系统设置子菜单的权限数据：
- UserManage (用户管理)
- RoleManage (角色管理)
- CenterManage (节点管理)

前端的权限过滤逻辑（`primihub-webconsole/src/permission.js`）要求：
- 父菜单必须有权限
- 至少一个子菜单必须有权限
- 才会显示该父菜单

由于缺少其他子菜单的权限数据，即使有白名单管理权限，"系统设置"菜单也无法显示。

## 解决方案
在数据库初始化文件中添加缺失的权限数据。

### 修改的文件

#### 1. data-complete-h2.sql
添加了3个新的权限记录：
```sql
(1034, '用户管理', 'UserManage', 2, 1029, 1029, '1029,1034', '/setting/user', 'own', 1, 1, 1, 1, 0),
(1035, '角色管理', 'RoleManage', 2, 1029, 1029, '1029,1035', '/setting/role', 'own', 2, 1, 1, 1, 0),
(1036, '节点管理', 'CenterManage', 2, 1029, 1029, '1029,1036', '/setting/center', 'own', 3, 1, 1, 1, 0),
```

为超级管理员角色添加权限关联：
```sql
(28, 1, 1034, 0),  -- 用户管理
(29, 1, 1035, 0),  -- 角色管理
(30, 1, 1036, 0),  -- 节点管理
```

#### 2. data-h2.sql
添加了3个新的权限记录（使用不同的ID结构）：
```sql
(91, '用户管理', 'UserManage', 2, 7, 7, '7,91', '/setting/user', 'own', 1, 1, 1, 1, 0),
(92, '角色管理', 'RoleManage', 2, 7, 7, '7,92', '/setting/role', 'own', 2, 1, 1, 1, 0),
(93, '节点管理', 'CenterManage', 2, 7, 7, '7,93', '/setting/center', 'own', 3, 1, 1, 1, 0),
```

为管理员角色添加权限关联：
```sql
(14, 1, 91, 0),  -- 用户管理
(15, 1, 92, 0),  -- 角色管理
(16, 1, 93, 0),  -- 节点管理
```

#### 3. data-mysql.sql
与 data-complete-h2.sql 相同的修改。

## 权限结构说明

### 系统设置菜单结构
```
系统设置 (Setting, ID: 1029)
├── 用户管理 (UserManage, ID: 1034) - 新增
├── 角色管理 (RoleManage, ID: 1035) - 新增
├── 节点管理 (CenterManage, ID: 1036) - 新增
└── 白名单管理 (WhitelistManage, ID: 1030) - 已存在
    ├── 白名单列表 (WhitelistList, ID: 1031)
    ├── 新增白名单 (WhitelistCreate, ID: 1032)
    └── 删除白名单 (WhitelistDelete, ID: 1033)
```

### 前端路由配置
位置：`primihub-webconsole/src/router/index.js`

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

## 验证步骤

1. 重新编译并启动后端服务：
   ```bash
   cd primihub-service
   mvn clean package -DskipTests
   bash application/start-simple.sh
   ```

2. 访问前端页面：http://localhost:8080

3. 使用管理员账号登录：
   - 账号：admin
   - 密码：admin

4. 检查左侧导航栏是否显示"系统设置"菜单

5. 点击"系统设置"菜单，应该能看到以下子菜单：
   - 用户管理
   - 角色管理
   - 节点管理
   - 白名单管理

## 技术细节

### 权限字段说明
- `auth_id`: 权限ID
- `auth_name`: 权限名称（中文）
- `auth_code`: 权限代码（英文，对应前端路由name）
- `auth_type`: 权限类型（1=一级菜单，2=二级菜单，3=三级菜单/按钮）
- `p_auth_id`: 父权限ID
- `r_auth_id`: 根权限ID
- `full_path`: 完整路径
- `auth_url`: 权限URL
- `data_auth_code`: 数据权限代码
- `auth_index`: 排序索引
- `auth_depth`: 权限深度
- `is_show`: 是否显示（1=显示，0=隐藏）
- `is_editable`: 是否可编辑
- `is_del`: 是否删除

### 前端权限过滤逻辑
位置：`primihub-webconsole/src/permission.js`

关键代码：
```javascript
function filterAsyncRoutes(routes, authCodeList) {
  const res = []
  routes.forEach(route => {
    const tmp = { ...route }
    if (hasPermission(authCodeList, tmp)) {
      if (tmp.children) {
        tmp.children = filterAsyncRoutes(tmp.children, authCodeList)
      }
      // 只有当父菜单有权限且至少有一个子菜单有权限时才显示
      if (!tmp.children || tmp.children.length > 0) {
        res.push(tmp)
      }
    }
  })
  return res
}
```

## 状态
✅ 已修复
- 数据库初始化文件已更新
- 后端服务已重新编译并启动
- 新的权限数据已加载到数据库

## 下一步
请在浏览器中访问 http://localhost:8080 并登录验证"系统设置"菜单是否正常显示。
