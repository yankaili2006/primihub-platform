DROP TABLE IF EXISTS `sys_access_party`;
CREATE TABLE `sys_access_party` (
    `id`           bigint(20)   NOT NULL AUTO_INCREMENT,
    `party_name`   varchar(200) NOT NULL                COMMENT '接入方名称',
    `party_code`   varchar(64)  DEFAULT NULL            COMMENT '接入方编码',
    `api_key`      varchar(128) DEFAULT NULL            COMMENT 'API密钥',
    `contact_person` varchar(100) DEFAULT NULL          COMMENT '联系人',
    `contact_phone` varchar(20)  DEFAULT NULL           COMMENT '联系电话',
    `status`       tinyint(4)   DEFAULT 1              COMMENT '状态 1=启用 0=禁用',
    `remark`       varchar(500) DEFAULT NULL,
    `is_del`       tinyint(4)   DEFAULT 0,
    `c_time`       datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`       datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_party_code` (`party_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='接入方管理表';