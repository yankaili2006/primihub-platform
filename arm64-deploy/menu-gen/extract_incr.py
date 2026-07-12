#!/usr/bin/env python3
# Harvest auth_name -> (auth_code, auth_url) from all increment scripts,
# handling the 3 different column layouts (VALUES-style only; @var parents ignored).
import re,csv,io,json,os
BASE="/Users/primihub/pcloud/external/primihub-platform/primihub-service/script/"
# order: canonical winners LAST (merged.update → last wins)
SCRIPTS=["federated_menu_permissions.sql","federated_menu_permissions_fixed.sql",
 "node_management_permissions.sql","node_management_permissions_updated.sql",
 "whitelist_button_permissions.sql","shared_dataset_permissions.sql",
 "data_requirement_permissions.sql","new_modules_permissions.sql",
 "police_data_fusion_permissions.sql","log_management_permissions.sql"]

def split_fields(s):
    """split a tuple body on top-level commas (paren+quote aware)."""
    depth=0;inq=False;q=None;esc=False;cur=[];out=[]
    for ch in s:
        if inq:
            cur.append(ch)
            if esc:esc=False
            elif ch=='\\':esc=True
            elif ch==q:inq=False
            continue
        if ch in "'\"":inq=True;q=ch;cur.append(ch);continue
        if ch=='(':depth+=1;cur.append(ch);continue
        if ch==')':depth-=1;cur.append(ch);continue
        if ch==',' and depth==0:out.append(''.join(cur));cur=[];continue
        cur.append(ch)
    out.append(''.join(cur))
    return [x.strip() for x in out]

def unq(v):
    v=v.strip()
    if len(v)>=2 and v[0]==v[-1] and v[0] in "'\"": return v[1:-1].replace("\\'","'")
    return v

def split_tuples(body):
    """yield raw inner strings of top-level (...) groups, paren-depth aware."""
    depth=0; cur=[]; out=[]
    inq=False; q=None; esc=False
    for ch in body:
        if inq:
            cur.append(ch)
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==q: inq=False
            continue
        if ch in "'\"": inq=True;q=ch;cur.append(ch);continue
        if ch=='(':
            depth+=1
            if depth==1: cur=[];continue
        if ch==')':
            depth-=1
            if depth==0: out.append(''.join(cur));continue
        if depth>=1: cur.append(ch)
    return out

def parse(path):
    sql=open(path,encoding='utf-8',errors='replace').read()
    res={}
    for m in re.finditer(r"INSERT\s+INTO\s+`?sys_auth`?\s*\(([^)]*)\)\s*VALUES(.*?);",sql,re.S|re.I):
        cols=[c.strip().strip('`').lower() for c in m.group(1).split(',')]
        try:
            i_name=cols.index('auth_name');i_code=cols.index('auth_code')
        except ValueError: continue
        i_url=cols.index('auth_url') if 'auth_url' in cols else None
        for t in split_tuples(m.group(2)):
            vals=split_fields(t)
            if len(vals)<len(cols): continue
            name=unq(vals[i_name]);code=unq(vals[i_code])
            url=unq(vals[i_url]) if i_url is not None else ''
            if not url.startswith('/'): url=''
            if name and not name.startswith('@'):
                res[name]=(code,url)
    return res

merged={}
per={}
for s in SCRIPTS:
    p=BASE+s
    if not os.path.exists(p): continue
    r=parse(p); per[s]=len(r); merged.update(r)
for s,n in per.items(): print(f"{n:4d}  {s}")
print("----\nmerged unique names:",len(merged))
json.dump(merged,open('/tmp/incr_namemap.json','w'),ensure_ascii=False,indent=1)
# show a few
for k in list(merged)[:8]: print("  ",k,"->",merged[k])
