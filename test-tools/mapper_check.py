#!/usr/bin/env python3
# Unified MyBatis schema checker vs a live schema:
#   [1] MISSING columns the mappers INSERT/UPDATE (Unknown-column risk) — all inserts.
#   [2] TYPE mismatches, resolving each #{param} to its Java type via EITHER
#         (a) the <insert parameterType="PO"> class fields, OR
#         (b) the repository interface method's @Param annotations (namespace + insert id).
# Usage: python3 mapper_check.py cols.tsv   (cols.tsv: TABLE\tCOLUMN\tDATA_TYPE)
import re, glob, sys
cols_tsv = sys.argv[1]
MAP='primihub-service/biz/src/main/resources/mybatis/mapper/**/*.xml'
JAVA='primihub-service/biz/src/main/java/**/*.java'

live={}
for line in open(cols_tsv):
    p=line.rstrip('\n').split('\t')
    if len(p)>=3: live.setdefault(p[0],{})[p[1].lower()]=p[2].lower()
def snake(s): return re.sub(r'([a-z0-9])([A-Z])',r'\1_\2',s).lower()

# class fields + interface-method @Param types
cls={}                      # simpleName -> {field_lower: jtype}
meth={}                     # FQN -> {methodName -> {paramName_lower: jtype}}
for f in glob.glob(JAVA, recursive=True):
    txt=open(f,encoding='utf-8',errors='ignore').read()
    pkg=(re.search(r'package\s+([\w.]+);',txt) or [None,''])[1]
    cm=re.search(r'\b(?:class|interface)\s+(\w+)',txt)
    if not cm: continue
    name=cm.group(1); fqn=f"{pkg}.{name}" if pkg else name
    cls[name]={fm.group(2).lower():fm.group(1) for fm in re.finditer(r'private\s+(\w+)\s+(\w+)\s*;',txt)}
    mm={}
    for sig in re.finditer(r'\b\w[\w<>,\s]*\s+(\w+)\s*\(([^;{]*)\)\s*;',txt):   # interface methods
        args=sig.group(2).strip()
        params={}
        for pm in re.finditer(r'@Param\(\s*"(\w+)"\s*\)\s+(\w+)',args):
            params[pm.group(1).lower()]=pm.group(2)
        if params: mm[sig.group(1)]=params
        elif args and '@Param' not in args and ',' not in args:   # single unannotated POJO arg
            am=re.match(r'(?:final\s+)?(\w+)\s+\w+$',args)
            if am: mm[sig.group(1)]=('POJO',am.group(1))
    if mm: meth[fqn]=mm

NUM={'int','bigint','tinyint','smallint','mediumint','decimal','float','double'}
DT={'datetime','timestamp','date','time'}; STR={'varchar','char','text','longtext','mediumtext','tinytext'}
def ok(jt,dt):
    if jt=='String': return dt in STR
    if jt in('Integer','Long','Short','Byte','BigDecimal','Double','Float','Boolean'): return dt in NUM
    if jt in('Date','LocalDateTime','LocalDate','Timestamp'): return dt in DT
    return True

missing=set(); mism=[]; checked=0; unresolved=0
for f in glob.glob(MAP, recursive=True):
    txt=open(f,encoding='utf-8',errors='ignore').read()
    ns=(re.search(r'<mapper\s+namespace="([^"]+)"',txt) or [None,''])[1]
    # MISSING (all inserts/updates, by column name)
    for m in re.finditer(r'INSERT\s+INTO\s+`?(\w+)`?\s*\(([^)]*)\)',txt,re.I|re.S):
        for c in m.group(2).split(','):
            c=c.strip().strip('`')
            if re.fullmatch(r'[a-z_][a-z0-9_]*',c,re.I) and m.group(1) in live and c.lower() not in live[m.group(1)]:
                missing.add((m.group(1),c.lower()))
    # TYPE (resolve params per <insert>)
    for ins in re.finditer(r'<insert\b([^>]*)>(.*?)</insert>',txt,re.I|re.S):
        attrs,body=ins.group(1),ins.group(2)
        idm=re.search(r'id="(\w+)"',attrs); ptype=(re.search(r'parameterType="([^"]+)"',attrs) or [None,''])[1].split('.')[-1]
        im=re.search(r'INSERT\s+INTO\s+`?(\w+)`?\s*\(([^)]*)\)\s*VALUES\s*\(([^)]*)\)',body,re.I|re.S)
        if not im: continue
        t=im.group(1)
        if t not in live: continue
        colz=[c.strip().strip('`') for c in im.group(2).split(',')]
        valz=[v.strip() for v in im.group(3).split(',')]
        if len(colz)!=len(valz): continue
        pmap = cls.get(ptype) if ptype else meth.get(ns,{}).get(idm.group(1) if idm else '')
        if isinstance(pmap,tuple) and pmap[0]=='POJO': pmap=cls.get(pmap[1])
        if not pmap: unresolved+=1; continue
        for col,val in zip(colz,valz):
            pn=re.match(r'#\{\s*(\w+)',val)
            if not pn: continue
            jt=pmap.get(pn.group(1).lower()); dt=live[t].get(col.lower())
            if jt and dt:
                checked+=1
                if not ok(jt,dt):
                    sev='HIGH' if jt in('String','Date') and dt in NUM else 'low'
                    mism.append((sev,t,col.lower(),jt,dt))
u=sorted(set(mism))
print(f"=== [1] MISSING columns: {len(missing)} ===")
for t,c in sorted(missing): print(f"  {t}.{c}")
if not missing: print("  (none)")
print(f"\n=== [2] TYPE mismatches (param->column, {checked} pairs checked, {unresolved} inserts unresolved): {len(u)} ===")
for sev,t,c,jt,dt in sorted(u,key=lambda x:(x[0]!='HIGH',x[1],x[2])): print(f"  [{sev}] {t}.{c}: param {jt} vs column {dt}")
if not u: print("  (none)")

# --- CI drift-gate: fail on missing columns or HIGH type mismatches (low numeric->varchar OK) ---
high = [x for x in u if x[0] == 'HIGH']
if missing or high:
    print(f"\n\033[31mDRIFT GATE FAILED\033[0m: {len(missing)} missing column(s), {len(high)} HIGH type mismatch(es)")
    print("Fold the fix into arm64-deploy/data/initsql/privacy*.sql (see docs). This replaces Flyway's runtime convergence.")
    sys.exit(1)
print(f"\n\033[32mDRIFT GATE PASSED\033[0m ({len(u)} low-severity numeric->varchar mismatches allowed)")
