-- Server module tables: server, agent, and five association tables
-- Style: MySQL utf8mb4, with COMMENT, CREATE TABLE IF NOT EXISTS
-- Compatible with privacy1.sql style

USE `privacy1`;

--
-- Table structure for table `server`
--

CREATE TABLE IF NOT EXISTS `server` (
  `server_id`       BIGINT(20)    NOT NULL AUTO_INCREMENT                 COMMENT '服务器主键ID',
  `server_name`     VARCHAR(100)  NOT NULL                                COMMENT '服务器名称',
  `server_desc`     VARCHAR(500)  DEFAULT NULL                            COMMENT '服务器描述',
  `server_ip`       VARCHAR(64)   DEFAULT NULL                            COMMENT '服务器IP地址',
  `server_port`     INT(11)       DEFAULT NULL                            COMMENT '服务器端口',
  `server_type`     VARCHAR(30)   DEFAULT 'compute'                       COMMENT '服务器类型: compute/storage/gateway/tee',
  `server_status`   TINYINT(4)    DEFAULT 0                               COMMENT '服务器状态: 0离线 1在线 2维护',
  `organ_id`        BIGINT(20)    DEFAULT NULL                            COMMENT '机构ID',
  `user_id`         BIGINT(20)    DEFAULT NULL                            COMMENT '创建人用户ID',
  `cpu_cores`       DOUBLE        DEFAULT NULL                            COMMENT 'CPU核数',
  `memory_gb`       BIGINT(20)    DEFAULT NULL                            COMMENT '内存(GB)',
  `storage_gb`      BIGINT(20)    DEFAULT NULL                            COMMENT '存储(GB)',
  `config`          TEXT          DEFAULT NULL                            COMMENT '扩展配置JSON',
  `last_heartbeat`  DATETIME      DEFAULT NULL                            COMMENT '最后心跳时间',
  `server_url`      VARCHAR(255)  DEFAULT NULL                            COMMENT '定位URL',
  `is_del`          TINYINT(4)    DEFAULT 0                               COMMENT '是否删除: 0否 1是',
  `create_date`     DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3)           COMMENT '创建时间',
  `update_date`     DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`server_id`),
  KEY `idx_organ_id` (`organ_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_server_type` (`server_type`),
  KEY `idx_server_status` (`server_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器主表';

--
-- Table structure for table `agent`
--

CREATE TABLE IF NOT EXISTS `agent` (
  `agent_id`    BIGINT(20)    NOT NULL AUTO_INCREMENT                     COMMENT '智能体主键ID',
  `agent_name`  VARCHAR(100)  NOT NULL                                    COMMENT '智能体名称',
  `agent_type`  VARCHAR(50)   DEFAULT NULL                                COMMENT '智能体类型',
  `agent_desc`  VARCHAR(500)  DEFAULT NULL                                COMMENT '智能体描述',
  `endpoint`    VARCHAR(500)  DEFAULT NULL                                COMMENT '智能体接入端点',
  `status`      TINYINT(4)    DEFAULT 0                                   COMMENT '状态: 0停用 1启用',
  `organ_id`    BIGINT(20)    DEFAULT NULL                                COMMENT '机构ID',
  `user_id`     BIGINT(20)    DEFAULT NULL                                COMMENT '创建人用户ID',
  `is_del`      TINYINT(4)    DEFAULT 0                                   COMMENT '是否删除: 0否 1是',
  `create_date` DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3)               COMMENT '创建时间',
  `update_date` DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`agent_id`),
  KEY `idx_organ_id` (`organ_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='智能体主表';

--
-- Table structure for table `server_resource`
--

CREATE TABLE IF NOT EXISTS `server_resource` (
  `id`                BIGINT(20)  NOT NULL AUTO_INCREMENT                 COMMENT '主键ID',
  `server_id`         BIGINT(20)  NOT NULL                                COMMENT '服务器ID',
  `resource_id`       BIGINT(20)  NOT NULL                                COMMENT '数据资源ID(data_resource.resource_id)',
  `allocation_status` TINYINT(4)  DEFAULT 0                               COMMENT '分配状态: 0待分配 1已分配 2已卸载',
  `uri`               VARCHAR(512) DEFAULT NULL                           COMMENT '定位URI',
  `is_del`            TINYINT(4)  DEFAULT 0                               COMMENT '是否删除: 0否 1是',
  `create_date`       DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)           COMMENT '创建时间',
  `update_date`       DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_resource` (`server_id`, `resource_id`),
  KEY `idx_server_id` (`server_id`),
  KEY `idx_resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器-数据资源关联表';

--
-- Table structure for table `server_model`
--

CREATE TABLE IF NOT EXISTS `server_model` (
  `id`                BIGINT(20)    NOT NULL AUTO_INCREMENT               COMMENT '主键ID',
  `server_id`         BIGINT(20)    NOT NULL                              COMMENT '服务器ID',
  `model_id`          BIGINT(20)    NOT NULL                              COMMENT '模型ID(data_model.model_id)',
  `model_version`     VARCHAR(50)   DEFAULT NULL                          COMMENT '部署模型版本',
  `deployment_status` TINYINT(4)    DEFAULT 0                             COMMENT '部署状态: 0待部署 1已部署 2运行中 3已停止',
  `uri`               VARCHAR(512)  DEFAULT NULL                          COMMENT '定位URI',
  `is_del`            TINYINT(4)    DEFAULT 0                             COMMENT '是否删除: 0否 1是',
  `create_date`       DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3)         COMMENT '创建时间',
  `update_date`       DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_model` (`server_id`, `model_id`),
  KEY `idx_server_id` (`server_id`),
  KEY `idx_model_id` (`model_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器-模型关联表';

--
-- Table structure for table `server_artifact`
--

CREATE TABLE IF NOT EXISTS `server_artifact` (
  `id`              BIGINT(20)  NOT NULL AUTO_INCREMENT                   COMMENT '主键ID',
  `server_id`       BIGINT(20)  NOT NULL                                  COMMENT '服务器ID',
  `artifact_id`     BIGINT(20)  NOT NULL                                  COMMENT '模型产物ID(data_model_artifact.artifact_id)',
  `artifact_status` TINYINT(4)  DEFAULT 0                                 COMMENT '产物状态: 0未部署 1已部署 2运行中',
  `uri`             VARCHAR(512) DEFAULT NULL                             COMMENT '定位URI',
  `is_del`          TINYINT(4)  DEFAULT 0                                 COMMENT '是否删除: 0否 1是',
  `create_date`     DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)             COMMENT '创建时间',
  `update_date`     DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_artifact` (`server_id`, `artifact_id`),
  KEY `idx_server_id` (`server_id`),
  KEY `idx_artifact_id` (`artifact_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器-模型产物关联表';

--
-- Table structure for table `server_node`
--

CREATE TABLE IF NOT EXISTS `server_node` (
  `id`          BIGINT(20)    NOT NULL AUTO_INCREMENT                     COMMENT '主键ID',
  `server_id`   BIGINT(20)    NOT NULL                                    COMMENT '服务器ID',
  `node_id`     BIGINT(20)    NOT NULL                                    COMMENT '节点ID(node_cooperation_party.id)',
  `access_type` VARCHAR(50)   DEFAULT NULL                                COMMENT '接入类型: project/compute/data_exchange',
  `is_primary`  TINYINT(4)    DEFAULT 0                                   COMMENT '是否主节点: 0否 1是',
  `uri`         VARCHAR(512)  DEFAULT NULL                                COMMENT '定位URI',
  `is_del`      TINYINT(4)    DEFAULT 0                                   COMMENT '是否删除: 0否 1是',
  `create_date` DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3)               COMMENT '创建时间',
  `update_date` DATETIME(3)   DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_node` (`server_id`, `node_id`),
  KEY `idx_server_id` (`server_id`),
  KEY `idx_node_id` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器-节点关联表';

--
-- Table structure for table `server_agent`
--

CREATE TABLE IF NOT EXISTS `server_agent` (
  `id`          BIGINT(20)  NOT NULL AUTO_INCREMENT                       COMMENT '主键ID',
  `server_id`   BIGINT(20)  NOT NULL                                      COMMENT '服务器ID',
  `agent_id`    BIGINT(20)  NOT NULL                                      COMMENT '智能体ID(agent.agent_id)',
  `run_status`  TINYINT(4)  DEFAULT 0                                     COMMENT '运行状态: 0停止 1运行中',
  `uri`         VARCHAR(512) DEFAULT NULL                                 COMMENT '定位URI',
  `is_del`      TINYINT(4)  DEFAULT 0                                     COMMENT '是否删除: 0否 1是',
  `create_date` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)                 COMMENT '创建时间',
  `update_date` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_agent` (`server_id`, `agent_id`),
  KEY `idx_server_id` (`server_id`),
  KEY `idx_agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器-智能体关联表';

--
-- 服务器管理菜单权限（sys_auth 菜单项 + sys_ra 授予超级管理员角色 role_id=1）
-- 幂等：INSERT IGNORE，重复执行不报错；auth_id 9801-9804 为本模块预留段。
-- 说明：多节点共享 Redis 时 sys_auth:bfs_list 缓存需失效一次（重启 application 或删该键）后菜单方可见。
--
INSERT IGNORE INTO `sys_auth`
  (`auth_id`,`auth_name`,`auth_code`,`auth_type`,`p_auth_id`,`r_auth_id`,`full_path`,`auth_url`,`data_auth_code`,`auth_index`,`auth_depth`,`is_show`,`is_editable`,`is_del`) VALUES
  (9801,'服务器管理','ServerMenu',1,0,9801,'9801','','own',22,0,1,1,0),
  (9802,'服务器列表','ServerList',2,9801,9801,'9801,9802','/server/findServerPage','own',1,1,1,1,0),
  (9803,'新增编辑服务器','ServerCreate',2,9801,9801,'9801,9803','/server/addServer','own',2,1,1,1,0),
  (9804,'服务器详情','ServerDetail',2,9801,9801,'9801,9804','/server/getServerDetail','own',3,1,1,1,0);

INSERT IGNORE INTO `sys_ra` (`role_id`,`auth_id`,`is_del`) VALUES
  (1,9801,0),(1,9802,0),(1,9803,0),(1,9804,0);

--
-- 幂等 ALTER：为既有库补加新列（若列已存在则跳过，避免重复执行报错）
-- 以及对既有行的回填 UPDATE
--

DROP PROCEDURE IF EXISTS `add_server_uri_columns`;
DELIMITER //
CREATE PROCEDURE `add_server_uri_columns`()
BEGIN
    -- server.server_url
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'server' AND COLUMN_NAME = 'server_url'
    ) THEN
        ALTER TABLE `server` ADD COLUMN `server_url` VARCHAR(255) DEFAULT NULL COMMENT '定位URL';
    END IF;

    -- server_resource.uri
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'server_resource' AND COLUMN_NAME = 'uri'
    ) THEN
        ALTER TABLE `server_resource` ADD COLUMN `uri` VARCHAR(512) DEFAULT NULL COMMENT '定位URI';
    END IF;

    -- server_model.uri
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'server_model' AND COLUMN_NAME = 'uri'
    ) THEN
        ALTER TABLE `server_model` ADD COLUMN `uri` VARCHAR(512) DEFAULT NULL COMMENT '定位URI';
    END IF;

    -- server_artifact.uri
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'server_artifact' AND COLUMN_NAME = 'uri'
    ) THEN
        ALTER TABLE `server_artifact` ADD COLUMN `uri` VARCHAR(512) DEFAULT NULL COMMENT '定位URI';
    END IF;

    -- server_node.uri
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'server_node' AND COLUMN_NAME = 'uri'
    ) THEN
        ALTER TABLE `server_node` ADD COLUMN `uri` VARCHAR(512) DEFAULT NULL COMMENT '定位URI';
    END IF;

    -- server_agent.uri
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'server_agent' AND COLUMN_NAME = 'uri'
    ) THEN
        ALTER TABLE `server_agent` ADD COLUMN `uri` VARCHAR(512) DEFAULT NULL COMMENT '定位URI';
    END IF;
END //
DELIMITER ;
CALL `add_server_uri_columns`();
DROP PROCEDURE IF EXISTS `add_server_uri_columns`;

-- 回填既有行
UPDATE `server`
SET `server_url` = CONCAT('https://primihub.com/', `server_name`)
WHERE `server_url` IS NULL AND `is_del` = 0;

UPDATE `server_resource` sr
JOIN `server` s ON s.server_id = sr.server_id AND s.is_del = 0
SET sr.`uri` = CONCAT(s.`server_url`, '/resource/', sr.`resource_id`)
WHERE sr.`uri` IS NULL AND sr.`is_del` = 0;

UPDATE `server_model` sm
JOIN `server` s ON s.server_id = sm.server_id AND s.is_del = 0
SET sm.`uri` = CONCAT(s.`server_url`, '/model/', sm.`model_id`)
WHERE sm.`uri` IS NULL AND sm.`is_del` = 0;

UPDATE `server_artifact` sa
JOIN `server` s ON s.server_id = sa.server_id AND s.is_del = 0
SET sa.`uri` = CONCAT(s.`server_url`, '/artifact/', sa.`artifact_id`)
WHERE sa.`uri` IS NULL AND sa.`is_del` = 0;

UPDATE `server_node` sn
JOIN `server` s ON s.server_id = sn.server_id AND s.is_del = 0
SET sn.`uri` = CONCAT(s.`server_url`, '/node/', sn.`node_id`)
WHERE sn.`uri` IS NULL AND sn.`is_del` = 0;

UPDATE `server_agent` sag
JOIN `server` s ON s.server_id = sag.server_id AND s.is_del = 0
SET sag.`uri` = CONCAT(s.`server_url`, '/agent/', sag.`agent_id`)
WHERE sag.`uri` IS NULL AND sag.`is_del` = 0;
