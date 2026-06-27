# 线上 106.53.4.114 应用「需求功能点菜单」runbook

把 demand.csv 的 18 模块 / 224 功能点补到线上隐私计算平台（`#/privateSearch/list`）。
基础 66 项菜单不动；需求树挂在 `auth_id=2000` 根下；幂等（`auth_id≥2000` 段先删后插，可反复跑/回滚）。

前置：本机无法连 106.53.4.114（SSH 密码被拒、3306 不对外）。以下命令在**有权限的人**那台机器/集群里执行。

---

## 0. 进入数据库所在环境

k8s 部署（NodePort 30811），MySQL 多半是集群内 pod：

```bash
# 登陆节点后
kubectl get pods -A | grep -iE 'mysql|maria'
POD=<mysql-pod>; NS=<namespace>
kubectl -n $NS exec -it $POD -- bash      # 进入 pod
# 或 docker：  docker ps | grep mysql ; docker exec -it <id> bash
```
root 密码见部署 env（离线包默认 `MYSQL_ROOT_PASSWORD=root`）。

## 1. 确认库名（base 树是 privacy1 体系，线上实际库名可能不同）

```bash
mysql -uroot -proot -e "SHOW DATABASES;"
# 找出含 sys_auth 且有「项目管理」的库：
for d in $(mysql -uroot -proot -N -e "SHOW DATABASES" | grep -iE 'privacy'); do
  c=$(mysql -uroot -proot -N "$d" -e "SELECT COUNT(*) FROM sys_auth WHERE auth_name='项目管理'" 2>/dev/null)
  [ "$c" = "1" ] && echo "TARGET DB = $d"
done
```
记下 `DB=<上面输出的库名>`。

## 2. 备份（务必先做）

```bash
mysqldump -uroot -proot --default-character-set=utf8mb4 "$DB" sys_auth sys_ra \
  > /tmp/menu_backup_$(date +%F).sql
wc -l /tmp/menu_backup_*.sql      # 确认非空
```

## 3. 应用（把 rebuild_demand_menu.sql 拷进该环境后）

```bash
mysql -uroot -proot --default-character-set=utf8mb4 "$DB" < rebuild_demand_menu.sql
# 若 root@'%' 不可登，用 root@localhost（在 pod/容器内即本地）
```
> ⚠️ 必须带 `--default-character-set=utf8mb4`，否则中文按 latin1 入库会乱码且长名报 "Data too long"。

## 4. 验证

```bash
mysql -uroot -proot --default-character-set=utf8mb4 "$DB" -e "
SELECT COUNT(*) total           FROM sys_auth WHERE is_del=0;                              -- 期望 309
SELECT COUNT(*) demand_modules  FROM sys_auth WHERE p_auth_id=2000 AND is_del=0;           -- 期望 18
SELECT COUNT(*) demand_leaves   FROM sys_auth WHERE auth_depth=2 AND r_auth_id=2000 AND is_del=0; -- 期望 224
SELECT COUNT(*) orphans FROM sys_auth a WHERE a.is_del=0 AND a.p_auth_id<>0
  AND NOT EXISTS(SELECT 1 FROM sys_auth p WHERE p.auth_id=a.p_auth_id AND p.is_del=0);     -- 期望 0
"
```
也可从外部直接看树（无需登录）：
```bash
curl -s 'http://106.53.4.114:30811/prod-api/sys/auth/getAuthTree' | python3 -c \
 "import sys,json;d=json.load(sys.stdin)['result']['sysAuthRootList'];print('top menus',len(d));print([n['authName'] for n in d])"
```
应能看到新增根「基于隐私计算的数据可信共享」。前端可能需清缓存/重新登录刷新侧边栏。

## 5. 回滚

```bash
mysql -uroot -proot --default-character-set=utf8mb4 "$DB" -e "
DELETE FROM sys_auth WHERE auth_id>=2000 AND auth_id<30000;
DELETE FROM sys_ra   WHERE auth_id>=2000 AND auth_id<30000;"
# 或整体恢复备份：
mysql -uroot -proot --default-character-set=utf8mb4 "$DB" < /tmp/menu_backup_<日期>.sql
```

## 注意
- 77/224 叶子挂了真实接口 url/code（前端有对应路由才可点开）；其余 147 为菜单占位，仅用于功能点清单展示/验收勾选。
- 已授权给 role 1（超管）与 role 1000（业务）。admin 重新登录即可在侧边栏 / 菜单管理 看到。
