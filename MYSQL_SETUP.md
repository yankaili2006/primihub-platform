# PrimiHub Platform MySQL持久化配置指南

## 概述

本文档说明如何将PrimiHub Platform从H2内存数据库切换到MySQL进行持久化存储。

## 前提条件

- MySQL 5.7+ 或 MySQL 8.0+
- Java 8+
- Maven 3.6+

## 快速开始

### 1. 安装MySQL

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
```

#### CentOS/RHEL
```bash
sudo yum install mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld
```

#### macOS
```bash
brew install mysql
brew services start mysql
```

### 2. 初始化数据库

运行数据库初始化脚本：

```bash
# 设置MySQL root密码（如果有）
export MYSQL_ROOT_PASSWORD='your_root_password'

# 初始化数据库
bash scripts/init-mysql.sh
```

或者手动创建数据库：

```bash
mysql -u root -p

CREATE DATABASE primihub DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. 配置数据库连接

编辑 `primihub-service/application/src/main/resources/application-mysql.yaml`，修改数据库连接信息：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/primihub?useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: your_password
```

### 4. 启动应用

#### 方式一：使用启动脚本（推荐）

```bash
# 启动应用（首次启动会自动初始化表结构和数据）
bash scripts/start-mysql.sh

# 如果需要先初始化数据库再启动
bash scripts/start-mysql.sh --init-db
```

#### 方式二：修改主配置文件

编辑 `primihub-service/application/src/main/resources/application.yaml`：

```yaml
spring:
  profiles:
    active: mysql  # 从 simple 改为 mysql
```

然后使用原有方式启动：

```bash
cd primihub-service/application
java -jar target/application-1.0-SNAPSHOT.jar
```

#### 方式三：命令行指定profile

```bash
cd primihub-service/application
java -jar target/application-1.0-SNAPSHOT.jar --spring.profiles.active=mysql
```

## 配置说明

### 数据库连接配置

主要配置位于 `application-mysql.yaml` 文件：

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/primihub?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf8
    username: root
    password: primihub2024
    druid:
      primary:
        url: jdbc:mysql://localhost:3306/primihub?...
        username: root
        password: primihub2024
      secondary:
        url: jdbc:mysql://localhost:3306/primihub?...
        username: root
        password: primihub2024
```

### JPA配置

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: none  # 不自动创建表，使用SQL脚本
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
```

### SQL初始化

```yaml
spring:
  sql:
    init:
      mode: always
      schema-locations: classpath:schema-mysql.sql
      data-locations: classpath:data-mysql.sql
```

## 数据库表结构

系统包含以下主要表：

### 系统表
- `sys_user` - 用户表
- `sys_role` - 角色表
- `sys_auth` - 权限表
- `sys_ra` - 角色权限关联表
- `sys_ur` - 用户角色关联表
- `sys_organ` - 机构表
- `sys_user_whitelist` - 用户白名单表

### 业务表
- `data_project` - 项目表
- `data_resource` - 资源表
- `data_model` - 模型表
- `data_task` - 任务表
- `data_psi_task` - PSI任务表
- `data_pir_task` - PIR任务表
- 等...

## 初始数据

系统会自动初始化以下数据：

- 默认管理员账号：`admin` / `admin`
- 系统角色和权限
- 测试项目和资源（可选）

## 故障排除

### 无法连接数据库

```bash
# 检查MySQL服务状态
sudo systemctl status mysql

# 启动MySQL服务
sudo systemctl start mysql

# 测试连接
mysql -u root -p -e "SELECT 1"
```

### 权限问题

```sql
-- 授予权限
GRANT ALL PRIVILEGES ON primihub.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
```

### 字符集问题

确保数据库使用UTF8MB4字符集：

```sql
ALTER DATABASE primihub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 查看初始化日志

应用启动时会显示SQL执行日志，检查是否有错误：

```
Hibernate: CREATE TABLE IF NOT EXISTS sys_user (...)
...
```

## 从H2迁移到MySQL

如果之前使用H2数据库，需要：

1. 备份H2数据（如果需要）
2. 修改 `application.yaml` 中的 `spring.profiles.active` 为 `mysql`
3. 启动应用，系统会自动初始化MySQL数据库

## 性能优化

### 连接池配置

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
    druid:
      primary:
        initial-size: 5
        min-idle: 5
        max-active: 20
```

### 数据库索引

系统已自动创建必要的索引，包括：
- 主键索引
- 唯一索引
- 外键索引

## 生产环境建议

1. **修改默认密码**：修改 `application-mysql.yaml` 中的数据库密码
2. **启用SSL**：在生产环境启用MySQL SSL连接
3. **定期备份**：设置数据库定期备份策略
4. **监控**：配置数据库性能监控
5. **安全**：限制数据库访问权限

## 相关文件

- `primihub-service/application/src/main/resources/application-mysql.yaml` - MySQL配置文件
- `primihub-service/application/src/main/resources/schema-mysql.sql` - 表结构SQL
- `primihub-service/application/src/main/resources/data-mysql.sql` - 初始数据SQL
- `scripts/init-mysql.sh` - 数据库初始化脚本
- `scripts/start-mysql.sh` - MySQL模式启动脚本

## 支持

如有问题，请查看：
- [PrimiHub文档](https://docs.primihub.com)
- [GitHub Issues](https://github.com/primihub/primihub-platform/issues)
