DROP TABLE IF EXISTS `sys_data_exchange_log`;
CREATE TABLE `sys_data_exchange_log` (
    `id`            bigint(20)   NOT NULL AUTO_INCREMENT,
    `exchange_type` varchar(64)  NOT NULL                COMMENT '交换类型(RESOURCE/MODEL/TASK)',
    `exchange_name` varchar(255) NOT NULL                COMMENT '交换名称',
    `source_organ`  varchar(255) DEFAULT NULL            COMMENT '源机构',
    `target_organ`  varchar(255) DEFAULT NULL            COMMENT '目标机构',
    `data_size`     bigint(20)   DEFAULT NULL            COMMENT '数据量',
    `sync_status`   tinyint(4)   DEFAULT 0              COMMENT '同步状态 0=待同步 1=同步中 2=成功 3=失败',
    `sync_msg`      varchar(1000) DEFAULT NULL           COMMENT '同步结果信息',
    `trigger_type`  varchar(64)  DEFAULT 'manual'        COMMENT '触发方式 manual/auto',
    `is_del`        tinyint(4)   DEFAULT 0,
    `c_time`        datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`        datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_sync_status` (`sync_status`),
    KEY `idx_exchange_type` (`exchange_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据交换日志表';