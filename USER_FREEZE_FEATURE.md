# 用户冻结/解冻功能说明

## 功能概述

在用户管理模块新增了用户冻结/解冻功能，管理员可以通过此功能临时禁止用户登录系统，而无需删除用户账号。

## 新增接口

### 1. 冻结单个用户
**接口路径**: `POST /sys/user/freezeUser`

**功能说明**: 冻结指定用户，冻结后该用户无法登录系统，已登录的会话将被强制下线。

**请求参数**:
```
userId: 123  // 用户ID
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功"
}
```

**业务逻辑**:
1. 检查用户是否存在
2. 检查用户是否已被冻结
3. 将用户的 `is_forbid` 字段设置为 1
4. 清除该用户的所有登录token，强制下线

---

### 2. 解冻单个用户
**接口路径**: `POST /sys/user/unfreezeUser`

**功能说明**: 解冻指定用户，恢复其登录权限。

**请求参数**:
```
userId: 123  // 用户ID
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功"
}
```

**业务逻辑**:
1. 检查用户是否存在
2. 检查用户是否处于冻结状态
3. 将用户的 `is_forbid` 字段设置为 0

---

### 3. 批量冻结用户
**接口路径**: `POST /sys/user/batchFreezeUser`

**功能说明**: 批量冻结多个用户。

**请求参数**:
```json
[123, 456, 789]  // 用户ID数组
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "successCount": 2,
    "totalCount": 3
  }
}
```

**业务逻辑**:
1. 遍历用户ID列表
2. 对每个未冻结的用户执行冻结操作
3. 清除已冻结用户的登录token
4. 返回成功冻结的数量和总数

---

### 4. 批量解冻用户
**接口路径**: `POST /sys/user/batchUnfreezeUser`

**功能说明**: 批量解冻多个用户。

**请求参数**:
```json
[123, 456, 789]  // 用户ID数组
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "successCount": 2,
    "totalCount": 3
  }
}
```

---

## 数据库字段

用户表 `sys_user` 中的 `is_forbid` 字段：
- **0**: 正常状态，可以登录
- **1**: 冻结状态，禁止登录

```sql
ALTER TABLE sys_user MODIFY COLUMN is_forbid tinyint(4) NOT NULL DEFAULT 0 COMMENT '是否冻结：0-正常，1-冻结';
```

---

## 前端集成指南

### API调用示例

```javascript
import { freezeUser, unfreezeUser, batchFreezeUser, batchUnfreezeUser } from '@/api/user'

// 冻结单个用户
freezeUser({ userId: 123 }).then(res => {
  if (res.code === 0) {
    this.$message.success('冻结成功')
  }
})

// 解冻单个用户
unfreezeUser({ userId: 123 }).then(res => {
  if (res.code === 0) {
    this.$message.success('解冻成功')
  }
})

// 批量冻结用户
batchFreezeUser([123, 456, 789]).then(res => {
  if (res.code === 0) {
    this.$message.success(`成功冻结${res.result.successCount}个用户`)
  }
})

// 批量解冻用户
batchUnfreezeUser([123, 456, 789]).then(res => {
  if (res.code === 0) {
    this.$message.success(`成功解冻${res.result.successCount}个用户`)
  }
})
```

### UI建议

在用户列表页面，可以添加以下UI元素：

1. **用户状态标识**
   - 在用户列表中显示用户状态：正常/冻结
   - 使用不同颜色的标签区分状态

2. **操作按钮**
   - 每行用户数据添加"冻结"或"解冻"按钮
   - 根据用户当前状态动态显示对应按钮

3. **批量操作**
   - 添加批量选择复选框
   - 在列表顶部添加"批量冻结"和"批量解冻"按钮

4. **确认对话框**
   - 冻结操作前显示确认对话框
   - 提示冻结后的影响（强制下线）

### 示例代码

```vue
<template>
  <div>
    <!-- 用户列表 -->
    <el-table :data="userList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" />
      <el-table-column prop="userName" label="用户名" />
      <el-table-column prop="userAccount" label="账号" />
      <el-table-column label="状态">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.isForbid === 0" type="success">正常</el-tag>
          <el-tag v-else type="danger">已冻结</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作">
        <template slot-scope="scope">
          <el-button
            v-if="scope.row.isForbid === 0"
            type="warning"
            size="mini"
            @click="handleFreeze(scope.row)"
          >
            冻结
          </el-button>
          <el-button
            v-else
            type="success"
            size="mini"
            @click="handleUnfreeze(scope.row)"
          >
            解冻
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 批量操作 -->
    <div class="batch-actions">
      <el-button
        type="warning"
        :disabled="selectedUsers.length === 0"
        @click="handleBatchFreeze"
      >
        批量冻结
      </el-button>
      <el-button
        type="success"
        :disabled="selectedUsers.length === 0"
        @click="handleBatchUnfreeze"
      >
        批量解冻
      </el-button>
    </div>
  </div>
</template>

<script>
import { freezeUser, unfreezeUser, batchFreezeUser, batchUnfreezeUser } from '@/api/user'

export default {
  data() {
    return {
      userList: [],
      selectedUsers: []
    }
  },
  methods: {
    handleSelectionChange(selection) {
      this.selectedUsers = selection
    },

    handleFreeze(user) {
      this.$confirm(`确定要冻结用户"${user.userName}"吗？冻结后该用户将无法登录系统。`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        freezeUser({ userId: user.userId }).then(res => {
          if (res.code === 0) {
            this.$message.success('冻结成功')
            this.fetchUserList() // 刷新列表
          }
        })
      })
    },

    handleUnfreeze(user) {
      unfreezeUser({ userId: user.userId }).then(res => {
        if (res.code === 0) {
          this.$message.success('解冻成功')
          this.fetchUserList() // 刷新列表
        }
      })
    },

    handleBatchFreeze() {
      const userIds = this.selectedUsers.map(u => u.userId)
      this.$confirm(`确定要冻结选中的${userIds.length}个用户吗？`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        batchFreezeUser(userIds).then(res => {
          if (res.code === 0) {
            this.$message.success(`成功冻结${res.result.successCount}个用户`)
            this.fetchUserList()
          }
        })
      })
    },

    handleBatchUnfreeze() {
      const userIds = this.selectedUsers.map(u => u.userId)
      batchUnfreezeUser(userIds).then(res => {
        if (res.code === 0) {
          this.$message.success(`成功解冻${res.result.successCount}个用户`)
          this.fetchUserList()
        }
      })
    }
  }
}
</script>
```

---

## 权限控制

建议为冻结/解冻功能添加权限控制：

```sql
-- 在 sys_auth 表中添加权限
INSERT INTO sys_auth (auth_code, auth_name, auth_url, auth_type, pid)
VALUES
('UserFreeze', '冻结用户', '/sys/user/freezeUser', 2, (SELECT auth_id FROM sys_auth WHERE auth_code = 'UserManage')),
('UserUnfreeze', '解冻用户', '/sys/user/unfreezeUser', 2, (SELECT auth_id FROM sys_auth WHERE auth_code = 'UserManage')),
('UserBatchFreeze', '批量冻结用户', '/sys/user/batchFreezeUser', 2, (SELECT auth_id FROM sys_auth WHERE auth_code = 'UserManage')),
('UserBatchUnfreeze', '批量解冻用户', '/sys/user/batchUnfreezeUser', 2, (SELECT auth_id FROM sys_auth WHERE auth_code = 'UserManage'));

-- 分配给管理员角色
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth WHERE auth_code IN ('UserFreeze', 'UserUnfreeze', 'UserBatchFreeze', 'UserBatchUnfreeze');
```

前端根据权限控制按钮显示：

```javascript
computed: {
  hasFreezePermission() {
    return this.buttonPermissionList.includes('UserFreeze')
  },
  hasUnfreezePermission() {
    return this.buttonPermissionList.includes('UserUnfreeze')
  }
}
```

---

## 注意事项

1. **强制下线**: 冻结用户时会清除其所有登录token，用户会被强制下线
2. **管理员保护**: 建议不要冻结超级管理员账号，避免无法管理系统
3. **日志记录**: 建议记录冻结/解冻操作的日志，包括操作人、操作时间、目标用户等
4. **通知机制**: 可以考虑在用户被冻结时发送邮件/短信通知
5. **批量操作**: 批量操作时会跳过已处于目标状态的用户，只处理需要变更的用户

---

## 测试用例

### 1. 冻结正常用户
- 输入：正常状态的用户ID
- 预期：用户状态变为冻结，登录token被清除
- 验证：用户无法登录，已登录会话被踢出

### 2. 重复冻结已冻结用户
- 输入：已冻结用户的ID
- 预期：返回错误提示"用户已被冻结"

### 3. 解冻冻结用户
- 输入：冻结状态的用户ID
- 预期：用户状态变为正常
- 验证：用户可以正常登录

### 4. 解冻正常用户
- 输入：正常状态的用户ID
- 预期：返回错误提示"用户未被冻结"

### 5. 批量操作
- 输入：包含正常和冻结用户的ID列表
- 预期：只处理需要变更的用户，返回实际操作数量

---

## 更新日期
2026-01-10

## 更新内容
- ✅ 新增冻结单个用户接口
- ✅ 新增解冻单个用户接口
- ✅ 新增批量冻结用户接口
- ✅ 新增批量解冻用户接口
- ✅ 冻结时自动清除登录token
- ✅ 前端API接口已添加
- ✅ Repository和Mapper已实现
