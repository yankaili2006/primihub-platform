# 📚 测试工具使用索引

## 🎯 快速选择

根据你的需求选择合适的工具：

### 我想...

| 需求 | 使用工具 | 文档 |
|------|---------|------|
| **快速测试联邦学习流程** | `test_with_token.py` | [快速开始.md](快速开始.md) |
| **了解如何获取Token** | - | [获取Token指南.md](获取Token指南.md) |
| **查看所有API功能** | `api_example.py --help` | [API参考](#api参考) |
| **演示API调用** | `api_example.py` | [快速开始.md](快速开始.md) |
| **完整的测试框架说明** | - | [../测试框架使用说明.md](../测试框架使用说明.md) |

## 📂 文件说明

### 测试脚本

```
tests/
├── suites/03_project_task/
│   ├── test_with_token.py          ⭐ 联邦学习完整流程测试（使用Token）
│   └── test_federated_learning_flow.py  联邦学习测试（需要完善登录）
├── api_example.py                  ⭐ API功能演示脚本
└── lib/
    ├── api_client.py              ⭐ Python API客户端
    └── report_generator.py        ⭐ 测试报告生成器
```

### 文档

```
tests/
├── 快速开始.md                    ⭐ 推荐阅读！快速上手指南
├── 获取Token指南.md               📖 详细的Token获取步骤
└── README_测试工具.md             📖 本文档
```

```
primihub-test-framework/
├── README.md                       📖 完整的框架文档
├── QUICKSTART.md                   📖 框架快速开始
└── 测试框架使用说明.md            📖 详细使用说明
```

## 🚀 快速命令

### 1️⃣ 最快上手（3步）

```bash
# Step 1: 进入目录
cd /home/primihub/primihub-platform/primihub-test-framework/tests

# Step 2: 设置Token
vim suites/03_project_task/test_with_token.py
# 修改第20行：USER_TOKEN = "你的token"

# Step 3: 运行测试
python3 suites/03_project_task/test_with_token.py
```

### 2️⃣ 查看API功能

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests
python3 api_example.py --help
```

### 3️⃣ 演示API调用

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests

# 编辑并设置Token
vim api_example.py
# 修改第16行：TOKEN = "你的token"

# 运行演示
python3 api_example.py
```

### 4️⃣ 查看测试报告

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests

# 列出所有报告
ls -lh reports/

# 查看最新的HTML报告
firefox reports/federated_learning_token_*.html
```

## 📊 测试流程图

```
┌─────────────────────────────────────────┐
│  1. 从浏览器获取Token                    │
│     (按F12 → Network → token)           │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  2. 设置Token到测试脚本                  │
│     vim test_with_token.py              │
│     USER_TOKEN = "你的token"            │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  3. 运行测试                            │
│     python3 test_with_token.py          │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  4. 测试自动执行                        │
│     ✅ 验证Token                        │
│     ✅ 获取机构列表                     │
│     ✅ 创建数据资源                     │
│     ✅ 创建联邦学习项目                 │
│     ✅ 查看项目详情                     │
│     ✅ 获取项目列表                     │
│     ✅ 查询任务列表                     │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  5. 生成测试报告                        │
│     HTML  📊 可视化报告                 │
│     JSON  📄 结构化数据                 │
│     MD    📝 文本报告                   │
└─────────────────────────────────────────┘
```

## 🎓 学习路径

### 新手入门

1. 📖 阅读 [快速开始.md](快速开始.md)
2. 🔑 按照 [获取Token指南.md](获取Token指南.md) 获取Token
3. 🏃 运行 `test_with_token.py` 进行第一次测试
4. 📊 查看生成的HTML报告

### 进阶使用

1. 📖 阅读 [../测试框架使用说明.md](../测试框架使用说明.md)
2. 🔍 查看 `api_client.py` 了解API封装
3. ✏️ 修改 `test_with_token.py` 自定义测试数据
4. 📝 编写自己的测试脚本

### 高级定制

1. 📖 阅读完整框架文档 [../README.md](../README.md)
2. 🔧 完善登录认证功能（添加RSA加密）
3. 📝 创建新的测试套件
4. 🚀 集成到CI/CD流程

## 📋 API参考

### 认证相关
```python
client.login(username, password)       # 用户登录（需完善）
client.logout()                         # 用户登出
```

### 用户管理
```python
client.create_user(user_data)           # 创建用户
client.get_user_list(page, page_size)   # 获取用户列表
client.freeze_user(user_id)             # 冻结用户
client.unfreeze_user(user_id)           # 解冻用户
```

### 机构管理
```python
client.create_organ(organ_data)         # 创建机构
client.get_organ_list()                 # 获取机构列表
```

### 资源管理
```python
client.create_resource(resource_data)   # 创建资源
client.get_resource_list(page, size)    # 获取资源列表
```

### 项目管理
```python
client.create_project(project_data)     # 创建项目
client.get_project_list(page, size)     # 获取项目列表
client.get_project_detail(project_id)   # 获取项目详情
```

### 任务管理
```python
client.get_task_list(page, size)        # 获取任务列表
client.get_task_detail(task_id)         # 获取任务详情
```

### 隐私计算
```python
client.create_psi_task(psi_data)        # 创建PSI任务
client.get_psi_task_list(page, size)    # 获取PSI任务列表
client.create_pir_task(pir_data)        # 创建PIR任务
client.get_pir_task_list(page, size)    # 获取PIR任务列表
```

完整API列表：
```bash
python3 api_example.py --help
```

## ❓ 常见问题

### Q: 如何获取Token?
**A:** 查看 [获取Token指南.md](获取Token指南.md)

### Q: Token在哪里设置?
**A:**
- `test_with_token.py` 第20行的 `USER_TOKEN`
- `api_example.py` 第16行的 `TOKEN`

### Q: 测试报告在哪里?
**A:** `reports/` 目录下，文件名包含时间戳

### Q: 如何查看详细日志?
**A:** 修改脚本末尾的日志级别为 `logging.DEBUG`

### Q: 测试失败怎么办?
**A:**
1. 查看HTML报告中的错误信息
2. 检查Token是否有效
3. 确认服务地址是否正确
4. 查看详细日志

## 📞 获取帮助

- 📖 查看文档：`快速开始.md`、`获取Token指南.md`
- 🔍 查看日志：测试运行时的控制台输出
- 📊 查看报告：`reports/` 目录下的HTML报告
- 💻 查看代码：`lib/api_client.py` 中的API实现

---

**开始你的第一次测试吧！** 🚀

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests
python3 suites/03_project_task/test_with_token.py
```
