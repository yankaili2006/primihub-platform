-- ============================================================
-- 时间戳管理 — 数据库表定义
-- 用于可信时间戳申请与管理
-- ============================================================

DROP TABLE IF EXISTS `data_timestamp`;
CREATE TABLE `data_timestamp` (
    `id`              bigint(20)   NOT NULL AUTO_INCREMENT COMMENT '自增ID',
    `apply_id`        varchar(64)  NOT NULL                 COMMENT '申请编号',
    `title`           varchar(255) NOT NULL                 COMMENT '时间戳标题',
    `file_name`       varchar(255) DEFAULT NULL             COMMENT '原始文件名',
    `file_hash`       varchar(128) DEFAULT NULL             COMMENT '文件哈希值(SHA256)',
    `file_size`       bigint(20)   DEFAULT NULL             COMMENT '文件大小(字节)',
    `timestamp_value` varchar(64)  DEFAULT NULL             COMMENT '时间戳值(授时中心返回)',
    `cert_number`     varchar(64)  DEFAULT NULL             COMMENT '证书编号',
    `apply_status`    tinyint(4)   NOT NULL DEFAULT 0      COMMENT '申请状态 0=待提交 1=已提交 2=已签发 3=失败',
    `apply_user_id`   bigint(20)   DEFAULT NULL             COMMENT '申请人用户ID',
    `apply_user_name` varchar(64)  DEFAULT NULL             COMMENT '申请人名称',
    `apply_time`      datetime(3)  DEFAULT NULL             COMMENT '申请时间',
    `issue_time`      datetime(3)  DEFAULT NULL             COMMENT '签发时间',
    `remark`          varchar(500) DEFAULT NULL             COMMENT '备注',
    `is_del`          tinyint(4)   NOT NULL DEFAULT 0      COMMENT '是否删除 0=否 1=是',
    `c_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `u_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `idx_apply_id` (`apply_id`) USING BTREE,
    KEY `idx_apply_status` (`apply_status`) USING BTREE,
    KEY `idx_apply_user_id` (`apply_user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='时间戳申请表';