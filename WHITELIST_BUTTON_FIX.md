# 白名单按钮权限修复指南

## 问题描述

白名单列表页面缺少"新增白名单"、"编辑"、"删除"等操作按钮。

## 原因分析

白名单管理模块的权限配置不完整：
- ✅ 已有菜单权限：Whitelist（一级菜单）、WhitelistList、WhitelistConfig、WhitelistAccessLog（二级菜单）
- ❌ 缺少按钮权限：WhitelistAdd、WhitelistEdit、WhitelistDelete 等

前端组件通过权限代码控制按钮显示：
```vue
<el-button v-if="hasAddPermission" type="primary" icon="el-icon-plus" @click="addWhitelist">新增白名单</el-button>
```

当用户没有 `WhitelistAdd` 权限时，按钮会被隐藏。

## 解决方案

### 方法一：执行补充权限SQL脚本（推荐）

已创建补充权限脚本：`primihub-service/script/whitelist_button_permissions.sql`

该脚本会添加以下按钮权限：

**白名单列表按钮：**
- WhitelistAdd - 添加白名单
- WhitelistEdit - 编辑白名单
- WhitelistDelete - 删除白名单

**白名单配置按钮：**
- WhitelistConfigAdd - 添加配置
- WhitelistConfigEdit - 编辑配置
- WhitelistConfigDelete - 删除配置

**访问日志按钮：**
- WhitelistLogClean - 清理日志
- WhitelistLogExport - 导出日志

### 执行步骤

#### 1. 复制SQL文件到MySQL容器
```bash
docker cp primihub-service/script/whitelist_button_permissions.sql mysql:/tmp/
```

#### 2. 在3个数据库中执行脚本
```bash
for db in privacy1 privacy2 privacy3; do
  echo "=== 数据库: $db ==="
  docker exec mysql mysql -uroot -proot $db -e "source /tmp/whitelist_button_permissions.sql"
done
```

或者分别执行：
```bash
docker exec mysql mysql -uroot -proot privacy1 < primihub-service/script/whitelist_button_permissions.sql
docker exec mysql mysql -uroot -proot privacy2 < primihub-service/script/whitelist_button_permissions.sql
docker exec mysql mysql -uroot -proot privacy3 < primihub-service/script/whitelist_button_permissions.sql
```

#### 3. 验证权限配置

```bash
docker exec mysql mysql -uroot -proot privacy1 -e "
SELECT
    a.auth_code,
    a.auth_name,
    a.auth_type,
    COUNT(ra.id) as assigned_to_admin
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE a.auth_code LIKE 'Whitelist%'
AND a.is_del = 0
GROUP BY a.auth_code, a.auth_name, a.auth_type
ORDER BY a.auth_type, a.auth_code;
"
```

应该看到类似这样的输出：
```
+------------------------+------------------+-----------+-------------------+
| auth_code              | auth_name        | auth_type | assigned_to_admin |
+------------------------+------------------+-----------+-------------------+
| Whitelist              | 白名单管理       | 1         | 1                 |
| WhitelistAccessLog     | 访问日志记录     | 2         | 1                 |
| WhitelistConfig        | 白名单配置       | 2         | 1                 |
| WhitelistList          | 白名单列表       | 2         | 1                 |
| WhitelistAdd           | 添加白名单       | 3         | 1                 |
| WhitelistEdit          | 编辑白名单       | 3         | 1                 |
| WhitelistDelete        | 删除白名单       | 3         | 1                 |
| WhitelistConfigAdd     | 添加配置         | 3         | 1                 |
| WhitelistConfigEdit    | 编辑配置         | 3         | 1                 |
| WhitelistConfigDelete  | 删除配置         | 3         | 1                 |
| WhitelistLogClean      | 清理日志         | 3         | 1                 |
| WhitelistLogExport     | 导出日志         | 3         | 1                 |
+------------------------+------------------+-----------+-------------------+
```

其中：
- `auth_type = 1`: 一级菜单
- `auth_type = 2`: 二级菜单
- `auth_type = 3`: 按钮权限

#### 4. 清除Redis缓存（如果使用了缓存）

```bash
# 清除权限相关的缓存
docker exec redis redis-cli -a primihub KEYS "*permission*" | xargs -I {} docker exec redis redis-cli -a primihub DEL {}
docker exec redis redis-cli -a primihub KEYS "*auth*" | xargs -I {} docker exec redis redis-cli -a primihub DEL {}
```

#### 5. 重新登录系统

退出当前登录，重新登录系统，权限会重新加载。

### 方法二：在系统中手动配置权限（不推荐）

如果无法执行SQL脚本，可以在系统的"角色管理"中手动为角色分配权限：

1. 登录系统
2. 进入"系统设置" → "角色管理"
3. 编辑超级管理员角色
4. 在权限树中找到"白名单管理"节点
5. 勾选所有子权限（包括按钮权限）
6. 保存

**注意**：此方法需要先执行SQL脚本创建按钮权限记录，否则权限树中不会显示这些权限。

## 验证修复结果

1. **重新登录系统**

2. **进入白名单列表页面**
   - 系统设置 → 白名单管理 → 白名单列表

3. **检查按钮是否显示**
   - 应该能看到"新增白名单"按钮（蓝色，右上角）
   - 表格每行应该有"编辑"和"删除"按钮

4. **测试功能**
   - 点击"新增白名单"，应该弹出添加对话框
   - 点击"编辑"，应该弹出编辑对话框
   - 点击"删除"，应该弹出删除确认对话框

## 常见问题

### Q1: 执行SQL后仍然看不到按钮？

**A**: 请尝试以下步骤：
1. 清除浏览器缓存
2. 清除Redis缓存（参考步骤4）
3. 重新登录系统
4. 检查数据库中权限是否真的插入成功（参考步骤3的验证命令）

### Q2: 其他角色用户看不到按钮？

**A**: 需要为其他角色也分配相应的按钮权限：

```sql
-- 为指定角色分配白名单按钮权限（替换YOUR_ROLE_ID）
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT YOUR_ROLE_ID, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('WhitelistAdd', 'WhitelistEdit', 'WhitelistDelete')
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = YOUR_ROLE_ID
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);
```

或在系统的"角色管理"中手动为该角色分配权限。

### Q3: 按钮显示了但点击没反应？

**A**: 可能是API接口权限或Gateway路由问题：
1. 检查Gateway日志：`docker logs -f gateway0`
2. 检查Application日志：`docker logs -f application0`
3. 检查浏览器控制台是否有报错
4. 确认API接口路径是否正确

### Q4: 想要移除某个按钮权限？

**A**: 可以不删除权限记录，只需在角色管理中取消勾选该权限即可。

如果要完全删除权限记录：
```sql
-- 删除指定按钮权限
UPDATE sys_auth SET is_del = 1 WHERE auth_code = 'WhitelistAdd';
```

## 其他模块的按钮权限

如果发现其他模块也有类似问题（比如租户管理、存证管理等），可以参考本脚本的模式创建相应的补充权限脚本：

```sql
-- 获取父菜单ID
SELECT auth_id INTO @parent_id FROM sys_auth WHERE auth_code = 'ParentMenuCode' AND is_del = 0;

-- 插入按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, ...)
VALUES
('按钮名称', 'ButtonCode', 3, @parent_id, @parent_id, '/path', '/api/path', ...);

-- 分配给角色
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth WHERE auth_code = 'ButtonCode' ...;
```

## 总结

通过执行补充权限SQL脚本，可以快速修复白名单管理模块缺少按钮的问题。该脚本：
- ✅ 自动添加所有缺失的按钮权限
- ✅ 自动分配给超级管理员角色
- ✅ 支持幂等执行（重复执行不会出错）
- ✅ 包含验证查询，可确认执行结果

执行后记得重新登录系统以加载新的权限配置。
