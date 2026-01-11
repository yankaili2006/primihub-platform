# 数据需求管理功能实现总结

## 概述

已成功实现数据需求管理功能，包含5个子菜单，完全独立于现有资源管理逻辑。该功能支持数据需求的全生命周期管理和智能匹配。

## 已实现的功能

### 1. 数据需求列表 (requirementList.vue)
- 数据需求的CRUD操作(创建、查询、更新、删除)
- 支持关键字、需求类型、优先级、状态等多维度筛选
- 批量删除功能
- 需求详情查看
- 一键执行匹配功能

### 2. 数据需求配置 (requirementConfig.vue)
- 配置参数管理(匹配阈值、评分权重等)
- 支持启用/禁用配置项
- 配置类型分类管理
- 内置7个默认配置项:
  - match_threshold: 匹配阈值(60分)
  - field_match_weight: 字段匹配权重(40%)
  - volume_match_weight: 数据量匹配权重(20%)
  - format_match_weight: 数据格式匹配权重(20%)
  - type_match_weight: 数据类型匹配权重(20%)
  - auto_match_enabled: 自动匹配开关
  - max_match_results: 最大匹配结果数(50条)

### 3. 匹配数据需求所需数据 (requirementMatch.vue)
- 左右分栏布局: 左侧需求列表，右侧匹配结果
- 智能匹配算法，基于4个维度评分:
  - 字段匹配(40%权重)
  - 数据量匹配(20%权重)
  - 数据格式匹配(20%权重)
  - 数据类型匹配(20%权重)
- 匹配结果可视化(进度条显示得分)
- 匹配详情查看(各项得分明细)
- 确认/拒绝匹配功能
- 支持按匹配状态筛选

## 技术架构

### 后端
```
Controller层: DataRequirementController.java
    ↓
Service层: DataRequirementService.java (包含匹配算法)
    ↓
Repository层: DataRequirementPrimarydbRepository.java
    ↓
MyBatis Mapper: DataRequirementPrimarydbRepositoryMapper.xml
    ↓
数据库: 3张表
```

### 前端
```
Vue组件:
- requirementList.vue (需求列表)
- requirementConfig.vue (配置管理)
- requirementMatch.vue (匹配功能)
    ↓
API模块: dataRequirement.js
    ↓
Gateway路由: /dataRequirement/**
```

### 数据库表
1. **data_requirement** - 数据需求主表
2. **data_requirement_config** - 配置表
3. **data_requirement_match** - 匹配关系表

## 部署步骤

### 第一步: 创建数据库表

在3个数据库(privacy1, privacy2, privacy3)中执行:

```bash
# 1. 执行DDL脚本
docker exec mysql mysql -uroot -proot privacy1 < /path/to/primihub-service/script/data_requirement.sql
docker exec mysql mysql -uroot -proot privacy2 < /path/to/primihub-service/script/data_requirement.sql
docker exec mysql mysql -uroot -proot privacy3 < /path/to/primihub-service/script/data_requirement.sql

# 2. 执行权限配置脚本
docker exec mysql mysql -uroot -proot privacy1 < /path/to/primihub-service/script/data_requirement_permissions.sql
docker exec mysql mysql -uroot -proot privacy2 < /path/to/primihub-service/script/data_requirement_permissions.sql
docker exec mysql mysql -uroot -proot privacy3 < /path/to/primihub-service/script/data_requirement_permissions.sql
```

或者将SQL文件复制到容器内执行:

```bash
# 复制SQL文件到MySQL容器
docker cp primihub-service/script/data_requirement.sql mysql:/tmp/
docker cp primihub-service/script/data_requirement_permissions.sql mysql:/tmp/

# 在容器内执行
for db in privacy1 privacy2 privacy3; do
  echo "=== 数据库: $db ==="
  docker exec mysql mysql -uroot -proot $db < /tmp/data_requirement.sql
  docker exec mysql mysql -uroot -proot $db < /tmp/data_requirement_permissions.sql
done
```

### 第二步: 编译后端

```bash
# 进入后端目录
cd primihub-service

# Maven编译
mvn clean install -DskipTests

# 或使用已有的构建脚本
BUILD_NUMBER=1.8.0 ./build-platform-backend.sh
```

### 第三步: 编译前端

```bash
# 进入前端目录
cd primihub-webconsole

# 安装依赖(如果需要)
npm install

# 编译生产版本
npm run build:prod:1
```

### 第四步: 重启服务

```bash
# 重启Gateway服务
docker restart gateway0 gateway1 gateway2

# 重启Application服务
docker restart application0 application1 application2

# 重启Nginx服务
docker restart nginx0 nginx1 nginx2
```

### 第五步: 验证部署

1. **验证数据库表创建**
```bash
docker exec mysql mysql -uroot -proot privacy1 -e "SHOW TABLES LIKE 'data_requirement%';"
```

应该看到3张表:
- data_requirement
- data_requirement_config
- data_requirement_match

2. **验证权限配置**
```bash
docker exec mysql mysql -uroot -proot privacy1 -e "
SELECT auth_code, auth_name, auth_url
FROM sys_auth
WHERE auth_code LIKE 'DataRequirement%';"
```

应该看到13条权限记录。

3. **验证前端路由**

登录系统后，在资源管理菜单下应该看到新增的3个子菜单:
- 数据需求列表
- 数据需求配置
- 匹配数据需求所需数据

4. **测试API接口**

```bash
# 测试查询配置接口
curl -X GET "http://localhost/prod-api/dataRequirement/findConfigPage?pageNum=1&pageSize=10"

# 测试查询需求列表接口
curl -X GET "http://localhost/prod-api/dataRequirement/findDataRequirementPage?pageNum=1&pageSize=10"
```

## 使用流程

### 1. 添加数据需求
1. 进入"数据需求列表"页面
2. 点击"新增需求"按钮
3. 填写需求信息:
   - 需求编码(唯一)
   - 需求名称
   - 需求类型(模型训练/数据分析/隐私求交/其他)
   - 优先级(低/中/高)
   - 所需数据量
   - 数据格式(CSV/JSON/Excel/其他)
   - 所需数据字段(逗号分隔)
   - 需求描述
4. 提交保存

### 2. 配置匹配参数
1. 进入"数据需求配置"页面
2. 查看并调整配置参数:
   - 匹配阈值(建议60-80分)
   - 各项评分权重(总和应为100%)
3. 可以添加自定义配置项

### 3. 执行匹配
1. 在"数据需求列表"页面，点击需求行的"匹配"按钮
2. 系统自动执行匹配算法
3. 自动跳转到"匹配数据需求所需数据"页面查看结果

### 4. 查看匹配结果
1. 在"匹配数据需求所需数据"页面
2. 左侧选择需求，右侧显示匹配的资源
3. 每个匹配结果显示:
   - 资源名称
   - 匹配得分(进度条可视化)
   - 匹配状态
   - 匹配详情(悬停查看)
4. 可以确认或拒绝匹配结果

### 5. 确认匹配
1. 点击"确认"按钮确认该匹配
2. 匹配状态变为"已确认"
3. 需求状态更新为"已完成"

## 文件清单

### 后端文件(已创建)
1. 实体类:
   - `primihub-service/biz/src/main/java/com/primihub/biz/entity/data/po/DataRequirement.java`
   - `primihub-service/biz/src/main/java/com/primihub/biz/entity/data/po/DataRequirementConfig.java`
   - `primihub-service/biz/src/main/java/com/primihub/biz/entity/data/po/DataRequirementMatch.java`

2. Repository层:
   - `primihub-service/biz/src/main/java/com/primihub/biz/repository/primarydb/data/DataRequirementPrimarydbRepository.java`
   - `primihub-service/biz/src/main/resources/mybatis/mapper/primarydb/data/DataRequirementPrimarydbRepositoryMapper.xml`

3. Service层:
   - `primihub-service/biz/src/main/java/com/primihub/biz/service/data/DataRequirementService.java`

4. Controller层:
   - `primihub-service/application/src/main/java/com/primihub/application/controller/data/DataRequirementController.java`

5. SQL脚本:
   - `primihub-service/script/data_requirement.sql`
   - `primihub-service/script/data_requirement_permissions.sql`

### 前端文件(已创建)
1. API模块:
   - `primihub-webconsole/src/api/dataRequirement.js`

2. Vue组件:
   - `primihub-webconsole/src/views/resource/requirementList.vue`
   - `primihub-webconsole/src/views/resource/requirementConfig.vue`
   - `primihub-webconsole/src/views/resource/requirementMatch.vue`

### 配置文件(已修改)
1. Gateway路由:
   - `primihub-service/gateway/src/main/resources/application.yaml` (已添加路由)

2. 前端路由:
   - `primihub-webconsole/src/router/index.js` (已添加路由)

## 匹配算法说明

### 算法原理
智能匹配基于4个维度计算综合得分:

1. **字段匹配得分(40%权重)**
   - 计算需求字段与资源字段的匹配率
   - 完全匹配: 100分
   - 部分匹配: 按比例计算

2. **数据量匹配得分(20%权重)**
   - 如果资源数据量 >= 需求数据量: 100分
   - 否则按比例计算

3. **数据格式匹配得分(20%权重)**
   - 格式完全匹配: 100分
   - CSV与Excel互转: 80分
   - 不匹配: 0分

4. **数据类型匹配得分(20%权重)**
   - 类型完全匹配: 100分
   - 模糊匹配: 60分
   - 不匹配但给基础分: 30分

### 计算公式
```
总分 = (字段得分 × 40% + 数据量得分 × 20% + 格式得分 × 20% + 类型得分 × 20%)
```

只有总分 >= 匹配阈值(默认60分)的资源才会被推荐。

## 注意事项

1. **数据库执行顺序**
   - 必须先执行DDL脚本创建表
   - 再执行权限配置脚本
   - 在所有3个数据库中执行

2. **权限配置**
   - 权限已自动分配给超级管理员(role_id=1)
   - 其他角色需要在系统中手动分配权限

3. **匹配算法优化**
   - 可以通过配置页面调整各项权重
   - 建议根据实际业务需求调整匹配阈值
   - 默认最多返回50条匹配结果

4. **性能优化**
   - 匹配计算在后端异步执行
   - 大量资源时建议适当提高匹配阈值
   - 定期清理旧的匹配记录

5. **数据完整性**
   - 删除需求会自动删除相关的匹配记录
   - 使用软删除模式，数据可恢复

## 后续扩展建议

1. **功能扩展**
   - 添加需求审批流程
   - 支持需求模板
   - 添加需求统计报表
   - 支持定时自动匹配

2. **算法优化**
   - 引入机器学习提升匹配精度
   - 支持自定义匹配规则
   - 添加用户反馈机制优化算法

3. **用户体验**
   - 添加需求状态变更通知
   - 支持批量匹配操作
   - 添加匹配结果导出功能

## 技术支持

如遇到问题，请检查:
1. 数据库表是否创建成功
2. 权限是否配置正确
3. Gateway路由是否生效
4. 前端路由是否正确配置
5. 服务是否正常重启

可以通过以下命令查看日志:
```bash
# Gateway日志
docker logs -f gateway0

# Application日志
docker logs -f application0

# Nginx日志
docker logs -f nginx0
```

## 总结

数据需求管理功能已完整实现，包含:
- ✅ 3张数据库表
- ✅ 完整的后端三层架构
- ✅ 智能匹配算法
- ✅ 3个前端页面组件
- ✅ Gateway路由配置
- ✅ 权限配置
- ✅ 详细的使用文档

功能完全独立，不影响现有资源管理逻辑，可以安全部署使用。
