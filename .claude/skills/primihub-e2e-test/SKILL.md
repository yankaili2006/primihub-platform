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

## 9. 已知问题修复清单

### 9.1 数据库表缺失（10 张表）
**现象**: API 返回 `"查询失败"` 或 `"系统异常"`
**修复**: `mysql -uroot -proot privacy < test-tools/init-privacy-db-tables.sql`
**涉及模块**: `federated_stats*`, `federated_analysis*`, `federated_learning*`, `single_party*`, `whitelist*`, `sys_operation_log`, `sys_config`

### 9.2 sys_config 列名不匹配
**现象**: `saveFtpConfig` 返回 `"保存失败"`
**根因**: MyBatis 需要 `id`, `created_by`, `created_at`, `updated_at` 列（非 `config_id`, `c_time`, `u_time`）
**修复**: `init-privacy-db-tables.sql` 已使用正确列名

### 9.3 sys_operation_log 列缺失
**现象**: 所有写操作 API 失败（事务回滚）
**根因**: 缺少 `user_name`, `error_message`, `operation_module` 等列
**修复**: 执行 `init-privacy-db-tables.sql` 重建表

### 9.4 PIR 提交失败 — `"资源不可用"`
**现象**: `POST /pir/pirSubmitTask` → `code:1007`
**根因**: `PirService.java` 中 Fusion 空结果导致 `available=1` 默认判断
**修复**: 提交 `c9be7d2f`，空结果时回退本地数据库
**文件**: `primihub-service/biz/src/main/java/.../PirService.java`

### 9.5 application0 容器缺少 Python3
**现象**: FL/单方训练任务 state=3 (失败)
**修复**: `test-tools/setup-python-algorithms.sh` 自动安装

### 9.6 FL 算法路径缺失
**现象**: FL 任务创建成功但执行失败
**修复**: `setup-python-algorithms.sh` 创建 16 个算法脚本

### 9.7 跨测试污染（Python SDK）
**现象**: 31 个测试一起运行失败，单独运行通过
**根因**: `test_fl_feature_engineering.py` 模块级 mock 污染
**修复**: `primihub/tests/conftest.py` 添加 session-scoped 清理 fixture

### 9.8 API/Evidence 表名不匹配
**现象**: `apiManage/findApiPage` 和 `evidence/findEvidencePage` 返回 `"查询失败"`
**根因**: MyBatis 期望 `api_definition` 和 `evidence_record` 表
**修复**: 创建 `api_definition`, `api_auth_config`, `api_call_log`, `evidence_record`, `evidence_timestamp`, `evidence_config`, `evidence_api_key` 表

### 9.9 数据库硬编码 — `privacy` 应为 `privacy0/1/2`
**现象**: 应用启动参数指定 `privacy0` 但日志显示连接 `privacy`
**根因**: `PrimaryNacosDatabaseConfigConfiguration.java` 和 `SecondaryDruidDataSourceWrapper.java` 硬编码 `jdbc:mysql://mysql:3306/privacy`
**修复**: 提交 `6e2bd578`，改用 `@Value` 注入，配合环境变量覆盖
**文件**: `primihub-service/biz/src/main/java/.../PrimaryNacosDatabaseConfigConfiguration.java`
         `primihub-service/biz/src/main/java/.../SecondaryNacosDatabaseConfigConfiguration.java`

### 9.10 fusion0 缺少主库表
**现象**: 登录返回 `Table 'fusion0.sys_user' doesn't exist`
**根因**: 部分 `secondarydb` 的 MyBatis mapper 查询主库表，但 fusion0 中不存在
**修复**: `DELETE FROM fusion0.$table; INSERT INTO fusion0.$table SELECT * FROM privacy0.$table`

### 9.11 多租户启动内存不足
**现象**: 同时启动 application0/1/2 导致 OOM
**根因**: 每个 Java 进程 ~1024m，3 个实例超 VM 内存上限
**解决**: 需至少 8GB 可用内存，推荐 16GB

## 10. 新架构部署

### 数据库架构
```
application0 → privacy0 (primary) + fusion0 (secondary)
application1 → privacy1 (primary) + fusion1 (secondary)
application2 → privacy2 (primary) + fusion2 (secondary)
```

### 部署步骤

```bash
# 0. 构建含 @Value 修复的 jar
cd ~/github/primihub-platform
git pull origin develop
cd primihub-service && mvn clean package -DskipTests -Dmaven.test.skip=true

# 1. 初始化所有数据库
for db in privacy0 privacy1 privacy2; do
  mysql -uroot -proot $db < test-tools/init-privacy-db-tables.sql
done

# 2. 同步主库表到从库
for src_db in privacy0 privacy1 privacy2; do
  dst_fusion="${src_db/privacy/fusion}"
  mysql -uroot -proot -e "
    SET @tables = (SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema='$src_db');
    -- 复制: CREATE TABLE $dst_fusion.$table LIKE $src_db.$table; INSERT INTO $dst_fusion.$table SELECT * FROM $src_db.$table;
  "
done

# 3. 启动应用（必须设置环境变量！）
docker run -d --name application0 \
  -e SPRING_DATASOURCE_DRUID_PRIMARY_URL="jdbc:mysql://mysql:3306/privacy0?..." \
  -e SPRING_DATASOURCE_DRUID_SECONDARY_URL="jdbc:mysql://mysql:3306/fusion0?..." \
  --nacos.config.namespace=demo0 \
  primihub-platform:latest

docker run -d --name application1 \
  -e SPRING_DATASOURCE_DRUID_PRIMARY_URL="jdbc:mysql://mysql:3306/privacy1?..." \
  -e SPRING_DATASOURCE_DRUID_SECONDARY_URL="jdbc:mysql://mysql:3306/fusion1?..." \
  --nacos.config.namespace=demo1 \
  primihub-platform:latest

# 4. 验证
docker logs application0 2>&1 | grep "Init Primary"
# 预期: URL: jdbc:mysql://mysql:3306/privacy0?...

# 5. Python算法
bash test-tools/setup-python-algorithms.sh

# 6. API测试
python3 test-tools/primihub-cli.py health --url http://<host>:30811
```

### 已知问题
| 问题 | 原因 | 解决 |
|------|------|------|
| 启动参数 --spring.datasource.druid.primary.url 不生效 | Shell 截断 `&` 字符 | 改用环境变量 `SPRING_DATASOURCE_DRUID_PRIMARY_URL` |
| application.yml 硬编码 privacy1 | 默认配置为 privacy1 | 环境变量优先级高于 yaml，设置后覆盖 |
| fusion 查询主库表失败 | secondarydb mapper 引用 sys_user 等表 | 手动同步 privacy → fusion 全表 |

## 11. 技术栈

- **Browser**: Playwright (Chromium headless)
- **API Client**: httpx
- **Target**: PrimiHub Platform (Vue.js SPA + Spring Boot)
- **Database**: MySQL 5.7 (privacy0/1/2 + fusion0/1/2), Nacos config center
- **Messaging**: RabbitMQ 3.6.15 cluster
- **Cache**: Redis 7
- **Auth**: JWT token, localStorage key `DataItemPer`
