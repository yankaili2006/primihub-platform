# PrimiHub API 完整分析报告

生成时间: 2026-01-11
系统: http://100.64.0.23:30811/prod-api
Token: SU202601111503542F1167CD6FFFD38A270C80D9D96A928C

## 📊 API测试结果总览

| API端点 | 状态 | 说明 |
|---------|------|------|
| 文件上传 | ✅ 成功 | POST /data/file/upload |
| 文件预览 | ✅ 成功 | GET /data/resource/resourceFilePreview |
| 资源列表 | ✅ 成功 | GET /data/fusionResource/getResourceList |
| 资源创建 | ⚠️ 异常 | POST /data/resource/saveorupdateresource |
| 机构列表 | ✅ 成功 | GET /sys/organ/getOrganList |

## ✅ 成功的API

### 1. 文件上传 API

**端点**: `POST /data/file/upload`

**请求格式**: multipart/form-data

**必需参数**:
```javascript
{
  file: <binary>,           // 文件内容
  userId: 1,                // 用户ID
  fileName: "xxx.csv",      // 文件名
  fileSource: 1,            // 文件来源(1=本地上传)
  timestamp: 1768118625000, // 时间戳
  nonce: 625,               // 随机数
  token: "SU202..."         // 认证token
}
```

**成功响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "sysFile": {
      "fileId": 2,
      "fileSource": 1,
      "fileUrl": "/data/upload/1/2026011116/xxx.csv",
      "fileName": "xxx",
      "fileSuffix": "csv",
      "fileSize": 307,
      "fileCurrentSize": 307,
      "fileArea": "local",
      "isDel": 0
    }
  }
}
```

**关键发现**:
- fileId在 `result.sysFile.fileId`
- 文件自动解析CSV格式
- 返回的fileId可用于创建资源

### 2. 文件预览 API

**端点**: `GET /data/resource/resourceFilePreview`

**参数**:
```
fileId: 2
timestamp: 1768118625000
nonce: 625
token: SU202...
```

**成功响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "fileId": 2,
    "fieldList": [
      {
        "fieldName": "user_id",
        "fieldType": "String",
        "relevance": false,
        "grouping": false,
        "protectionStatus": false
      }
    ],
    "dataList": [
      {"user_id": "U001", "age": "25", ...}
    ]
  }
}
```

**关键发现**:
- 自动检测字段类型
- fieldType使用大写: "String", "Integer", "Double"
- boolean字段使用false/true (JSON boolean)
- 返回前10行数据预览

### 3. 资源列表 API

**端点**: `GET /data/fusionResource/getResourceList`

**参数**:
```
pageNo: 1
pageSize: 10
timestamp: 1768118625000
nonce: 625
token: SU202...
```

**成功响应**:
```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "total": 0,
    "data": []
  }
}
```

## ⚠️ 问题的API

### 资源创建 API

**端点**: `POST /data/resource/saveorupdateresource`

**测试的请求格式**:
```json
{
  "resourceName": "用户特征数据_20260111_080625",
  "resourceDesc": "用户基本信息和行为特征数据集",
  "resourceAuthType": 1,
  "resourceSource": 1,
  "tags": ["测试数据", "用户特征"],
  "fileId": 2,
  "fieldList": [
    {
      "fieldName": "user_id",
      "fieldType": "String",
      "fieldDesc": "用户ID",
      "relevance": 1,
      "grouping": 0,
      "protectionStatus": 0
    }
  ],
  "fusionOrganList": [],
  "timestamp": 1768118625000,
  "nonce": 625,
  "token": "SU202..."
}
```

**Headers**:
```
Content-Type: application/json
userId: 1
```

**失败响应**:
```json
{
  "code": -1,
  "msg": "请求异常",
  "result": null
}
```

**尝试的变体**:

1. ✅ 端点路径: `/data/resource/saveorupdateresource` (正确)
2. ✅ 包含所有必需字段
3. ✅ fileId=2存在且有效
4. ✅ userId在header中
5. ✅ timestamp/nonce/token都包含
6. ❌ 仍然返回"请求异常"

**可能的原因**:

1. **数据库约束**: 可能有外键约束或触发器失败
2. **节点配置**: 系统可能需要额外的节点配置
3. **机构要求**: organId可能是必需的(系统中目前没有机构)
4. **后端bug**: 可能是特定版本的bug

## 📋 数据库结构

### data_resource 表结构

```sql
CREATE TABLE `data_resource` (
  `resource_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `resource_name` varchar(255) DEFAULT NULL,
  `resource_desc` varchar(255) DEFAULT NULL,
  `resource_auth_type` int(1) DEFAULT NULL,
  `resource_source` int(1) DEFAULT NULL,
  `file_id` bigint(20) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `organ_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `update_date` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
```

**关键字段**:
- resource_id: 自增主键
- file_id: 关联sys_file表
- user_id: 关联用户
- organ_id: 关联机构 (可能为NULL)

## 🎯 推荐方案

### 方案1: 使用Web界面(强烈推荐)

由于API创建存在未知问题，建议通过Web界面创建资源:

1. 访问: http://100.64.0.23:30811
2. 登录系统
3. 找到"数据资源管理"
4. 点击"创建资源"
5. 上传文件或配置数据库
6. 填写资源信息
7. 保存

### 方案2: 使用脚本上传文件

虽然无法通过API创建资源,但可以批量上传文件:

```bash
python3 create_resource_complete.py
```

这个脚本可以:
- ✅ 创建CSV文件
- ✅ 上传到系统获取fileId
- ✅ 预览文件内容
- ❌ 创建资源(需要手动在Web界面完成)

上传文件后，在Web界面中可以直接选择已上传的文件创建资源。

### 方案3: 联系系统管理员

如果需要批量创建资源，建议:
1. 提供后端日志以诊断具体错误
2. 检查是否需要额外的系统配置
3. 确认API版本和预期参数格式

## 🔧 工作流程

### 当前可用的完整流程

```
1. 准备CSV数据
   ↓
2. 调用上传API ✅
   fileId = 2
   ↓
3. 调用预览API ✅
   验证文件内容
   ↓
4. ❌ 调用创建API失败
   |
   ↓ (替代方案)
   在Web界面手动创建
   使用已上传的fileId=2
   ↓
5. 调用资源列表API ✅
   验证创建成功
```

## 📝 源代码参考

**Frontend**: `/primihub-webconsole/src/views/resource/create.vue`
```javascript
dataForm: {
  resourceName: '',
  resourceDesc: '',
  tags: [],
  resourceSource: 1,
  resourceAuthType: 1,
  fileId: -1,
  fieldList: [],
  fusionOrganList: []
}
```

**Backend**: `/primihub-service/application/controller/data/ResourceController.java`
```java
@PostMapping("saveorupdateresource")
public ResponseEntity<String> saveorupdateresource(
    @RequestBody DataResourceReq req,
    @RequestHeader("userId") Long userId
)
```

## 🎓 经验总结

1. **API路径**: 需要 `/data/` 前缀, 不是 `/resource/`
2. **字段类型**: 使用大写 (String, Integer, Double)
3. **Boolean值**: 在请求中使用整数(0/1), API返回时是boolean
4. **认证**: timestamp/nonce/token需要同时在URL和Body中
5. **文件上传**: 必须包含fileSource参数
6. **FileId位置**: 在 `result.sysFile.fileId`, 不是 `result.fileId`

## 🚀 下一步

1. ✅ 文件上传功能已完成并测试
2. ⚠️ 资源创建需要通过Web界面
3. 📌 建议在Web界面创建第一个资源后，抓取实际的API请求
4. 🔍 可能需要后端日志来诊断"请求异常"的具体原因

## 📞 联系支持

如需进一步协助，请提供:
1. 后端application日志 (docker logs application2)
2. 数据库错误日志
3. 网络抓包 (Chrome DevTools)
4. 系统版本信息
