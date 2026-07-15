-- ============================================================
-- 白名单管理 — 数据库表定义
-- 用于管理短信服务白名单、IP白名单等
-- ============================================================

DROP TABLE IF EXISTS `sys_white_list`;
CREATE TABLE `sys_white_list` (
    `id`          bigint(20)   NOT NULL AUTO_INCREMENT COMMENT '自增ID',
    `wl_type`     tinyint(4)   NOT NULL DEFAULT 1      COMMENT '白名单类型 1=手机号 2=IP地址 3=邮箱',
    `wl_value`    varchar(255) NOT NULL                 COMMENT '白名单值（手机号/IP/邮箱）',
    `wl_reason`   varchar(500) DEFAULT NULL             COMMENT '添加原因/备注',
    `status`      tinyint(4)   NOT NULL DEFAULT 1      COMMENT '状态 1=启用 0=禁用',
    `creator_id`  bigint(20)   DEFAULT NULL             COMMENT '创建人用户ID',
    `creator_name` varchar(64) DEFAULT NULL             COMMENT '创建人名称',
    `is_del`      tinyint(4)   NOT NULL DEFAULT 0      COMMENT '是否删除 0=否 1=是',
    `c_time`      datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `u_time`      datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `idx_wl_type` (`wl_type`) USING BTREE,
    KEY `idx_wl_value` (`wl_value`) USING BTREE,
    KEY `idx_status` (`status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='白名单表';