DROP TABLE IF EXISTS `sys_middleware_monitor_config`;
CREATE TABLE `sys_middleware_monitor_config` (
    `id`              bigint(20)   NOT NULL AUTO_INCREMENT,
    `mw_type`         varchar(64)  NOT NULL                COMMENT '中间件类型(REDIS/MYSQL/RABBITMQ/ES)',
    `mw_name`         varchar(200) NOT NULL                COMMENT '中间件名称',
    `host`            varchar(255) DEFAULT NULL            COMMENT '连接地址',
    `port`            int(11)      DEFAULT NULL            COMMENT '端口',
    `connect_timeout` int(11)      DEFAULT 5000            COMMENT '连接超时(ms)',
    `warning_threshold` decimal(10,2) DEFAULT 80.00        COMMENT '告警阈值(%)',
    `critical_threshold` decimal(10,2) DEFAULT 95.00       COMMENT '严重阈值(%)',
    `check_interval`  int(11)      DEFAULT 60              COMMENT '检查间隔(秒)',
    `enabled`         tinyint(4)   DEFAULT 1               COMMENT '是否启用',
    `notify_type`     varchar(100) DEFAULT 'email'          COMMENT '通知方式',
    `remark`          varchar(500) DEFAULT NULL,
    `is_del`          tinyint(4)   DEFAULT 0,
    `c_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_mw_type` (`mw_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='中间件监控告警配置表';

INSERT INTO `sys_middleware_monitor_config`(`mw_type`,`mw_name`,`host`,`port`,`warning_threshold`,`critical_threshold`,`check_interval`,`enabled`,`notify_type`) VALUES
('REDIS','Redis缓存','127.0.0.1',6379,80.00,95.00,60,1,'email'),
('MYSQL','MySQL数据库','127.0.0.1',3306,80.00,95.00,60,1,'email'),
('RABBITMQ','RabbitMQ消息队列','127.0.0.1',5672,80.00,95.00,60,0,'email'),
('ES','ElasticSearch','127.0.0.1',9200,80.00,95.00,60,0,'email'),
('JVM','JVM监控','127.0.0.1',8080,85.00,95.00,30,0,'email');