# PrimiHub 平台 44 缺陷：根因分析与验收覆盖

> 真源 = 项目根 `隐私计算数据可信共享缺陷问题.docx`（44 条 UI 缺陷），结构化为
> `automation/defects.py::DEFECTS`。本文档 = **根因剖析（8 族）+ 逐条精析 + 严重度分级 +
> 修复优先级 + 验收方式**。缺陷计数由代码推导（`python3 -m automation.defects`），不手工重录。

## 0. 一句话结论

44 条缺陷 **不是 44 个独立 bug，而是 8 个根因族**：同一根因往往炸出多条，改一处绿一片。
runbook 已落地 Fix1–13 + Feature1–6（平台镜像迭代到 `...s`），覆盖了 A/B/C/D/E/F 各族的
**一部分**；**G（写操作无响应）/H（时间字段）基本未动**。从"数据可信共享"视角，**C 族假成功
最该零容忍**（静默数据丢失，破坏信任前提）。

> **⚡ 浏览器实测更新（见 §8）**：经中转隧道 + agent-browser 连到活平台 VM131 实测，**族 G
> 的监控告警保存(D12–D17)真根因是前端"Maximum call stack size exceeded"栈溢出**（点保存
> 直接抛 JS 错、根本不发请求），**不是**"后端端点未知"——修复在前端而非 DB/后端。API 层探针
> 无法发现此类前端 bug，必须浏览器验证。

## live 基线速览（VM131 primihub-full-clean, admin/123456）

`skill.py verify-defects` 实测：**22 满足 / 9 未满足 / 2 待数据 / 11 需手工**（`docs/e2e-proof/
baseline-vm131-clean.json`）。浏览器复核把其中若干"满足/需手工"的真相还原（§8）。

---

## 1. 八大根因族

| 根因族 | 缺陷 | 已修 | 本质 | runbook 模板 |
|--------|------|------|------|------------|
| **A. 部署库↔代码 schema 漂移** | D01,D07-D09,D26,D27 | D26✅ | 部署 DB 表结构/mapper 与代码期望分叉 | Fix3/4/5/8 |
| **B. RBAC 按钮权限种子缺失** | D02,D03 | D02✅ | 前端按权限渲染按钮，种子没灌→按钮不出现 | Fix2 |
| **C. 假成功（内存 mock 伪持久化）** | D22,D24,D28,D31 | D28✅ | 后端恒返回成功但**不落库/不真触发** | Fix9 |
| **D. 导出空桩/假下载** | D10,D19,D34,D35,D37,D42 | D19✅ | 导出是空实现→空文件/乱码/无数据也报成功 | Fix10 |
| **E. 整页/整模块后端缺失** | D04,D05,D32-D34,D38-D40,D43,D44 | D38-40✅ | 控制器/路由根本不存在→404/"功能开发中" | Fix11 / Feature1-6 |
| **F. 搜索匹配污染/特殊字符崩** | D27,D29,D36,D41 | — | "-001"特殊字符崩、"001"返回无关数据 | Fix8 |
| **G. 写操作无响应（保存不工作）** | D06,D12-D17,D20,D21,D23 | — | 点保存/确定页面无响应，端点缺失或未接线 | 无（未修重灾区） |
| **H. 时间字段/时区映射** | D11 | — | 创建时间显示≠实时（UTC/CST 或字段映射） | 无 |

### A — 部署库 ↔ 代码 schema 漂移（最隐蔽）
填完点确定→无响应/请求异常；或新建成功但列表"看不见"。实锤根因：`sys_user` 缺
`first_login` 列（Fix3）；`tenant_isolation_config` 缺 `cpu_quota` 列（Fix4）；**写库 primary、
读库 fusion 分裂**→"新建后看不见"（Fix5 根因级）；日志 mapper 与真实表 schema 分叉→搜索
"查询失败"（Fix8）。**根治点在镜像/init SQL/compose 模板**，热补丁治标；runbook 已指出
kit 里 fusion 侧 `sys_*` 灌入步骤缺失，是**上游部署可复现性缺口**（需全栈全新部署冒烟确认）。

### B — RBAC 按钮权限种子缺失
前端按 `sys_auth`/`sys_ra` 按钮级权限渲染"新增"按钮；种子 SQL 没灌→按钮不渲染（Fix2，非前端
bug）。D02 已修，**D03 是同模式未做**——照抄 Fix2 给租户模块补按钮权限种子即可。

### C — 假成功（对"数据可信共享"最致命）
后端用**内存 mock 伪装持久化**，恒返回成功但不落库/不真触发同步（Fix9 实锤共享数据集）。
在"可信共享"平台里，"假成功"= **用户以为共享/合作/同步成功了，实际什么都没发生**——静默数据
丢失，比报错危害大一个数量级。D28 已按"真持久化"修好，**D22/D24/D31 同族未修，应最优先**。

### D — 导出空桩/假下载
导出是空实现→空文件、UTF-8 无 BOM 乱码、"提示开始下载但下不动"、无数据也走导出（Fix10：
空桩+路由不可达+结果读取三重）。D19 经 Feature1 补齐；分析结果导出经 Fix10 修好可作模板。
剩余 5 条按 Fix10 模式（真实结果读取 + BOM + 无数据拦截）逐个套。

### E — 整页/整模块后端缺失（工作量最大）
控制器/路由根本不存在，或前端调不存在的接口（Fix11：控制器类前缀多带被剥的 `sys/`→整页
404；Feature1-6：后端整块缺失需补齐）。联邦学习大模块经 Feature4/5/6 打通（D38/39/40✅）；
**联邦求差 D32-34、警务 D43、电子证照 D44、租户隔离页 D04/05 仍整块缺失**——要补后端+前端。

### F — 搜索匹配污染/特殊字符崩
两种根因：特殊字符 `-` 未转义/未参数化→模糊查询直接崩（D27/D29）；匹配未加 scope/未精确→
输"001"把无关数据也返回（D36/D41 污染）。Fix8 修了操作日志搜索，同款参数化 + 精确匹配可套。

### G — 写操作无响应（未修重灾区）
点保存/提交/确定→页面无响应或请求异常。根因待定位：保存按钮未接后端端点，或后端保存端点
缺失。监控告警 6 条（getXxxMonitor 只读端点存在，但**保存端点未知**）最集中。**基本未动，且无
安全只读端点可自动验收**→在线测试标 `manual`，需浏览器人工 + 抓包定位保存端点。

### H — 时间字段/时区
后端存 UTC、前端本地显示错位（差 8h），或 `created_time` 字段映射/默认值错。单点，低优先。

---

## 2. 逐条缺陷精析（docx 原文 → 根因族 / 严重度 / 状态）

严重度：🔴致命(静默数据丢失) 🟠严重(核心功能缺失) 🟡高(核心CRUD/查询不可用) 🟢中(辅助) ⚪低(UI)

| ID | docx 现象（摘） | 族 | 严重 | 状态 | 验证 |
|----|----------------|----|----|------|------|
| D01 | 用户管理 新增用户点确定无响应 | A | 🟡 | 未修(~Fix3/5) | roundtrip |
| D02 | 白名单列表 无新增按钮 | B | ⚪ | ✅Fix2 | has_button |
| D03 | 租户列表 无新增按钮 | B | ⚪ | 未修(类Fix2) | has_button |
| D04 | 租户间计算流程隔离 进入 404 | E | ⚪ | 未修 | route_exists |
| D05 | 租户流程隔离 进入 404 | E | ⚪ | 未修 | route_exists |
| D06 | 时间戳管理 申请时间戳提交无响应 | G | 🟢 | 未修 | manual |
| D07 | 操作日志定义 新增点确定请求异常 | A/G | 🟡 | 未修(~Fix8) | route_exists |
| D08 | 调度日志定义 新增点确定请求异常 | A/G | 🟡 | 未修(~Fix8) | route_exists |
| D09 | 计算日志定义 新增点确定请求异常 | A/G | 🟡 | 未修 | route_exists |
| D10 | 计算日志记录 无数据也导出+乱码 | D | 🟢 | 未修(~Fix10) | export_nonempty* |
| D11 | 新增角色 创建时间≠实时 | H | 🟢 | 未修 | manual |
| D12 | 操作系统CPU告警保存无响应 | G | 🟢 | 未修 | manual |
| D13 | 操作系统内存告警保存无响应 | G | 🟢 | 未修 | manual |
| D14 | 操作系统磁盘告警保存无响应 | G | 🟢 | 未修 | manual |
| D15 | 数据库监控告警保存无响应 | G | 🟢 | 未修 | manual |
| D16 | 中间件JVM告警保存无响应 | G | 🟢 | 未修 | manual |
| D17 | 中间件Redis告警保存无响应 | G | 🟢 | 未修 | manual |
| D18 | 项目列表 新增项目无响应无提示 | A/G | 🟡 | 未修(需外部依赖) | route_exists |
| D19 | 项目台账导出 下载失败 | D | 🟢 | ✅Feature1 | export_nonempty* |
| D20 | 节点管理 创建机构请求异常 | E/G | 🟡 | 未修 | route_exists* |
| D21 | 接入方管理 新增请求异常 | A/G | 🟡 | 未修 | roundtrip |
| D22 | 合作方管理 建立合作**假成功**无法新增 | C | 🔴 | 未修 | manual |
| D23 | 审批工作流 创建请求异常 | E/G | 🟡 | 未修 | manual |
| D24 | 数据交换日志 触发同步**假成功** | C | 🔴 | 未修 | manual |
| D25 | 我的资源 新建资源保存异常 | A/G | 🟡 | 未修(需外部依赖) | route_exists* |
| D26 | 数据需求列表 新增需求异常 | A | 🟡 | ✅Fix7 | route_exists |
| D27 | 数据需求 "-001"搜索崩 | F | 🟡 | 未修(~Fix8) | search_scoped |
| D28 | 共享数据集 新增**假成功** | C | 🟡 | ✅Fix9 | route_exists* |
| D29 | 共享数据集 "-001"搜索崩 | F | 🟡 | 未修 | search_scoped |
| D30 | 接口列表 新增无响应 | A | 🟡 | ✅crud已绿 | roundtrip |
| D31 | 接口日志 无数据报**导出成功** | C/D | 🔴 | 未修 | export_nonempty* |
| D32 | 联邦求差 **功能不存在** | E | 🟠 | 未修 | route_exists |
| D33 | 联邦求差日志记录 **不存在** | E | 🟠 | 未修 | route_exists |
| D34 | 联邦求差日志导出 **不存在** | E/D | 🟠 | 未修 | export_nonempty* |
| D35 | 联邦统计结果导出 下载失败 | D | 🟢 | 未修(~Fix10) | export_nonempty* |
| D36 | 联邦统计日志 "001"搜索污染 | F | 🟡 | 未修 | search_scoped |
| D37 | 联邦统计日志导出 下载失败 | D | 🟢 | 未修 | export_nonempty* |
| D38 | 联邦学习整模块报"请求错误/加载失败" | E | 🟠 | ✅Feature5/6 | route_exists |
| D39 | 单方数据 只有合并/指标缺失 | E | 🟠 | ✅Feature4 | route_exists |
| D40 | 创建联邦学习任务 "功能开发中" | E | 🟠 | ✅Feature5 | route_exists |
| D41 | 联邦学习日志 "001"搜索污染(docx误标于联邦统计) | F | 🟡 | 未修 | search_scoped |
| D42 | 联邦学习日志导出 下载失败 | D | 🟢 | 未修 | export_nonempty* |
| D43 | 警务数据融合整模块不可用 | E | 🟠 | 未修 | route_exists |
| D44 | 电子证照对比整模块不可用 | E | 🟠 | 未修 | route_exists |

（`*` = inferred 端点，未在现有 skill 代码确认，在线若路由不存在如实记 fail。）

---

## 3. 修复优先级（投入产出比）

1. **族 C 假成功 D22/D24/D31**（🔴致命 + 有 Fix9 模板，改动小）——先止血"数据不可信"。
2. **族 B D03 + 族 F D29/D36/D41**（低成本，照抄 Fix2/Fix8 已验证模式）。
3. **族 D 剩余 5 条导出 D10/D34/D35/D37/D42**（套 Fix10 模式，中等工作量）。
4. **族 G 监控告警 D12-D17 + D06/D20/D21/D23**（需先抓包定位保存端点，判前端未接线还是后端缺失）。
5. **族 E 整模块 D32-D34/D43/D44/D04/D05**（后端+前端从零补，工作量最大，排最后）。

## 4. 验证方式语义（诚实边界）

在线评判器 `automation/defect_check.py::evaluate()` 产出 `pass/fail/skip/manual`：

| assert_kind | 证明 | 不证明 |
|-------------|------|--------|
| `roundtrip` | 安全 create→edit→delete 全绿 | — 最强证据 |
| `route_exists` | 端点已接线（非 404/whitelabel/系统异常） | 不证明写入真成功 |
| `code0`/`has_button` | 安全 GET code=0（页面加载） | 按钮**可视性**仍需人工 |
| `search_scoped` | 搜 "001"/"-001" 返回行全含关键字 | 无数据判 pass |
| `export_nonempty` | 导出非空文件体或 code=0 | inferred 路由不存在→fail |
| `manual` | —（跳过自动） | 保存写操作/假成功/时间字段：**必须**人工浏览器 |

路由缺失判定与 `scripts/regression-smoke.py` 同源（HTTP 404 / Spring `path` / '系统异常'）。

## 5. 与 regression-smoke.py 映射

| smoke 项 | 对应缺陷 |
|----------|---------|
| 数据需求搜索 #26/E | D26 / D27 |
| 共享数据集 list G | D28 / D29 |
| 分析结果导出路由 G | D35 家族 |
| 单方作业 preprocess/log list H | D39 |
| 联邦学习工作台 overview/options H | D38 / D40 |

smoke 关注"镜像迭代无回归"，本缺陷验收关注"44 条是否满足需求"，两者并跑互补。

## 6. 复跑

```bash
cd skills/primihub-platform-func
python3 -m pytest tests/ -m "not live" -q                     # 离线不变量（现在就绿）
PRIMIHUB_WEB_URL=http://<vm>:30811 PRIMIHUB_PASS=<pw> python3 skill.py verify-defects  # 在线 44 条
PRIMIHUB_PASS=123456 python3 scripts/regression-smoke.py       # 冒烟不回归
```

## 7. 关键洞察

- **改一处绿一片**：44 条塌缩到 8 族，A/C/D/F 各有一个 runbook 模板（Fix5/9/10/8），同族剩余是复制模式。
- **根治点在部署层不在业务代码**：族 A 漂移、fusion 侧 `sys_*` 灌入缺失是镜像/init SQL/compose 的
  可复现性问题——热补丁治标，全新部署仍复发，除非固化进 kit（runbook 已做一部分，fusion RBAC
  灌入仍缺，需全栈全新部署冒烟确认）。
- **假成功零容忍**：在"可信共享"语境下静默失败比显式报错危害大一个数量级。

## 8. 浏览器实测发现（VM131, agent-browser, 2026-07-15）

经 **本机 →(SSH root@pve101 100.64.0.25)→ VM130/131** SSH 端口转发隧道连到活平台，
用 agent-browser(Chromium) 以 admin/123456 登录 webconsole 逐页复核。截图存
`screenshots/`（D02/D03 无按钮、D01 提交失败、D12 保存栈溢出）。

| 缺陷 | API 层判定 | **浏览器实测真相** | 修复层 |
|------|-----------|-------------------|--------|
| D02 白名单新增按钮 | has_button ✅(页面加载) | ❌ **确认无「新增」按钮、无操作列** | DB 按钮种子(Fix2 已有) |
| D03 租户新增按钮 | has_button ✅(页面加载) | ❌ **确认无「新增」按钮、无操作列** | DB 按钮种子(`fix-d03-tenant-buttons.sql` 已产出) |
| ~~D04/D05 租户隔离页~~ | ~~route missing~~ | ⚠️ **本会话浏览器判定作废**：见下「更正」——实为 skill 假阴性，后端隔离端点已实现 | 无需修(误报) |
| D01 新增用户 | roundtrip fail(MyBatis schema) | ❌ **填满点确定弹窗不关、无成功；且点确定竟不发 XHR** → 疑前端提交处理器亦有问题，叠加后端 schema 漂移 | 前端 + DB schema |
| **D12–D17 监控告警保存** | manual(端点未知) | ❌ **点保存→红色错误 toast "Maximum call stack size exceeded"(前端栈溢出)，不发请求、弹窗不关**（无钩子复现，平台真 bug） | **前端**(save 处理器无限递归) |

**关键纠正**：
- `has_button` 探针（只验列表端点 code=0）**无法发现按钮缺失**——D02/D03 API 报"满足"，
  实际按钮不存在。凡"无按钮"类缺陷，**结论以浏览器为准**。
- D12–D17 此前归 **族 G「后端端点未知」是错的**：真根因是**前端 alarm-config 保存处理器
  爆栈**（`Maximum call stack size exceeded`），请求根本没发出。修复应查前端该组件的
  递归 watcher/computed 或循环引用的 save 载荷，**与 DB/后端无关**。
- D01 点确定**不发 XHR**：除已知的后端建用户 schema 漂移外，前端提交链路疑亦有断点，
  需前端一并排查。

**更正（D04/D05，2026-07-15）**：本会话 §8 曾断言 D04/D05「侧栏无菜单、路由表无隔离节点→404
坐实」——**此结论错误，已作废**。原因：(1) 本 SPA 是 Vue 3，浏览器用 `#app.__vue__` 取路由表
introspection 失败返回 `[]`，被误读为「无隔离路由」；(2) 租户列表 0 条，隔离页是**按租户**的
子页，无租户时根本进不去，非「页面不存在」。fleet 提交 `4e631acc` 已证：后端
`TenantController.getComputeIsolationConfig/getIsolationStatusList` **早已实现**，前端调
`/tenant/isolation/config`、`/tenant/isolation/status/list`（live code=0）；skill 原探的
`/tenant/getTenantIsolationConfig` 是猜错路径才 404。**D04/D05 实为 skill 假阴性，非平台缺陷**，
以 fleet 的 API 核实为准。教训：Vue3 路由 introspection 不能用 `__vue__`；空列表下的按行子页
不可达 ≠ 页面缺失。

**验证环境（可复现）**：
```bash
# 隧道（后台）: 本机 30821 -> VM131:30811 经 pve101
ssh -i ~/.ssh/id_rsa_primihub -N -L 30821:192.168.99.131:30811 root@100.64.0.25
# agent-browser(用户级安装) + no-sandbox chrome 包装
export PATH="$HOME/.npm-global/bin:$PATH"
export AGENT_BROWSER_EXECUTABLE_PATH=/tmp/chrome-ns.sh   # exec 缓存 chromium --no-sandbox
agent-browser open http://localhost:30821/     # admin / 123456
```
