# 白名单访问日志功能测试指南

## 部署状态

✅ **所有功能已成功部署**

- ✅ Controller新增7个接口
- ✅ Service实现所有业务逻辑
- ✅ Repository & Mapper完整实现
- ✅ 定时清理任务已配置
- ✅ 前端API接口已更新

---

## 快速测试步骤

### 1. 访问Swagger文档

访问地址：`http://your-host:port/platform/swagger-ui.html`

在Swagger中找到 **白名单管理接口** 模块，可以看到以下新增接口：

#### 基础功能（已存在）
- ✅ POST `/whitelist/findWhitelistPage` - 查询白名单分页列表
- ✅ POST `/whitelist/addWhitelist` - 添加白名单
- ✅ POST `/whitelist/updateWhitelist` - 更新白名单
- ✅ POST `/whitelist/deleteWhitelist` - 删除白名单
- ✅ GET `/whitelist/getWhitelistDetail` - 查询白名单详情
- ✅ GET `/whitelist/findWhitelistAccessLogPage` - 查询访问日志分页列表
- ✅ GET `/whitelist/getWhitelistAccessLogDetail` - 查询访问日志详情
- ✅ GET `/whitelist/getWhitelistAccessStatistics` - 查询访问统计

#### 新增功能
- ⭐ POST `/whitelist/batchDeleteAccessLog` - 批量删除访问日志
- ⭐ POST `/whitelist/cleanExpiredLogs` - 清理过期日志
- ⭐ GET `/whitelist/exportAccessLog` - 导出访问日志
- ⭐ GET `/whitelist/getAccessTrend` - 获取访问趋势
- ⭐ GET `/whitelist/getTopAccessIps` - 获取IP访问排行
- ⭐ GET `/whitelist/getTopAccessUrls` - 获取URL访问排行
- ⭐ GET `/whitelist/getAccessDetailStatistics` - 获取访问详细统计

---

### 2. 准备测试数据

首先需要在数据库中插入一些测试日志数据：

```sql
-- 插入测试访问日志
INSERT INTO whitelist_access_log
(whitelist_id, access_ip, access_url, request_method, access_result, response_code, response_time, access_time)
VALUES
(NULL, '192.168.1.100', '/api/user/info', 'GET', 'SUCCESS', 200, 45, NOW()),
(NULL, '192.168.1.101', '/api/data/list', 'GET', 'SUCCESS', 200, 120, NOW()),
(NULL, '192.168.1.102', '/api/user/login', 'POST', 'DENIED', 403, 30, NOW()),
(NULL, '192.168.1.100', '/api/user/info', 'GET', 'SUCCESS', 200, 50, NOW() - INTERVAL 1 DAY),
(NULL, '192.168.1.103', '/api/admin/config', 'GET', 'ERROR', 500, 200, NOW() - INTERVAL 2 DAY),
(NULL, '192.168.1.100', '/api/data/list', 'GET', 'SUCCESS', 200, 80, NOW() - INTERVAL 3 DAY),
(NULL, '192.168.1.104', '/api/user/info', 'GET', 'SUCCESS', 200, 60, NOW() - INTERVAL 4 DAY),
(NULL, '192.168.1.101', '/api/data/export', 'GET', 'DENIED', 403, 25, NOW() - INTERVAL 5 DAY),
(NULL, '10.0.0.50', '/api/system/health', 'GET', 'SUCCESS', 200, 15, NOW() - INTERVAL 6 DAY),
(NULL, '10.0.0.51', '/api/user/logout', 'POST', 'SUCCESS', 200, 35, NOW() - INTERVAL 7 DAY);
```

执行命令：
```bash
docker exec mysql mysql -uroot -proot privacy1 < test_data.sql
```

---

### 3. 测试新增接口

#### 3.1 测试访问趋势

**接口**: `GET /whitelist/getAccessTrend?days=7`

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "trendList": [
      {
        "date": "2026-01-10",
        "totalCount": 3,
        "successCount": 2,
        "deniedCount": 1,
        "errorCount": 0
      }
    ],
    "days": 7
  }
}
```

#### 3.2 测试IP访问排行

**接口**: `GET /whitelist/getTopAccessIps?limit=5`

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "topIps": [
      {
        "ip": "192.168.1.100",
        "accessCount": 3,
        "successCount": 3,
        "deniedCount": 0,
        "lastAccessTime": "2026-01-10 13:00:00"
      }
    ]
  }
}
```

#### 3.3 测试URL访问排行

**接口**: `GET /whitelist/getTopAccessUrls?limit=5`

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "topUrls": [
      {
        "url": "/api/user/info",
        "accessCount": 4,
        "successCount": 4,
        "deniedCount": 0,
        "avgResponseTime": 50.0
      }
    ]
  }
}
```

#### 3.4 测试详细统计

**接口**: `GET /whitelist/getAccessDetailStatistics`

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "totalCount": 10,
    "uniqueIpCount": 6,
    "uniqueUrlCount": 7,
    "successCount": 7,
    "deniedCount": 2,
    "errorCount": 1,
    "avgResponseTime": 65.0,
    "maxResponseTime": 200,
    "minResponseTime": 15
  }
}
```

#### 3.5 测试导出日志

**接口**: `GET /whitelist/exportAccessLog`

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "list": [
      {...},
      {...}
    ],
    "total": 10
  }
}
```

#### 3.6 测试批量删除

**接口**: `POST /whitelist/batchDeleteAccessLog`

**请求Body**:
```json
[1, 2, 3]
```

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功"
}
```

#### 3.7 测试清理过期日志

**接口**: `POST /whitelist/cleanExpiredLogs?days=30`

**预期响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "deletedCount": 0,
    "beforeDate": "2025-12-11 13:00:00"
  }
}
```

---

### 4. 验证定时任务

#### 查看定时任务日志

```bash
# 查看定时任务是否已加载
docker logs application0 2>&1 | grep "WhitelistLogCleanTask"

# 等待到凌晨2点后查看清理日志
docker logs application0 2>&1 | grep "白名单访问日志清理任务"
```

#### 手动触发清理（可选）

如果不想等到凌晨2点，可以临时修改定时任务的cron表达式进行测试。

---

### 5. 前端集成测试

在前端"访问日志记录"页面中，应该能够：

1. ✅ 查看日志列表（分页）
2. ✅ 筛选日志（按IP、URL、结果、时间）
3. ✅ 查看日志详情
4. ✅ 批量删除日志（选中多条后点击删除）
5. ✅ 导出日志（下载Excel或CSV）
6. ✅ 查看统计图表（访问趋势图）
7. ✅ 查看排行榜（TOP IP、TOP URL）
8. ✅ 查看详细统计数据
9. ✅ 清理过期日志（管理员功能）

---

## 性能测试

### 1. 大数据量测试

插入10万条测试数据：

```sql
-- 创建存储过程生成测试数据
DELIMITER //
CREATE PROCEDURE generate_test_logs(IN num INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < num DO
        INSERT INTO whitelist_access_log
        (access_ip, access_url, request_method, access_result, response_code, response_time, access_time)
        VALUES
        (CONCAT('192.168.', FLOOR(1 + RAND() * 255), '.', FLOOR(1 + RAND() * 255)),
         CONCAT('/api/', SUBSTRING(MD5(RAND()), 1, 10)),
         'GET',
         CASE FLOOR(RAND() * 3) WHEN 0 THEN 'SUCCESS' WHEN 1 THEN 'DENIED' ELSE 'ERROR' END,
         200,
         FLOOR(10 + RAND() * 1000),
         DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- 执行生成10万条数据
CALL generate_test_logs(100000);
```

### 2. 查询性能测试

测试各个接口在大数据量下的响应时间：

- 列表查询：应 < 500ms
- 趋势分析：应 < 1s
- 排行查询：应 < 500ms
- 详细统计：应 < 800ms
- 导出功能：应 < 3s（10000条）

---

## 故障排查

### 接口404
检查Gateway路由配置是否包含whitelist路由，并且没有StripPrefix=1

### 接口500
查看application日志：
```bash
docker logs application0 2>&1 | grep -i "error\|exception" | tail -50
```

### 数据库连接失败
检查数据库表是否已创建：
```bash
docker exec mysql mysql -uroot -proot -e "SHOW TABLES FROM privacy1 LIKE '%whitelist%';"
```

### 定时任务未执行
检查定时任务是否已加载：
```bash
docker logs application0 2>&1 | grep "WhitelistLogCleanTask"
```

---

## 常见问题

**Q: 为什么导出限制10000条？**
A: 为了防止一次性导出大量数据导致内存溢出。如需导出更多数据，建议分批导出或使用数据库导出工具。

**Q: 定时清理任务会不会误删数据？**
A: 默认清理30天前的数据，这个时间可以在代码中配置。建议定期备份数据库。

**Q: 如何临时关闭定时清理？**
A: 可以在配置文件中设置`spring.task.scheduling.enabled=false`或注释掉`@Scheduled`注解。

**Q: 统计数据不准确？**
A: 检查数据库时区设置，确保与应用服务器时区一致。

---

## 总结

本次更新大幅增强了白名单访问日志的管理能力，提供了：

- 📊 **丰富的统计分析** - 趋势、排行、详细指标
- 🗑️ **灵活的数据管理** - 批量删除、定时清理、导出
- ⚡ **高性能查询** - 索引优化、分页、缓存
- 🔧 **易于维护** - 自动化任务、完整日志

所有功能已部署到生产环境，可以开始测试使用！
