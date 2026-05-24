# PrimiHub 新环境部署验证指南

## 1. 环境准备

### 1.1 PVE 上创建 VM
```bash
# 从 Cloud-Init Template 克隆
qm clone 9024 <VMID> --name <NAME> --full 1
qm set <VMID> --cores <N> --memory <MB>
qm start <VMID>
```

### 1.2 部署 PrimiHub 平台

```bash
# 进入平台目录
cd ~/github/primihub-platform

# 启动 Docker 容器
bash deploy-offline.sh
# 或手动启动
docker-compose up -d

# 等待服务就绪（约 2 分钟）
docker-compose ps
```

### 1.3 数据库初始化

```bash
# 修复缺失的权限和字段
mysql -uroot -p<password> privacy < fix_missing_auth_entries.sql

# 确认 auth 条目完整
mysql -uroot -p<password> privacy -e "SELECT COUNT(*) FROM sys_auth"
# 预期: 166+ 条
```

## 2. 测试环境准备

### 2.1 本机（测试执行机）安装依赖

```bash
# Playwright
pip install playwright httpx
python3 -m playwright install chromium

# 确保能访问目标 VM
# 方式1: 直连
ping <VM-IP>
curl http://<VM-IP>:30811/

# 方式2: 通过 PVE 跳板机 socat 代理
ssh <PVE_HOST>
socat TCP-LISTEN:13081,fork TCP:<VM-IP>:30811 &
# 访问 http://<PVE_HOST>:13081/
```

### 2.2 配置测试目标地址

```bash
export TEST_BASE="http://<PVE_HOST>:13081"
# 或直接
export TEST_BASE="http://<VM-IP>:30811"
```

## 3. 执行验证

### 3.1 一键验证（推荐）

```bash
cd ~/github/primihub-platform

# 快速验证（路由+API，~10分钟）
python3 deploy_verify.py

# 完整验证（含交互测试，~20分钟）
python3 deploy_verify.py --full

# 指定目标 + 修复数据库
python3 deploy_verify.py --base http://<ip>:30811 --fix-db
```

### 3.2 单个运行（调试用）

```bash
cd ~/github/primihub-platform

# 路由测试（8 分钟）
python3 test-tools/e2e_all_167.py

# API 测试（2 分钟）
python3 test-tools/api_test_all.py

# 交互测试（8 分钟，可选）
python3 test-tools/e2e_final_v6.py
```

## 4. 预期结果

| 测试 | 预期通过率 | 耗时 |
|------|:---------:|:----:|
| 路由加载（167 页） | 100% | ~8 分钟 |
| API 功能（223 点） | 100% | ~2 分钟 |
| 页面交互（99 操作） | 100% | ~6 分钟 |

## 5. 常见问题处理

### 5.1 路由跳转到登录页

- 检查 `auth_codes.txt` 中是否包含所有 route name
- 确保 `window.location.href` 在单页应用中使用 hash 导航
- 分页测试（每 20 页刷新）避免 SPA 状态退化

### 5.2 API 返回 code=-1

- `查询失败` → 空数据库，API 正常
- `系统异常` → 参数错误，检查参数名和格式
- `1001/1003/1006/1013` → 业务逻辑错误，需 gRPC 后端

### 5.3 交互元素不可见

- 检查 Element UI 组件渲染时机（`wait_for_selector`）
- 区分 readonly 输入框（select/date）和可写输入框
- 使用 `input[type=text]:not([readonly])` 选择器

## 6. 测试数据说明

| 测试数据 | 来源 |
|---------|------|
| 登录账号 | `admin / 123456` |
| 权限注入 | `test-tools/auth_codes.txt` |
| 数据库修复 | `fix_missing_auth_entries.sql` |
