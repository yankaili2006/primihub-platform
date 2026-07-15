DROP TABLE IF EXISTS `sys_database_monitor_config`;
CREATE TABLE `sys_database_monitor_config` (
    `id`              bigint(20)   NOT NULL AUTO_INCREMENT,
    `db_type`         varchar(64)  NOT NULL                COMMENT '数据库类型(MYSQL/POSTGRESQL/CLICKHOUSE)',
    `db_name`         varchar(200) NOT NULL                COMMENT '数据库名称/别名',
    `host`            varchar(255) DEFAULT '127.0.0.1'     COMMENT '连接地址',
    `port`            int(11)      DEFAULT NULL            COMMENT '端口',
    `db_user`         varchar(100) DEFAULT NULL            COMMENT '用户名',
    `db_password`     varchar(255) DEFAULT NULL            COMMENT '密码',
    `connect_timeout` int(11)      DEFAULT 5000            COMMENT '连接超时(ms)',
    `warning_threshold` decimal(10,2) DEFAULT 80.00        COMMENT '连接数告警阈值(%)',
    `critical_threshold` decimal(10,2) DEFAULT 95.00       COMMENT '连接数严重阈值(%)',
    `check_interval`  int(11)      DEFAULT 60              COMMENT '检查间隔(秒)',
    `enabled`         tinyint(4)   DEFAULT 1               COMMENT '是否启用',
    `notify_type`     varchar(100) DEFAULT 'email'          COMMENT '通知方式',
    `remark`          varchar(500) DEFAULT NULL,
    `is_del`          tinyint(4)   DEFAULT 0,
    `c_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_db_type` (`db_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据库监控告警配置表';

INSERT INTO `sys_database_monitor_config`(`db_type`,`db_name`,`host`,`port`,`db_user`,`warning_threshold`,`critical_threshold`,`check_interval`,`enabled`,`notify_type`) VALUES
('MYSQL','MySQL主库','127.0.0.1',3306,'root',80.00,95.00,60,1,'email'),
('CLICKHOUSE','ClickHouse分析库','127.0.0.1',8123,'default',80.00,95.00,60,1,'email');