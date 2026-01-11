# 数据资源API使用文档

## API概述

**接口地址**: `/data/resource/saveorupdateresource`
**请求方法**: POST
**Content-Type**: application/json
**超时时间**: 600秒

## 认证参数

所有请求需要包含以下参数：

### 请求头
- `userId`: 用户ID (必填)

### 请求体中的认证字段
- `timestamp`: 时间戳（毫秒）
- `nonce`: 随机数
- `token`: 访问令牌

## 请求参数

### 必填参数

| 参数名 | 类型 | 说明 |
|--------|------|------|
| resourceName | String | 资源名称（3-20字符） |
| resourceDesc | String | 资源描述（最多200字符） |
| resourceAuthType | Integer | 授权类型：1=公开，2=私有，3=指定机构可见 |
| resourceSource | Integer | 资源来源：1=文件上传，2=数据库连接 |
| tags | Array\<String\> | 标签列表（至少一个标签） |
| fieldList | Array\<Object\> | 字段列表（至少一个字段） |

### 文件类型资源（resourceSource=1）额外参数

| 参数名 | 类型 | 说明 |
|--------|------|------|
| fileId | Long | 文件ID（必填） |

### 数据库类型资源（resourceSource=2）额外参数

需要提供 `dataSource` 对象：

| 参数名 | 类型 | 说明 |
|--------|------|------|
| dataSource.dbType | Integer | 数据库类型：1=MySQL, 2=SQLite, 3=Hive, 4=DM, 5=SqlServer, 6=Oracle |
| dataSource.dbUrl | String | 数据库连接URL（必填） |
| dataSource.dbName | String | 数据库名称（必填） |
| dataSource.dbTableName | String | 表名（必填） |
| dataSource.dbDriver | String | 数据库驱动（MySQL必填） |
| dataSource.dbUsername | String | 用户名（MySQL必填） |
| dataSource.dbPassword | String | 密码（MySQL必填） |

### fieldList 字段结构

每个字段对象包含：

| 参数名 | 类型 | 说明 |
|--------|------|------|
| fieldName | String | 字段名称 |
| fieldAs | String | 字段别名 |
| fieldType | String | 字段类型：String, Integer, Double, Long, Enum, Date |
| fieldDesc | String | 字段描述 |
| relevance | Integer | 是否关键字：0=否，1=是 |
| grouping | Integer | 是否分组：0=否，1=是 |
| protectionStatus | Integer | 保护开关：0=关闭，1=开启 |

## 请求示例

### 1. 文件类型资源

```bash
curl -X POST "http://100.64.0.23:30811/prod-api/data/resource/saveorupdateresource" \
  -H "Content-Type: application/json" \
  -H "userId: 1" \
  -d '{
    "resourceName": "用户数据资源",
    "resourceDesc": "用户基本信息数据",
    "resourceAuthType": 1,
    "resourceSource": 1,
    "tags": ["用户数据", "测试"],
    "fileId": 1,
    "fieldList": [
      {
        "fieldName": "user_id",
        "fieldAs": "用户ID",
        "fieldType": "String",
        "fieldDesc": "用户唯一标识",
        "relevance": 1,
        "grouping": 0,
        "protectionStatus": 0
      },
      {
        "fieldName": "age",
        "fieldAs": "年龄",
        "fieldType": "Integer",
        "fieldDesc": "用户年龄",
        "relevance": 0,
        "grouping": 1,
        "protectionStatus": 0
      }
    ],
    "timestamp": 1768134600000,
    "nonce": 993,
    "token": "YOUR_TOKEN_HERE"
  }'
```

### 2. 数据库类型资源

```bash
curl -X POST "http://100.64.0.23:30811/prod-api/data/resource/saveorupdateresource" \
  -H "Content-Type: application/json" \
  -H "userId: 1" \
  -d '{
    "resourceName": "数据库用户表",
    "resourceDesc": "MySQL用户表数据",
    "resourceAuthType": 1,
    "resourceSource": 2,
    "tags": ["数据库", "用户"],
    "dataSource": {
      "dbType": 1,
      "dbUrl": "jdbc:mysql://mysql:3306/privacy1",
      "dbName": "privacy1",
      "dbTableName": "sys_user",
      "dbDriver": "com.mysql.cj.jdbc.Driver",
      "dbUsername": "root",
      "dbPassword": "root"
    },
    "fieldList": [
      {
        "fieldName": "id",
        "fieldAs": "用户ID",
        "fieldType": "Long",
        "fieldDesc": "用户ID",
        "relevance": 1,
        "grouping": 0,
        "protectionStatus": 0
      },
      {
        "fieldName": "user_name",
        "fieldAs": "用户名",
        "fieldType": "String",
        "fieldDesc": "用户名称",
        "relevance": 0,
        "grouping": 0,
        "protectionStatus": 1
      }
    ],
    "timestamp": 1768134600000,
    "nonce": 993,
    "token": "YOUR_TOKEN_HERE"
  }'
```

## 响应格式

### 成功响应

```json
{
  "code": 0,
  "msg": "请求成功",
  "result": {
    "resourceId": "123",
    "resourceFusionId": "unique-code",
    "resourceName": "用户数据资源",
    "resourceDesc": "用户基本信息数据"
  },
  "extra": null
}
```

### 失败响应

```json
{
  "code": 100,
  "msg": "缺少参数:fieldList",
  "result": null,
  "extra": null
}
```

## 常见错误码

| 错误码 | 错误信息 | 说明 |
|--------|----------|------|
| 100 | 缺少参数:xxx | 缺少必填参数 |
| 1011 | 数据库失败:连接失败 | 数据库连接配置错误 |
| -1 | 请求异常 | 服务器内部错误或gRPC连接失败 |

## 当前已知问题

### 问题: 创建资源时返回"请求异常"（code: -1）

**可能原因**:
1. **Meta服务健康检查失败**: primihub-meta服务状态为unhealthy
2. **gRPC连接问题**: 资源注册到数据集时需要与node服务gRPC通信
3. **Nacos服务发现问题**: 服务注册中心连接不稳定

**排查步骤**:

```bash
# 1. 检查Meta服务状态
docker ps | grep meta

# 2. 查看Meta服务日志
docker logs primihub-meta0 --tail 50

# 3. 检查Node服务状态
docker ps | grep node

# 4. 查看Application日志
docker logs application1 --tail 100 | grep -i "exception\|error"

# 5. 重启Meta服务
docker restart primihub-meta0 primihub-meta1 primihub-meta2

# 6. 重启Application服务
docker restart application1 application2 application3
```

## 查询现有文件

在创建文件类型资源前，可以查询系统中已有的文件：

```bash
# 查询数据库中的文件列表
docker exec mysql mysql -uroot -proot privacy1 -e \
  "SELECT file_id, file_name, file_suffix, file_size FROM sys_file LIMIT 10"
```

## 测试脚本

使用提供的测试脚本快速测试：

```bash
# 执行脚本
chmod +x /tmp/create_resource_api.sh
/tmp/create_resource_api.sh
```

## 相关API

- 查询资源详情: `GET /data/resource/getdataresource?resourceId={id}`
- 删除资源: `GET /data/resource/deldataresource?resourceId={id}`
- 查询派生资源列表: `GET /data/resource/getDerivationResourceList`
- 编辑资源: `POST /data/resource/saveorupdateresource` (带resourceId参数)

## 代码参考

- **Controller**: `/primihub-service/application/src/main/java/com/primihub/application/controller/data/ResourceController.java`
- **Service**: `/primihub-service/biz/src/main/java/com/primihub/biz/service/data/DataResourceService.java`
- **前端API**: `/primihub-webconsole/src/api/resource.js`
- **前端页面**: `/primihub-webconsole/src/views/resource/create.vue`
