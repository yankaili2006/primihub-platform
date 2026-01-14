# PIR（隐私信息检索）测试工具

本目录包含了PrimiHub平台PIR功能的完整测试工具和文档。

## 📁 文件说明

### 核心测试脚本

1. **create_pir_dh.py**
   - 创建基于DH算法的PIR任务
   - 支持隐私信息检索
   - 保护查询方隐私

2. **create_resource_and_test_pir.py**
   - 自动创建测试资源并执行PIR任务
   - 完整的端到端测试流程

3. **create_db_resource_and_test_pir.py**
   - 基于数据库资源的PIR测试
   - 支持Fusion资源类型

### 文档

- **PIR_README.md** - PIR功能说明
- **PIR_QUICKSTART_GUIDE.md** - 快速开始指南
- **PIR_SUCCESS_SUMMARY.md** - PIR成功案例总结
- **PIR_STATUS_REPORT.md** - PIR状态报告
- **PIR_CONFIGURATION_INVESTIGATION_REPORT.md** - PIR配置调研报告

---

## 🚀 快速开始

### 环境要求

- Python 3.6+
- requests库：`pip3 install requests`
- PrimiHub平台正在运行

### 基本使用

```bash
cd ~/primihub-platform/tests/pir

# 创建DH算法的PIR任务
python3 create_pir_dh.py

# 完整的PIR测试（包含资源创建）
python3 create_resource_and_test_pir.py

# 基于数据库的PIR测试
python3 create_db_resource_and_test_pir.py
```

---

## 📖 什么是PIR

PIR（Private Information Retrieval，隐私信息检索）允许用户从数据库中检索信息，而不向数据库服务器透露查询的具体内容。

### PIR的优势

1. **查询隐私**：服务器不知道用户查询了什么
2. **数据安全**：用户只能获取查询的特定记录
3. **零知识证明**：双方都无法获取额外信息

### 应用场景

- **医疗记录查询**：患者查询病历而不暴露查询内容
- **金融数据检索**：查询交易记录保护隐私
- **位置服务**：查询地理位置信息不泄露用户位置
- **广告匹配**：精准广告推荐但保护用户画像隐私

---

## 🔧 配置说明

### API端点

```python
BASE_URL = "http://172.20.0.6:8080"
```

### 测试资源

PIR任务需要配置：

- **数据提供方**：拥有完整数据集的机构
- **查询方**：需要检索特定信息的机构
- **查询关键字**：用于定位数据的字段

---

## 📝 PIR任务执行流程

```
1. 登录系统
   ↓
2. 创建/验证数据资源
   ↓
3. 创建PIR任务
   ↓
4. 任务执行（隐私检索）
   ↓
5. 获取检索结果
```

---

## 🔍 故障排查

### 问题：资源创建失败

**解决方法**：
1. 检查数据文件格式
2. 验证机构ID和项目ID
3. 确认资源类型配置正确

### 问题：PIR任务执行失败

**解决方法**：
1. 确认查询关键字在数据中存在
2. 检查数据资源的可访问性
3. 验证节点间网络连接

---

## 📚 相关文档

详细信息请参阅：

- [PIR快速开始指南](PIR_QUICKSTART_GUIDE.md)
- [PIR配置说明](PIR_CONFIGURATION_INVESTIGATION_REPORT.md)
- [PIR成功案例](PIR_SUCCESS_SUMMARY.md)

---

**最后更新**: 2026-01-14
**维护者**: PrimiHub Team
