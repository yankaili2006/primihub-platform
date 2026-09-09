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
  `is_del`      TINYINT(4)  DEFAULT 0                                     COMMENT '是否删除: 0否 1是',
  `create_date` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)                 COMMENT '创建时间',
  `update_date` DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_agent` (`server_id`, `agent_id`),
  KEY `idx_server_id` (`server_id`),
  KEY `idx_agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器-智能体关联表';
