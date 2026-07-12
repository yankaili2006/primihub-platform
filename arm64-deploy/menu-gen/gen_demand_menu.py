#!/usr/bin/env python3
# Generate spec-faithful menu sub-tree from demand.csv into base sys_auth schema.
# Reuses REAL auth_code/auth_url from base(66) + increment scripts where names match.
# Usage: python3 gen_menu.py <db_name> <out.sql>
import json,sys

DB  = sys.argv[1] if len(sys.argv)>1 else 'privacy1'
OUT = sys.argv[2] if len(sys.argv)>2 else '/tmp/privacy_menu_rebuild.sql'

spec = json.load(open('/tmp/demand_spec.json'))['menus']
base = json.load(open('/tmp/base_namemap.json'))   # cn_name -> [code,url]  (working pages)
incr = json.load(open('/tmp/incr_namemap.json'))   # cn_name -> [code,url]  (prev-version pages)
# base wins ties (currently-deployed working pages)
enriched = {**incr, **base}

# curated demand-name -> source cn_name (where wording differs)
curated = {
    '用户列表展示':'用户管理','新增用户':'用户新增','删除用户':'用户删除',
    '角色列表':'角色管理','增加角色':'角色新增','编辑角色':'角色编辑','删除角色':'角色删除',
    '新建项目':'新建项目','删除项目':'关闭项目','项目列表':'项目列表',
}
def lookup(fn):
    if fn in enriched: return enriched[fn]
    if fn in curated and curated[fn] in enriched: return enriched[curated[fn]]
    return None

def leaf_type(name):
    return 2 if any(k in name for k in ('列表','展示','概览','首页','工作台','查询','详情')) else 3

CID=2000; DA='own'
rows=[]; ra=[]; reused=0; gen=0
rows.append((CID,'基于隐私计算的数据可信共享','DemandRoot',1,0,CID,str(CID),'',0,100)); ra.append(CID)
for i,(module,funcs) in enumerate(spec.items(),1):
    mid=CID+i
    rows.append((mid,module,f'DM{i:02d}',1,CID,CID,f'{CID},{mid}','',1,i)); ra.append(mid)
    for j,fn in enumerate(funcs,1):
        lid=20000+i*100+j
        hit=lookup(fn)
        if hit and hit[0]:
            code,url=hit[0],(hit[1] or f'/demand/m{i:02d}/f{j:03d}'); reused+=1
            if len(code)>32:                       # auth_code is varchar(32)
                code=f'DM{i:02d}F{j:03d}'           # keep real url, shorten code
        else:
            code,url=f'DM{i:02d}F{j:03d}',f'/demand/m{i:02d}/f{j:03d}'; gen+=1
        rows.append((lid,fn,code,leaf_type(fn),mid,CID,f'{CID},{mid},{lid}',url,2,j)); ra.append(lid)

esc=lambda s:s.replace("\\","\\\\").replace("'","\\'")
o=['-- ============================================================',
   'SET NAMES utf8mb4;',
   f'USE `{DB}`;',
   '-- privacy_full menu rebuild: demand.csv 18 modules / 224 funcs',
   '-- base 66 menus kept intact; demand tree under root auth_id=2000',
   '-- ============================================================',
   'DELETE FROM `sys_auth` WHERE `auth_id` >= 2000 AND `auth_id` < 30000;',
   'DELETE FROM `sys_ra`   WHERE `auth_id` >= 2000 AND `auth_id` < 30000;']
for (aid,name,code,typ,pid,rid,fp,url,depth,idx) in rows:
    o.append("INSERT INTO `sys_auth` (`auth_id`,`auth_name`,`auth_code`,`auth_type`,`p_auth_id`,"
      "`r_auth_id`,`full_path`,`auth_url`,`data_auth_code`,`auth_index`,`auth_depth`,"
      "`is_show`,`is_editable`,`is_del`) VALUES "
      f"({aid},'{esc(name)}','{esc(code)}',{typ},{pid},{rid},'{fp}','{esc(url)}','{DA}',{idx},{depth},1,1,0);")
for role in (1,1000):
    for aid in ra:
        o.append(f"INSERT INTO `sys_ra` (`role_id`,`auth_id`,`is_del`) VALUES ({role},{aid},0);")
open(OUT,'w',encoding='utf-8').write('\n'.join(o)+'\n')
print(f"[{DB}] modules={len(spec)} leaves={sum(len(v) for v in spec.values())} "
      f"sys_auth_rows={len(rows)} reused_real_pages={reused} menu_only={gen} -> {OUT}")
