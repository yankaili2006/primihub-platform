DROP TABLE IF EXISTS `sys_approval_workflow`;
CREATE TABLE `sys_approval_workflow` (
    `id`              bigint(20)   NOT NULL AUTO_INCREMENT,
    `workflow_name`   varchar(200) NOT NULL                COMMENT '工作流名称',
    `workflow_desc`   varchar(500) DEFAULT NULL            COMMENT '工作流描述',
    `approval_type`   varchar(64)  DEFAULT NULL            COMMENT '审批类型(PROJECT/RESOURCE/ORGAN)',
    `approval_levels` int(11)      DEFAULT 1              COMMENT '审批层级',
    `approvers`       varchar(1000) DEFAULT NULL           COMMENT '审批人列表(JSON)',
    `status`          tinyint(4)   DEFAULT 1              COMMENT '状态 1=启用 0=禁用',
    `is_del`          tinyint(4)   DEFAULT 0,
    `c_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `u_time`          datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批工作流配置表';