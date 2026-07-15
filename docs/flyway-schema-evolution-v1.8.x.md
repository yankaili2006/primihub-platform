# Flyway 架构演进与 v1.8.x 修复汇总

> 本轮工作：让 primihub-platform **应用自己拥有 schema 演进**（Flyway 版本化迁移随启动幂等应用），
> 取代长期漂移的手维护部署 SQL dump；并在 arm64 离线包上端到端验证功能。
> 发布：`v1.8.0 → v1.8.1 → v1.8.2`，每版经 **GitHub ARM runner 复验 + 全新 VM 重部署** 双重验证。

---

## 1. 交付物

| 项 | 内容 |
|---|---|
| 迁移链 | **Flyway V2–V14**（13 个迁移 + baseline），全新库/存量库幂等收敛 |
| 离线包 | `primihub-offline-arm64-v1.8.2.tar.gz`（OSS 公开，platform+web:v1.8.2） |
| 功能验证 | ~45 个功能端点 / 18 模块，**0 schema 错误** |
| 镜像 | ACR `primihub/{primihub-platform,primihub-web}:v1.8.0/v1.8.1/v1.8.2`（多架构） |
| 工具 | `mapper_check.py`（静态漂移扫描）、`functional_verify.py`（功能冒烟） |

**发布包 sha256**
- v1.8.0 `23c0faab…` · v1.8.1 `43bf99e2…` · v1.8.2 `bc05cc5a…`
- OSS 路径 `https://primihub.oss-cn-beijing.aliyuncs.com/primihub-offline/arm64/primihub-offline-arm64-<ver>.tar.gz`

---

## 2. 迁移链 V2–V14

| 版本 | 迁移 | 作用 |
|---|---|---|
| baseline | — | 标记 initsql dump 引导的基础 schema（不重建） |
| V2 | button_perms | 前端按钮权限（authType=3）+ 授权超管 |
| V3 | v18_tables | 18 张 v1.8.0 后端表（租户/白名单/日志/审批），**从代码对齐的 fusion schema 重生成** |
| V4 | scene_imported_data | 场景导入数据（develop 自带） |
| V5 | scene_base_tables | 场景定制（警务融合/电子证件，模块17-18）基础表 |
| V6 | sys_user_first_login | `sys_user.first_login`（新增用户所需） |
| V7 | complete_feature_tables | ~50 张功能表（存证/联邦/求差求并/监控/项目权限…） |
| V8 | log_definition_type_columns | 3 张日志定义表 `*_type` int→varchar + 补 module_name |
| V9 | extra_feature_tables | 求差/求并/联邦学习/单方计算表 |
| V10 | reconcile_mapper_columns | mapper 引用但缺的 35 列（sys_operation_log 等 5 表） |
| V11 | federated_learning_schema | 联邦学习主表 |
| V12 | organ_tree_columns | `sys_organ` 父/序列列（内部机构树） |
| V13 | missing_feature_tables | 11 张 mapper 用到但从未建的表 |
| V14 | sys_organ_identity | `sys_organ.identity`（创建机构所需） |

---

## 3. PR 分类

### A. Flyway 架构 & 迁移核心
| PR | 说明 |
|---|---|
| **#32** | Flyway-owned schema evolution：自定义 `FlywayMigrationConfiguration` @Bean 绑 primaryDB（arm64=privacy*/生产=fusion*，自动对齐）；baselineOnMigrate/cleanDisabled；`app.flyway.enabled` 开关；引入 V2/V3 |
| **#34** | V3 从**代码对齐的 fusion schema 重生成**（旧 V3 来自陈旧 zz，列名不符）；`flyway-core:7.15.0` 加进 dependencyManagement（否则被 spring-boot BOM 覆盖回 6.4.4） |

### B. Schema 漂移修复（缺列/缺表/类型不符）
| PR | 问题 → 修复 |
|---|---|
| **#38 (V5)** | 新增用户报 `Unknown column 'first_login'` → 补 sys_user.first_login |
| **#39 (V6)** | 新增日志定义：`log_type` int 但代码传 String('登出') Data truncation → int→varchar + 补列 |
| **#41 (V7)** | 静态分析 mapper 发现 35 列缺失（sys_operation_log/whitelist_access_log/tenant_resource_allocation 等）→ 一次性补齐 |
| **#51 (V13)** | contract-check 报 11 张表 mapper 用到但未建 → 从 fusion 补齐（greens contract-check） |
| **#59 (V14)** | 创建机构报 `Unknown column 'identity'`（V12 补了 p_organ_id/organ_index 漏了 identity）→ 补 sys_organ.identity |

### C. 应用启动阻塞（重复 @RequestMapping）
| PR | 说明 |
|---|---|
| **#37** | `SceneController` 重复 `/policeFusion|electronicCert/log/export` → Spring Ambiguous mapping 崩启动 → 删重复方法 |
| **#54** | `OrganNodeCreateController` 与 `OrganController` 撞 `/organ/createOrganNode` → 删冗余 patch 控制器 |
| — | 附带：加入控制器全量重复映射静态扫描器 |

### D. 迁移版本号碰撞（并行 renumber 竞态）
| PR | 说明 |
|---|---|
| **#45** | 两人各自 renumber 同一批迁移 → 合并后 V5/V6/V7 重复，Flyway 拒启 → 去重 |
| **#49** | 第二次碰撞：两个"修重复"提交都合并 → V8-V11 再次重复（同名文件两个版本号）→ 采用一方编号去重，验证 V2..V11 全链 |

> ⚠️ **教训**：并行 renumber 共享迁移文件是本轮最大耗时点。建议**协调迁移版本号归属**（预留区段/单人owner）。

### E. 部署 & 应用健壮性
| PR | 问题 → 修复 |
|---|---|
| **#55** | 迁移瞬时失败后 validateOnMigrate 永久拒启 → Flyway `repair()` before `migrate()` 自愈（幂等迁移可安全重放） |
| **#56** | mariadb 无 --force 载 initsql，并发冷启时 privacy3 半载（25/32 表，缺 sys_auth）→ V2 崩 crashloop → initdb `.sh` loader `mysql --force` + sys_auth fail-fast 守卫 |

### F. Web / 前端
| PR | 说明 |
|---|---|
| **#43** | 创建审批工作流缺"工作流标题"输入框 → 补 el-input + 必填规则 |

### 协作（另一开发者并行，本轮同期合入 develop）
供理解上下文：#44 联邦学习菜单去重、#46 版本重复修复(中文版，与#45并行)、#48 D20 创建机构、#52 V13(并行版)、
以及 v1.8.2 纳入的：evidence 证书/时间戳下载、授权审核/记录端点、organId/resourceId 类型冲突修复、44 个写 API content-type 修复。

---

## 4. 功能验证结果（v1.8.1/v1.8.2）

`functional_verify.py`（登录 admin/123456 → 打各功能端点，标 SQL-shape 错）：

| 段 | 端点数 | SQL 错 |
|---|---|---|
| [A] 各模块 list/query | 18 | **0** |
| [B] 曾报错的 create（用户/日志定义/工作流/机构） | 4 | **0** |
| [C] 各模块 create/save | 23 | **0** |

**Flyway**：privacy1/2/3 各 14/14 全 success；应用 login 200；审计日志写入正常。
非 OK 响应均为业务校验（缺参/无效参），非 schema 问题。

---

## 5. 工具（`/mnt/data2/claude/fwpkg/`）

- **`mapper_check.py`** — 解析所有 mybatis mapper 的 INSERT/UPDATE 列引用，比对活库 information_schema：报缺列 + （parameterType/@Param/单POJO 解析的）类型不符。用：活库 dump `SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE ... WHERE TABLE_SCHEMA='privacy1'` → TSV → 跑分析器。**替代 UI 逐点手测**。
  - 盲区：只扫 mapper XML；Java 内建 SQL 或扫描后新增的 mapper 会漏（sys_organ.identity 即扫描后新加）。代码变动后重跑。
- **`functional_verify.py`** — 登录 + 功能端点冒烟，标 SQL-shape 失败。
- **`vm_build_1717.sh`**（env TS/PTAG 参数化，platform+web 同 tag，oss2 上传）、**`vm_redeploy_*.sh`**（全新库复验）。

---

## 6. 建议

1. **协调迁移版本号** —— 别并行 renumber 共享迁移文件（本轮两次碰撞）。预留版本区段或单人 owner。
2. **重复 @RequestMapping** —— 合并前跑控制器重复映射扫描（本轮两次崩启动）。
3. **base dump 健壮性** —— initsql `--force` 载 + fail-fast，已在 #56 落地。
4. **schema 漂移预防** —— CI 里跑 `mapper_check.py` 门禁，代码/迁移改动即扫。
5. **arm64-deploy/.env** —— 现浮动 `:develop`；打包脚本会覆盖成版本号，但建议发布分支 pin 版本。
