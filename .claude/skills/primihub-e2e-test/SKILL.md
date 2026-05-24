# PrimiHub E2E 自动测试 Skill

## Overview

PrimiHub 平台端到端自动化测试技能。覆盖 185 前端路由 + 223 后端 API + 40 页面交互操作。

## 前置条件

```bash
# Playwright 浏览器自动化
pip install playwright
python3 -m playwright install chromium

# 依赖
pip install httpx

# 环境
# 确保测试目标可访问（默认 http://100.64.0.25:13081）
export TEST_BASE="http://100.64.0.25:13081"
```

## 测试脚本清单

| 脚本 | 覆盖 | 用例数 |
|------|------|:------:|
| `test-tools/e2e_test.py` | 185 前端路由页面加载 | 185 |
| `test-tools/e2e_all_167.py` | 167 页面分批测试 | 167 |
| `test-tools/e2e_demand_aligned.py` | 对齐 demand.csv 223 功能点 | 178 |
| `test-tools/e2e_final_v5.py` | 40 页 × 2-4 交互操作 | 101 |
| `test-tools/e2e_complete.py` | 39 模块 × 3 操作 | 120 |
| `test-tools/api_test.py` | 52 核心 API 端点 | 52 |
| `test-tools/api_test_all.py` | 223 功能点 API 全量 | 223 |

## 快速运行

```bash
# 全量路由测试（推荐）
python3 test-tools/e2e_all_167.py

# API 功能测试
python3 test-tools/api_test_all.py

# 完整交互测试
python3 test-tools/e2e_final_v5.py
```

## 数据库修复

当部署新环境时，需要执行以下 SQL 修复：

```sql
-- 文件: fix_missing_auth_entries.sql
-- 1. 补充缺失权限（EC 子页面 10 条 + FL/FA/FS/SP 子页面 70 条）
-- 2. 补充 sys_user.first_login 字段
mysql -uroot privacy < fix_missing_auth_entries.sql
```

## 已知问题

| 问题 | 状态 |
|------|------|
| 警务/证件场景 API 需 gRPC 后端 | ⚠️ 需部署 primihub-node |
| 用户创建需 `application/x-www-form-urlencoded` 格式 | ✅ 已修复 |
| `sys_user` 缺少 `first_login` 列 | ✅ 已修复 |
| SPA 累积 hash 切换后路由守卫退化 | ⚠️ 分批测试（每 20 页刷新） |

## 测试结果参考

| 测试类型 | 通过率 | 截图目录 |
|---------|:------:|---------|
| 路由加载 | 100% | `/tmp/e2e_all_167/` |
| API 功能 | 96%+ | - |
| 页面交互 | 100% (页面加载) | `/tmp/e2e_final_v5/` |

## 技术栈

- **Browser**: Playwright (Chromium headless)
- **API Client**: httpx
- **Target**: PrimiHub Platform (Vue.js SPA + Spring Boot)
- **Auth**: JWT token in localStorage (`DataItemPer` key)

## PVE VM 创建

```bash
# 一键创建 VM（自动注入 SSH 密钥）
bash scripts/create-vm.sh <VMID> <IP_LAST> [TEMPLATE_ID]
# 示例
bash scripts/create-vm.sh 106 106 9010
```

### 已知问题
- `--sshkey` 在部分 Ubuntu cloud-init 模板中不生效
- 必须使用 `virt-customize --ssh-inject` 注入密钥
- 需要 `--ciuser root --cipassword` 配合
