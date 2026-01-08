# 权限问题调试指南

## 问题描述
后端返回错误码 103 "暂无权限"

## 核心验证逻辑位置
- 文件：`primihub-service/gateway/src/main/java/com/primihub/gateway/filter/SysAuthGatewayFilterFactory.java:63-65`
- 错误码定义：`primihub-service/biz/src/main/java/com/primihub/biz/entity/base/BaseResultEnum.java:12`

## 调试步骤

### 1. 检查访问的具体接口
确认是哪个接口返回的 "暂无权限" 错误。

### 2. 添加调试日志
在 `SysAuthGatewayFilterFactory.java` 第 60-66 行添加日志：

```java
Map<String, SysAuthNodeVO> mapping = sysAuthService.getSysAuthUrlMapping();
SysAuthNodeVO sysAuthNodeVO = mapping.get(rawPath);
log.info("=== 权限验证调试 ===");
log.info("请求路径: {}", rawPath);
log.info("URL映射中的权限节点: {}", sysAuthNodeVO);
if (sysAuthNodeVO != null) {
    log.info("所需权限ID: {}", sysAuthNodeVO.getAuthId());
    log.info("用户权限ID列表: {}", sysUserListVO.getAuthIdList());
    log.info("角色权限ID集合: {}", authIdList);
    if (!sysUserListVO.getAuthIdList().contains(sysAuthNodeVO.getAuthId().toString())
        &&!authIdList.contains(sysAuthNodeVO.getAuthId())) {
        log.warn("权限验证失败！用户和角色都没有权限ID: {}", sysAuthNodeVO.getAuthId());
        return GatewayFilterFactoryTool.writeFailureJsonToResponse(exchange, BaseResultEnum.NO_AUTH);
    }
}
```

### 3. 检查权限数据

#### 3.1 查看数据库中的权限配置
```sql
-- 查看所有权限
SELECT * FROM sys_auth;

-- 查看用户权限
SELECT * FROM sys_user WHERE user_id = <你的用户ID>;

-- 查看角色权限
SELECT * FROM sys_role_auth WHERE role_id IN (
    SELECT role_id FROM sys_user_role WHERE user_id = <你的用户ID>
);
```

#### 3.2 查看Redis缓存
```bash
# 查看用户登录状态
redis-cli
keys *user*
get <具体的key>

# 查看权限映射缓存
keys *auth*
```

### 4. 检查新增的白名单接口

白名单相关接口可能还未在权限系统中注册：
- `/whitelist/saveOrUpdateWhitelist`
- `/whitelist/deleteWhitelist`
- `/whitelist/findWhitelistPage`

**解决方案**：
1. 在数据库的 `sys_auth` 表中添加这些接口的权限记录
2. 或者调用 `SysAuthService.generateAllAuth()` 方法重新生成权限（如果已在代码中配置）
3. 清除Redis中的权限缓存，强制重新加载

### 5. 临时解决方案

#### 方案A：给用户添加权限
1. 登录系统管理后台
2. 找到"系统设置" -> "用户管理"
3. 编辑用户，分配相应的权限或角色

#### 方案B：使用超级Token（仅用于测试）
在配置文件中查找 `usefulToken` 配置项，使用该token可以绕过权限检查（参见 `SysAuthGatewayFilterFactory.java:48`）

#### 方案C：将接口添加到权限白名单
修改 `SysAuthGatewayFilterFactory.java`，在第 62 行的 `if (sysAuthNodeVO != null)` 判断中，对特定接口跳过权限检查：

```java
if (sysAuthNodeVO != null) {
    // 临时豁免白名单相关接口（仅用于测试）
    if (!rawPath.startsWith("/whitelist/")) {
        if (!sysUserListVO.getAuthIdList().contains(sysAuthNodeVO.getAuthId().toString())
            &&!authIdList.contains(sysAuthNodeVO.getAuthId())) {
            return GatewayFilterFactoryTool.writeFailureJsonToResponse(exchange, BaseResultEnum.NO_AUTH);
        }
    }
}
```

### 6. 检查配置文件

查看 `application.yaml` 中的配置：
- Redis连接是否正常
- 数据库连接是否正常
- `usefulToken` 配置

### 7. 常见问题检查清单

- [ ] 用户是否已登录（token是否有效）
- [ ] 访问的接口是否在权限系统中注册
- [ ] 用户账号是否被分配了相应的角色
- [ ] 角色是否配置了相应的权限
- [ ] Redis中的权限缓存是否是最新的
- [ ] 数据库中的权限数据是否正确
- [ ] 是否是新增的接口需要添加权限配置

## 快速诊断命令

```bash
# 查看应用日志
tail -f primihub-service/application/logs/application.log

# 检查Redis连接
redis-cli ping

# 查看当前用户信息（需要在应用中添加调试接口）
curl -H "token: <your-token>" http://localhost:8090/debug/userinfo
```

## 相关文件位置

- 权限验证过滤器：`primihub-service/gateway/src/main/java/com/primihub/gateway/filter/SysAuthGatewayFilterFactory.java`
- 权限服务：`primihub-service/biz/src/main/java/com/primihub/biz/service/sys/SysAuthService.java`
- 错误码定义：`primihub-service/biz/src/main/java/com/primihub/biz/entity/base/BaseResultEnum.java`
- 前端权限处理：`primihub-webconsole/src/permission.js`
- 前端请求拦截：`primihub-webconsole/src/utils/request.js`
