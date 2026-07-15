-- ============================================================
-- 操作日志定义表
-- ============================================================
DROP TABLE IF EXISTS `sys_log_type`;
CREATE TABLE `sys_log_type` (
    `id`          bigint(20)   NOT NULL AUTO_INCREMENT COMMENT '自增ID',
    `type_name`   varchar(100) NOT NULL                 COMMENT '日志类型名称',
    `type_code`   varchar(64)  NOT NULL                 COMMENT '日志类型编码',
    `type_desc`   varchar(500) DEFAULT NULL             COMMENT '类型描述',
    `status`      tinyint(4)   NOT NULL DEFAULT 1      COMMENT '状态 1=启用 0=禁用',
    `sort_order`  int(11)      DEFAULT 0               COMMENT '排序号',
    `is_del`      tinyint(4)   NOT NULL DEFAULT 0      COMMENT '是否删除',
    `c_time`      datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `u_time`      datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `idx_type_code` (`type_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='操作日志类型定义表';

INSERT INTO `sys_log_type`(`type_name`,`type_code`,`type_desc`,`status`,`sort_order`) VALUES
('登录日志','LOGIN','用户登录操作日志',1,1),
('新增日志','INSERT','数据新增操作日志',1,2),
('修改日志','UPDATE','数据修改操作日志',1,3),
('删除日志','DELETE','数据删除操作日志',1,4),
('查询日志','QUERY','数据查询操作日志',1,5);