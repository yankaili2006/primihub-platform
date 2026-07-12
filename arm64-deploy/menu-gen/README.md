# 需求功能点菜单生成（demand.csv → sys_auth）

把 demand.csv 的 18 模块 / 224 功能点生成为隐私计算平台的菜单树（sys_auth），
作为自包含子树挂在根节点 auth_id=2000「基于隐私计算的数据可信共享」下，
并授权给超管(role 1)与业务角色(role 1000)。基础 66 项菜单保持不动。

## 复现
```
# 1. demand_spec.json 由 demand.csv 解析得到（菜单→功能名）
# 2. base_namemap.json = 基础包 privacy1.sql 的 名称→(code,url)
# 3. incr_namemap.json = 各增量脚本 名称→(code,url)（提取：python3 extract_incr.py）
python3 gen_demand_menu.py privacy1 /tmp/rebuild_privacy1.sql
python3 gen_demand_menu.py privacy2 /tmp/rebuild_privacy2.sql
python3 gen_demand_menu.py privacy3 /tmp/rebuild_privacy3.sql
# 然后把 rebuild_privacyN.sql 追加到 data/initsql/privacyN.sql 末尾
# （已 bake：见 privacyN.sql 中 "DEMAND-MENU REBUILD" 标记块）
```

## 验证（mysql 5.7 entrypoint，三库各 309 行 / 18 模块 / 224 功能点）
```
docker run -d --name t -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=nacos_config \
  -e MYSQL_USER=primihub -e MYSQL_PASSWORD=primihub@123 \
  -v $PWD/../data/initsql:/docker-entrypoint-initdb.d:ro \
  <mysql-image> --character-set-server=utf8mb4
```
77/224 叶子复用了真实接口 url（base + 增量脚本），其余 147 为菜单占位。
