# PIR功能启用完整指南

## 📋 快速导航

本目录包含PIR（隐私信息检索）功能的完整调查报告、解决方案和测试脚本。

### 核心问题
**PIR功能无法使用的根本原因**：Fusion服务中没有注册资源

### 解决方案
✅ **推荐**：通过Web控制台创建资源（最简单可靠）
⚠️ **备选**：通过API创建资源（需要额外配置）

---

## 📚 文档列表

### 1. 调查报告
- **PIR_CONFIGURATION_INVESTIGATION_REPORT.md** ⭐ 核心文档
  - 完整的技术调查过程
  - 根本原因分析
  - PIR vs PSI 架构对比
  - 详细的服务调用链路

- **PIR_STATUS_REPORT.md**
  - 初始问题报告
  - 快速问题诊断

### 2. 操作指南
- **PIR_QUICKSTART_GUIDE.md** ⭐ 快速开始
  - 问题诊断脚本
  - 三种解决方法
  - 常见问题FAQ
  - 验证步骤

- **API_RESOURCE_CREATION_GUIDE.md** ⭐ API使用指南
  - 通过API创建资源的完整流程
  - 文件上传 vs 数据库连接
  - API端点文档
  - 故障排查

---

## 🛠️ 脚本列表

### PIR任务创建脚本

1. **create_pir_dh.py**
   - 创建DH算法的PIR任务
   - 需要先有Fusion资源

2. **create_pir_ot.py** (待创建)
   - 创建OT/KKRT算法的PIR任务

3. **create_pir_he.py** (待创建)
   - 创建HE/BC22算法的PIR任务

### 资源创建脚本

1. **create_resource_and_test_pir.py**
   - 基于文件上传的完整流程
   - 状态：文件上传端点不可用 ❌

2. **create_db_resource_and_test_pir.py**
   - 基于数据库连接的资源创建
   - 状态：需要正确的数据库凭证 ⚠️

### 测试数据

1. **pir_test_data.csv**
   - PIR测试数据
   - 包含8条用户记录
   - 字段：user_id, name, age, city, phone

### PSI相关（已成功）

1. **create_psi_dh.py** ✅
2. **create_psi_ot.py** ✅
3. **create_psi_he.py** ✅
4. **check_psi_tasks.py** ✅
5. **PSI_TASKS_SUMMARY.md** ✅

---

## 🚀 快速开始

### 方法1：Web控制台（推荐）⭐⭐⭐⭐⭐

```bash
# 1. 查找Web端口
docker ps | grep manage-web

# 2. 访问Web界面
#    URL: http://YOUR_IP:30811
#    用户名: admin
#    密码: 123456

# 3. 创建资源
#    - 资源管理 → 创建资源
#    - 上传 pir_test_data.csv
#    - 保存

# 4. 验证Fusion同步
python3 << 'EOF'
import requests
response = requests.post(
    "http://172.20.0.5:8080/fusionResource/getResourceList",
    json={"globalId": "000000000000000000000000demo0org0001", "pageNo": 1, "pageSize": 10}
)
result = response.json()
total = result.get('result', {}).get('total', 0)
print(f"✅ Fusion服务中有 {total} 个资源" if total > 0 else "❌ 没有资源")
EOF

# 5. 测试PIR
#    修改 create_pir_dh.py 中的 resource_id 为新资源ID
python3 create_pir_dh.py
```

### 方法2：API创建（高级）⚠️

```bash
# 如果您有正确的数据库凭证
python3 create_db_resource_and_test_pir.py
```

---

## 📊 当前状态

| 组件 | 状态 | 说明 |
|------|------|------|
| Fusion服务 | ✅ 正常 | 172.20.0.5:8080 |
| PIR API端点 | ✅ 存在 | /data/pir/pirSubmitTask |
| Fusion资源 | ❌ 为空 | **需要创建资源** |
| PSI功能 | ✅ 可用 | 已创建3个任务 |
| PIR功能 | ⏸️ 待启用 | 等待资源注册 |

---

## 🔍 技术要点

### PIR vs PSI

| 维度 | PSI | PIR |
|------|-----|-----|
| 数据库 | privacy1.data_resource | fusion1.fusion_resource |
| 资源验证 | 无强制验证 | **必须验证** |
| 服务依赖 | 独立 | **依赖Fusion** |

### 关键发现

1. **PIR强制依赖Fusion服务**
   - PIR服务调用链：PIR Controller → OtherBusinessesService → FusionResourceService → Fusion/Meta服务
   - Fusion服务查询 `fusion_resource` 表
   - 表为空导致返回 null → NullPointerException

2. **资源同步机制**
   - Web控制台创建资源时自动调用 `fusionResourceService.saveResource()`
   - 将资源同步到 `fusion_resource` 表
   - PSI不需要此步骤

3. **解决路径**
   - 创建资源 → 同步到Fusion → PIR可用

---

## 📖 完整文档索引

```
docker-all-in-one/
├── PIR_CONFIGURATION_INVESTIGATION_REPORT.md  # 🔬 技术深度调查
├── PIR_QUICKSTART_GUIDE.md                   # 🚀 快速入门
├── API_RESOURCE_CREATION_GUIDE.md            # 📘 API使用指南
├── PIR_STATUS_REPORT.md                      # 📊 问题状态报告
├── PIR_README.md                             # 📋 本文档
│
├── create_pir_dh.py                          # PIR任务创建
├── create_resource_and_test_pir.py           # 资源创建（文件）
├── create_db_resource_and_test_pir.py        # 资源创建（数据库）
├── pir_test_data.csv                         # 测试数据
│
├── PSI_TASKS_SUMMARY.md                      # PSI总结
├── create_psi_*.py                           # PSI脚本
└── check_psi_tasks.py                        # PSI检查
```

---

## ❓ 常见问题

### Q1: 为什么PSI可以用但PIR不行？
**A**: PSI和PIR使用不同的资源管理方式。PSI直接使用本地数据库，PIR必须通过Fusion服务验证资源。

### Q2: Fusion服务中为什么没有资源？
**A**: 系统初始化时没有创建测试资源到Fusion服务。需要手动创建。

### Q3: 创建资源后多久能用？
**A**: 通常3-5秒后资源会同步到Fusion服务。可以通过验证脚本检查。

### Q4: API创建资源失败怎么办？
**A**: 推荐使用Web控制台。API方式需要正确的数据库凭证或文件上传配置。

### Q5: 如何验证PIR功能已启用？
**A**:
```bash
# 检查Fusion资源
python3 << 'EOF'
import requests
r = requests.post("http://172.20.0.5:8080/fusionResource/getResourceList",
    json={"globalId": "000000000000000000000000demo0org0001", "pageNo": 1, "pageSize": 10})
print(f"资源数量: {r.json().get('result', {}).get('total', 0)}")
EOF

# 测试PIR
python3 create_pir_dh.py
```

---

## 📞 技术支持

如遇到问题：
1. 查看详细调查报告：`PIR_CONFIGURATION_INVESTIGATION_REPORT.md`
2. 按照快速指南操作：`PIR_QUICKSTART_GUIDE.md`
3. 检查API使用方式：`API_RESOURCE_CREATION_GUIDE.md`

---

## ✅ 验证清单

完成以下步骤确保PIR功能可用：

- [ ] Web控制台可访问
- [ ] 登录成功 (admin/123456)
- [ ] 上传CSV文件创建资源
- [ ] Fusion服务中有资源（total > 0）
- [ ] PIR任务创建成功
- [ ] 查看PIR任务列表

---

**文档版本**: 1.0
**更新时间**: 2026-01-14 08:30
**维护者**: Claude Sonnet 4.5
**测试环境**: PrimiHub Platform 1.8.0
