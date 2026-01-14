# PIR (隐私信息检索) 功能状态报告

## 调查日期
2026-01-14

## 问题概述
尝试创建PIR（Private Information Retrieval，隐私信息检索）任务时遇到技术障碍。PSI功能正常工作，但PIR功能存在实现问题。

## 技术发现

### 1. PIR端点存在但不可用
- **端点路径**: `/data/pir/pirSubmitTask` (不是 `/pir/pirSubmitTask`)
- **发现方式**: 通过测试确认端点返回500错误而非404，说明端点存在
- **查询端点**: `/data/pir/getPirTaskList` 可正常访问并返回空列表

### 2. 错误详情
```
java.lang.NullPointerException
at com.primihub.biz.service.data.PirService.pirSubmitTask(PirService.java:54)
```

错误发生在资源验证阶段，PIR服务尝试从fusion服务获取资源元数据时返回null。

### 3. 与PSI的对比
| 功能 | PSI | PIR |
|------|-----|-----|
| 端点前缀 | `/data/psi/` | `/data/pir/` |
| 创建任务 | ✅ 正常工作 | ❌ NullPointerException |
| 资源验证 | ✅ 通过 | ❌ 失败 |
| 任务列表查询 | ✅ 可用 | ✅ 可用（但为空） |

### 4. 根本原因
PIR服务调用 `fusionResourceService.getDataResource()` 获取资源详情时返回空结果，导致后续处理失败。这可能是由于：

1. Fusion/Meta服务中缺少PIR所需的资源配置
2. PIR功能在当前版本中未完全实现
3. PIR需要额外的资源注册步骤（与PSI不同）

### 5. 代码分析

**PIR Controller** (`/pir/pirSubmitTask`):
```java
public BaseResultEntity pirSubmitTask(String resourceId, String pirParam, String taskName)
```

**PSI Controller** (`/data/psi/saveDataPsi`):
```java
public BaseResultEntity saveDataPsi(@RequestHeader("userId") Long userId, DataPsiReq req)
```

关键差异：PSI有完整的请求对象 `DataPsiReq`，而PIR只接受简单的字符串参数。

## 尝试过的解决方案

1. ✅ 确认了正确的端点路径 (`/data/pir/` 前缀)
2. ✅ 测试了不同的参数格式（查询参数、JSON body）
3. ✅ 验证了资源ID格式（字符串"3"与PSI相同）
4. ❌ 无法绕过资源验证失败问题

## 建议

### 短期方案
由于PIR功能当前不可用，建议：
1. 使用PSI（隐私集合求交）功能作为替代方案
2. PSI已成功创建3个不同算法的任务：
   - PSI ID 3: DH密钥交换算法
   - PSI ID 4: KKRT不经意传输算法
   - PSI ID 5: BC22全同态加密算法

### 长期方案
1. 检查Fusion/Meta服务的资源配置
2. 确认PIR功能是否需要额外的系统配置
3. 联系PrimiHub技术支持确认PIR功能状态
4. 考虑升级到包含完整PIR支持的版本

## 结论
PIR（实时联邦查询）功能的接口存在但存在实现问题，无法在当前环境中成功创建任务。PSI（批量联邦查询）功能完全正常，可以作为隐私计算的替代方案。

---
**生成时间**: 2026-01-14 08:10:00
**调查工具**: API测试、日志分析、源代码审查
