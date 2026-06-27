# 隐私计算平台 — 功能点菜单 + 前端页面解锁 增量热修复包

**用途**：在**已部署的离线环境**里，把菜单补全到 demand.csv 的 **18 模块 / 224 功能点**，
并**解锁全部前端页面**（admin 登录后侧边栏可见并可打开 ~255 个页面）。
**只改数据库 + 清后端菜单缓存**，不动镜像、不重新部署、纯离线、幂等、可回滚。

## 适用环境
- docker-compose 离线部署，含 `mysql`(或 mariadb) 与 `redis` 容器；
- 数据库为 `privacy1/2/3`（脚本会自动探测所有含 `sys_auth` 的库）；
- 前端为完整版镜像（`platform:1.8.x`，自带各功能页面路由）。

## 一键安装
```bash
tar xzf demand-menu-hotfix.tgz && cd hotfix-demand-menu
sudo bash install.sh
```
默认按离线包默认值连接（mysql root/`root`、redis 密码 `primihub`、容器名 `mysql`/`redis`）。
如不同，用环境变量覆盖：
```bash
MYSQL_CONTAINER=mysql MYSQL_ROOT_PASSWORD=xxx \
REDIS_CONTAINER=redis REDIS_PASSWORD=xxx \
DBS="privacy1 privacy2 privacy3" sudo bash install.sh
```

安装脚本会：①自动定位容器 ②**先备份** `sys_auth`+`sys_ra` 到 `backups/<时间戳>/`
③应用 `sql/01_demand_menu.sql`(224 功能点) 与 `sql/02_unlock_pages.sql`(解锁+`auth_code`扩到varchar64)
④清 redis 缓存 `sys_auth:bfs_list` ⑤校验（每库 demand_leaves=224 / unlock_codes=255）。

## 安装后
- 让用户**重新登录**（admin/123456）刷新侧边栏；
- 若菜单未变：再次清缓存或 `docker restart application0 application1 application2`。

## 回滚
```bash
sudo bash rollback.sh                 # 用最新一次备份
sudo bash rollback.sh backups/<时间戳>  # 指定备份
```
或手动：`DELETE FROM sys_auth WHERE auth_id>=2000 AND auth_id<30000;`
`DELETE FROM sys_ra WHERE auth_id>=2000 AND auth_id<30000;` 再清缓存。

## 说明
- **幂等**：脚本内 SQL 对 `auth_id` 2000-2018/20xxx(功能点) 与 26000+(解锁) 段先删后插，可重复执行。
- **不影响原有 66 项基础菜单**（项目/模型/匿踪/求交/资源/系统设置/推理/日志）。
- 两部分内容：①根「基于隐私计算的数据可信共享」下 224 功能点（验收对照）；②解锁 255 个前端路由使页面可打开。
- 若客户前端是**裁剪版**（缺页面路由），菜单仍会显示但部分页面打不开——需替换为完整版前端镜像。
- 字符集：脚本统一用 `--default-character-set=utf8mb4`，避免中文乱码（这是最常见的坑）。

## Logo 修复（PrimiHub）
`install.sh` 末尾会自动调用 `logo-fix.sh`，把侧边栏老 logo(`logo-DataItem.png`)替换为 PrimiHub logo：
- 即时：`docker cp assets/logo-primihub.png` 覆盖容器内 `/images/logo-DataItem.png` 与 `static/img/logo-DataItem.*.png`；
- 持久化：自动给 compose 的前端服务加 bind-mount（备份原 compose），重建 `nginx*` 服务后长期生效。
- 单独执行：`sudo bash logo-fix.sh`；跳过：`SKIP_LOGO=1 sudo bash install.sh`。
- 浏览器需强刷(Ctrl+F5)。若前端容器重建后 logo 复原，重跑 `logo-fix.sh` 或确认 compose 挂载已生效。
