# 缺陷整改 —— 部署 Runbook（合并 develop 后生效步骤）

> 前提：8 个整改 PR(#10–#17) 已合并进 `develop`，`develop` 后端 `mvn compile` 已验证 BUILD SUCCESS。
> 本 runbook 把"代码已合并"落到"运行环境生效"。**执行前先确认目标实例**（见 §0）。
> 拓扑：单节点 docker-compose，容器 `mysql-db` / `primihub-platform`(application) / `primihub-gateway` / `primihub-web` / `redis-cache` / `nacos-server`；DB 为 `privacy1/privacy2/privacy3`（3 组织节点各一库）。

---

## 0. 前置：确认目标 ⚠️

- 明确要更新的是**哪一套部署**（客户验收环境 / pve100 VM802·803 primihub-platform / pve101 primihub-full / arm64 客户机 等）。
- 确认 MySQL 访问方式：容器 `mysql-db`（`docker exec`）还是外部 MySQL（直连 host:3306）。
- 确认 3 个库名（默认 `privacy1/privacy2/privacy3`；单库部署可能只有 `privacy1` 或 `privacy`）。
- **备份**：迁移虽幂等，仍建议先 `mysqldump` 三库留档。

```bash
# 目标容器/主机自检
docker ps --format '{{.Names}}\t{{.Image}}' | grep -E 'mysql|primihub'
docker exec mysql-db mysql -uroot -p<PWD> -e "show databases like 'privacy%';"
```

---

## 1. 数据库迁移（T4+T5）—— 幂等，可重复

对**每个** privacy 库执行 `docs/requirements/T4_T5_remediation_mysql.sql`。

**方式 A：DB 在 `mysql-db` 容器内**
```bash
SQL=docs/requirements/T4_T5_remediation_mysql.sql
for DB in privacy1 privacy2 privacy3; do
  echo "== applying to $DB =="
  docker exec -i mysql-db mysql -uroot -p<PWD> "$DB" < "$SQL"
done
```

**方式 B：外部 MySQL**
```bash
for DB in privacy1 privacy2 privacy3; do
  mysql -h<HOST> -P3306 -uroot -p<PWD> "$DB" < docs/requirements/T4_T5_remediation_mysql.sql
done
```

**校验**（脚本末尾已带校验查询；也可手动确认）：
```bash
docker exec mysql-db mysql -uroot -p<PWD> privacy1 -e "
  SHOW TABLES LIKE 'shared_dataset';
  SHOW TABLES LIKE 'sys_compute_log_definition';
  SELECT auth_code FROM sys_auth WHERE auth_code IN ('WhitelistAdd','TenantAdd','Difference') AND is_del=0;"
```
> 幂等：`CREATE TABLE IF NOT EXISTS` + `INSERT ... WHERE NOT EXISTS`，重复执行安全。**失败无需回滚**（不会产生半成品）。

---

## 2. 重建镜像

后端 `application` 与 `gateway` **同一镜像** `primihub/primihub-platform`（含 T3 网关路由 + T6/T7/T8/T9/T10 后端改动）；前端 `primihub/primihub-web`（含 T1/T2/T6-monitor 前端改动）。

```bash
# 在 develop 已合并的工作树根目录
git checkout develop && git pull

# 后端镜像（application + gateway 同源）
./build-platform-image.sh        # 或 ./build-platform-backend.sh，按你现有 CI 习惯

# 前端镜像
./quick-build-platform.sh        # 内部 npm run build:prod + docker build web
```
> arm64 目标改用 `./build-arm-image.sh` / `./quick-build-arm.sh`（见 `arm64-deploy/`）。
> 镜像 tag 与仓库地址按你现网 registry 调整（脚本默认 `192.168.99.10/primihub/...`）。

---

## 3. 重启容器

```bash
# 拉新镜像并重建受影响容器（application/gateway/web）
docker-compose pull primihub-platform primihub-gateway primihub-web
docker-compose up -d primihub-platform primihub-gateway primihub-web

# 或全栈
docker-compose up -d
```
> 网关路由随镜像打包（`bootstrap.yaml` 未从 Nacos 拉路由）；重启 gateway 容器即生效。若你的部署把路由托管到 Nacos，需同步该 config 再重启。

---

## 4. 清缓存 + 强制重登

```bash
docker exec redis-cache redis-cli FLUSHDB     # 或按 DB index 清权限缓存键
```
- 前端**退出并重新登录**，菜单/按钮权限（白名单新增、租户、联邦求差）方刷新。

---

## 5. 冒烟验证（对照缺陷）

| 缺陷类 | 验证点 |
|---|---|
| T4 权限 | 白名单列表出现"新增/编辑"按钮；租户列表出现"新增/编辑/删除/冻结"；联邦求差菜单出现 |
| T5 缺表 | 操作/调度/计算 日志定义可新增；数据需求、共享数据集可新增 |
| T3 网关 | 联邦学习各菜单不再"加载任务列表失败"；单方数据子功能可用 |
| T1 | 接入方/合作方/审批/数据交换 新增不再"成功却报错"；数据需求/共享数据集模糊查询"-001"可用 |
| T6 | 监控 CPU/内存/磁盘/DB/JVM/Redis 告警配置**保存成功**（不再无响应）；接口新增所选请求方法正确保存 |
| T7 | 用户/项目/接口新增失败有明确报错（不再"点了没反应"）；用户角色可多选 |
| T8 | 租户"计算流程隔离/数据隔离"页进入不再 404，可读可存 |
| T9 | 角色新增后"创建时间"与实时时间一致（时区正确） |
| T10 | 接口日志无数据导出提示"暂无数据可导出"；有数据导出真实 xlsx |
| T2 | 联邦统计/学习 日志记录按 taskId 搜索真实过滤；日志/结果/模型 导出产生真实文件；电子证照 批量交换/实时交换/机构导入导出 动作真实提交后端 |

---

## 6. 回滚

- **DB**：迁移幂等且仅新增（表/权限），无破坏性变更；如需回退权限，可将新增 `sys_auth`/`sys_ra` 行 `is_del=1`（不建议，因这些是修复缺陷所需）。
- **镜像**：`docker-compose` 指回上一个镜像 tag 重启即可（后端/前端各自回退）。

---

## 7. 遗留（不在本次范围，需新后端开发）

警务融合/电子证照的**日志记录+导出**、警务融合 **batchExchange**、联邦学习 **dataMerge/modelImport**、**时间戳 evidenceId 语义** —— 详见 `docs/requirements/缺陷整改-总汇总与合并顺序.md` §五。
