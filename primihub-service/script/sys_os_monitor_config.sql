DROP TABLE IF EXISTS `sys_os_monitor_config`;
CREATE TABLE `sys_os_monitor_config` (
    `id`            bigint(20)   NOT NULL AUTO_INCREMENT,
    `config_key`    varchar(100) NOT NULL                 COMMENT '配置项(CPU/MEM/DISK/NET)',
    `config_name`   varchar(100) NOT NULL                 COMMENT '配置名称',
    `warning_threshold` decimal(10,2) DEFAULT NULL        COMMENT '告警阈值(%)',
    `critical_threshold` decimal(10,2) DEFAULT NULL       COMMENT '严重阈值(%)',
    `interval_sec`  int(11)      DEFAULT 60              COMMENT '采集间隔(秒)',
    `enabled`       tinyint(4)   DEFAULT 1               COMMENT '是否启用',
    `notify_type`   varchar(100) DEFAULT 'email'          COMMENT '通知方式(email/sms/webhook)',
    `notify_contact` varchar(500) DEFAULT NULL            COMMENT '通知联系人',
    `remark`        varchar(500) DEFAULT NULL,
    `is_del`        tinyint(4)   DEFAULT 0,
    `c_time`        datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`        datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作系统监控告警配置表';

INSERT INTO `sys_os_monitor_config`(`config_key`,`config_name`,`warning_threshold`,`critical_threshold`,`interval_sec`,`enabled`,`notify_type`) VALUES
('CPU','CPU使用率',80.00,95.00,60,1,'email'),
('MEMORY','内存使用率',80.00,95.00,60,1,'email'),
('DISK','磁盘使用率',85.00,95.00,300,1,'email'),
('NETWORK','网络流量',90.00,98.00,60,0,'email');