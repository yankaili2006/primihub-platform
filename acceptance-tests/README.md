# PrimiHub 平台 — 44 缺陷验收测试体系（acceptance-tests）

黑盒验收/回归测试套件：以 HTTP 驱动**已部署的**平台，量出「隐私计算数据可信共享缺陷问题.docx」
列出的 44 条 UI 缺陷逐条是否满足需求。**不依赖平台源码即可运行**（源自 pCloud skill
`primihub-platform-func`，此处为可移植子集，去掉了 pCloud 专属的 Fragments/Web/agent-browser 部分）。

## 结构

```
acceptance-tests/
├── run_acceptance.py         # 最小 CLI：跑 44 缺陷在线验收
├── automation/               # 黑盒驱动（登录握手/CRUD/功能点/缺陷真源/评判器）
│   ├── client.py             # RSA 登录 + 认证 API 客户端（仅 stdlib + 可选 crypto）
│   ├── config.py             # 目标平台/18 模块/demand.csv 解析
│   ├── crud.py functions.py  # 通用 CRUD + 224 功能点注册
│   ├── defects.py            # 44 缺陷唯一真源（DEFECTS D01..D44）
│   └── defect_check.py       # 在线评判器：pass/fail/skip/manual
├── tests/                    # pytest：离线不变量 + 在线验收(@live 无平台自动 skip)
├── data/demand.csv           # 需求功能点计数表（附表3，224 点）
├── docs/                     # 缺陷根因分析 + 修复 runbook + 部署硬化 SQL + 证据截图
└── pyproject.toml
```

## 运行

```bash
# 离线不变量（无需平台，锁死 demand.csv↔18模块↔44缺陷↔CRUD 不漂移）
python3 -m pytest tests/ -m "not live" -q            # 应全绿

# 在线验收（有平台时）
PRIMIHUB_WEB_URL=http://<vm>:30811 PRIMIHUB_USER=admin PRIMIHUB_PASS=<pw> \
    python3 run_acceptance.py            # 44 条 pass/fail/skip/manual 报告
python3 run_acceptance.py --json         # 机读
python3 run_acceptance.py D27            # 单条
# 等价 pytest：PRIMIHUB_WEB_URL=... python3 -m pytest tests/test_defects_online.py -v
```

依赖：Python 3.9+；在线登录需 `cryptography`/`pycryptodome`/`rsa` 三选一（RSA 加密口令）。

## 判据（诚实边界）

`pass`=满足 / `fail`=可达但未满足(真·未修) / `skip`=需真实数据或网络抖动 /
`manual`=保存写操作/假成功/时间字段等需人工浏览器。详见 `docs/defect-analysis-2025.md`
（8 族根因分析 + 严重度分级 + 浏览器实测 §8 + 与 regression-smoke 映射）。

## 部署硬化 SQL

`docs/deploy-hardening/*.sql` 为幂等的部署库修复（列漂移 ALTER、RBAC 按钮种子等），
建议随平台部署 kit 一起应用（详见 `docs/platform-fixes-runbook.md`）。
