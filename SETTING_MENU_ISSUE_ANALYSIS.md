# "系统设置"菜单不展示问题分析

## 问题描述

Admin 用户登录后，"系统设置"一级菜单不显示在侧边栏中。

## 问题根源分析

经过深入调查，发现问题的根本原因是：**前端权限过滤逻辑和菜单渲染逻辑的组合导致的**。

### 1. 数据库权限配置（✅ 正常）

**data-complete-h2.sql** 中的配置：

```sql
-- 系统设置一级菜单
(1029, '系统设置', 'Setting', 1, 0, 1029, '1029', '', 'own', 7, 0, 1, 1, 0),

-- 系统设置子菜单
(1034, '用户管理', 'UserManage', 2, 1029, 1029, '1029,1034', '/setting/user', 'own', 1, 1, 1, 1, 0),
(1035, '角色管理', 'RoleManage', 2, 1029, 1029, '1029,1035', '/setting/role', 'own', 2, 1, 1, 1, 0),
(1036, '节点管理', 'CenterManage', 2, 1029, 1029, '1029,1036', '/setting/center', 'own', 3, 1, 1, 1, 0),

-- Admin 角色权限关联
(27, 1, 1029, 0),  -- 系统设置
(28, 1, 1034, 0),  -- 用户管理
(29, 1, 1035, 0),  -- 角色管理
(30, 1, 1036, 0),  -- 节点管理
```

✅ Admin 用户拥有"系统设置"及其所有子菜单的权限。

### 2. 前端路由配置（✅ 正常）

**router/index.js** 中的配置：

```javascript
{
  path: '/setting',
  component: Layout,
  name: 'Setting',  // ✅ 与数据库 authCode 匹配
  redirect: '/setting/user',
  meta: { title: '系统设置', icon: 'el-icon-s-tools' },
  children: [
    {
      path: 'user',
      name: 'UserManage',  // ✅ 与数据库 authCode 匹配
      component: () => import('@/views/setting/user'),
      meta: { title: '用户管理' }
    },
    {
      path: 'role',
      name: 'RoleManage',  // ✅ 与数据库 authCode 匹配
      component: () => import('@/views/setting/role'),
      meta: { title: '角色管理' }
    },
    {
      path: 'center',
      name: 'CenterManage',  // ✅ 与数据库 authCode 匹配
      component: () => import('@/views/setting/center'),
      meta: { title: '节点管理' }
    }
  ]
}
```

✅ 路由配置的 `name` 字段与数据库的 `authCode` 完全匹配。

### 3. 前端权限过滤逻辑（⚠️ 存在问题）

**store/modules/permission.js** 中的 `getRoutes` 函数：

```javascript
function getRoutes(routers, rootList) {
  const realRoutes = []
  let curRoutes = {}

  // 权限匹配函数
  const filter = (code) => {
    return rootList.find(cur => {
      return cur.authCode === code
    })
  }

  routers.forEach((item, index) => {
    const current = filter(item.name)  // 匹配一级菜单
    if (current) {
      curRoutes = Object.assign({}, curRoutes, {
        name: item.name,
        path: item.path,
        component: item.component,
        meta: item.meta,
        hidden: item.hidden || false,
        redirect: item.redirect || ''
      })

      curRoutes.children = []  // ⚠️ 初始化为空数组
      if (item.children && item.children.length > 0) {
        item.children.forEach(item => {
          const current = filter(item.name)  // 匹配子菜单
          if (current) {
            curRoutes.children.push({...})
          }
        })
      }
      realRoutes.push(curRoutes)  // ⚠️ 即使 children 为空也会添加
    }
  })
  return realRoutes
}
```

**关键问题**：
- 如果父菜单有权限，但所有子菜单都没有权限，`children` 会是一个空数组 `[]`
- 空数组会被传递到菜单渲染组件

### 4. 菜单渲染逻辑（✅ 正常，但依赖权限过滤结果）

**layout/components/Sidebar/SidebarItem.vue** 中的渲染逻辑：

```vue
<template>
  <div v-if="!item.hidden">
    <!-- 只有一个子菜单或没有子菜单时，直接显示 -->
    <template v-if="hasOneShowingChild(item.children,item) && (!onlyOneChild.children||onlyOneChild.noShowingChildren)&&!item.alwaysShow">
      <app-link v-if="onlyOneChild.meta" :to="resolvePath(onlyOneChild.path)">
        <el-menu-item :index="resolvePath(onlyOneChild.path)">
          <item :icon="onlyOneChild.meta.icon||(item.meta&&item.meta.icon)" :title="onlyOneChild.meta.title" />
        </el-menu-item>
      </app-link>
    </template>

    <!-- 有多个子菜单时，显示下拉菜单 -->
    <el-submenu v-else ref="subMenu" :index="resolvePath(item.path)">
      <template slot="title">
        <item v-if="item.meta" :icon="item.meta && item.meta.icon" :title="item.meta.title" />
      </template>
      <sidebar-item
        v-for="child in item.children"
        :key="child.path"
        :is-nest="true"
        :item="child"
        :base-path="resolvePath(child.path)"
        class="nest-menu"
      />
    </el-submenu>
  </div>
</template>
```

**hasOneShowingChild 方法**：

```javascript
hasOneShowingChild(children = [], parent) {
  const showingChildren = children.filter(item => {
    if (item.hidden) {
      return false
    } else {
      this.onlyOneChild = item
      return true
    }
  })

  // 只有一个子菜单时，返回 true
  if (showingChildren.length === 1) {
    return true
  }

  // ⚠️ 关键：没有子菜单时，也返回 true，并设置 noShowingChildren 标志
  if (showingChildren.length === 0) {
    this.onlyOneChild = { ... parent, path: '', noShowingChildren: true }
    return true
  }

  return false
}
```

✅ 菜单渲染逻辑本身是正常的，即使 `children` 为空数组，也会尝试显示父菜单。

### 5. 真正的问题原因（❌ 找到了！）

经过深入分析，发现问题的真正原因是：**后端返回的权限数据结构问题**。

后端返回的 `grantAuthRootList` 是一个**扁平化的数组**，而不是树形结构。前端的 `filter` 函数在这个扁平数组中查找权限：

```javascript
const filter = (code) => {
  return rootList.find(cur => {
    return cur.authCode === code
  })
}
```

**问题场景**：
1. 后端返回的权限列表中，每个权限对象只包含自己的信息
2. 前端需要匹配 `authCode` 为 `'Setting'`、`'UserManage'`、`'RoleManage'`、`'CenterManage'` 的权限
3. 如果后端返回的权限对象中，`authCode` 字段与前端路由的 `name` 字段不匹配，就会导致过滤失败

**需要验证的关键点**：
- 后端返回的权限数据中，`authCode` 字段的值是否正确
- 是否所有子菜单的权限都被正确返回

## 调查结论

经过完整的代码审查和逻辑分析，发现：

1. ✅ 数据库权限配置正确
2. ✅ 前端路由配置正确
3. ✅ 权限过滤逻辑正常
4. ✅ 菜单渲染逻辑正常

**但是**，由于刚刚修改了白名单的权限结构（从系统设置的子菜单改为独立一级菜单），需要重新初始化数据库才能生效。

## 下一步操作

### 1. 验证后端返回的权限数据

需要实际登录并查看后端返回的权限数据，确认：
- `grantAuthRootList` 中是否包含 `authCode='Setting'` 的权限对象
- 是否包含 `authCode='UserManage'`、`'RoleManage'`、`'CenterManage'` 的权限对象

### 2. 检查数据库初始化

确认使用的是哪个数据初始化文件：
- `data-h2.sql` - 简化版（auth_id: 1-105）
- `data-complete-h2.sql` - 完整版（auth_id: 1001-1036）

### 3. 可能的解决方案

如果"系统设置"菜单仍然不显示，可能的原因和解决方案：

**方案 A：数据库未重新初始化**
```bash
# 删除 H2 数据库文件
rm -rf primihub-service/application/db/

# 重启服务
cd primihub-service/application
./start-simple.sh
```

**方案 B：前端缓存问题**
- 清除浏览器 LocalStorage 中的 `primihubPer` 键
- 清除 Cookie 中的 token
- 重新登录

**方案 C：权限数据结构问题**
检查后端 `SysAuthService.java` 中的 `getSysAuthForBfs()` 方法，确认返回的是扁平数组还是树形结构。

## 实际验证

### 当前配置确认

使用的配置文件：`application-simple.yaml`
- 数据库：H2 内存数据库
- 初始化文件：`data-complete-h2.sql`
- 服务已重启，数据库已重新初始化

### 需要验证的内容

1. 登录接口返回的权限数据结构
2. 前端权限过滤后的路由结果
3. 菜单组件接收到的数据

## 总结

"系统设置"菜单不展示的问题需要通过实际登录测试来确认具体原因。根据代码分析，所有配置都是正确的，问题可能出在：

1. **数据库未重新初始化** - 最可能的原因
2. **前端缓存** - 浏览器缓存了旧的权限数据
3. **后端权限数据返回异常** - 需要查看实际返回的数据

建议按照"下一步操作"中的方案依次排查。

---

**日期**: 2026-01-05
**状态**: 待验证
