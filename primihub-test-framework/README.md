# PrimiHub 测试框架

PrimiHub平台的初始化系统和自动化测试框架，提供完整的数据库初始化、测试数据生成和自动化测试功能。

## 项目概述

本框架提供：
- **初始化系统**: 一键初始化PrimiHub数据库和测试环境
- **自动化测试**: 覆盖用户管理、数据管理、项目任务、隐私计算等核心功能
- **测试报告**: 支持HTML、JSON、Markdown多种格式的测试报告
- **模块化设计**: 可独立运行特定模块的测试

## 目录结构

```
primihub-test-framework/
├── init/                           # 初始化脚本
│   ├── main_init.sh               # 主初始化脚本 ⭐
│   ├── modules/                    # 初始化模块
│   │   ├── 01_env_check.sh        # 环境检查
│   │   ├── 02_service_check.sh    # 服务检查
│   │   ├── 03_db_init.sh          # 数据库初始化 ⭐
│   │   ├── 04_data_seed.sh        # 测试数据初始化
│   │   └── 05_health_check.sh     # 健康检查
│   ├── sql/                        # SQL脚本
│   │   ├── schema/                 # 表结构SQL
│   │   ├── permissions/            # 权限数据SQL
│   │   └── seed/                   # 测试数据SQL
│   └── config/
│       └── env.conf                # 环境配置 ⭐
├── tests/                          # 测试脚本
│   ├── run_tests.sh               # 主测试运行器 ⭐
│   ├── lib/                        # 共享库
│   │   ├── api_client.py          # Python API客户端 ⭐
│   │   ├── report_generator.py    # 报告生成器 ⭐
│   │   ├── db_helper.py           # 数据库工具
│   │   └── test_utils.py          # 测试工具
│   ├── suites/                     # 测试套件
│   │   ├── 01_user_management/    # 用户管理测试
│   │   ├── 02_data_management/    # 数据管理测试
│   │   ├── 03_project_task/       # 项目任务测试
│   │   ├── 04_privacy_computing/  # 隐私计算测试
│   │   └── 05_system_features/    # 系统功能测试
│   ├── performance/                # 性能测试
│   ├── config/
│   │   └── test_config.yml        # 测试配置 ⭐
│   └── reports/                    # 测试报告目录
├── docs/                           # 文档
├── requirements.txt                # Python依赖 ⭐
└── README.md                       # 本文件
```

## 快速开始

### 前置条件

- Linux/macOS系统
- Bash 4.0+
- Python 3.6+
- MySQL 5.7+
- 已部署的PrimiHub服务（Gateway, Application等）

### 1. 安装Python依赖

```bash
cd ~/primihub-platform/primihub-test-framework
pip3 install -r requirements.txt
```

### 2. 配置环境

编辑配置文件 `init/config/env.conf`，根据实际环境修改：

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=privacy
DB_USER=root
DB_PASSWORD=your_password

# Gateway服务
GATEWAY_HOST=localhost
GATEWAY_PORT=8080
```

编辑测试配置 `tests/config/test_config.yml`：

```yaml
api:
  base_url: http://localhost:8080

database:
  host: localhost
  password: "your_password"
```

### 3. 初始化数据库

```bash
cd init

# 全量初始化（推荐首次使用）
./main_init.sh --with-test-data

# 仅初始化数据库结构
./main_init.sh --only-db

# 清除现有数据并重新初始化（谨慎使用）
./main_init.sh --clean --with-test-data
```

### 4. 运行测试

```bash
cd ../tests

# 给测试脚本添加执行权限
chmod +x run_tests.sh

# 运行所有测试
./run_tests.sh --all

# 运行特定模块测试
./run_tests.sh --suite user_management

# 生成HTML报告
./run_tests.sh --all --report-format html
```

## 详细使用说明

### 初始化系统

#### 主初始化脚本

`init/main_init.sh` 是初始化系统的入口，支持多种选项：

```bash
# 显示帮助
./main_init.sh --help

# 跳过环境检查
./main_init.sh --skip-env-check

# 跳过服务检查
./main_init.sh --skip-service-check

# 仅初始化数据库
./main_init.sh --only-db

# 包含测试数据
./main_init.sh --with-test-data

# 清除现有数据
./main_init.sh --clean
```

#### 数据库初始化模块

`init/modules/03_db_init.sh` 负责数据库初始化，包括：

1. 检查数据库连接
2. 备份现有数据库（可选）
3. 创建/重置数据库
4. 执行schema SQL文件
5. 执行权限数据SQL文件
6. 验证表结构完整性

可独立运行：
```bash
cd init/modules
./03_db_init.sh
```

### 测试系统

#### Python API客户端

`tests/lib/api_client.py` 提供完整的API调用封装：

```python
from lib.api_client import PrimiHubAPIClient

# 创建客户端
client = PrimiHubAPIClient("http://localhost:8080")

# 登录
response = client.login("admin", "Admin@123456")

# 创建用户
user_data = {
    "userAccount": "test_user",
    "userName": "Test User",
    "userPassword": "Test@123456",
    "userPhone": "13800138000",
    "userEmail": "test@example.com"
}
result = client.create_user(user_data)

# 获取用户列表
users = client.get_user_list(page=1, page_size=10)

# 登出
client.logout()
```

#### 测试报告生成

`tests/lib/report_generator.py` 支持生成多种格式的报告：

```python
from lib.report_generator import TestReport

# 创建报告对象
report = TestReport()

# 添加测试结果
report.add_test_result("用户管理", "test_user_login", "passed", 0.5)
report.add_test_result("数据管理", "test_resource_upload", "failed", 1.2,
                      error_msg="连接超时")

# 生成报告
report.generate_html_report("./reports/test_report.html")
report.generate_json_report("./reports/test_report.json")
report.generate_markdown_report("./reports/test_report.md")

# 打印摘要
report.print_summary()
```

#### 测试运行器

`tests/run_tests.sh` 提供灵活的测试执行选项：

```bash
# 运行所有测试
./run_tests.sh --all

# 运行特定测试套件
./run_tests.sh --suite user_management     # 用户管理
./run_tests.sh --suite data_management     # 数据管理
./run_tests.sh --suite project_task        # 项目任务
./run_tests.sh --suite privacy_computing   # 隐私计算
./run_tests.sh --suite system_features     # 系统功能

# 运行特定类型测试
./run_tests.sh --type api                  # 仅API测试
./run_tests.sh --type flow                 # 仅业务流程测试

# 性能测试
./run_tests.sh --performance

# 生成不同格式报告
./run_tests.sh --all --report-format html
./run_tests.sh --all --report-format json
./run_tests.sh --all --report-format markdown

# 详细输出
./run_tests.sh --all --verbose
```

## SQL文件组织

### Schema SQL

需要将现有的SQL文件复制到 `init/sql/schema/` 目录：

```bash
cd ~/primihub-platform/primihub-service/script

# 复制核心表结构
cp ddl.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/01_core_tables.sql
cp whitelist.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/02_whitelist.sql
cp tenant.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/03_tenant.sql
cp log_management.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/04_log_management.sql
cp node_management_enhancement.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/05_node_management.sql
cp data_requirement.sql ~/primihub-platform/primihub-test-framework/init/sql/schema/06_data_requirement.sql
```

### 权限SQL

```bash
# 复制权限SQL
cd ~/primihub-platform
cp init_permissions.sql ~/primihub-platform/primihub-test-framework/init/sql/permissions/01_init_permissions.sql
```

### 测试数据SQL

创建测试数据SQL文件（示例见 `init/sql/seed/` 目录）。

## 当前状态和后续工作

### 已完成 ✅

1. ✅ 完整的目录结构
2. ✅ 环境配置文件 (`env.conf`, `test_config.yml`)
3. ✅ Python依赖配置 (`requirements.txt`)
4. ✅ 主初始化脚本 (`main_init.sh`)
5. ✅ 数据库初始化模块 (`03_db_init.sh`)
6. ✅ Python API客户端 (`api_client.py`)
7. ✅ 测试报告生成器 (`report_generator.py`)
8. ✅ 主测试运行器 (`run_tests.sh`)

### 待完成 📋

1. ⏳ 其他初始化模块（env_check, service_check, data_seed, health_check）
2. ⏳ 组织SQL文件（从现有脚本复制）
3. ⏳ 测试辅助库（db_helper.py, test_utils.py, api_client.sh）
4. ⏳ 各模块测试套件（用户、数据、项目、隐私计算、系统）
5. ⏳ 性能测试脚本
6. ⏳ 详细文档（INIT_GUIDE.md, TEST_GUIDE.md, API_REFERENCE.md）

### 快速开始使用

即使某些功能还未完全实现，核心功能已经可用：

```bash
# 1. 安装依赖
cd ~/primihub-platform/primihub-test-framework
pip3 install -r requirements.txt

# 2. 复制SQL文件到相应目录
# (参考上面的SQL文件组织部分)

# 3. 修改配置
vim init/config/env.conf
vim tests/config/test_config.yml

# 4. 初始化数据库
cd init
chmod +x main_init.sh modules/*.sh
./modules/03_db_init.sh  # 直接运行数据库初始化

# 5. 测试API客户端
cd ../tests
python3 lib/api_client.py  # 运行示例代码
```

## 贡献指南

欢迎贡献新的测试用例和改进！

### 添加新测试套件

1. 在 `tests/suites/` 下创建新目录
2. 添加测试脚本（Shell或Python）
3. 更新 `run_tests.sh` 中的测试套件列表

### 添加新的API方法

1. 在 `tests/lib/api_client.py` 中添加新方法
2. 遵循现有的命名和文档规范
3. 添加对应的测试用例

## 故障排除

### 数据库连接失败

检查配置文件中的数据库连接信息：
```bash
mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "SELECT 1"
```

### Python依赖安装失败

使用国内镜像加速：
```bash
pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### API调用失败

检查服务是否运行：
```bash
curl http://localhost:8080/test/healthConnection
```

## 许可证

本项目遵循PrimiHub项目的许可证。

## 联系方式

如有问题，请联系PrimiHub团队或提交Issue。
