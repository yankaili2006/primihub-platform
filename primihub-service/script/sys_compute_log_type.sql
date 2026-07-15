DROP TABLE IF EXISTS `sys_compute_log_type`;
CREATE TABLE `sys_compute_log_type` (
    `id`          bigint(20)   NOT NULL AUTO_INCREMENT COMMENT '自增ID',
    `type_name`   varchar(100) NOT NULL                 COMMENT '计算日志类型名称',
    `type_code`   varchar(64)  NOT NULL                 COMMENT '计算日志类型编码',
    `type_desc`   varchar(500) DEFAULT NULL             COMMENT '描述',
    `status`      tinyint(4)   NOT NULL DEFAULT 1      COMMENT '状态 1=启用 0=禁用',
    `sort_order`  int(11)      DEFAULT 0               COMMENT '排序号',
    `is_del`      tinyint(4)   NOT NULL DEFAULT 0      COMMENT '是否删除',
    `c_time`      datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`      datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `idx_compute_type_code` (`type_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='计算日志类型定义表';

INSERT INTO `sys_compute_log_type`(`type_name`,`type_code`,`type_desc`,`sort_order`) VALUES
('MPC计算','MPC','安全多方计算任务日志',1),
('联邦学习','FL','联邦学习训练任务日志',2),
('隐私求交','PSI','隐私求交任务日志',3),
('隐匿查询','PIR','隐匿查询任务日志',4),
('模型推理','REASONING','模型推理任务日志',5);