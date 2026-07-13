-- MySQL数据库完整表结构初始化
-- 使用小写表名，UTF8MB4字符集，InnoDB引擎

-- 系统表
CREATE TABLE IF NOT EXISTS sys_user (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_account VARCHAR(64) NOT NULL,
    user_password VARCHAR(128) NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    role_id_list VARCHAR(255) NOT NULL,
    is_forbid TINYINT NOT NULL,
    is_editable TINYINT NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    auth_uuid VARCHAR(255),
    ip VARCHAR(255),
    register_type TINYINT NOT NULL,
    first_login TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)',
    UNIQUE KEY ix_unique_user_account (user_account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_organ (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    apply_id VARCHAR(255),
    organ_id VARCHAR(255),
    organ_name VARCHAR(255),
    organ_gateway VARCHAR(255),
    public_key VARCHAR(1000),
    examine_state TINYINT DEFAULT 0,
    examine_msg TEXT,
    node_state TINYINT DEFAULT 0,
    fusion_state TINYINT DEFAULT 0,
    platform_state TINYINT DEFAULT 0,
    lat DECIMAL(18,14),
    lon DECIMAL(18,14),
    country VARCHAR(255),
    enable TINYINT NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_role (
    role_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(32) NOT NULL,
    is_editable TINYINT NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_auth (
    auth_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    auth_name VARCHAR(64) NOT NULL,
    auth_code VARCHAR(32) NOT NULL,
    auth_type TINYINT NOT NULL,
    p_auth_id BIGINT NOT NULL,
    r_auth_id BIGINT NOT NULL,
    full_path VARCHAR(255) NOT NULL,
    auth_url VARCHAR(255) NOT NULL,
    data_auth_code VARCHAR(64) NOT NULL,
    auth_index INT NOT NULL,
    auth_depth INT NOT NULL,
    is_show TINYINT NOT NULL,
    is_editable TINYINT NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_ra (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT NOT NULL,
    auth_id BIGINT NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_ur (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    is_del BIGINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_file (
    file_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_source INT NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    file_name VARCHAR(64) NOT NULL,
    file_suffix VARCHAR(64) NOT NULL,
    file_size BIGINT NOT NULL,
    file_current_size BIGINT NOT NULL,
    file_area VARCHAR(32) NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sys_user_whitelist (
    whitelist_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    whitelist_type TINYINT NOT NULL COMMENT '白名单类型：1=邮箱，2=手机号',
    whitelist_value VARCHAR(100) NOT NULL COMMENT '白名单值（邮箱地址或手机号）',
    whitelist_desc VARCHAR(255) COMMENT '备注说明',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0=禁用，1=启用',
    is_del TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除：0=否，1=是',
    creator_id BIGINT COMMENT '创建人ID',
    creator_name VARCHAR(64) COMMENT '创建人姓名',
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_type_value (whitelist_type, whitelist_value, is_del)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 业务表
CREATE TABLE IF NOT EXISTS data_project (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id VARCHAR(141) NOT NULL,
    project_name VARCHAR(255) NOT NULL,
    project_desc VARCHAR(255) NOT NULL,
    created_organ_id VARCHAR(64),
    created_organ_name VARCHAR(255),
    created_username VARCHAR(255),
    resource_num INT DEFAULT 0,
    provider_organ_names VARCHAR(255),
    server_address VARCHAR(255),
    status TINYINT DEFAULT 0,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY project_id_ix (project_id),
    KEY created_organ_id_ix (created_organ_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_project_organ (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    po_id VARCHAR(64),
    project_id VARCHAR(64),
    organ_id VARCHAR(64),
    initiate_organ_id VARCHAR(255),
    participation_identity TINYINT,
    audit_status TINYINT,
    audit_opinion VARCHAR(255),
    secretkey_id VARCHAR(64),
    server_address VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY project_id_ix (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_project_resource (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pr_id VARCHAR(64),
    project_id VARCHAR(64),
    initiate_organ_id VARCHAR(64),
    organ_id VARCHAR(64),
    participation_identity TINYINT,
    is_del TINYINT DEFAULT 0,
    resource_id VARCHAR(64) DEFAULT '0',
    audit_status TINYINT,
    audit_opinion VARCHAR(255),
    secretkey_id VARCHAR(64),
    server_address VARCHAR(255),
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY project_id_ix (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_resource (
    resource_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(255),
    resource_desc VARCHAR(255),
    resource_sort_type INT,
    resource_auth_type INT,
    resource_source INT,
    resource_num INT,
    file_id INT,
    file_size INT,
    file_suffix VARCHAR(255),
    file_rows INT,
    file_columns INT,
    file_handle_status TINYINT,
    file_handle_field BLOB,
    file_contains_y TINYINT DEFAULT 0,
    file_y_rows INT DEFAULT 0,
    file_y_ratio DECIMAL(8,4) DEFAULT 0.0000,
    public_organ_id VARCHAR(3072),
    resource_fusion_id VARCHAR(255),
    db_id INT,
    user_id BIGINT,
    organ_id BIGINT,
    url VARCHAR(255),
    resource_hash_code VARCHAR(255),
    resource_state TINYINT NOT NULL DEFAULT 0,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_resource_tag (
    tag_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_rt (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource_id BIGINT,
    tag_id BIGINT,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_file_field (
    field_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_id BIGINT,
    resource_id BIGINT,
    field_name VARCHAR(255),
    field_as VARCHAR(255),
    field_type INT DEFAULT 0,
    field_desc VARCHAR(255),
    relevance INT DEFAULT 0,
    `grouping` INT DEFAULT 0,
    protection_status INT DEFAULT 0,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_model (
    model_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_uuid VARCHAR(255),
    model_name VARCHAR(255),
    model_desc VARCHAR(255),
    model_type INT,
    project_id BIGINT,
    resource_num INT,
    y_value_column VARCHAR(255),
    component_speed VARCHAR(255),
    train_type TINYINT DEFAULT 0,
    is_draft TINYINT DEFAULT 0,
    user_id BIGINT,
    organ_id VARCHAR(255),
    component_json BLOB,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_model_component (
    mc_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_id BIGINT,
    task_id BIGINT,
    input_component_id BIGINT,
    output_component_id BIGINT,
    point_type VARCHAR(255),
    point_json VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_model_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_id BIGINT,
    task_id BIGINT,
    predict_file VARCHAR(255),
    predict_content BLOB,
    component_json BLOB,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_component (
    component_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    front_component_id VARCHAR(255),
    model_id BIGINT,
    task_id BIGINT,
    component_code VARCHAR(255),
    component_name VARCHAR(255),
    shape VARCHAR(255),
    width INT DEFAULT 0,
    height INT DEFAULT 0,
    coordinate_y INT DEFAULT 0,
    coordinate_x INT DEFAULT 0,
    data_json BLOB,
    start_time BIGINT DEFAULT 0,
    end_time BIGINT DEFAULT 0,
    component_state TINYINT DEFAULT 0,
    input_file_path VARCHAR(255),
    output_file_path VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_mr (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_id BIGINT,
    resource_id VARCHAR(255) NOT NULL,
    task_id BIGINT,
    take_part_type TINYINT DEFAULT 0,
    alignment_num INT,
    primitive_param_num INT,
    modelparam_num INT,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_model_quota (
    quota_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    quota_type INT,
    quota_images VARCHAR(255),
    model_id BIGINT,
    component_id BIGINT,
    auc DECIMAL(12,6),
    ks DECIMAL(12,6),
    gini DECIMAL(12,6),
    `precision` DECIMAL(12,6),
    recall DECIMAL(12,6),
    f1_score DECIMAL(12,6),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_psi (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    own_organ_id VARCHAR(255),
    own_resource_id BIGINT,
    own_keyword VARCHAR(255),
    other_organ_id VARCHAR(255),
    other_resource_id VARCHAR(255),
    other_keyword VARCHAR(255),
    output_file_path_type TINYINT DEFAULT 0,
    output_no_repeat TINYINT DEFAULT 0,
    tag TINYINT DEFAULT 0,
    result_name VARCHAR(255),
    output_content INT DEFAULT 0,
    output_format VARCHAR(255),
    result_organ_ids VARCHAR(255),
    server_address VARCHAR(255),
    remarks VARCHAR(255),
    user_id BIGINT,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_psi_resource (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource_id BIGINT,
    psi_resource_desc VARCHAR(255),
    table_structure_template VARCHAR(255),
    organ_type INT,
    results_allow_open INT,
    keyword_list VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_psi_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    psi_id BIGINT,
    task_id VARCHAR(255),
    task_state INT DEFAULT 0,
    ascription_type INT DEFAULT 0,
    ascription VARCHAR(255),
    file_rows INT DEFAULT 0,
    file_path VARCHAR(255),
    file_content BLOB,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_pir_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT,
    server_address VARCHAR(255),
    provider_organ_name VARCHAR(255),
    resource_id VARCHAR(64),
    resource_name VARCHAR(64),
    retrieval_id VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_task (
    task_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id_name VARCHAR(255),
    task_name VARCHAR(255),
    task_desc VARCHAR(255),
    task_state INT DEFAULT 0,
    task_type INT,
    task_result_path VARCHAR(255),
    task_result_content BLOB,
    task_start_time BIGINT,
    task_end_time BIGINT,
    task_user_id BIGINT,
    task_error_msg BLOB,
    is_cooperation TINYINT DEFAULT 0,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_mpc_task (
    task_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id_name VARCHAR(255),
    script_id BIGINT,
    user_id BIGINT,
    task_status INT DEFAULT 0,
    task_desc VARCHAR(255),
    log_data BLOB,
    result_file_path VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_script (
    script_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    catalogue INT DEFAULT 0,
    p_script_id BIGINT,
    script_type INT,
    script_status INT,
    script_content BLOB,
    user_id BIGINT,
    organ_id BIGINT,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_reasoning (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reasoning_id VARCHAR(255),
    reasoning_name VARCHAR(255),
    reasoning_desc VARCHAR(255),
    reasoning_type TINYINT,
    reasoning_state TINYINT,
    task_id BIGINT,
    run_task_id BIGINT,
    user_id BIGINT,
    release_date TIMESTAMP NULL,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_reasoning_resource (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reasoning_id BIGINT,
    resource_id VARCHAR(64),
    organ_id VARCHAR(64),
    participation_identity TINYINT,
    server_address VARCHAR(255),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_source (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    db_type INT,
    db_driver VARCHAR(100),
    db_url VARCHAR(500),
    db_name VARCHAR(100),
    db_table_name VARCHAR(100),
    db_username VARCHAR(100),
    db_password VARCHAR(100),
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_component_draft (
    draft_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    draft_name VARCHAR(255),
    user_id BIGINT,
    component_json BLOB,
    component_image BLOB,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_fusion_copy_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_type TINYINT NOT NULL,
    current_offset BIGINT NOT NULL,
    target_offset BIGINT NOT NULL,
    task_table VARCHAR(64) NOT NULL,
    fusion_server_address VARCHAR(64) NOT NULL,
    latest_error_msg VARCHAR(1024) NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY current_offset_ix (current_offset),
    KEY target_offset_ix (target_offset),
    KEY c_time_ix (c_time),
    KEY u_time_ix (u_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_resource_visibility_auth (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource_id BIGINT NOT NULL,
    organ_global_id VARCHAR(64) NOT NULL,
    organ_name VARCHAR(64) NOT NULL,
    organ_server_address VARCHAR(255) NOT NULL,
    is_del TINYINT NOT NULL,
    c_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY resource_id_ix (resource_id),
    KEY organ_global_id_ix (organ_global_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS data_visiting_users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    familiarity_practitioner TINYINT,
    familiarity_alreadyinusE TINYINT,
    familiarity_veryfamiliar TINYINT,
    familiarity_generalfamiliar TINYINT,
    familiarity_notknow TINYINT,
    gender_male TINYINT,
    gender_female TINYINT,
    city_beijing TINYINT,
    city_shanghai TINYINT,
    city_shenzhen TINYINT,
    city_hangzhou TINYINT,
    city_changsha TINYINT,
    industry_internet TINYINT,
    industry_financial TINYINT,
    industry_government TINYINT,
    industry_medical TINYINT,
    industry_industrial TINYINT,
    industry_car TINYINT,
    industry_newenergy TINYINT,
    industry_other TINYINT,
    visitpurposes_cooperation TINYINT,
    visitpurposes_learning TINYINT,
    visitpurposes_trial TINYINT,
    visitpurposes_browse TINYINT,
    age_age TINYINT,
    jobposition_manager TINYINT,
    jobposition_pm TINYINT,
    jobposition_developer TINYINT,
    jobposition_commerceaffairs TINYINT,
    jobposition_solution TINYINT,
    jobposition_other TINYINT,
    is_del TINYINT DEFAULT 0,
    create_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 系统操作日志表
CREATE TABLE IF NOT EXISTS sys_operation_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '日志ID',
    user_id BIGINT COMMENT '操作用户ID',
    user_name VARCHAR(100) COMMENT '操作用户名',
    operation_type TINYINT COMMENT '操作类型：1-新增 2-修改 3-删除 4-登录 5-登出',
    operation_module VARCHAR(50) COMMENT '操作模块（如：用户管理、项目管理）',
    operation_desc VARCHAR(200) COMMENT '操作描述',
    request_method VARCHAR(10) COMMENT '请求方法：POST/PUT/DELETE',
    request_url VARCHAR(500) COMMENT '请求URL',
    request_params TEXT COMMENT '请求参数（JSON格式）',
    response_code VARCHAR(20) COMMENT '响应状态码',
    response_msg VARCHAR(500) COMMENT '响应消息',
    operation_time BIGINT COMMENT '操作耗时（毫秒）',
    ip_address VARCHAR(50) COMMENT 'IP地址',
    user_agent VARCHAR(500) COMMENT '用户代理',
    exception_msg TEXT COMMENT '异常信息',
    is_success TINYINT DEFAULT 1 COMMENT '是否成功：0-失败 1-成功',
    is_del TINYINT DEFAULT 0 COMMENT '是否删除：0-否 1-是',
    created_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    KEY idx_user_id (user_id),
    KEY idx_operation_type (operation_type),
    KEY idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统操作日志表';

-- 任务执行日志表
CREATE TABLE IF NOT EXISTS data_task_execution_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '日志ID',
    task_id VARCHAR(50) NOT NULL COMMENT '任务ID',
    task_id_name VARCHAR(100) COMMENT '任务标识名称',
    task_type TINYINT COMMENT '任务类型：1-模型 2-PSI 3-PIR 4-推理 5-联合统计',
    component_id BIGINT COMMENT '组件ID（模型任务有组件）',
    component_name VARCHAR(100) COMMENT '组件名称',
    log_level VARCHAR(20) COMMENT '日志级别：INFO/WARN/ERROR',
    log_type VARCHAR(50) COMMENT '日志类型：START/RUNNING/SUCCESS/FAIL/CANCEL',
    log_message TEXT COMMENT '日志消息',
    execution_phase VARCHAR(50) COMMENT '执行阶段（如：数据准备、模型训练、结果保存）',
    error_code VARCHAR(50) COMMENT '错误码',
    error_stack TEXT COMMENT '错误堆栈',
    execution_time BIGINT COMMENT '执行耗时（毫秒）',
    created_by BIGINT COMMENT '创建人ID',
    is_del TINYINT DEFAULT 0 COMMENT '是否删除：0-否 1-是',
    created_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    KEY idx_task_id (task_id),
    KEY idx_task_type (task_type),
    KEY idx_log_level (log_level),
    KEY idx_created_time (created_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务执行日志表';

-- 系统配置表
CREATE TABLE IF NOT EXISTS sys_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_group VARCHAR(50) NOT NULL COMMENT '配置分组: network/time/login_restriction/personalization/ftp',
    config_key VARCHAR(100) NOT NULL COMMENT '配置键',
    config_value TEXT COMMENT '配置值',
    config_desc VARCHAR(500) COMMENT '配置说明',
    is_encrypted TINYINT(1) DEFAULT 0 COMMENT '是否加密存储',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_group_key (config_group, config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 联邦统计任务表
CREATE TABLE IF NOT EXISTS federated_stats_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_name VARCHAR(200) NOT NULL COMMENT '任务名称',
    project_id BIGINT COMMENT '关联项目ID',
    stats_type VARCHAR(50) NOT NULL COMMENT '统计类型: descriptive/group_by/conditional/proportion/t_test/f_test/chi_square/regression/correlation',
    algorithm_type VARCHAR(30) COMMENT '算法类型: DH/OT/HE',
    task_state TINYINT DEFAULT 0 COMMENT '状态: 0待执行 1执行中 2成功 3失败 4取消',
    task_param JSON COMMENT '任务参数',
    result_summary VARCHAR(500) COMMENT '结果摘要',
    error_message VARCHAR(2000) COMMENT '错误信息',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_project (project_id),
    INDEX idx_stats_type (stats_type),
    INDEX idx_task_state (task_state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦统计任务表';

-- 联邦统计结果表
CREATE TABLE IF NOT EXISTS federated_stats_result (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL COMMENT '关联任务ID',
    result_type VARCHAR(30) DEFAULT 'final' COMMENT '结果类型: interim/final',
    result_data JSON COMMENT '结果数据',
    result_file VARCHAR(500) COMMENT '结果文件路径',
    row_count INT COMMENT '结果行数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦统计结果表';

-- 联邦统计存储配置表
CREATE TABLE IF NOT EXISTS federated_stats_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_name VARCHAR(100) NOT NULL COMMENT '配置名称',
    storage_type VARCHAR(30) NOT NULL COMMENT '存储类型: local/oss/s3',
    storage_path VARCHAR(500) COMMENT '存储路径',
    connection_json JSON COMMENT '连接参数',
    is_default TINYINT(1) DEFAULT 0 COMMENT '是否默认',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦统计存储配置表';

-- 联邦分析任务表
CREATE TABLE IF NOT EXISTS federated_analysis_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_name VARCHAR(200) NOT NULL COMMENT '任务名称',
    project_id BIGINT COMMENT '关联项目ID',
    source_sql TEXT NOT NULL COMMENT '原始SQL',
    rewritten_sql TEXT COMMENT '改写后SQL',
    task_state TINYINT DEFAULT 0 COMMENT '状态: 0待执行 1执行中 2成功 3失败',
    task_param JSON COMMENT '执行参数',
    result_summary VARCHAR(500) COMMENT '结果摘要',
    result_row_count INT COMMENT '结果行数',
    error_message VARCHAR(2000) COMMENT '错误信息',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_project (project_id),
    INDEX idx_task_state (task_state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦分析任务表';

-- 联邦分析数据源配置表
CREATE TABLE IF NOT EXISTS federated_analysis_datasource (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(100) NOT NULL COMMENT '数据源名称',
    source_type VARCHAR(30) NOT NULL COMMENT '类型: mysql/postgresql/oracle/spark/hive/flink/oss/s3',
    source_config JSON NOT NULL COMMENT '连接参数',
    is_connected TINYINT(1) DEFAULT 0 COMMENT '上次连接测试结果',
    last_test_time DATETIME COMMENT '最后测试时间',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_source_type (source_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦分析数据源配置表';

-- 联邦分析结果表
CREATE TABLE IF NOT EXISTS federated_analysis_result (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL COMMENT '关联任务ID',
    result_type VARCHAR(30) DEFAULT 'final' COMMENT '结果类型: schema/interim/final',
    result_data JSON COMMENT '结果数据',
    result_file VARCHAR(500) COMMENT '结果文件路径',
    column_metadata JSON COMMENT '列元数据',
    row_count INT COMMENT '结果行数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦分析结果表';

-- 联邦查询计费规则表
CREATE TABLE IF NOT EXISTS federated_billing_rule (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL COMMENT '规则名称',
    billing_type VARCHAR(30) NOT NULL COMMENT '计费类型: by_count/by_hit/fixed_dedup/rolling_dedup',
    apply_resource_ids JSON COMMENT '适用资源ID列表',
    apply_organ_ids JSON COMMENT '适用机构ID列表',
    base_fee DECIMAL(12,4) DEFAULT 0 COMMENT '基础费',
    min_charge DECIMAL(12,4) DEFAULT 0 COMMENT '最低收费',
    is_active TINYINT(1) DEFAULT 0 COMMENT '是否启用',
    effective_from DATETIME COMMENT '生效时间',
    effective_to DATETIME COMMENT '失效时间',
    price_per_query DECIMAL(12,4) COMMENT '每次查询价格',
    enable_discount TINYINT(1) COMMENT '是否启用折扣',
    discount_threshold INT COMMENT '折扣阈值',
    discount_rate DECIMAL(5,4) COMMENT '折扣率',
    price_per_hit DECIMAL(12,4) COMMENT '每条命中价格',
    enable_tiered TINYINT(1) COMMENT '是否启用阶梯价',
    tiered_pricing JSON COMMENT '阶梯价配置',
    dedup_time_window VARCHAR(20) COMMENT '去重窗口',
    price_per_unique DECIMAL(12,4) COMMENT '去重后每条价格',
    repeat_discount DECIMAL(5,4) COMMENT '重复折扣',
    rolling_window_hours INT COMMENT '滚动窗口(小时)',
    slide_interval_hours INT COMMENT '滑动间隔(小时)',
    rolling_price_per_unique DECIMAL(12,4) COMMENT '滚动去重价格',
    rolling_repeat_discount DECIMAL(5,4) COMMENT '滚动重复折扣',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_billing_type (billing_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询计费规则表';

-- 联邦查询计费记录表
CREATE TABLE IF NOT EXISTS federated_billing_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rule_id BIGINT NOT NULL COMMENT '关联规则ID',
    task_type VARCHAR(30) NOT NULL COMMENT '任务类型: psi/difference/union/analysis',
    task_id BIGINT NOT NULL COMMENT '关联任务ID',
    requester_organ_id VARCHAR(50) NOT NULL COMMENT '请求方机构ID',
    provider_organ_id VARCHAR(50) COMMENT '提供方机构ID',
    resource_ids JSON COMMENT '使用资源ID列表',
    billing_type VARCHAR(30) NOT NULL COMMENT '计费类型',
    query_count INT DEFAULT 0 COMMENT '查询次数',
    hit_count INT DEFAULT 0 COMMENT '命中记录数',
    dedup_key VARCHAR(64) COMMENT '去重KEY',
    dedup_window_start DATETIME COMMENT '去重窗口开始',
    dedup_window_end DATETIME COMMENT '去重窗口结束',
    unit_price DECIMAL(12,4) COMMENT '单价',
    discount_rate_applied DECIMAL(5,4) COMMENT '实际折扣率',
    total_charge DECIMAL(12,4) NOT NULL COMMENT '总费用',
    charge_status TINYINT DEFAULT 0 COMMENT '状态: 0待结算 1已结算 2已退款',
    billing_time DATETIME NOT NULL COMMENT '计费时间',
    settled_at DATETIME COMMENT '结算时间',
    remark VARCHAR(500) COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task (task_type, task_id),
    INDEX idx_requester (requester_organ_id),
    INDEX idx_billing_time (billing_time),
    INDEX idx_dedup_key (dedup_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询计费记录表';

-- 场景定制化任务表
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

-- ========== 存证管理 ==========

CREATE TABLE IF NOT EXISTS evidence_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    evidence_hash VARCHAR(128) NOT NULL COMMENT '存证哈希',
    evidence_data LONGTEXT COMMENT '存证数据(JSON)',
    evidence_type VARCHAR(50) COMMENT '存证类型: file/text/hash',
    file_name VARCHAR(255) COMMENT '文件名',
    file_size BIGINT COMMENT '文件大小(字节)',
    file_type VARCHAR(50) COMMENT '文件MIME类型',
    status TINYINT DEFAULT 0 COMMENT '状态: 0待上链 1已上链 2已验证 3已过期',
    block_height BIGINT COMMENT '区块链高度',
    block_hash VARCHAR(128) COMMENT '区块哈希',
    tx_hash VARCHAR(128) COMMENT '交易哈希',
    chain_type VARCHAR(30) DEFAULT 'FABRIC' COMMENT '区块链类型',
    description VARCHAR(500) COMMENT '存证描述',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_evidence_hash (evidence_hash),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证记录表';

CREATE TABLE IF NOT EXISTS evidence_timestamp (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    evidence_id BIGINT NOT NULL COMMENT '关联存证ID',
    timestamp_value DATETIME NOT NULL COMMENT '时间戳时间',
    timestamp_hash VARCHAR(128) COMMENT '时间戳哈希',
    timestamp_source VARCHAR(50) DEFAULT 'LOCAL' COMMENT '时间戳来源: LOCAL/NTP/BLOCKCHAIN',
    nonce VARCHAR(64) COMMENT '随机数',
    status TINYINT DEFAULT 0 COMMENT '状态: 0待确认 1已确认 2已验证',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_evidence_id (evidence_id),
    INDEX idx_timestamp_value (timestamp_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证时间戳表';

CREATE TABLE IF NOT EXISTS evidence_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(64) NOT NULL COMMENT '配置键',
    config_value TEXT COMMENT '配置值',
    config_desc VARCHAR(500) COMMENT '配置说明',
    is_encrypted TINYINT(1) DEFAULT 0 COMMENT '是否加密',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证配置表';

CREATE TABLE IF NOT EXISTS evidence_api_key (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    api_key VARCHAR(128) NOT NULL COMMENT 'API密钥',
    secret_key VARCHAR(256) NOT NULL COMMENT '密钥密文',
    status TINYINT DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    expiry_date DATETIME COMMENT '过期时间',
    description VARCHAR(500) COMMENT '描述',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_api_key (api_key),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证API密钥表';

CREATE TABLE IF NOT EXISTS evidence_export_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    evidence_id BIGINT COMMENT '关联存证ID',
    export_type VARCHAR(30) NOT NULL COMMENT '导出类型: plain/encrypted',
    file_name VARCHAR(255) COMMENT '文件名',
    file_size BIGINT COMMENT '文件大小',
    is_encrypted TINYINT(1) DEFAULT 0 COMMENT '是否加密',
    encrypt_algorithm VARCHAR(30) COMMENT '加密算法',
    status TINYINT DEFAULT 0 COMMENT '状态: 0处理中 1已完成 2失败',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_evidence_id (evidence_id),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证导出记录表';

CREATE TABLE IF NOT EXISTS evidence_api_call_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    api_key_id BIGINT COMMENT '关联API密钥ID',
    api_path VARCHAR(255) NOT NULL COMMENT '请求路径',
    request_method VARCHAR(10) COMMENT '请求方法',
    request_params TEXT COMMENT '请求参数',
    response_code INT COMMENT '响应码',
    response_body TEXT COMMENT '响应体',
    client_ip VARCHAR(64) COMMENT '客户端IP',
    execution_time INT COMMENT '执行时间(ms)',
    status TINYINT DEFAULT 1 COMMENT '状态: 0失败 1成功',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_api_key_id (api_key_id),
    INDEX idx_api_path (api_path),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证API调用日志表';

-- ========== 监控管理 ==========

CREATE TABLE IF NOT EXISTS monitor_alert_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    monitor_type VARCHAR(30) NOT NULL COMMENT '监控类型: CPU/MEMORY/DISK/DATABASE/JVM/REDIS',
    threshold DECIMAL(10,2) NOT NULL COMMENT '告警阈值',
    duration INT DEFAULT 300 COMMENT '持续时长(秒)',
    alert_level TINYINT DEFAULT 1 COMMENT '告警级别: 1警告 2严重 3紧急',
    notify_method VARCHAR(50) COMMENT '通知方式: email/sms/webhook',
    notify_target VARCHAR(500) COMMENT '通知目标',
    is_enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_monitor_type (monitor_type),
    INDEX idx_is_enabled (is_enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控告警配置表';

CREATE TABLE IF NOT EXISTS monitor_alert_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_id BIGINT COMMENT '关联配置ID',
    monitor_type VARCHAR(30) NOT NULL COMMENT '监控类型',
    alert_level TINYINT DEFAULT 1 COMMENT '告警级别',
    alert_value DECIMAL(10,2) COMMENT '触发值',
    threshold DECIMAL(10,2) COMMENT '阈值',
    message VARCHAR(1000) COMMENT '告警消息',
    status TINYINT DEFAULT 0 COMMENT '状态: 0未处理 1已处理 2已忽略',
    handled_by BIGINT COMMENT '处理人',
    handled_at DATETIME COMMENT '处理时间',
    handle_remark VARCHAR(500) COMMENT '处理备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_config_id (config_id),
    INDEX idx_monitor_type (monitor_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控告警历史表';

CREATE TABLE IF NOT EXISTS monitor_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    monitor_type VARCHAR(30) NOT NULL COMMENT '监控类型: CPU/MEMORY/DISK/DATABASE/JVM/REDIS',
    metric_name VARCHAR(100) NOT NULL COMMENT '指标名称',
    metric_value DECIMAL(15,4) NOT NULL COMMENT '指标值',
    unit VARCHAR(20) COMMENT '单位',
    extra_data JSON COMMENT '扩展数据',
    recorded_at DATETIME NOT NULL COMMENT '记录时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_monitor_type (monitor_type),
    INDEX idx_metric_name (metric_name),
    INDEX idx_recorded_at (recorded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控记录表';

-- ========== 接口管理 ==========

CREATE TABLE IF NOT EXISTS api_definition (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    api_name VARCHAR(100) NOT NULL COMMENT '接口名称',
    api_path VARCHAR(255) NOT NULL COMMENT '接口路径',
    api_method VARCHAR(10) NOT NULL COMMENT '请求方法: GET/POST/PUT/DELETE',
    protocol VARCHAR(20) DEFAULT 'REST' COMMENT '协议',
    content_type VARCHAR(50) DEFAULT 'application/json' COMMENT 'Content-Type',
    description VARCHAR(500) COMMENT '接口描述',
    request_example TEXT COMMENT '请求示例',
    response_example TEXT COMMENT '响应示例',
    status TINYINT DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    is_require_auth TINYINT(1) DEFAULT 1 COMMENT '是否需要授权',
    rate_limit INT DEFAULT 0 COMMENT '速率限制(次/秒)',
    timeout INT DEFAULT 30000 COMMENT '超时时间(ms)',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_api_path (api_path),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='接口定义表';

CREATE TABLE IF NOT EXISTS api_auth_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    api_id BIGINT NOT NULL COMMENT '关联接口ID',
    auth_name VARCHAR(100) NOT NULL COMMENT '授权名称',
    app_key VARCHAR(128) NOT NULL COMMENT 'AppKey',
    app_secret VARCHAR(256) NOT NULL COMMENT 'AppSecret',
    auth_type VARCHAR(30) DEFAULT 'APP_KEY' COMMENT '鉴权类型: APP_KEY/JWT/OAuth2',
    allowed_ips VARCHAR(500) COMMENT '允许IP列表(逗号分隔)',
    expire_time DATETIME COMMENT '过期时间',
    status TINYINT DEFAULT 1 COMMENT '状态: 0禁用 1启用',
    description VARCHAR(500) COMMENT '描述',
    created_by BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_app_key (app_key),
    INDEX idx_api_id (api_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='接口授权配置表';

CREATE TABLE IF NOT EXISTS api_call_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    api_id BIGINT COMMENT '关联接口ID',
    auth_id BIGINT COMMENT '关联授权ID',
    request_path VARCHAR(255) NOT NULL COMMENT '请求路径',
    request_method VARCHAR(10) COMMENT '请求方法',
    request_params TEXT COMMENT '请求参数',
    request_headers TEXT COMMENT '请求头',
    response_code INT COMMENT '响应状态码',
    response_body TEXT COMMENT '响应体',
    client_ip VARCHAR(64) COMMENT '客户端IP',
    execution_time INT COMMENT '执行时长(ms)',
    is_success TINYINT(1) DEFAULT 1 COMMENT '是否成功',
    error_message VARCHAR(2000) COMMENT '错误信息',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_api_id (api_id),
    INDEX idx_auth_id (auth_id),
    INDEX idx_is_success (is_success),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='接口调用日志表';

-- ========== 联邦查询管理 ==========

CREATE TABLE IF NOT EXISTS federated_query_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_name VARCHAR(200) NOT NULL COMMENT '任务名称',
    algorithm VARCHAR(30) NOT NULL COMMENT '算法: DH/OT/HE',
    query_mode VARCHAR(30) NOT NULL COMMENT '模式: batch/realtime',
    query_type VARCHAR(30) DEFAULT 'psi' COMMENT '查询类型: psi/difference/union',
    task_state TINYINT DEFAULT 0 COMMENT '状态: 0待执行 1执行中 2成功 3失败',
    source_config JSON COMMENT '数据源配置',
    result_summary VARCHAR(500) COMMENT '结果摘要',
    result_row_count INT COMMENT '结果行数',
    error_message VARCHAR(2000) COMMENT '错误信息',
    created_by BIGINT COMMENT '创建人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_algorithm (algorithm),
    INDEX idx_task_state (task_state),
    INDEX idx_created_by (created_by),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询任务表';

CREATE TABLE IF NOT EXISTS federated_query_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT COMMENT '关联任务ID',
    log_level VARCHAR(10) DEFAULT 'INFO' COMMENT '日志级别: DEBUG/INFO/WARN/ERROR',
    log_message TEXT COMMENT '日志内容',
    log_data JSON COMMENT '结构化日志数据',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_id (task_id),
    INDEX idx_log_level (log_level),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询日志表';

-- =====================================================================
-- 缺陷整改 T5：补齐随功能上线却漏建的启动表（列名对齐 MyBatis mapper）
-- 缺陷映射：操作/调度/计算 日志定义新增异常、计算日志记录、数据需求、共享数据集
-- =====================================================================
CREATE TABLE IF NOT EXISTS `sys_operation_log_definition` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码',
  `log_name` VARCHAR(200) NOT NULL COMMENT '日志名称',
  `log_type` VARCHAR(50) NOT NULL COMMENT '日志类型',
  `module_name` VARCHAR(100) DEFAULT NULL COMMENT '模块名称',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用',
  `retention_days` INT(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志定义表';

CREATE TABLE IF NOT EXISTS `sys_schedule_log_definition` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码',
  `log_name` VARCHAR(200) NOT NULL COMMENT '日志名称',
  `schedule_type` VARCHAR(50) NOT NULL COMMENT '调度类型',
  `module_name` VARCHAR(100) DEFAULT NULL COMMENT '模块名称',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用',
  `retention_days` INT(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='调度日志定义表';

CREATE TABLE IF NOT EXISTS `sys_compute_log_definition` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码',
  `log_name` VARCHAR(200) NOT NULL COMMENT '日志名称',
  `compute_type` VARCHAR(50) NOT NULL COMMENT '计算类型',
  `module_name` VARCHAR(100) DEFAULT NULL COMMENT '模块名称',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用',
  `retention_days` INT(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计算日志定义表';

CREATE TABLE IF NOT EXISTS `sys_compute_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码',
  `task_id` VARCHAR(100) DEFAULT NULL COMMENT '任务ID',
  `task_name` VARCHAR(200) DEFAULT NULL COMMENT '任务名称',
  `compute_type` VARCHAR(50) DEFAULT NULL COMMENT '计算类型',
  `project_id` BIGINT DEFAULT NULL COMMENT '项目ID',
  `project_name` VARCHAR(200) DEFAULT NULL COMMENT '项目名称',
  `user_id` BIGINT DEFAULT NULL COMMENT '用户ID',
  `user_name` VARCHAR(100) DEFAULT NULL COMMENT '用户名',
  `organ_id` BIGINT DEFAULT NULL COMMENT '机构ID',
  `organ_name` VARCHAR(200) DEFAULT NULL COMMENT '机构名称',
  `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
  `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
  `execution_time` BIGINT DEFAULT NULL COMMENT '执行时长(ms)',
  `status` TINYINT(1) DEFAULT 0 COMMENT '状态',
  `result_data` TEXT COMMENT '计算结果',
  `error_msg` TEXT COMMENT '错误信息',
  `resource_usage` TEXT COMMENT '资源使用',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_log_code` (`log_code`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计算日志记录表';

CREATE TABLE IF NOT EXISTS `data_requirement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_code` VARCHAR(64) NOT NULL COMMENT '需求编码',
  `requirement_name` VARCHAR(128) NOT NULL COMMENT '需求名称',
  `requirement_desc` TEXT COMMENT '需求描述',
  `requirement_type` VARCHAR(32) COMMENT '需求类型',
  `data_fields` TEXT COMMENT '所需数据字段(JSON)',
  `data_volume` BIGINT COMMENT '所需数据量',
  `data_format` VARCHAR(32) COMMENT '所需数据格式',
  `priority` TINYINT DEFAULT 0 COMMENT '优先级',
  `status` TINYINT DEFAULT 0 COMMENT '状态',
  `user_id` BIGINT NOT NULL COMMENT '创建人ID',
  `user_name` VARCHAR(64) COMMENT '创建人',
  `organ_id` BIGINT COMMENT '机构ID',
  `organ_name` VARCHAR(128) COMMENT '机构名称',
  `start_date` DATETIME COMMENT '开始日期',
  `end_date` DATETIME COMMENT '结束日期',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_code` (`requirement_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求表';

CREATE TABLE IF NOT EXISTS `data_requirement_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_key` VARCHAR(64) NOT NULL COMMENT '配置键',
  `config_value` TEXT NOT NULL COMMENT '配置值',
  `config_desc` VARCHAR(255) COMMENT '配置描述',
  `config_type` VARCHAR(32) COMMENT '配置类型',
  `is_enabled` TINYINT DEFAULT 1 COMMENT '启用标记',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求配置表';

CREATE TABLE IF NOT EXISTS `data_requirement_match` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_id` BIGINT NOT NULL COMMENT '需求ID',
  `resource_id` BIGINT NOT NULL COMMENT '资源ID',
  `match_score` DECIMAL(5,2) DEFAULT 0.00 COMMENT '匹配得分',
  `match_status` TINYINT DEFAULT 0 COMMENT '匹配状态',
  `match_type` VARCHAR(32) COMMENT '匹配类型',
  `match_details` TEXT COMMENT '匹配详情(JSON)',
  `confirm_user_id` BIGINT COMMENT '确认人ID',
  `confirm_user_name` VARCHAR(64) COMMENT '确认人',
  `confirm_date` DATETIME COMMENT '确认时间',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_requirement_id` (`requirement_id`),
  KEY `idx_resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求匹配表';

CREATE TABLE IF NOT EXISTS `shared_dataset` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `dataset_code` VARCHAR(64) NOT NULL COMMENT '数据集编码',
  `dataset_name` VARCHAR(255) NOT NULL COMMENT '数据集名称',
  `dataset_desc` TEXT COMMENT '数据集描述',
  `data_type` VARCHAR(32) COMMENT '数据类型',
  `data_format` VARCHAR(32) COMMENT '数据格式',
  `data_fields` TEXT COMMENT '数据字段(JSON)',
  `data_volume` BIGINT COMMENT '数据量',
  `share_status` INT DEFAULT 0 COMMENT '共享状态',
  `share_scope` INT DEFAULT 0 COMMENT '共享范围',
  `target_organ_ids` TEXT COMMENT '目标机构ID列表',
  `resource_id` BIGINT COMMENT '关联资源ID',
  `resource_name` VARCHAR(255) COMMENT '关联资源名称',
  `usage_terms` VARCHAR(1000) COMMENT '使用条款',
  `user_id` BIGINT COMMENT '创建人ID',
  `user_name` VARCHAR(64) COMMENT '创建人',
  `organ_id` BIGINT COMMENT '机构ID',
  `organ_name` VARCHAR(128) COMMENT '机构名称',
  `start_date` DATETIME COMMENT '共享开始日期',
  `end_date` DATETIME COMMENT '共享结束日期',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dataset_code` (`dataset_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_share_status` (`share_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='共享数据集表';
