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
    grouping INT DEFAULT 0,
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
    precision DECIMAL(12,6),
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
