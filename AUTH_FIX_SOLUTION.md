# 权限问题修复方案

## 问题诊断结果

### 根本原因
通过调试发现，**白名单相关接口（`/whitelist/*`）没有在权限系统中注册**，导致用户无法访问这些接口。

### 诊断数据

#### 1. Redis中的用户权限
```
userId: 1 (管理员)
authIdList: 1008,1016,1001,1002,1003,1019,1022,1007,1023
```

#### 2. 系统中已注册的权限
- 项目管理 (1001)
- 项目列表 (1002) - `/project/getProjectList`
- 项目详情 (1003) - `/project/getProjectDetails`
- 模型管理 (1007) - `/model/getmodellist`
- 模型列表 (1008) - `/model/getmodellist`
- 匿踪查询 (1016) - `/fusionResource/getResourceList`
- 隐私求交 (1019)
- 资源管理 (1022)
- 资源概览 (1023) - `/resource/getdataresourcelist`

#### 3. 缺失的权限
白名单相关接口**完全没有在 `sys_auth` 表中注册**：
- `/whitelist/saveOrUpdateWhitelist` ❌
- `/whitelist/deleteWhitelist` ❌
- `/whitelist/findWhitelistPage` ❌

### 权限验证逻辑
位置：`primihub-service/gateway/src/main/java/com/primihub/gateway/filter/SysAuthGatewayFilterFactory.java:63-65`

```java
if (!sysUserListVO.getAuthIdList().contains(sysAuthNodeVO.getAuthId().toString())
    && !authIdList.contains(sysAuthNodeVO.getAuthId())) {
    return GatewayFilterFactoryTool.writeFailureJsonToResponse(exchange, BaseResultEnum.NO_AUTH);
}
```

## 修复方案

### 方案一：在数据库中添加白名单权限（推荐）

#### 步骤 1：添加权限记录到数据初始化SQL

编辑文件：`primihub-service/application/src/main/resources/data-complete-h2.sql`

在系统设置相关权限后添加：

```sql
-- 白名单管理权限
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
-- 父级菜单（假设系统设置的auth_id是1026，需要根据实际情况调整）
(1035, '白名单管理', 'WhitelistManage', 2, 1026, 1035, '1026,1035', '', 'own', 7, 1, 1, 1, 0),
(1036, '白名单列表', 'WhitelistList', 3, 1035, 1036, '1026,1035,1036', '/whitelist/findWhitelistPage', 'own', 1, 2, 1, 1, 0),
(1037, '新增白名单', 'WhitelistCreate', 3, 1035, 1037, '1026,1035,1037', '/whitelist/saveOrUpdateWhitelist', 'own', 2, 2, 1, 1, 0),
(1038, '删除白名单', 'WhitelistDelete', 3, 1035, 1038, '1026,1035,1038', '/whitelist/deleteWhitelist', 'own', 3, 2, 1, 1, 0);

-- 给超级管理员角色分配权限
INSERT INTO sys_role_auth (id, role_id, auth_id, c_time, u_time, is_del)
VALUES
(1035, 1, 1035, NOW(), NOW(), 0),
(1036, 1, 1036, NOW(), NOW(), 0),
(1037, 1, 1037, NOW(), NOW(), 0),
(1038, 1, 1038, NOW(), NOW(), 0);
```

#### 步骤 2：清除Redis缓存

```bash
redis-cli DEL sys_auth:bfs_list
redis-cli DEL sys_user:login_status_1
```

#### 步骤 3：重启应用

```bash
# 停止当前应用
kill <进程ID>

# 重新编译并启动
cd /home/primihub/github/primihub-platform/primihub-service/application
mvn clean package -DskipTests
java -jar target/application-1.0-SNAPSHOT.jar --spring.profiles.active=simple
```

### 方案二：临时豁免白名单接口（快速测试）

#### 修改权限验证代码

编辑：`primihub-service/gateway/src/main/java/com/primihub/gateway/filter/SysAuthGatewayFilterFactory.java`

在第 62 行后添加临时豁免逻辑：

```java
SysAuthNodeVO sysAuthNodeVO = mapping.get(rawPath);

// 临时豁免白名单相关接口（仅用于开发测试）
if (rawPath.startsWith("/whitelist/")) {
    log.info("临时豁免白名单接口权限检查: {}", rawPath);
    // 跳过权限检查
} else if (sysAuthNodeVO != null) {
    // ... 原有权限验证逻辑
}
```

**注意**：这个方案仅适用于开发测试，不要用于生产环境！

### 方案三：使用超级Token（仅用于调试）

在配置文件中已配置了超级Token：`excalibur_forever_ABCDEFGHIJKLMN`

测试时使用这个token可以绕过所有权限检查：

```bash
curl -H "token: excalibur_forever_ABCDEFGHIJKLMN" \
     http://localhost:8090/whitelist/findWhitelistPage
```

### 方案四：将白名单接口加入Token验证黑名单

编辑：`application-simple.yaml`

```yaml
base:
  tokenValidateUriBlackList:
    - "/user/login"
    # ... 其他路径
    - "/whitelist/**"  # 添加这一行
```

这样白名单接口将完全跳过token和权限验证。

**注意**：这会让任何人都可以访问白名单接口，存在安全风险！

## 推荐执行顺序

### 开发环境快速测试
1. 使用**方案二**临时豁免权限检查
2. 重新编译并启动应用
3. 测试白名单功能是否正常

### 正式环境部署
1. 使用**方案一**在数据库中正确配置权限
2. 清除Redis缓存
3. 重启应用
4. 在管理后台给需要的用户/角色分配白名单管理权限

## 调试日志说明

我已经在权限验证代码中添加了详细的调试日志，重新编译后，每次权限验证都会输出：
- 请求路径
- 用户ID和账号
- 用户的权限ID列表
- 角色的权限ID集合
- 所需的权限ID
- 权限验证结果

这些日志会帮助你快速定位权限问题。

## 验证步骤

修复后，通过以下步骤验证：

1. **检查Redis中的权限数据**
```bash
redis-cli GET sys_auth:bfs_list | jq '.[] | select(.authUrl | contains("/whitelist"))'
```

2. **检查用户权限**
```bash
redis-cli HGETALL sys_user:login_status_1
# 查看 authIdList 字段是否包含白名单相关的权限ID
```

3. **访问白名单接口测试**
```bash
curl -H "token: <your-token>" \
     http://localhost:8090/whitelist/findWhitelistPage?pageNum=1&pageSize=10
```

4. **查看调试日志**
```bash
tail -f /home/primihub/github/primihub-platform/primihub-service/backend.log | grep "权限验证"
```

## 相关文件清单

- ✅ 调试日志已添加：`primihub-service/gateway/src/main/java/com/primihub/gateway/filter/SysAuthGatewayFilterFactory.java`
- ⚠️ 需要修改：`primihub-service/application/src/main/resources/data-complete-h2.sql`
- 📖 参考文档：`DEBUG_AUTH_ISSUE.md`
