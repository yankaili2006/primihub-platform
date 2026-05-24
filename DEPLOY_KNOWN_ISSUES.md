# 离线部署 v2.8.0 已知问题记录

## 1. PVE VM 创建

### 1.1 SSH 密钥注入失败
- **现象**: `qm set <VMID> --sshkey <file>` 后 SSH 仍拒绝连接
- **根因**: Ubuntu cloud-init 模板在某些版本中 `--sshkey` 参数不生效
- **解决**: 改用 `virt-customize -a /dev/pve/vm-<VMID>-disk-0 --ssh-inject "root:file:<keyfile>"`
- **验证**: 脚本 `scripts/create-vm.sh` 已实现该方案

### 1.2 VM 锁住
- **现象**: `can't lock file '/var/lock/qemu-server/lock-<VMID>.conf' - got timeout`
- **根因**: 并发执行 qm 命令导致文件锁
- **解决**: `rm -f /var/lock/qemu-server/lock-<VMID>.conf` + `qm unlock <VMID>`

### 1.3 磁盘空间不足
- **现象**: 克隆后 10GB 磁盘运行部署时 "No space left on device"
- **根因**: Ubuntu 22.04 模板默认 10GB，离线包 2.9G + 镜像解压 ~5G + Docker 数据 ~5G
- **解决**: 
  ```bash
  qm resize <VMID> scsi0 30G
  ssh root@<IP> "growpart /dev/sda 1 && resize2fs /dev/sda1"
  ```
- **建议**: 新 VM 至少 30GB 磁盘

## 2. 平台部署

### 2.1 Nacos 配置推送跳过
- **现象**: 部署日志显示 "Nacos 不可访问，跳过配置推送"
- **根因**: Step 11 检测 Nacos 时服务尚未就绪
- **解决**: 手动重启应用服务: `docker restart application0 gateway0 gateway1 gateway2`
- **状态**: 重试后 Nacos 自动获取配置，服务恢复正常

### 2.2 application0 健康检查失败
- **现象**: `docker ps` 显示 `application0 ... (unhealthy)`
- **根因**: Nacos 配置尚未完全加载
- **解决**: 等待 30-60s 后自动恢复，或 `docker restart application0`
- **状态**: 自动恢复

### 2.3 primihub-node 重启循环
- **现象**: `primihub-node0  Restarting (127)`
- **根因**: 节点间 gRPC 连接超时，等待其他节点启动
- **解决**: 无需干预，所有节点启动后自动稳定
- **状态**: 自动恢复

### 2.4 Docker 镜像导入失败
- **现象**: "No space left on device" 导致后续镜像加载失败
- **根因**: 磁盘空间不足
- **解决**: 
  ```bash
  # 紧急清理
  docker system prune -af
  rm -rf /root/primihub-offline.tar.gz /snap/*
  apt-get remove --purge -y snapd
  # 扩容
  qm resize <VMID> scsi0 30G
  growpart /dev/sda 1 && resize2fs /dev/sda1
  ```
- **验证**: `df -h /` 确认可用空间 > 20GB

## 3. 数据库修复

### 3.1 fix_missing_auth_entries.sql 执行错误
- **现象**: "Column count doesn't match value count at row 1"
- **根因**: INSERT 语句列数与值不匹配（`r_auth_id` 重复）
- **解决**: 使用简化的 INSERT 语句，删除重复的 `r_auth_id` 列
- **状态**: 已修复

### 3.2 sys_user.first_login 字段缺失
- **现象**: 创建用户返回 "Unknown column 'first_login'"
- **根因**: 后端代码引用 `first_login` 字段但表结构缺失
- **解决**: `ALTER TABLE sys_user ADD COLUMN first_login tinyint(4) DEFAULT 1 AFTER register_type;`
- **状态**: 已写入 `fix_missing_auth_entries.sql`

## 4. 测试执行

### 4.1 Playwright 浏览器进程崩溃
- **现象**: "write EPIPE" - Node.js 进程异常退出
- **根因**: 长时间运行 + 资源紧张导致 Chromium 崩溃
- **解决**: 缩短单次测试规模，分批执行（20 页/批）
- **建议**: 单次运行 `e2e_all_167.py` 而非 `e2e_final_v6.py`

### 4.2 SPA 路由退化
- **现象**: 连续 30+ 次 hash 切换后路由守卫重定向到登录页
- **根因**: Vue Router 状态累积导致权限验证失败
- **解决**: 分批测试（每 20 页刷新浏览器上下文）

## 5. 数据库表缺失问题

### 5.1 sys_operation_log 表结构不完整
- **现象**: 所有需要写入操作日志的 API 返回 `code=-1 "系统异常"`
- **根因**: 社区版 `create_platform.sql` 未包含完整 DDL，表缺少 `user_name`、`error_message` 等列
- **解决**: 执行 `test-tools/init-privacy-db-tables.sql` 重建表
- **影响API**: 所有 POST 请求（创建项目/PSI/PIR/FL等都可能因事务回滚而失败）
- **状态**: ✅ 已修复

### 5.2 sys_config 表列名不匹配
- **现象**: `saveFtpConfig`、`saveTimeConfig` 等返回 `"保存失败"`
- **根因**: MyBatis 映射需要 `id`、`created_by`、`created_at`、`updated_at` 列，但默认表使用 `config_id`、`c_time`、`u_time`
- **解决**: 执行 `init-privacy-db-tables.sql` 重建表
- **状态**: ✅ 已修复

### 5.3 federated_stats/analysis/learning/single_party 等模块表缺失
- **现象**: 相应 API 返回 `"查询失败"` 或 `"创建失败"`
- **根因**: 这些模块的表未被初始 DDL 脚本创建
- **解决**: 执行 `init-privacy-db-tables.sql` 一次性创建所有缺失表
- **状态**: ✅ 已修复

## 6. 运行时依赖缺失

### 6.1 application0 容器缺少 Python3
- **现象**: FL 训练/预测、单方算法任务失败 (taskState=3)
- **根因**: 容器为 Amazon Linux 2，默认无 Python3
- **解决**: 执行 `test-tools/setup-python-algorithms.sh` 自动安装 Python3 + 脚本
- **状态**: ✅ 已修复

### 6.2 FL 算法 Python 脚本缺失
- **现象**: FL 训练/预测任务创建成功但执行失败
- **根因**: 算法路径 `/home/primihub/primihub-platform/python-algorithms/` 下无对应脚本
- **解决**: 执行 `setup-python-algorithms.sh` 自动创建 16 个算法脚本
- **状态**: ✅ 已修复

## 7. 代码 Bug

### 7.1 PIR 提交 - Fusion 空结果导致"资源不可用"
- **现象**: `POST /pir/pirSubmitTask` 返回 `code:1007 "资源不可用"`
- **根因**: `PirService.java` 中 Fusion 服务返回空 `{}` 结果时，`getOrDefault("available","1")` 默认返回 `"1"`，而代码将 `available == 1` 视为不可用
- **修复**: 
  ```java
  // 增加空结果判断，跳过 Fusion 路径回退本地数据库
  boolean useFusion = dataResource.getCode() == 0
      && dataResource.getResult() != null
      && !(dataResource.getResult() instanceof LinkedHashMap
           && ((LinkedHashMap)dataResource.getResult()).isEmpty());
  // 默认 available 改为 "0"
  String availableStr = pirDataResource.getOrDefault("available","0").toString();
  ```
- **提交**: `c9be7d2f` (primihub-platform)
- **状态**: ✅ 已修复

### 7.2 Python SDK 跨测试污染
- **现象**: 运行全部测试时出现 31 个失败的测试，单独运行则通过
- **根因**: `tests/test_fl_feature_engineering.py` 在模块级替换了 `sys.modules` 中的多个模块（`primihub.FL.crypto.*`、`google.*` 等），污染后续测试
- **修复**: 在 `primihub/tests/conftest.py` 添加 session-scoped autouse fixture，在运行前清理被 mock 的模块
- **提交**: `1be2c201` (primihub)
- **状态**: ✅ 已修复

## 8. 环境要求总结

| 资源 | 最低要求 | 推荐配置 |
|------|---------|---------|
| CPU | 4 核 | 8 核 |
| 内存 | 8 GB | 16 GB |
| 磁盘 | 30 GB | 50 GB |
| Docker | 20.10+ | 24.0+ |
| 网络 | 100 Mbps | 1000 Mbps |
