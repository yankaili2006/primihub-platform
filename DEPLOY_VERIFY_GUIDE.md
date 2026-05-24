# PrimiHub 新环境部署验证指南

## 1. 全流程概览

```
PVE 创建 VM → 部署平台 → 修复数据库 → 一键验证
```

## 2. PVE 上创建 VM

```bash
# 从 Cloud-Init Template 克隆（Ubuntu 22.04 模板 ID 9010）
VMID=105
NAME=test-offline
qm clone 9010 $VMID --name $NAME --full 1

# ⚠️ 注意：必须使用 virt-customize 注入 SSH 密钥
# cloud-init 的 --sshkey 参数在部分模板中不生效
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..." > /tmp/sshkey
qm set $VMID --cores 4 --memory 8192 \
  --ipconfig0 ip=192.168.99.$VMID/24,gw=192.168.99.1 \
  --ciuser root --cipassword 1qazmko0
qm stop $VMID --skiplock
virt-customize -a /dev/pve/vm-$VMID-disk-0 --ssh-inject "root:file:/tmp/sshkey"
qm start $VMID

# 等待 SSH 就绪
for i in $(seq 1 30); do
  ssh -o StrictHostKeyChecking=no root@192.168.99.$VMID "hostname" && break
  sleep 4
done
```

## 3. 部署 PrimiHub 平台

### 方式 A：离线部署（推荐）

```bash
# 已打包离线工具
cd ~/primihub-offline
bash deploy-offline.sh
```

部署脚本会自动执行：
1. 启动 Docker 容器
2. 修复数据库（权限 + 字段）
3. **执行自动化验证**（路由 167 页 + API 223 点）

### 方式 B：源码部署

```bash
cd ~/github/primihub-platform
bash scripts/deploy.sh
# 或
docker-compose up -d
mysql -uroot privacy < fix_missing_auth_entries.sql
```

## 4. 一键验证

```bash
cd ~/github/primihub-platform

# 快速验证（路由+API，~10 分钟）
python3 deploy_verify.py

# 完整验证（含交互测试，~20 分钟）
python3 deploy_verify.py --full

# 指定目标地址
python3 deploy_verify.py --base http://192.168.99.101:30811

# 先修复数据库再验证
python3 deploy_verify.py --fix-db

# 完整命令
python3 deploy_verify.py --base http://<ip>:<port> --fix-db --full
```

## 5. 验证内容

| 测试 | 覆盖 | 耗时 | 说明 |
|------|------|:----:|------|
| 路由测试 | 167 页面 | ~8 min | 验证所有前端路由可访问 |
| API 测试 | 223 功能点 | ~2 min | 验证所有后端接口可用 |
| 交互测试 | 40 页 × 99 操作 | ~8 min | 模拟用户操作（--full 时启用）|

## 6. 手动验证（调试用）

```bash
# 路由测试
python3 test-tools/e2e_all_167.py

# API 测试
python3 test-tools/api_test_all.py

# 交互测试
python3 test-tools/e2e_final_v6.py
```

## 7. 测试脚本清单

| 脚本 | 用途 |
|------|------|
| `deploy_verify.py` | **一键验证入口** |
| `test-tools/e2e_all_167.py` | 全量路由测试（20 页一批）|
| `test-tools/api_test_all.py` | 223 功能点 API 测试 |
| `test-tools/e2e_final_v6.py` | 40 页面交互测试 |
| `fix_missing_auth_entries.sql` | 数据库修复（权限+字段）|

## 8. 测试环境准备

```bash
# 本机安装依赖
pip install playwright httpx
python3 -m playwright install chromium

# 配置目标地址
export TEST_BASE="http://<vm-ip>:30811"
# 或直连
export TEST_BASE="http://100.64.0.25:13081"
```

## 9. 部署环境要求

| 资源 | 最低 | 推荐 | 说明 |
|------|:----:|:----:|------|
| CPU | 4核 | 8核 | Docker 22 个容器 |
| 内存 | 8GB | 16GB | 镜像加载+Java服务 |
| 磁盘 | 30GB | 50GB | 离线包2.9G+镜像5G+数据 |
| Docker | 20.10+ | 24.0+ | 需 Compose v2 |
| 网络 | 100Mbps | 1000Mbps | 下载离线包2.9G |

## 10. 常见问题

### PVE VM 创建

| 问题 | 原因 | 解决 |
|------|------|------|
| SSH 密钥不生效 | cloud-init 模板的 `--sshkey` 参数不兼容 | 改用 `virt-customize -a <disk> --ssh-inject` |
| SSH 连接被拒 | cloud-init 未完成、sshd 未启动 | 等待 60-120s；配置 `--ciuser root --cipassword` |
| VM 锁住 | 并发操作导致 | `rm -f /var/lock/qemu-server/lock-<VMID>.conf` |
| qemu-guest-agent 未运行 | Ubuntu 模板默认不含 | 需额外安装 `apt install qemu-guest-agent` |

推荐使用 `scripts/create-vm.sh` 一键创建：

```bash
bash scripts/create-vm.sh 106 106 9010
```

### 路由跳转到登录页
- 检查 `auth_codes.txt` 中是否包含所有 route name
- 确保 `window.location.href` 在单页应用中使用 hash 导航
- 分页测试（每 20 页刷新）避免 SPA 状态退化

### API 返回 code=-1
- `查询失败` → 空数据库，API 正常
- `系统异常` → 参数错误，检查参数名和格式
- `1001/1003/1006/1013` → 业务逻辑错误（需 gRPC 后端）

### 交互元素不可见
- 使用 `input[type=text]:not([readonly])` 选择器
- Element UI 组件需等待渲染
