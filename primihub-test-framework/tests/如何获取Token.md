# 如何获取Token

## 📌 重要说明

由于PrimiHub的安全设计，`/sys/user/getPubKey` 接口也需要token认证，这导致**无法**直接通过API从零开始获取token（需要token才能获取公钥，需要公钥才能加密密码登录）。

因此，你需要**首次从浏览器获取token**，之后就可以一直使用API了。

---

## 方法1：从浏览器获取Token（推荐）

### 步骤1：登录系统

**Node0:**
- 访问: http://172.20.0.12:8080
- 用户名: `admin`
- 密码: `123456`

**Node1:**
- 访问: http://172.20.0.2:8080
- 用户名: `admin`
- 密码: `123456`

### 步骤2：获取Token

1. **打开开发者工具**
   - 按 `F12` 键
   - 或右键点击页面 → 选择"检查"

2. **切换到Network标签**
   - 点击顶部的 "Network"（网络）标签

3. **刷新页面**
   - 按 `F5` 或点击刷新按钮

4. **找到API请求**
   - 在网络请求列表中，找到任意一个API请求
   - 例如：`getOrganList`、`getResourceList` 等

5. **复制Token**
   - 点击该请求
   - 在右侧找到 "Headers"（请求头）
   - 滚动找到 "Request Headers"
   - 找到 `token` 字段
   - 复制完整的token值

Token示例：
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Mzc1MzQ2MjMsImlhdCI6MTczNzQ0ODIyMywib3JnYW5JZCI6IjAiLCJvcmdhbklkTGlzdCI6WyIwIl0sInVzZXJJZCI6MSwidXNlck5hbWUiOiJhZG1pbiJ9.xxxxxxxxxxxxxxxx
```

### 步骤3：使用Token

将获取的token填入测试脚本：

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests

# 编辑脚本
vim suites/03_project_task/test_with_token.py

# 修改第26行：
USER_TOKEN = "你的token"  # 粘贴刚才复制的token

# 保存并运行
python3 suites/03_project_task/test_with_token.py
```

---

## 方法2：使用已有Token调用API

如果你已经有了一个有效的token，可以直接使用我们的API客户端：

```python
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

from api_client import PrimiHubAPIClient

# 配置
BASE_URL = "http://172.20.0.12:8080"
TOKEN = "你的token"

# 创建客户端
client = PrimiHubAPIClient(BASE_URL)
client.token = TOKEN

# 测试token是否有效
response = client.get_user_list(page=1, page_size=1)
if response.get('code') == 0:
    print("✅ Token有效!")
else:
    print(f"❌ Token无效: {response.get('msg')}")
```

---

## 💡 Token有效期

- Token通常有24小时的有效期
- 如果token过期，会返回错误："token已过期"或"未登录"
- 需要重新登录获取新token

---

## 🔧 常见问题

### Q1: Token在哪个位置？

在请求头（Request Headers）中，字段名为 `token`，注意**不是** Authorization。

### Q2: 如何判断Token是否有效？

运行简单的API调用测试：
```bash
python3 api_example.py
```

### Q3: Token会过期吗？

会的，通常24小时后过期。过期后需要重新从浏览器获取。

### Q4: 可以共享Token吗？

可以，但要注意：
- 不同节点的token不能混用（node0的token不能用于node1）
- Token代表用户身份，不要泄露

---

## 📚 下一步

获取token后，你可以：

1. **运行完整测试流程**
   ```bash
   python3 suites/03_project_task/test_with_token.py
   ```

2. **创建数据资源**
   ```bash
   python3 create_resources_interactive.py
   ```

3. **批量添加资源**
   - 编辑 `add_resources_to_nodes.py`
   - 填入node0和node1的token
   - 运行 `python3 add_resources_to_nodes.py`

4. **查看API功能**
   ```bash
   python3 api_example.py --help
   ```

---

**准备好了吗？现在就去浏览器获取你的第一个Token吧！** 🚀
