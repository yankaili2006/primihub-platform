# 需求文档 — 系统功能点 (demand.csv)

`demand.csv` 是 PrimiHub 隐私计算平台的**需求基线 / 系统功能点计数表**（附表3），是平台
「有哪些功能、是否实现」的**单一事实来源 (source of truth)**。菜单、权限、页面解锁等最终都
应与本表对齐。

## 文件

- **`demand.csv`** — 系统功能点计数表，352 行，约 **224 个功能点**，覆盖平台各子系统 / 一级功能
  模块。

### 列说明

| 列 | 含义 |
|---|---|
| 序号 | 功能点编号 |
| 子系统 | 所属子系统 |
| 一级功能模块 / 功能模块名称 | 模块归类 |
| 事务事项编号及名称 | 事务事项 |
| 功能名称 | 具体功能点 |
| 数据类型 / 是否计算 | 功能点计数属性 |
| 复用度 / 调整复用度后的分值 | 计数分值 |
| **是否实现** | 该功能点是否已在平台落地（验收判据） |

## 如何被平台消费

需求 → 菜单/权限/页面 的落地在部署侧完成：

- 菜单 + 页面解锁烘焙进 initsql: `arm64-deploy/hotfix-demand-menu/sql/01_demand_menu.sql`
  （`02_unlock_pages.sql` 解锁前端页面）。参见 `arm64-deploy/hotfix-demand-menu/README.md`。
- 相关实现说明: 根目录 `DATA_REQUIREMENT_IMPLEMENTATION.md`。
- 验收: 登录后 `getAuthTree` 应含本表全部一级模块 / 224 功能点，前端侧边栏逐页无报错
  （见 `.claude/skills/primihub-e2e-test` 与 primihub-offline-deploy 的浏览器验证）。

## 维护约定

1. **改需求先改这里**：新增/调整功能点先更新 `demand.csv`（尤其 `是否实现` 列）。
2. 再据此同步菜单 SQL（`arm64-deploy/hotfix-demand-menu/sql/01_demand_menu.sql`）与前端页面解锁。
3. 通过浏览器验证确认 224 功能点在部署实例上全部可见 / 可用。

> 历史上 `demand.csv` 散落在 `arm64-deploy/`（部署产物）与 pcloud `data/`。现以本目录
> `docs/requirements/demand.csv` 为受控基线，其余为其派生/部署副本。
