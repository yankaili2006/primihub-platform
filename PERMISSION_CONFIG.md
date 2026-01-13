# 新增功能权限配置说明

## 权限系统工作原理

平台采用基于 `authCode` 的权限控制系统：
- **authType = 1**: 一级菜单权限
- **authType = 2**: 二级菜单权限
- **authType = 3**: 按钮权限

前端路由的 `name` 属性需要与后端返回的 `authCode` 进行匹配，只有匹配成功的菜单才会显示。

## 新增菜单权限配置清单

### 1. 白名单管理 (Whitelist)

**一级菜单：**
- authCode: `Whitelist`
- authType: `1`
- authName: `白名单管理`

**二级菜单：**
- authCode: `WhitelistList`, authType: `2`, authName: `白名单列表`
- authCode: `WhitelistConfig`, authType: `2`, authName: `白名单配置`
- authCode: `WhitelistAccessLog`, authType: `2`, authName: `访问日志记录`

**按钮权限示例（可选）：**
- `WhitelistList:add` - 新增白名单
- `WhitelistList:edit` - 编辑白名单
- `WhitelistList:delete` - 删除白名单
- `WhitelistConfig:save` - 保存配置

---

### 2. 租户管理 (Tenant)

**一级菜单：**
- authCode: `Tenant`
- authType: `1`
- authName: `租户管理`

**二级菜单：**
- authCode: `TenantList`, authType: `2`, authName: `租户列表`
- authCode: `TenantResource`, authType: `2`, authName: `资源分配`（hidden子页面）

**按钮权限示例：**
- `TenantList:add` - 新增租户
- `TenantList:edit` - 编辑租户
- `TenantList:delete` - 删除租户
- `TenantList:freeze` - 冻结租户
- `TenantList:unfreeze` - 解冻租户
- `TenantResource:allocate` - 分配资源
- `TenantResource:remove` - 移除资源

---

### 3. 存证管理 (Evidence)

**一级菜单：**
- authCode: `Evidence`
- authType: `1`
- authName: `存证管理`

**二级菜单：**
- authCode: `EvidenceQuery`, authType: `2`, authName: `存证查询`
- authCode: `EvidenceTimestamp`, authType: `2`, authName: `时间戳管理`
- authCode: `EvidenceConfig`, authType: `2`, authName: `存证配置`
- authCode: `EvidenceExport`, authType: `2`, authName: `存证加密导出`
- authCode: `EvidenceApi`, authType: `2`, authName: `存证接口对接`

**按钮权限示例：**
- `EvidenceQuery:verify` - 验证存证
- `EvidenceQuery:download` - 下载证书
- `EvidenceTimestamp:apply` - 申请时间戳
- `EvidenceTimestamp:verify` - 验证时间戳
- `EvidenceConfig:save` - 保存配置
- `EvidenceExport:export` - 导出存证
- `EvidenceApi:regenerate` - 重新生成密钥

---

### 4. 监控管理 (Monitor)

**一级菜单：**
- authCode: `Monitor`
- authType: `1`
- authName: `监控管理`

**二级菜单：**
- authCode: `MonitorIndex`, authType: `2`, authName: `监控管理`

**按钮权限示例：**
- `MonitorIndex:alertConfig` - 配置告警
- `MonitorIndex:handleAlert` - 处理告警
- `MonitorIndex:exportLog` - 导出日志

---

### 5. 接口管理 (ApiManage)

**一级菜单：**
- authCode: `ApiManage`
- authType: `1`
- authName: `接口管理`

**二级菜单：**
- authCode: `ApiList`, authType: `2`, authName: `接口列表`
- authCode: `ApiAuth`, authType: `2`, authName: `接口授权`
- authCode: `ApiLog`, authType: `2`, authName: `接口日志`

**按钮权限示例：**
- `ApiList:add` - 新增接口
- `ApiList:edit` - 编辑接口
- `ApiList:delete` - 删除接口
- `ApiList:batchDelete` - 批量删除
- `ApiAuth:add` - 新增授权
- `ApiAuth:edit` - 编辑授权
- `ApiAuth:delete` - 删除授权
- `ApiAuth:refreshToken` - 刷新令牌
- `ApiAuth:validate` - 校验授权
- `ApiLog:export` - 导出日志
- `ApiLog:clear` - 清空日志

---

### 6. 系统设置 - 系统配置 (SystemConfig)

**已有一级菜单：** `Setting` (系统设置)

**新增二级菜单：**
- authCode: `SystemConfig`, authType: `2`, authName: `系统配置`

**按钮权限示例：**
- `SystemConfig:saveNetwork` - 保存网络配置
- `SystemConfig:saveTime` - 保存时间配置
- `SystemConfig:saveLoginRestriction` - 保存登录限制
- `SystemConfig:savePersonalization` - 保存个性化配置
- `SystemConfig:saveFtp` - 保存FTP配置
- `SystemConfig:testFtp` - 测试FTP连接

---

## 数据库权限表结构参考

```sql
-- 权限表示例结构
CREATE TABLE sys_auth (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    auth_code VARCHAR(100) NOT NULL COMMENT '权限代码，对应前端路由name',
    auth_name VARCHAR(100) NOT NULL COMMENT '权限名称',
    auth_type TINYINT NOT NULL COMMENT '权限类型：1-一级菜单 2-二级菜单 3-按钮',
    parent_id BIGINT COMMENT '父级权限ID',
    sort_order INT DEFAULT 0 COMMENT '排序',
    icon VARCHAR(100) COMMENT '图标（一级菜单）',
    is_enabled TINYINT DEFAULT 1 COMMENT '是否启用',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## 初始化权限数据SQL

```sql
-- 1. 白名单管理
INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order, icon)
VALUES ('Whitelist', '白名单管理', 1, NULL, 10, 'el-icon-s-check');

SET @whitelist_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order) VALUES
('WhitelistList', '白名单列表', 2, @whitelist_id, 1),
('WhitelistConfig', '白名单配置', 2, @whitelist_id, 2),
('WhitelistAccessLog', '访问日志记录', 2, @whitelist_id, 3);

-- 2. 租户管理
INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order, icon)
VALUES ('Tenant', '租户管理', 1, NULL, 11, 'el-icon-office-building');

SET @tenant_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order) VALUES
('TenantList', '租户列表', 2, @tenant_id, 1),
('TenantResource', '资源分配', 2, @tenant_id, 2);

-- 3. 存证管理
INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order, icon)
VALUES ('Evidence', '存证管理', 1, NULL, 12, 'el-icon-document-checked');

SET @evidence_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order) VALUES
('EvidenceQuery', '存证查询', 2, @evidence_id, 1),
('EvidenceTimestamp', '时间戳管理', 2, @evidence_id, 2),
('EvidenceConfig', '存证配置', 2, @evidence_id, 3),
('EvidenceExport', '存证加密导出', 2, @evidence_id, 4),
('EvidenceApi', '存证接口对接', 2, @evidence_id, 5);

-- 4. 监控管理
INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order, icon)
VALUES ('Monitor', '监控管理', 1, NULL, 13, 'el-icon-data-line');

SET @monitor_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order) VALUES
('MonitorIndex', '监控管理', 2, @monitor_id, 1);

-- 5. 接口管理
INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order, icon)
VALUES ('ApiManage', '接口管理', 1, NULL, 14, 'el-icon-connection');

SET @api_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order) VALUES
('ApiList', '接口列表', 2, @api_id, 1),
('ApiAuth', '接口授权', 2, @api_id, 2),
('ApiLog', '接口日志', 2, @api_id, 3);

-- 6. 系统设置 - 系统配置（假设Setting一级菜单已存在）
-- 首先查询Setting的ID
SELECT @setting_id := id FROM sys_auth WHERE auth_code = 'Setting';

INSERT INTO sys_auth (auth_code, auth_name, auth_type, parent_id, sort_order) VALUES
('SystemConfig', '系统配置', 2, @setting_id, 4);
```

## 角色权限关联

为超级管理员角色分配所有新增权限：

```sql
-- 假设超级管理员角色ID为1
INSERT INTO sys_role_auth (role_id, auth_id)
SELECT 1, id FROM sys_auth WHERE auth_code IN (
    'Whitelist', 'WhitelistList', 'WhitelistConfig', 'WhitelistAccessLog',
    'Tenant', 'TenantList', 'TenantResource',
    'Evidence', 'EvidenceQuery', 'EvidenceTimestamp', 'EvidenceConfig', 'EvidenceExport', 'EvidenceApi',
    'Monitor', 'MonitorIndex',
    'ApiManage', 'ApiList', 'ApiAuth', 'ApiLog',
    'SystemConfig'
);
```

## 前端权限检查示例

在页面中使用按钮权限：

```vue
<template>
  <div>
    <!-- 使用 v-if 检查按钮权限 -->
    <el-button
      v-if="buttonPermissionList.includes('WhitelistList:add')"
      type="primary"
      @click="handleAdd"
    >
      新增白名单
    </el-button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters(['buttonPermissionList'])
  }
}
</script>
```

## API返回数据格式参考

`/sys/oauth/getAuthList` 接口应返回如下格式：

```json
{
  "code": 0,
  "message": "success",
  "result": [
    {
      "id": 1,
      "authCode": "Whitelist",
      "authName": "白名单管理",
      "authType": 1,
      "parentId": null,
      "icon": "el-icon-s-check",
      "children": [
        {
          "id": 2,
          "authCode": "WhitelistList",
          "authName": "白名单列表",
          "authType": 2,
          "parentId": 1
        },
        {
          "id": 3,
          "authCode": "WhitelistConfig",
          "authName": "白名单配置",
          "authType": 2,
          "parentId": 1
        }
      ]
    },
    {
      "id": 10,
      "authCode": "WhitelistList:add",
      "authName": "新增白名单",
      "authType": 3,
      "parentId": 2
    }
  ]
}
```

## 注意事项

1. **authCode必须与前端路由name完全一致**（区分大小写）
2. 一级菜单需要配置 `icon` 属性
3. 按钮权限建议使用 `菜单Code:操作` 的命名规范
4. 新用户默认不应分配所有权限，需要管理员手动分配
5. 权限变更后，用户需要重新登录才能生效（或实现权限刷新机制）
6. hidden: true 的子页面（如TenantResource）也需要配置权限，否则无法访问

## 验证方法

1. 后端配置完权限后，使用管理员账号登录
2. 打开浏览器开发者工具，查看 Network 标签
3. 找到 `/sys/oauth/getAuthList` 请求，检查返回的权限列表
4. 确认新增菜单的 authCode 都在返回列表中
5. 刷新页面，验证菜单是否正常显示
