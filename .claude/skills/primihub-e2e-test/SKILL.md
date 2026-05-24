# PrimiHub E2E 自动测试 Skill

## Overview

PrimiHub 平台全生命周期验证技能：从 PVE 创建 VM → 离线部署 → 数据库修复 → 全量测试。

| 测试 | 覆盖 | 通过率 | 耗时 |
|------|------|:------:|:----:|
| 路由测试 | 167 页面 | 100% | ~8 min |
| API 测试 | 223 功能点 | 100% | ~2 min |
| 交互测试 | 40 页 × 99 操作 | 100% | ~8 min |

---

## 1. PVE VM 创建

```bash
# 一键创建 VM（自动注入 SSH 密钥）
bash scripts/create-vm.sh <VMID> <IP_LAST> [TEMPLATE_ID]
# 示例
bash scripts/create-vm.sh 106 106 9010
```

**注意**：cloud-init 的 `--sshkey` 在部分 Ubuntu 模板中不生效，脚本已改用 `virt-customize` 注入密钥。

### 已知 PVE 问题

| 问题 | 原因 | 解决 |
|------|------|------|
| SSH 密钥不生效 | Ubuntu cloud-init 模板 `--sshkey` 参数不兼容 | 改用 `virt-customize -a <disk> --ssh-inject "root:file:<key>"` |
| SSH 连接被拒 | cloud-init 未完成或 root 登录禁用 | 配置 `--ciuser root --cipassword <pwd>` |
| VM 锁住 | 并发 PVE 操作 | `rm -f /var/lock/qemu-server/lock-<VMID>.conf` |
| qemu-guest-agent 未运行 | Ubuntu 模板默认不含 | `apt install qemu-guest-agent`（容器化部署非必需）|
| 磁盘空间不足 | 模板默认 10GB，离线包+镜像需 20GB+ | `qm resize <VMID> scsi0 30G` + `growpart /dev/sda 1` + `resize2fs /dev/sda1` |

## 2. 离线部署

```bash
# 下载离线包（~2.9GB）
curl -sL -o /root/primihub-offline.tar.gz \
  'https://primihub.oss-cn-beijing.aliyuncs.com/primihub-offline-v2.8.0.tar.gz'

# 解压部署
cd /root && tar xzf primihub-offline.tar.gz
cd primihub-offline-package
bash deploy-offline.sh
```

### 已知部署问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 磁盘空间不足 | 镜像总大小 2.3G，解压后 ~5G | 扩容至 30GB+ |
| Nacos 配置推送跳过 | Step 11 检测到 Nacos 不可访问 | 重启服务: `docker restart application0 gateway0-2` |
| application0 不健康 | Nacos 配置未就绪 | 等待 Nacos 完全启动后应用会自动恢复 |
| primihub-node 重启循环 | 节点间 gRPC 连接超时 | 等待所有节点启动后自动恢复 |
| 部署日志 "No space left" | `/var/lib/docker` 磁盘满 | `docker system prune -af` + 扩容 |

### 部署后验证

```bash
# 检查所有容器运行状态（应有 22 个）
docker ps --format 'table {{.Names}}\t{{.Status}}'

# 测试平台登录
curl -s -X POST http://localhost:30811/prod-api/user/login \
  -d 'userAccount=admin&userPassword=123456'
# 预期: {"code":0,"msg":"请求成功",...}
```

## 3. 数据库修复

```bash
docker exec -i mysql mysql -uroot -proot privacy < fix_missing_auth_entries.sql
```

修复内容：
- 补充缺失权限（EC/FL/FA/FS/SP 子页面 80+ 条）
- 补充 `sys_user.first_login` 列
- 角色权限关联（`sys_ra`）

## 4. 一键验证

```bash
cd ~/github/primihub-platform

# 快速验证（路由+API，~10 min）
export TEST_BASE="http://<vm-ip>:30811"
python3 deploy_verify.py
python3 deploy_verify.py --fix-db --full
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `--base` | 目标地址（默认 `TEST_BASE` 环境变量）|
| `--full` | 包含交互测试（较慢）|
| `--fix-db` | 先执行数据库修复 |

## 5. 测试脚本清单

| 脚本 | 用途 | 推荐场景 |
|------|------|---------|
| `deploy_verify.py` | **一键验证入口** | 部署后快速检查 |
| `test-tools/e2e_all_167.py` | 167 路由全量 | 前端回归 |
| `test-tools/api_test_all.py` | 223 API 全量 | 后端回归 |
| `test-tools/e2e_final_v6.py` | 40 页面交互 | 完整验证（--full）|

## 6. Skill 命令

| 命令 | 功能 |
|------|------|
| `test-all` | 全量测试（路由+API）|
| `test-routes` | 路由测试 |
| `test-api` | API 测试 |
| `test-interactive` | 交互测试 |
| `fix-db` | 数据库修复 |
| `create-vm <VMID>` | 创建测试 VM |

## 7. 验证结果参考

| 环境 | 路由测试 | API 测试 | 交互测试 |
|------|:--------:|:--------:|:--------:|
| pve101-VM101 (v2.7.x) | 167/167 ✅ | 223/223 ✅ | 99/99 ✅ |
| pve101-VM105 (v2.8.0) | 167/167 ✅ | 223/223 ✅ | - |

## 8. 离线部署常见问题

### PVE VM 创建
| 问题 | 现象 | 解决 |
|------|------|------|
| SSH 密钥不生效 | `qm set --sshkey` 后仍 Permission denied | `virt-customize -a <disk> --ssh-inject "root:file:<key>"` |
| VM 锁住 | `can't lock file ... lock-<VMID>.conf` | `rm -f /var/lock/qemu-server/lock-<VMID>.conf` |
| 磁盘空间不足 | "No space left on device" | `qm resize <VMID> scsi0 30G` + `growpart` + `resize2fs` |

### 平台部署
| 问题 | 现象 | 解决 |
|------|------|------|
| Nacos 配置跳过 | 日志 "Nacos 不可访问，跳过配置推送" | `docker restart application0 gateway0 gateway1 gateway2` |
| application0 不健康 | `(unhealthy)` 状态 | 等待 30-60s 自动恢复 |
| node 重启循环 | `Restarting (127)` | 等待所有节点启动后自动稳定 |

### 环境要求
| 资源 | 最低 | 推荐 |
|------|:----:|:----:|
| CPU | 4核 | 8核 |
| 内存 | 8GB | 16GB |
| 磁盘 | 30GB | 50GB |

## 9. 技术栈

- **Browser**: Playwright (Chromium headless)
- **API Client**: httpx
- **Target**: PrimiHub Platform (Vue.js SPA + Spring Boot)
- **Database**: MySQL 5.7, Nacos config center
- **Messaging**: RabbitMQ 3.6.15 cluster
- **Cache**: Redis 7
- **Auth**: JWT token, localStorage key `DataItemPer`
