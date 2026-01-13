# 如何获取Token并运行测试

## 方法1：从浏览器开发者工具获取

### 步骤1：登录PrimiHub平台

1. 打开浏览器
2. 访问PrimiHub平台（例如：http://你的IP:端口）
3. 使用admin账户登录

### 步骤2：获取Token

1. **按F12打开开发者工具**（或右键点击 → 检查）

2. **切换到 Network（网络）标签**

3. **刷新页面或执行任意操作**（如点击菜单）

4. **找到任意一个请求**（通常是API请求，如 `getOrganList`）

5. **查看请求头**：
   - 点击该请求
   - 在右侧找到 "Headers"（请求头）标签
   - 向下滚动找到 "Request Headers"（请求头）
   - 找到 `token` 字段
   - 复制token的值

### 步骤3：设置Token并运行测试

1. **编辑测试脚本**：
```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests
vim suites/03_project_task/test_with_token.py
```

2. **找到这一行**（大约在第20行）：
```python
USER_TOKEN = ""  # 在这里填入你的token
```

3. **填入你的token**：
```python
USER_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Mzc1MzQ2MjMsImlhdCI6MTczNzQ0ODIyMywib3JnYW5JZCI6IjAiLCJvcmdhbklkTGlzdCI6WyIwIl0sInVzZXJJZCI6MSwidXNlck5hbWUiOiJhZG1pbiJ9.xxxxxxxxxxxxx"
```

4. **保存并退出**（vim中按 `:wq`）

5. **运行测试**：
```bash
python3 suites/03_project_task/test_with_token.py
```

## 方法2：使用curl快速获取Token

如果你知道admin密码，可以用curl获取token（需要先实现完整登录流程）。

## Token示例

Token通常是一个很长的字符串，类似这样：

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Mzc1MzQ2MjMsImlhdCI6MTczNzQ0ODIyMywib3JnYW5JZCI6IjAiLCJvcmdhbklkTGlzdCI6WyIwIl0sInVzZXJJZCI6MSwidXNlck5hbWUiOiJhZG1pbiJ9.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 测试流程说明

运行测试脚本后，会自动执行以下步骤：

1. ✅ **验证Token有效性** - 确认token可以正常使用
2. ✅ **获取机构列表** - 获取所有可用的合作机构
3. ✅ **创建数据资源** - 模拟两个机构各创建一个数据集
4. ✅ **创建联邦学习项目** - 创建包含两个合作方的项目
5. ✅ **查看项目详情** - 验证项目创建成功
6. ✅ **获取项目列表** - 查看所有项目
7. ✅ **查询任务列表** - 查看相关任务

## 测试报告

测试完成后会生成三种格式的报告：

- **JSON报告**: `federated_learning_token_{时间戳}.json`
- **HTML报告**: `federated_learning_token_{时间戳}.html` ⭐ 推荐
- **Markdown报告**: `federated_learning_token_{时间戳}.md`

报告保存在：`/home/primihub/primihub-platform/primihub-test-framework/tests/reports/`

使用浏览器打开HTML报告可以看到：
- 📊 测试通过率
- ✅ 成功的测试
- ❌ 失败的测试
- ⏱️ 每个测试的耗时
- 📝 详细的错误信息

## 故障排除

### Token验证失败

如果提示"Token验证失败"，可能是：
1. Token已过期 - 重新登录获取新token
2. Token复制不完整 - 确保复制完整的token
3. 服务地址错误 - 检查 `BASE_URL` 是否正确

### 找不到机构

如果提示"机构数量少于2个"，需要先在系统中创建至少2个机构。

### 创建资源失败

检查资源数据格式是否正确，查看错误信息中的详细原因。

## 快速命令

```bash
# 1. 进入测试目录
cd /home/primihub/primihub-platform/primihub-test-framework/tests

# 2. 添加执行权限
chmod +x suites/03_project_task/test_with_token.py

# 3. 编辑并设置token
vim suites/03_project_task/test_with_token.py

# 4. 运行测试
python3 suites/03_project_task/test_with_token.py

# 5. 查看测试报告
ls -lh reports/
```

## 进阶使用

### 自定义测试数据

可以修改脚本中的资源数据：

```python
resources = [
    {
        "resourceName": "我的测试数据",
        "resourceDesc": "自定义描述",
        "resourceRowsCount": 5000,  # 修改行数
        # ... 其他字段
    }
]
```

### 调整测试步骤

可以注释掉不需要的测试步骤：

```python
# self.test_create_resources()  # 跳过创建资源
```

### 开启详细日志

在运行时添加调试参数：

```python
logging.basicConfig(
    level=logging.DEBUG,  # 改为DEBUG
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

---

**祝测试顺利！** 🎉
