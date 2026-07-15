-- V5__scene_base_tables.sql — 场景定制化(警务融合/电子证件, 模块17-18)的基础表。
-- 背景(runtime 实测 39.105.61.64): 这些表只在 application/resources/schema-mysql.sql 里定义,
-- 从未进入 Flyway 迁移/部署 initsql, 导致 fresh 部署缺表 -> scene_task doesn't exist ->
-- 整个场景模块(createTask/PSI比对/import/export/exchange/convert)全部报错。
-- 本迁移把 5 张基础表纳入 Flyway(scene_imported_data 已在 V4)。CREATE IF NOT EXISTS 幂等。

CREATE TABLE IF NOT EXISTS scene_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scene_type VARCHAR(50) NOT NULL COMMENT '场景类型: police_fusion/electronic_cert',
    task_name VARCHAR(200) NOT NULL COMMENT '任务名称',
    task_type VARCHAR(50) NOT NULL COMMENT '任务子类型',
    params JSON COMMENT '任务参数',
    task_state TINYINT DEFAULT 0 COMMENT '状态: 0待执行 1成功 2失败',
    result_data JSON COMMENT '结果数据',
    error_message VARCHAR(2000) COMMENT '错误信息',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_scene_type (scene_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景定制化任务表';

CREATE TABLE IF NOT EXISTS scene_api_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scene_type VARCHAR(50) NOT NULL COMMENT '场景类型',
    api_name VARCHAR(100) NOT NULL COMMENT '接口名称',
    api_url VARCHAR(500) COMMENT '接口地址',
    protocol VARCHAR(20) DEFAULT 'REST' COMMENT '协议',
    auth_type VARCHAR(30) COMMENT '鉴权类型',
    api_key VARCHAR(500) COMMENT 'API密钥',
    status TINYINT DEFAULT 1 COMMENT '状态',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景API配置表';

CREATE TABLE IF NOT EXISTS scene_key_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scene_type VARCHAR(50) NOT NULL COMMENT '场景类型',
    key_name VARCHAR(100) NOT NULL COMMENT '密钥名称',
    scheme VARCHAR(30) COMMENT '加密方案: BFV/CKKS/BGV',
    public_key TEXT COMMENT '公钥',
    private_key TEXT COMMENT '私钥',
    key_size INT COMMENT '密钥长度',
    status TINYINT DEFAULT 1 COMMENT '状态',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景密钥配置表';

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
