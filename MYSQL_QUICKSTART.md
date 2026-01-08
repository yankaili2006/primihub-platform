# PrimiHub Platform - MySQL持久化快速指南

## 方式一：使用Docker（推荐，最简单）

### 1. 启动MySQL和Redis服务
```bash
bash scripts/start-docker-mysql.sh
```

### 2. 启动PrimiHub Platform
```bash
bash scripts/start-mysql.sh
```

### 3. 访问应用
- 应用地址: http://localhost:8090
- 默认账号: admin / admin

### 4. 管理数据库
```bash
# 连接MySQL
docker exec -it primihub-mysql mysql -u root -pprimihub2024 primihub

# 查看日志
docker compose -f docker-compose-mysql.yml logs -f mysql

# 停止服务
docker compose -f docker-compose-mysql.yml down

# 停止并删除数据
docker compose -f docker-compose-mysql.yml down -v
```

---

## 方式二：使用本地MySQL

### 1. 安装MySQL

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install mysql-server
sudo systemctl start mysql
```

#### CentOS/RHEL
```bash
sudo yum install mysql-server
sudo systemctl start mysqld
```

#### macOS
```bash
brew install mysql
brew services start mysql
```

### 2. 初始化数据库
```bash
# 方法1: 使用脚本
export MYSQL_ROOT_PASSWORD='your_password'
bash scripts/init-mysql.sh

# 方法2: 手动创建
mysql -u root -p
CREATE DATABASE primihub DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
exit
```

### 3. 配置连接信息
编辑 `primihub-service/application/src/main/resources/application-mysql.yaml`：
```yaml
spring:
  datasource:
    username: root
    password: your_password
```

### 4. 启动应用
```bash
bash scripts/start-mysql.sh
```

---

## 配置文件说明

### 主配置切换
编辑 `primihub-service/application/src/main/resources/application.yaml`：
```yaml
spring:
  profiles:
    active: mysql  # 从 simple 改为 mysql
```

### MySQL连接配置
位于 `application-mysql.yaml`：
- 数据库地址: localhost:3306
- 数据库名: primihub
- 用户名: root
- 密码: primihub2024（请在生产环境修改）

---

## 文件列表

### 配置文件
- `primihub-service/application/src/main/resources/application-mysql.yaml` - MySQL配置
- `primihub-service/application/src/main/resources/schema-mysql.sql` - 表结构
- `primihub-service/application/src/main/resources/data-mysql.sql` - 初始数据

### 脚本
- `scripts/start-docker-mysql.sh` - 启动Docker MySQL环境
- `scripts/start-mysql.sh` - 启动应用（MySQL模式）
- `scripts/init-mysql.sh` - 初始化本地MySQL数据库

### Docker
- `docker-compose-mysql.yml` - MySQL和Redis的Docker编排文件

### 文档
- `MYSQL_SETUP.md` - 详细的MySQL配置文档

---

## 故障排查

### 无法连接MySQL
```bash
# 检查MySQL是否运行
docker ps | grep mysql
# 或
sudo systemctl status mysql

# 测试连接
mysql -h localhost -u root -pprimihub2024 -e "SELECT 1"
```

### 端口冲突
如果3306端口被占用，修改 `docker-compose-mysql.yml`：
```yaml
ports:
  - "13306:3306"  # 使用其他端口
```

然后修改 `application-mysql.yaml` 中的连接地址。

### 数据初始化失败
查看应用启动日志，检查SQL执行情况：
```bash
cd primihub-service/application
tail -f logs/application.log
```

---

## 下一步

- 查看 [MYSQL_SETUP.md](MYSQL_SETUP.md) 了解详细配置
- 修改默认密码以提高安全性
- 配置数据库备份策略
- 优化连接池参数
