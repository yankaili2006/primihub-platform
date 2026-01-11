# 白名单访问日志功能完善说明

## 新增功能概览

本次更新对白名单访问日志功能进行了全面完善，新增了以下核心功能：

### 1. 批量删除日志
**接口路径**: `POST /whitelist/batchDeleteAccessLog`

**功能说明**: 支持批量删除多条访问日志记录

**请求参数**:
```json
[1, 2, 3, 4, 5]  // 日志ID数组
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功"
}
```

---

### 2. 清理过期日志
**接口路径**: `POST /whitelist/cleanExpiredLogs`

**功能说明**: 清理指定天数之前的访问日志

**请求参数**:
```
days: 30  // 清理30天前的日志
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "deletedCount": 1523,
    "beforeDate": "2025-12-11 03:30:00"
  }
}
```

---

### 3. 导出访问日志
**接口路径**: `GET /whitelist/exportAccessLog`

**功能说明**: 导出访问日志数据（最多10000条）

**请求参数**:
- `accessIp`: 访问IP（可选）
- `accessUrl`: 访问URL（可选）
- `accessResult`: 访问结果（可选：SUCCESS/DENIED/ERROR）
- `startTime`: 开始时间（可选）
- `endTime`: 结束时间（可选）

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "list": [
      {
        "id": 1,
        "accessIp": "192.168.1.100",
        "accessUrl": "/api/user/info",
        "requestMethod": "GET",
        "accessResult": "SUCCESS",
        "responseCode": 200,
        "responseTime": 45,
        "accessTime": "2026-01-10 10:30:00"
      }
    ],
    "total": 1234
  }
}
```

---

### 4. 访问趋势分析
**接口路径**: `GET /whitelist/getAccessTrend`

**功能说明**: 查询最近N天的访问趋势，按天统计

**请求参数**:
```
days: 7  // 查询最近7天，默认7天
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "trendList": [
      {
        "date": "2026-01-10",
        "totalCount": 1250,
        "successCount": 1100,
        "deniedCount": 120,
        "errorCount": 30
      },
      {
        "date": "2026-01-09",
        "totalCount": 1180,
        "successCount": 1050,
        "deniedCount": 100,
        "errorCount": 30
      }
    ],
    "days": 7
  }
}
```

---

### 5. IP访问排行
**接口路径**: `GET /whitelist/getTopAccessIps`

**功能说明**: 查询访问次数最多的IP地址排行

**请求参数**:
```
limit: 10  // 返回前10名，默认10
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "topIps": [
      {
        "ip": "192.168.1.100",
        "accessCount": 5230,
        "successCount": 5100,
        "deniedCount": 130,
        "lastAccessTime": "2026-01-10 15:30:00"
      },
      {
        "ip": "192.168.1.101",
        "accessCount": 3890,
        "successCount": 3800,
        "deniedCount": 90,
        "lastAccessTime": "2026-01-10 15:28:00"
      }
    ]
  }
}
```

---

### 6. URL访问排行
**接口路径**: `GET /whitelist/getTopAccessUrls`

**功能说明**: 查询访问次数最多的URL排行

**请求参数**:
```
limit: 10  // 返回前10名，默认10
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "topUrls": [
      {
        "url": "/api/user/info",
        "accessCount": 8230,
        "successCount": 8100,
        "deniedCount": 130,
        "avgResponseTime": 45.5
      },
      {
        "url": "/api/data/list",
        "accessCount": 6890,
        "successCount": 6800,
        "deniedCount": 90,
        "avgResponseTime": 120.3
      }
    ]
  }
}
```

---

### 7. 访问详细统计
**接口路径**: `GET /whitelist/getAccessDetailStatistics`

**功能说明**: 查询指定时间范围内的详细统计信息

**请求参数**:
- `startTime`: 开始时间（可选）
- `endTime`: 结束时间（可选）

**响应示例**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "totalCount": 125680,
    "uniqueIpCount": 352,
    "uniqueUrlCount": 48,
    "successCount": 118230,
    "deniedCount": 6320,
    "errorCount": 1130,
    "avgResponseTime": 85.6,
    "maxResponseTime": 3500,
    "minResponseTime": 12
  }
}
```

**统计字段说明**:
- `totalCount`: 总访问次数
- `uniqueIpCount`: 独立IP数
- `uniqueUrlCount`: 独立URL数
- `successCount`: 成功访问次数
- `deniedCount`: 拒绝访问次数
- `errorCount`: 错误访问次数
- `avgResponseTime`: 平均响应时间（毫秒）
- `maxResponseTime`: 最大响应时间（毫秒）
- `minResponseTime`: 最小响应时间（毫秒）

---

## 8. 定时任务

### 自动清理过期日志
- **执行时间**: 每天凌晨 2:00
- **清理规则**: 自动删除30天前的日志
- **任务类**: `com.primihub.biz.task.WhitelistLogCleanTask`

### 每小时统计任务
- **执行时间**: 每小时整点
- **功能**: 执行统计分析，可扩展为异常检测、告警通知等
- **任务类**: `com.primihub.biz.task.WhitelistLogCleanTask`

---

## 使用场景

### 1. 安全审计
- 查看所有访问记录
- 分析异常访问模式
- 导出日志用于合规审计

### 2. 性能监控
- 查看响应时间统计
- 分析慢接口
- 优化访问频繁的URL

### 3. 访问分析
- IP访问分布
- URL热度分析
- 访问趋势预测

### 4. 运维管理
- 定期清理过期日志
- 批量删除测试数据
- 导出数据进行离线分析

---

## 数据库表结构

访问日志表 `whitelist_access_log`:
```sql
CREATE TABLE `whitelist_access_log` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `whitelist_id` BIGINT(20) DEFAULT NULL COMMENT '白名单ID',
  `access_ip` VARCHAR(50) NOT NULL COMMENT '访问IP',
  `access_url` VARCHAR(500) NOT NULL COMMENT '访问URL',
  `request_method` VARCHAR(10) DEFAULT NULL COMMENT '请求方法',
  `access_result` VARCHAR(20) NOT NULL COMMENT '访问结果：SUCCESS-成功，DENIED-拒绝，ERROR-异常',
  `fail_reason` VARCHAR(500) DEFAULT NULL COMMENT '失败原因',
  `user_id` BIGINT(20) DEFAULT NULL COMMENT '用户ID',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT 'User-Agent',
  `request_params` TEXT DEFAULT NULL COMMENT '请求参数',
  `response_code` INT(11) DEFAULT NULL COMMENT '响应码',
  `response_time` BIGINT(20) DEFAULT NULL COMMENT '响应时间(ms)',
  `access_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '访问时间',
  PRIMARY KEY (`id`),
  KEY `idx_whitelist_id` (`whitelist_id`),
  KEY `idx_access_ip` (`access_ip`),
  KEY `idx_access_result` (`access_result`),
  KEY `idx_access_time` (`access_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='白名单访问日志表';
```

---

## 性能优化建议

1. **索引优化**: 已为常用查询字段建立索引
2. **定期清理**: 定时任务自动清理过期数据
3. **导出限制**: 单次导出限制10000条
4. **分页查询**: 列表查询支持分页，避免大数据量查询

---

## 更新日期
2026-01-10

## 更新内容
- ✅ 新增批量删除日志功能
- ✅ 新增清理过期日志功能
- ✅ 新增导出日志功能
- ✅ 新增访问趋势分析
- ✅ 新增IP访问排行
- ✅ 新增URL访问排行
- ✅ 新增访问详细统计
- ✅ 新增定时清理任务
- ✅ 优化SQL查询性能
