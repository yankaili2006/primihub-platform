# 可信空间模块（Trusted Space）

> 2026-10-22 新增。把原先「`data_resource.trusted_space` = 某个 `data_resource_tag.tag_id`」的隐式约定，
> 做成**独立实体 + CRUD + 资源归属**的正式模块：后端 `TrustedSpaceController`/`DataTrustedSpaceService`，
> 前端 `可信空间` 菜单（列表 / 详情 / 划入 / 移出），一次性幂等迁移 SQL。

## 1. 为什么

- 旧约定下平台自己从不写 `trusted_space`，唯一写入方是 pcloud 的 `primihub-meta-resource space-assign`，
  它取「最早同名 tag」的 `tag_id`。而资源一经编辑，`DataResourceService.handleResourceTag` 会硬删该资源的
  tag 行 → 指针悬空 → 资源静默回落成 PrimiHub；前端没有任何入口能设置或管理空间。
- 同名标签三库各攒了十几条（每次保存都新建 tag 行），「空间」没有稳定身份，无法做权限、排序、停用。

## 2. 数据模型

新表 `data_trusted_space`（**机构本地实体，不进 fusion 同步**；协作方看到的资源不带空间归属）：

| 列 | 类型 | 说明 |
|---|---|---|
| `space_id` | bigint PK AUTO_INCREMENT（起点 ≥1001 且 > max(tag_id)） | `data_resource.trusted_space` 指向它 |
| `space_code` | varchar(64) **UNIQUE** | 稳定编码：`primihub` / `water` / `nev` / `agri` / 自定义 `^[A-Za-z0-9_-]{1,64}$` |
| `space_name` | varchar(128) | 显示名（未删除行内唯一，服务层校验） |
| `space_desc` | varchar(512) | 描述 |
| `organ_id` / `organ_name` | varchar | 所属机构（`OrganConfiguration` 本机构） |
| `is_default` | tinyint | 1 = 缺省空间：不可删、不可停用、不可改编码 |
| `status` | tinyint | 1 启用 / 0 停用（停用后不能再划入资源） |
| `sort_index` | int | 排序，小者在前 |
| `user_id` / `is_del` / `create_date` / `update_date` | | 常规 |

**`data_resource.trusted_space` 沿用，语义改为 `space_id`；`NULL` 仍表示缺省空间**（`DataResourceConvert`
对空名字兜底 `"PrimiHub"` 的行为不变）。因此所有消费 `trustedSpaceName` 的地方（资源列表筛选/详情、agentHub
「数据空间」、pcloud data-spaces）零改动。`resourceColumns` 的名字解析改为
`(select s.space_name from data_trusted_space s where s.space_id = trusted_space and s.is_del = 0)`。

`data_resource` 的 `resource_kind` / `object_key` / `trusted_space` 三列也一并补进了部署 dump（此前 mapper 早已读写
它们而 dump 没有 → CI `schema-drift-check` 一直红）。顺带把 6 张任务表缺的 `project_id` 也折了进去，门禁现为绿。

## 3. 接口（`/data/trustedSpace/*`，经网关 `data-url-proxy` StripPrefix，**无需改网关/nginx**）

| 方法 | 路径 | 入参 | 说明 / 鉴权码 |
|---|---|---|---|
| GET | `page` | `pageNo,pageSize,spaceName,spaceCode,status` | 分页，`PageDataEntity{total,pageSize,index,totalPage,data[]}`，行含 `resourceCount` · `TrustedSpaceList` |
| GET | `listAll` | — | 启用空间列表（下拉用，缺省排前） · 不登记 |
| GET | `detail` | `spaceId` | 详情 + `resourceCount` · `TrustedSpaceDetail` |
| POST json | `save` | `spaceName,[spaceCode],[spaceDesc],[status],[sortIndex]` | 名称/编码查重 → `106 NON_REPEATABLE`；编码留空自动 `ts_<ts>_<hex>` · `TrustedSpaceAdd` |
| POST json | `update` | `spaceId` + 任意上面字段 | 缺省空间禁改编码/禁停用 → `104 CAN_NOT_ALTER` · `TrustedSpaceEdit` |
| POST | `delete?spaceId=` | | 缺省空间拒绝 `105`；其余：资源置回缺省（NULL）后软删，返回 `movedResources` · `TrustedSpaceDelete` |
| POST json | `assignResources` | `spaceId, resourceIds[]` | 停用空间拒绝；id 去重；返回 `affected` · `TrustedSpaceAssign` |
| POST json | `removeResources` | `spaceId, resourceIds[]` | 置回缺省；对缺省空间调用拒绝 · `TrustedSpaceRemove` |
| GET | `resources` | `spaceId,pageNo,pageSize,resourceName…` | 复用 `DataResourceService.getDataResourceList`（同一套 `DataResourceVo`），缺省空间含 NULL 资源 · 不登记 |

资源接口的变化：`DataResourceReq` 新增 `trustedSpace`（Long）—— 列表按 id 过滤；`saveorupdateresource` 时写入归属
（须存在且启用，否则 `101 PARAM_INVALIDATION`）。`getTrustedSpaces` 保留，现返回 `data_trusted_space` 启用空间名。

## 4. 权限 / 菜单

`sys_auth` 9840–9847（`auth_code` = 前端路由 name / 按钮码）：

```
9840 可信空间 TrustedSpace (菜单)   9841 TrustedSpaceList /trustedSpace/page   9842 TrustedSpaceDetail /trustedSpace/detail
9843 TrustedSpaceAdd /trustedSpace/save   9844 TrustedSpaceEdit /trustedSpace/update   9845 TrustedSpaceDelete /trustedSpace/delete
9846 TrustedSpaceAssign /trustedSpace/assignResources   9847 TrustedSpaceRemove /trustedSpace/removeResources
```

`sys_ra` 给 role_id=1 逐条守卫授权。菜单在 redis 有缓存：入库后 `DEL sys_auth:bfs_list`（各机构 redis 库）并重新登录。

## 5. SQL 落点

| 位置 | 用途 |
|---|---|
| `arm64-deploy/data/sql-patches/20261022-trusted-space.sql` | **规范补丁**：建表 + 种子（PrimiHub/水利/新能源车/农业）+ 导入被引用的其它标签名 + 指针迁移 + 悬空清理 + 菜单。幂等，MySQL 5.7 / MariaDB 10 均可。对既有库**逐库**执行（privacy% 与 fusion%，看 application 的 `primary.url` 实际指向） |
| `arm64-deploy/data/initsql/privacy{1,2,3}.sql` | 全新部署：`data_resource` 已含三列；文件尾追加同一补丁块（显式 `USE privacyN`——此前的追加块落在 `USE fusionN` 之后，已一并纠正） |
| `test-tools/dump-fixup.sql` | `regen-base-dumps.sh` 重生成 dump 时保留以上内容 |
| `application/src/main/resources/schema-complete-h2.sql` + `data-complete-h2.sql` | `simple` profile（H2）同步建表/种子/菜单 |
| pcloud `scripts/primihub/schema-patch-20261022-trusted-space.sql` + `apply-schema-patch.sh --only-trusted-space` | 生产实例打补丁（带备份与校验） |

迁移语义（可重复执行，第二次零变更）：
1. 表为空时把 `AUTO_INCREMENT` 抬到 `GREATEST(1001, max(tag_id)+1)`，保证 `space_id` 永不等于既有 `tag_id`；
2. 种子按 `space_code` 判存在，不覆盖管理员改过的名字/状态；
3. 仍以 tag_id 被引用的标签名按名字归并导入（`tag_<最小tag_id>`）；
4. `trusted_space`：tag_id → 同名空间 `space_id`（守卫：当前值不是任何 `space_id`）；
5. 悬空指针（标签被删、无同名空间）→ NULL（缺省）。

本地 MariaDB 实测（2026-10-22）：重复 `水利` 标签归并为一行、`遥感` 导入为 `tag_20`、悬空/已删标签指针置 NULL、
显式 PrimiHub 指针指向缺省行；两次执行快照逐字相同。

## 6. 前端

- 路由 `/trustedSpace`（`TrustedSpace` → `TrustedSpaceList` / hidden `TrustedSpaceDetail`，`activeMenu` 回列表），放在
  资源管理之后。
- `views/trustedSpace/list.vue`：筛选（名称/状态）、表格（含资源数、缺省标记）、新建/编辑弹窗、删除确认（提示将回落的资源数）。
- `views/trustedSpace/detail.vue`：空间信息卡 + 空间内资源分页（复用资源列表列集）+「划入资源」（`components/ResourcePickerDialog.vue`，
  本机构资源多选、跨页保留勾选、已在本空间的行不可选）+ 行内「移出空间」。
- `const/trustedSpace.js` 收敛了 `resource/list.vue` 与 `agentHub/index.vue` 原先各一份的兜底列表和标签颜色；
  `resource/create.vue` 新增「可信空间」下拉（`listAll`），编辑时回填。
- 按钮显隐走 `buttonPermissionList`（上表的 auth_code）。

## 7. 验证记录（2026-10-22，pve22 容器）

- `mvn -pl biz,application -am compile`：通过（JDK8 / Maven 3.8.6）。
- JUnit：`DataTrustedSpaceServiceTest` 22 例、`TrustedSpaceControllerTest` 17 例通过。
  ⚠️ 仓库里 `DataDifferenceServiceImplTest` / `DataUnionServiceImplTest` / `UnionControllerTest` /
  `BaseModuleControllersTest` 等**上游既有测试已与现有签名不一致、无法编译**（与本模块无关），跑新测试时需把它们排除。
- `privacy{1,2,3}.sql` 可干净加载；`test-tools/mapper_check.py` 门禁 **PASSED**（此前因 data_resource 三列 + 6 个 project_id 缺失为红）。
- 前端 `npm run build:prod` 通过；`eslint` 对本次新增/改动文件 0 error（仓库整体有 ~400 个既有 lint 错误，未动）。
- `tests/unit/api/trustedSpace.spec.js` 已加；仓库的 jest 工具链（Vue2 + `@vue/test-utils ^2`）目前跑不起来，待修。

## 8. 上线步骤（下一轮）

1. 构建后端镜像（application 与 gateway 同镜像；gateway 可不换）+ web 镜像。
2. **先打 SQL 再换镜像**：`apply-schema-patch.sh --host <ssh目标> --only-trusted-space`（或逐库 `mysql -D <db> < 20261022-trusted-space.sql`）；
   新 jar 的 `resourceColumns` 子查询依赖 `data_trusted_space`，表不存在时资源列表会直接 SQL 报错。
3. 换 application 与 web 镜像；各机构 redis `DEL sys_auth:bfs_list`，用户重新登录看到「可信空间」菜单。
4. 回滚：换回旧镜像即可；表与列可留（旧代码不读 `data_trusted_space`，`trusted_space` 列对旧 mapper 透明）。

## 9. 边界与已知限制

- 空间不进 fusion 同步，协作方看到的本机构资源无空间归属（范围内决策）。
- 空间是机构本地的：三机构库各有一份 `data_trusted_space`，编码可相同、id 各自独立。
- 删除空间把资源置回缺省而不是拒绝（范围内决策，前端删除前提示数量）。
- 未做成员机构 / 可见性过滤——后续若做「空间级授权」，在 `DataTrustedSpace` 上扩展即可，接口形态不变。
