-- ========================================================================
-- 警务数据融合 - 数据源对接 DDL
-- 表: scene_data_source / scene_data_sync_record
-- 幂等: CREATE TABLE IF NOT EXISTS
-- ========================================================================

CREATE TABLE IF NOT EXISTS scene_data_source (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(200) NOT NULL COMMENT '数据源名称',
    source_type VARCHAR(50) COMMENT '数据源类型: mysql/oracle/postgresql/api等',
    department VARCHAR(200) COMMENT '所属部门',
    host VARCHAR(255) COMMENT '主机地址',
    port INT COMMENT '端口',
    db_name VARCHAR(200) COMMENT '数据库名',
    username VARCHAR(200) COMMENT '用户名',
    password VARCHAR(500) COMMENT '密码',
    connection_info VARCHAR(1000) COMMENT '连接信息描述',
    data_count BIGINT DEFAULT 0 COMMENT '数据量',
    status TINYINT DEFAULT 0 COMMENT '状态: 1已连接 0未连接',
    last_sync_time DATETIME COMMENT '最近同步时间',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_source_type (source_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景数据源对接表';

CREATE TABLE IF NOT EXISTS scene_data_sync_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_id BIGINT COMMENT '数据源ID',
    source_name VARCHAR(200) COMMENT '数据源名称',
    sync_type VARCHAR(50) COMMENT '同步类型: manual/auto',
    record_count BIGINT DEFAULT 0 COMMENT '同步记录数',
    duration VARCHAR(50) COMMENT '耗时',
    status TINYINT DEFAULT 1 COMMENT '状态: 1成功 0失败',
    sync_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '同步时间',
    INDEX idx_source_id (source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景数据源同步记录表';
