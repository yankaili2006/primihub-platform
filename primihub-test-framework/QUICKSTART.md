# 快速开始指南

本指南帮助您快速上手使用PrimiHub测试框架。

## 当前可用功能

已完成核心功能，可以立即使用：

- ✅ 完整的目录结构
- ✅ 数据库初始化系统
- ✅ Python API客户端
- ✅ 测试报告生成器
- ✅ 测试运行器框架
- ✅ 配置文件模板

## 5分钟快速上手

### 步骤1：安装依赖

```bash
cd ~/primihub-platform/primihub-test-framework
pip3 install -r requirements.txt
```

### 步骤2：准备SQL文件

将现有SQL文件复制到framework目录：

```bash
# 进入现有SQL脚本目录
cd ~/primihub-platform/primihub-service/script

# 复制schema文件
cp ddl.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/01_core_tables.sql
cp whitelist.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/02_whitelist.sql
cp tenant.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/03_tenant.sql
cp log_management.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/04_log_management.sql
cp node_management_enhancement.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/05_node_management.sql
cp data_requirement.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/06_data_requirement.sql

# 复制权限文件
cd ~/primihub-platform
cp init_permissions.sql ~/primihub-platform/primihub-test-framework/init/sql/permissions/01_init_permissions.sql
```

### 步骤3：配置数据库连接

编辑 `init/config/env.conf`：

```bash
cd ~/primihub-platform/primihub-test-framework
vim init/config/env.conf
```

修改以下配置：
```bash
DB_HOST=localhost
DB_PORT=3306
DB_NAME=privacy
DB_USER=root
DB_PASSWORD=primihub@123  # 改为实际密码
```

### 步骤4：初始化数据库

```bash
cd ~/primihub-platform/primihub-test-framework/init
./modules/03_db_init.sh
```

如果成功，您将看到：
```
[INFO] 数据库连接成功
[INFO] 开始备份数据库...
[INFO] 执行 schema 目录下的SQL文件...
[SUCCESS] 数据库初始化完成
```

### 步骤5：测试API客户端

编辑测试配置：
```bash
vim tests/config/test_config.yml
```

修改API基础URL和数据库密码：
```yaml
api:
  base_url: http://localhost:8080

database:
  password: "primihub@123"  # 改为实际密码
```

运行API客户端示例：
```bash
cd ~/primihub-platform/primihub-test-framework/tests
python3 lib/api_client.py
```

如果服务正常运行，您将看到登录成功的响应。

## 使用场景

### 场景1：重新初始化数据库

```bash
cd ~/primihub-platform/primihub-test-framework/init
./modules/03_db_init.sh
```

这将：
1. 备份现有数据库
2. 执行所有schema SQL
3. 执行权限初始化SQL
4. 验证表结构

### 场景2：编写自定义测试

创建测试脚本：

```bash
cd ~/primihub-platform/primihub-test-framework/tests/suites/01_user_management
vim my_test.py
```

使用API客户端：

```python
#!/usr/bin/env python3
import sys
sys.path.append('../../lib')

from api_client import PrimiHubAPIClient

client = PrimiHubAPIClient("http://localhost:8080")

# 登录
response = client.login("admin", "Admin@123456")
print("Login:", response)

# 获取用户列表
users = client.get_user_list()
print("Users:", users)

# 登出
client.logout()
```

运行测试：
```bash
python3 my_test.py
```

### 场景3：生成测试报告

创建报告脚本：

```bash
cd ~/primihub-platform/primihub-test-framework/tests
vim generate_report.py
```

```python
#!/usr/bin/env python3
import sys
sys.path.append('./lib')

from report_generator import TestReport

report = TestReport()

# 添加测试结果
report.add_test_result("用户管理", "test_login", "passed", 0.5)
report.add_test_result("用户管理", "test_create_user", "passed", 0.8)
report.add_test_result("数据管理", "test_upload", "failed", 1.2,
                      error_msg="文件过大")

# 生成HTML报告
report.generate_html_report("./reports/my_report.html")
print("报告已生成")
```

运行：
```bash
python3 generate_report.py
# 然后用浏览器打开 reports/my_report.html
```

## 下一步

### 完善系统

1. **添加环境检查模块** (`init/modules/01_env_check.sh`)
2. **添加服务检查模块** (`init/modules/02_service_check.sh`)
3. **创建测试数据SQL** (`init/sql/seed/*.sql`)
4. **编写测试用例** (在各个suites目录下)

### 示例：添加简单的环境检查

创建 `init/modules/01_env_check.sh`：

```bash
#!/bin/bash
echo "[INFO] 检查Python版本..."
python3 --version

echo "[INFO] 检查MySQL客户端..."
mysql --version

echo "[INFO] 环境检查完成"
```

添加执行权限并运行：
```bash
chmod +x init/modules/01_env_check.sh
./init/modules/01_env_check.sh
```

### 示例：创建测试数据SQL

创建 `init/sql/seed/01_test_users.sql`：

```sql
-- 测试用户
INSERT INTO sys_user (user_account, user_name, user_password, user_phone, user_email, create_date, is_del)
VALUES
  ('test_user1', '测试用户1', MD5('Test@123456'), '13800138001', 'test1@example.com', NOW(), 0),
  ('test_user2', '测试用户2', MD5('Test@123456'), '13800138002', 'test2@example.com', NOW(), 0)
ON DUPLICATE KEY UPDATE update_date = NOW();
```

## 故障排除

### Q: 数据库连接失败

A: 检查配置文件中的数据库信息是否正确：
```bash
mysql -hlocalhost -P3306 -uroot -pprimihub@123 -e "SELECT 1"
```

### Q: SQL执行失败

A: 查看日志文件：
```bash
cat ~/primihub-platform/primihub-test-framework/logs/db_init_*.log
```

### Q: Python模块导入失败

A: 确保依赖已安装：
```bash
pip3 install -r requirements.txt
```

### Q: API调用失败

A: 检查服务是否运行：
```bash
curl http://localhost:8080/test/healthConnection
```

## 获取帮助

- 查看完整README: `cat README.md`
- 查看脚本帮助: `./init/main_init.sh --help`
- 查看测试帮助: `./tests/run_tests.sh --help`

## 项目结构速查

```
primihub-test-framework/
├── init/
│   ├── main_init.sh           ← 主初始化脚本
│   ├── modules/
│   │   └── 03_db_init.sh     ← 数据库初始化
│   ├── sql/
│   │   ├── schema/           ← 放SQL表结构文件
│   │   ├── permissions/      ← 放权限SQL文件
│   │   └── seed/             ← 放测试数据SQL文件
│   └── config/
│       └── env.conf          ← 环境配置
└── tests/
    ├── run_tests.sh          ← 测试运行器
    ├── lib/
    │   ├── api_client.py     ← API客户端
    │   └── report_generator.py ← 报告生成器
    ├── suites/               ← 测试用例目录
    ├── config/
    │   └── test_config.yml   ← 测试配置
    └── reports/              ← 测试报告输出
```

祝您使用愉快！
