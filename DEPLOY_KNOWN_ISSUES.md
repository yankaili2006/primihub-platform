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

## 5. 环境要求总结

| 资源 | 最低要求 | 推荐配置 |
|------|---------|---------|
| CPU | 4 核 | 8 核 |
| 内存 | 8 GB | 16 GB |
| 磁盘 | 30 GB | 50 GB |
| Docker | 20.10+ | 24.0+ |
| 网络 | 100 Mbps | 1000 Mbps |
