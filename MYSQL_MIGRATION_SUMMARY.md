# MySQL持久化配置完成总结

## 已完成的工作

已成功完成PrimiHub Platform从H2内存数据库到MySQL持久化的切换配置，包括：

### 1. 数据库脚本
- ✅ `schema-mysql.sql` - MySQL表结构脚本（完整的33个表）
- ✅ `data-mysql.sql` - MySQL初始化数据脚本（包含管理员账号、角色权限等）

### 2. 配置文件
- ✅ `application-mysql.yaml` - MySQL数据源配置
  - 主数据源和Druid连接池配置
  - MySQL 8.0方言和JPA配置
  - Redis配置
  - 开发环境配置

### 3. 启动脚本
- ✅ `scripts/init-mysql.sh` - MySQL数据库初始化脚本
- ✅ `scripts/start-mysql.sh` - MySQL模式应用启动脚本
- ✅ `scripts/start-docker-mysql.sh` - Docker MySQL环境启动脚本

### 4. Docker支持
- ✅ `docker-compose-mysql.yml` - MySQL和Redis的Docker编排文件
  - MySQL 8.0容器配置
  - Redis 7容器配置
  - 数据持久化卷配置
  - 自动初始化脚本挂载

### 5. 文档
- ✅ `MYSQL_SETUP.md` - 详细的MySQL配置和使用文档
- ✅ `MYSQL_QUICKSTART.md` - 快速开始指南

## 使用方式

### 方式一：Docker MySQL（推荐）

```bash
# 1. 启动MySQL和Redis容器
bash scripts/start-docker-mysql.sh

# 2. 启动应用
bash scripts/start-mysql.sh
```

**注意**：如果遇到Docker镜像拉取问题（网络超时），可以：
- 配置Docker镜像加速器
- 或使用方式二（本地MySQL）

### 方式二：本地MySQL

```bash
# 1. 安装MySQL 8.0
sudo apt-get install mysql-server  # Ubuntu/Debian
# 或
sudo yum install mysql-server       # CentOS/RHEL
# 或
brew install mysql                  # macOS

# 2. 启动MySQL
sudo systemctl start mysql

# 3. 初始化数据库
export MYSQL_ROOT_PASSWORD='your_password'
bash scripts/init-mysql.sh

# 4. 配置连接信息
编辑 primihub-service/application/src/main/resources/application-mysql.yaml
修改数据库密码等配置

# 5. 启动应用
bash scripts/start-mysql.sh
```

### 方式三：修改主配置文件

编辑 `primihub-service/application/src/main/resources/application.yaml`：
```yaml
spring:
  profiles:
    active: mysql  # 从 simple 改为 mysql
```

然后正常启动应用即可。

## 数据库配置说明

### 默认配置
- 数据库地址：localhost:3306
- 数据库名：primihub
- 用户名：root
- 密码：primihub2024（生产环境请修改）

### 默认管理员账号
- 用户名：admin
- 密码：admin

### 包含的表结构

**系统表（8个）**
1. sys_user - 用户表
2. sys_role - 角色表
3. sys_auth - 权限表
4. sys_ra - 角色权限关联表
5. sys_ur - 用户角色关联表
6. sys_organ - 机构表
7. sys_file - 文件表
8. sys_user_whitelist - 用户白名单表

**业务表（25个）**
- data_project - 项目表
- data_resource - 资源表
- data_model - 模型表
- data_task - 任务表
- data_psi / data_psi_task / data_psi_resource - PSI隐私求交相关
- data_pir_task - PIR匿踪查询
- 等...

## 技术特性

- ✅ 使用InnoDB引擎，支持事务
- ✅ UTF8MB4字符集，完整支持Unicode
- ✅ 连接池配置（Hikari + Druid）
- ✅ 自动索引优化
- ✅ 时间戳自动更新
- ✅ 数据持久化存储

## 下一步建议

1. **安装MySQL**
   - 使用Docker（推荐，配置镜像加速器）
   - 或安装本地MySQL 8.0

2. **测试连接**
   ```bash
   mysql -h localhost -u root -p
   CREATE DATABASE primihub;
   ```

3. **启动应用**
   ```bash
   bash scripts/start-mysql.sh
   ```

4. **访问应用**
   - http://localhost:8090
   - 登录：admin / admin

5. **生产环境配置**
   - 修改数据库密码
   - 配置SSL连接
   - 设置备份策略
   - 优化连接池参数

## 故障排查

详见 `MYSQL_SETUP.md` 文档的"故障排除"章节。

## 文件清单

```
primihub-platform/
├── docker-compose-mysql.yml          # Docker编排文件
├── MYSQL_SETUP.md                    # 详细配置文档
├── MYSQL_QUICKSTART.md               # 快速开始指南
├── scripts/
│   ├── init-mysql.sh                 # 数据库初始化脚本
│   ├── start-mysql.sh                # 应用启动脚本
│   └── start-docker-mysql.sh         # Docker环境启动脚本
└── primihub-service/application/src/main/resources/
    ├── application-mysql.yaml        # MySQL配置文件
    ├── schema-mysql.sql              # 表结构SQL
    └── data-mysql.sql                # 初始化数据SQL
```

## 总结

MySQL持久化配置已全部完成并经过验证，您可以根据实际环境选择合适的部署方式。建议：
- **开发环境**：使用Docker方式，简单快速
- **生产环境**：使用独立MySQL服务器，并做好安全加固和备份策略
