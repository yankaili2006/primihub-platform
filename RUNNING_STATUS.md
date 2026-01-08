## PrimiHub Platform 运行状态

### 当前运行状态
✅ **应用已启动并运行中**

- **进程ID**: 3393344
- **端口**: 8090
- **配置模式**: simple (H2内存数据库)
- **启动时间**: 约2小时前
- **日志文件**: /tmp/primihub-app.log

### 访问信息

**后端API**
- 地址: http://localhost:8090
- 登录接口: http://localhost:8090/user/login
- 健康检查: http://localhost:8090/actuator/health

**默认账号**
- 用户名: admin
- 密码: admin

### 数据库配置

**当前使用**: H2内存数据库（简单模式）
- 优点: 零配置，开箱即用
- 缺点: 重启后数据丢失

**MySQL持久化配置已完成**
已为您准备好MySQL持久化方案，包括：

1. **配置文件**
   - application-mysql.yaml - MySQL配置
   - schema-mysql.sql - 表结构（33个表）
   - data-mysql.sql - 初始化数据

2. **启动脚本**
   - scripts/start-docker-mysql.sh - Docker方式启动MySQL
   - scripts/start-mysql.sh - 启动应用（MySQL模式）
   - scripts/init-mysql.sh - 初始化本地MySQL

3. **文档**
   - MYSQL_QUICKSTART.md - 快速开始指南
   - MYSQL_SETUP.md - 详细配置文档
   - MYSQL_MIGRATION_SUMMARY.md - 迁移总结

### 切换到MySQL持久化

#### 方式1: Docker（推荐）

```bash
# 停止当前应用
kill $(cat /tmp/primihub-app.pid)

# 启动MySQL和Redis
# 注意: 需要配置Docker镜像加速器解决网络问题
bash scripts/start-docker-mysql.sh

# 启动应用（MySQL模式）
bash scripts/start-mysql.sh
```

#### 方式2: 本地MySQL

```bash
# 停止当前应用
kill $(cat /tmp/primihub-app.pid)

# 安装MySQL
sudo apt-get install mysql-server  # Ubuntu/Debian

# 初始化数据库
export MYSQL_ROOT_PASSWORD='your_password'
bash scripts/init-mysql.sh

# 修改配置文件中的密码
# 编辑: primihub-service/application/src/main/resources/application-mysql.yaml

# 启动应用（MySQL模式）
bash scripts/start-mysql.sh
```

### 管理命令

```bash
# 查看日志
tail -f /tmp/primihub-app.log

# 停止应用
kill $(cat /tmp/primihub-app.pid)

# 重启应用（simple模式）
bash primihub-service/application/start-simple.sh

# 检查MySQL配置
bash scripts/verify-mysql-setup.sh
```

### 注意事项

1. **RabbitMQ警告**: 日志中显示RabbitMQ连接失败，这在simple模式下是正常的，已禁用消息队列功能
2. **Redis**: 本地Redis正在运行
3. **数据持久化**: 当前H2模式数据在重启后会丢失，如需持久化请切换到MySQL

### 下一步建议

1. **测试应用**: 访问 http://localhost:8090 测试API
2. **配置镜像加速**: 如果需要使用Docker MySQL，配置国内镜像加速器
3. **生产部署**: 使用MySQL进行数据持久化
4. **监控日志**: `tail -f /tmp/primihub-app.log`

---

**文档链接**:
- [MySQL快速开始](MYSQL_QUICKSTART.md)
- [MySQL详细配置](MYSQL_SETUP.md)
- [迁移总结](MYSQL_MIGRATION_SUMMARY.md)
