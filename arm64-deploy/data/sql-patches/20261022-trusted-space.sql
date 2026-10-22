-- ===== 可信空间模块 (TrustedSpace) — schema / seed / migration / menu (2026-10-22) =====
-- 独立实体 data_trusted_space 取代「trusted_space 列 = data_resource_tag.tag_id」的隐式约定。
-- data_resource.trusted_space 沿用，语义改为 data_trusted_space.space_id；NULL 仍表示缺省空间(PrimiHub)。
-- 幂等：可反复执行；MySQL 5.7 / MariaDB 10.x 均可。逐机构库执行（privacy% 与 fusion%，看 application
-- 的 primary.url 实际指向哪个库）。执行后 `redis DEL sys_auth:bfs_list` 并重新登录以刷新菜单。
-- 注意：本文件不含 ALTER TABLE data_resource ADD COLUMN（MySQL 5.7 无 IF NOT EXISTS）；对既有库补列用
-- pcloud scripts/primihub/schema-patch-20261022-trusted-space.sql（information_schema 守卫），
-- 全新部署的 dump 已内置 resource_kind/object_key/trusted_space 三列。

CREATE TABLE IF NOT EXISTS `data_trusted_space` (
  `space_id`    bigint(20)   NOT NULL AUTO_INCREMENT COMMENT '可信空间id（data_resource.trusted_space 指向它）',
  `space_code`  varchar(64)  NOT NULL COMMENT '空间编码，库内唯一（primihub/water/nev/agri/...）',
  `space_name`  varchar(128) NOT NULL COMMENT '空间名称（未删除行内唯一，服务层校验）',
  `space_desc`  varchar(512) DEFAULT NULL COMMENT '描述',
  `organ_id`    varchar(64)  DEFAULT NULL COMMENT '所属机构全局id',
  `organ_name`  varchar(128) DEFAULT NULL COMMENT '所属机构名称',
  `is_default`  tinyint(4)   NOT NULL DEFAULT 0 COMMENT '1=缺省空间（trusted_space 为 NULL 的资源归它），不可删',
  `status`      tinyint(4)   NOT NULL DEFAULT 1 COMMENT '1 启用 0 停用',
  `sort_index`  int(11)      NOT NULL DEFAULT 100 COMMENT '排序，小者在前',
  `user_id`     bigint(20)   DEFAULT NULL COMMENT '创建人',
  `is_del`      tinyint(4)   NOT NULL DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3)  NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3)  NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`space_id`) USING BTREE,
  UNIQUE KEY `uk_trusted_space_code` (`space_code`),
  KEY `idx_trusted_space_name` (`space_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1001 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='可信空间';

-- (a) id 空间隔离：首次建表（表为空）时把起点抬到 max(tag_id)+1 以上，保证 space_id 永不等于任何既有 tag_id，
--     迁移守卫「trusted_space 不是任何 space_id」才成立。表非空时不动。
SET @ts_n  = (SELECT COUNT(*) FROM data_trusted_space);
SET @ts_ai = (SELECT GREATEST(1001, IFNULL(MAX(tag_id),0)+1) FROM data_resource_tag);
SET @ts_sql = IF(@ts_n = 0, CONCAT('ALTER TABLE data_trusted_space AUTO_INCREMENT=', @ts_ai), 'SELECT 1');
PREPARE ts_stmt FROM @ts_sql; EXECUTE ts_stmt; DEALLOCATE PREPARE ts_stmt;

-- (b) 种子：缺省空间 + pcloud DOMAIN_RULES 对齐的三个领域。按 space_code 判存在，不覆盖管理员改过的名字/状态。
INSERT INTO data_trusted_space (space_code, space_name, space_desc, is_default, status, sort_index)
SELECT 'primihub', 'PrimiHub', '缺省可信空间：未归类的数据资源', 1, 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM data_trusted_space WHERE space_code = 'primihub');
INSERT INTO data_trusted_space (space_code, space_name, space_desc, is_default, status, sort_index)
SELECT 'water', '水利', '水利领域数据资源', 0, 1, 10 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM data_trusted_space WHERE space_code = 'water');
INSERT INTO data_trusted_space (space_code, space_name, space_desc, is_default, status, sort_index)
SELECT 'nev', '新能源车', '新能源车领域数据资源', 0, 1, 20 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM data_trusted_space WHERE space_code = 'nev');
INSERT INTO data_trusted_space (space_code, space_name, space_desc, is_default, status, sort_index)
SELECT 'agri', '农业', '农业领域数据资源', 0, 1, 30 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM data_trusted_space WHERE space_code = 'agri');

-- (c) 当前仍被 trusted_space 以 tag_id 引用、且不在种子里的标签名 → 导入为空间（code=tag_<最小tag_id>）。
--     同名标签三库各攒了多条，按名字归并。
INSERT INTO data_trusted_space (space_code, space_name, space_desc, is_default, status, sort_index)
SELECT CONCAT('tag_', MIN(t.tag_id)), t.tag_name, CONCAT('由资源主标签「', t.tag_name, '」迁移'), 0, 1, 100
FROM data_resource r
JOIN data_resource_tag t ON t.tag_id = r.trusted_space AND t.is_del = 0
WHERE r.is_del = 0
  AND r.trusted_space NOT IN (SELECT space_id FROM data_trusted_space)
  AND NOT EXISTS (SELECT 1 FROM data_trusted_space s WHERE s.space_name = t.tag_name AND s.is_del = 0)
GROUP BY t.tag_name;

-- (d) 指针迁移：tag_id → 同名空间的 space_id。守卫「当前值不是任何 space_id」使重复执行为空操作。
UPDATE data_resource r
JOIN data_resource_tag  t ON t.tag_id = r.trusted_space AND t.is_del = 0
JOIN data_trusted_space s ON s.space_name = t.tag_name AND s.is_del = 0
SET r.trusted_space = s.space_id, r.update_date = r.update_date
WHERE r.trusted_space NOT IN (SELECT x.space_id FROM (SELECT space_id FROM data_trusted_space) x);

-- (e) 悬空指针（标签已被 handleResourceTag 硬删/软删、又无同名空间）→ NULL = 回缺省空间。
UPDATE data_resource
SET trusted_space = NULL, update_date = update_date
WHERE trusted_space IS NOT NULL
  AND trusted_space NOT IN (SELECT space_id FROM data_trusted_space)
  AND trusted_space NOT IN (SELECT tag_id FROM data_resource_tag WHERE is_del = 0);

-- ===== 菜单/权限：可信空间（auth_id 9840–9847，沿用 CancelCooperation 9829 幂等形态） =====
-- auth_code 与前端路由 name / 按钮码一一对应；auth_url 为网关 StripPrefix 后的路径（无 /data 前缀）。
-- listAll / resources 为只读辅助端点，不登记（与 getTrustedSpaces 同策略：未登记的 URL 不做鉴权拦截）。
INSERT INTO sys_auth
  (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
  (9840, '可信空间', 'TrustedSpace',       1, 0,    9840, '9840',           '',                               'own', 5, 0, 1, 1, 0),
  (9841, '空间列表', 'TrustedSpaceList',   2, 9840, 9840, '9840,9841',      '/trustedSpace/page',             'own', 1, 1, 1, 1, 0),
  (9842, '空间详情', 'TrustedSpaceDetail', 3, 9840, 9840, '9840,9842',      '/trustedSpace/detail',           'own', 2, 1, 1, 1, 0),
  (9843, '新建空间', 'TrustedSpaceAdd',    3, 9840, 9840, '9840,9843',      '/trustedSpace/save',             'own', 3, 1, 1, 1, 0),
  (9844, '编辑空间', 'TrustedSpaceEdit',   3, 9840, 9840, '9840,9844',      '/trustedSpace/update',           'own', 4, 1, 1, 1, 0),
  (9845, '删除空间', 'TrustedSpaceDelete', 3, 9840, 9840, '9840,9845',      '/trustedSpace/delete',           'own', 5, 1, 1, 1, 0),
  (9846, '划入资源', 'TrustedSpaceAssign', 3, 9840, 9840, '9840,9846',      '/trustedSpace/assignResources',  'own', 6, 1, 1, 1, 0),
  (9847, '移出资源', 'TrustedSpaceRemove', 3, 9840, 9840, '9840,9847',      '/trustedSpace/removeResources',  'own', 7, 1, 1, 1, 0)
ON DUPLICATE KEY UPDATE
  auth_name=VALUES(auth_name), auth_code=VALUES(auth_code), auth_type=VALUES(auth_type),
  p_auth_id=VALUES(p_auth_id), r_auth_id=VALUES(r_auth_id), full_path=VALUES(full_path),
  auth_url=VALUES(auth_url), data_auth_code=VALUES(data_auth_code), auth_index=VALUES(auth_index),
  auth_depth=VALUES(auth_depth), is_show=VALUES(is_show), is_editable=VALUES(is_editable), is_del=0;

-- 超级管理员(role_id=1) 授权，逐条守卫；重复执行不插入。
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9840, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9840 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9841, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9841 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9842, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9842 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9843, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9843 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9844, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9844 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9845, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9845 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9846, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9846 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
INSERT INTO sys_ra (id, role_id, auth_id, is_del) SELECT nid, 1, 9847, 0 FROM (SELECT COALESCE(MAX(id),0)+1 AS nid, SUM(CASE WHEN role_id=1 AND auth_id=9847 AND is_del=0 THEN 1 ELSE 0 END) AS existing FROM sys_ra) t WHERE t.existing = 0;
-- ===== end TrustedSpace =====
