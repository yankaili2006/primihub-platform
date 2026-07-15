# D20 —「创建机构」实现规格（唯一真·未完成功能）

> 结论（2026-07-15，回 develop 源码核实）：44 条 UI 缺陷里，其余均已在 develop 修复，
> **仅 D20 是真正未完成的功能**（前端有 UI、后端从未实现来匹配）。本文给出精确实现清单，
> 供有构建环境者接手。**需先做一个产品决策**，否则会造出错模型的半成品。

## 现象（docx #020）

系统设置 >> 节点管理，点「创建机构」，填完信息点确定 → 页面顶部「请求异常」。

## 根因（源码级）

- 前端 `src/api/organ.js::createOrganNode(data)` 调 **`POST /sys/organ/createOrganNode`**，
  入参语义为 `{ organName, pOrganId(父节点id), organIndex(顺序) }` → **机构树**模型。
- 后端 `OrganController`（`@RequestMapping("organ")`）**无 `createOrganNode` 方法**；
  `NodeEnhancedController`（`@RequestMapping("/node")`）只有接入方/合作方 CRUD，也无建机构。
  → 前端调的路径 404 → 「请求异常」。
- 表 `sys_organ` 结构：`organ_id, organ_name, created_organ_id, created_organ_name,
  provider_organ_names` —— **无 `p_organ_id` / `organ_index` 列**，不支持树。
- **无 `OrganService`** —— 整个机构 CRUD 服务层不存在。

即：前端按「机构树」建了 UI，但后端的 表/实体/服务/端点 从未实现。

## ⚠️ 需先定的产品决策

「机构」在本平台指什么？两种模型，实现完全不同：

1. **内部机构树**（组织架构目录，父子层级）——匹配前端入参 `pOrganId/organIndex`。
   是一个**新概念**（当前联邦模型里没有内部组织树）。
2. **联邦节点/机构**——联邦参与方，本已通过「接入方(access party)」joining 流程加入
   （`NodeEnhancedController /node/access/*`）。若「创建机构」= 建联邦节点，则应复用
   接入方流程，而非新建 `createOrganNode`；此时**修法是改前端**指向接入方新增，或**移除**
   这个与模型冲突的按钮。

> 未定此决策前不要实现。fleet 已将 D20 标为「需产品决策」，本文与之一致。

## 若选「内部机构树」——实现清单（4–5 处改动）

1. **Schema 迁移**（新 Flyway `V5__organ_tree.sql`，幂等）：
   ```sql
   ALTER TABLE sys_organ ADD COLUMN p_organ_id VARCHAR(255) NULL COMMENT '父机构id';
   ALTER TABLE sys_organ ADD COLUMN organ_index INT DEFAULT 0 COMMENT '同级顺序';
   -- 若 organ_id 非自增主键，需定生成策略（UUID/雪花）
   ```
2. **实体 PO** `biz/.../entity/sys/po/SysOrgan.java`：加 `pOrganId`、`organIndex` 字段。
3. **Mapper** `biz/.../repository/.../SysOrganRepository` + XML：`insertOrganNode`
   （幂等：同 `pOrganId` 下 `organName` 唯一校验，防重复）。
4. **Service** `biz/.../service/sys/OrganService.java`（新建）：
   `createOrganNode(String organName, String pOrganId, Integer organIndex)`
   —— 校验父节点存在、名称非空、生成 organ_id、落库、返回。
5. **Controller** `OrganController`：
   ```java
   @PostMapping("createOrganNode")
   public BaseResultEntity createOrganNode(@RequestBody CreateOrganNodeParam param) { ... }
   ```
   **注意路径**：前端调 `/sys/organ/createOrganNode`，而 `OrganController` 现为
   `@RequestMapping("organ")`（→ `/organ/...`）。二者不一致——需**统一**：
   要么把控制器改/加 `/sys/organ` 前缀，要么把前端 `organ.js` 的 url 改成 `/organ/createOrganNode`
   （与 `getOrganList` 用的 `/organ/getOrganList` 一致——**推荐改前端**，最小且与既有 GET 对齐）。

## 验收

实现后，`acceptance-tests` 的 D20 会从 `fail(route missing)` 转为 `route_exists` pass：
```bash
PRIMIHUB_WEB_URL=http://<vm>:30811 PRIMIHUB_PASS=<pw> python3 run_acceptance.py D20
```
并应补一个 `@live` 用例：建节点 → 列表可见 → 删除（安全 round-trip）。

## 备注

其余 43 条已在 develop 修复（见 `defect-analysis-2025.md` §10）；VM131 若仍复现旧 bug，
是**陈旧构建未重部署**所致，非源码问题——重部署到当前 develop 即可。
