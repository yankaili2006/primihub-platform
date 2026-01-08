-- H2数据库表结构初始化
-- 注意：H2语法与MySQL略有不同
-- 使用小写表名以匹配MyBatis mapper中的引用

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
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    auth_uuid VARCHAR(255),
    ip VARCHAR(255),
    register_type TINYINT NOT NULL,
    UNIQUE KEY ix_unique_user_account (user_account)
);

CREATE TABLE IF NOT EXISTS sys_organ (
    organ_id VARCHAR(255) PRIMARY KEY,
    organ_name VARCHAR(255) NOT NULL,
    gateway_address VARCHAR(500),
    public_key TEXT,
    private_key TEXT,
    pin_code VARCHAR(255),
    organ_status TINYINT,
    is_del TINYINT,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sys_role (
    role_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(255) NOT NULL,
    role_code VARCHAR(255) NOT NULL,
    is_del TINYINT,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sys_auth (
    auth_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    auth_name VARCHAR(255) NOT NULL,
    auth_code VARCHAR(255) NOT NULL,
    auth_type TINYINT NOT NULL DEFAULT 1 COMMENT '权限类型：1=菜单，2=列表，3=按钮',
    p_auth_id BIGINT NOT NULL DEFAULT 0 COMMENT '父权限ID',
    r_auth_id BIGINT NOT NULL DEFAULT 0 COMMENT '根权限ID',
    full_path VARCHAR(255) DEFAULT '',
    auth_url VARCHAR(255) DEFAULT '',
    data_auth_code VARCHAR(64) DEFAULT '',
    auth_index INT DEFAULT 0,
    auth_depth INT DEFAULT 0,
    is_show TINYINT DEFAULT 1,
    is_editable TINYINT DEFAULT 1,
    is_del TINYINT DEFAULT 0,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sys_ra (
    ra_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT NOT NULL,
    auth_id BIGINT NOT NULL,
    is_del TINYINT,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sys_ur (
    ur_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    is_del TINYINT,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sys_file (
    file_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size BIGINT,
    is_del TINYINT,
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 用户白名单表
CREATE TABLE IF NOT EXISTS sys_user_whitelist (
    whitelist_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    whitelist_type TINYINT NOT NULL COMMENT '白名单类型：1=邮箱，2=手机号',
    whitelist_value VARCHAR(100) NOT NULL COMMENT '白名单值（邮箱地址或手机号）',
    whitelist_desc VARCHAR(255) COMMENT '备注说明',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0=禁用，1=启用',
    is_del TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除：0=否，1=是',
    creator_id BIGINT COMMENT '创建人ID',
    creator_name VARCHAR(64) COMMENT '创建人姓名',
    c_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    u_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_type_value (whitelist_type, whitelist_value, is_del)
);

-- 项目表
CREATE TABLE IF NOT EXISTS data_project (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id VARCHAR(255),
    project_name VARCHAR(255),
    project_desc VARCHAR(500),
    created_organ_id VARCHAR(255),
    created_organ_name VARCHAR(255),
    created_username VARCHAR(255),
    resource_num INT,
    provider_organ_names VARCHAR(1000),
    status INT,
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 资源表
CREATE TABLE IF NOT EXISTS data_resource (
    resource_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(255),
    resource_desc VARCHAR(500),
    resource_type INT,
    resource_source INT,
    resource_auth_type INT,
    fusions VARCHAR(2000),
    fusions_map VARCHAR(2000),
    resource_rows_count INT,
    resource_column_count INT,
    resource_column_name_list VARCHAR(2000),
    resource_column_type_list VARCHAR(2000),
    resource_state INT DEFAULT 0,
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT,
    organ_id VARCHAR(255)
);

-- PSI任务表
CREATE TABLE IF NOT EXISTS data_psi_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(255),
    task_name VARCHAR(255),
    task_desc VARCHAR(500),
    task_state INT,
    resource_id VARCHAR(255),
    resource_name VARCHAR(255),
    organ_id VARCHAR(255),
    organ_name VARCHAR(255),
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PIR任务表
CREATE TABLE IF NOT EXISTS data_pir_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(255),
    task_name VARCHAR(255),
    task_desc VARCHAR(500),
    task_state INT,
    resource_id VARCHAR(255),
    resource_name VARCHAR(255),
    organ_id VARCHAR(255),
    organ_name VARCHAR(255),
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 项目机构关联表
CREATE TABLE IF NOT EXISTS data_project_organ (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    po_id VARCHAR(255),
    project_id VARCHAR(255),
    organ_id VARCHAR(255),
    initiate_organ_id VARCHAR(255),
    participation_identity INT,
    audit_status INT,
    audit_opinion VARCHAR(500),
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 项目资源关联表
CREATE TABLE IF NOT EXISTS data_project_resource (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pr_id VARCHAR(255),
    project_id VARCHAR(255),
    initiate_organ_id VARCHAR(255),
    organ_id VARCHAR(255),
    participation_identity INT,
    is_del INT DEFAULT 0,
    resource_id VARCHAR(255),
    audit_status INT,
    audit_opinion VARCHAR(500),
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 资源标签表
CREATE TABLE IF NOT EXISTS data_resource_tag (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource_id VARCHAR(255),
    tag_name VARCHAR(255),
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PSI主表
CREATE TABLE IF NOT EXISTS data_psi (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    result_name VARCHAR(255),
    other_organ_id VARCHAR(255),
    tag VARCHAR(255),
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 任务表
CREATE TABLE IF NOT EXISTS data_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id_name VARCHAR(255),
    task_name VARCHAR(255),
    task_start_time TIMESTAMP,
    task_end_time TIMESTAMP,
    is_del INT DEFAULT 0,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 系统操作日志表
CREATE TABLE IF NOT EXISTS sys_operation_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    user_name VARCHAR(100),
    operation_type INT,
    operation_module VARCHAR(50),
    operation_desc VARCHAR(200),
    request_method VARCHAR(10),
    request_url VARCHAR(500),
    request_params TEXT,
    response_code VARCHAR(20),
    response_msg VARCHAR(500),
    operation_time BIGINT,
    ip_address VARCHAR(50),
    user_agent VARCHAR(500),
    exception_msg TEXT,
    is_success INT DEFAULT 1,
    is_del INT DEFAULT 0,
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_operation_log_user_id ON sys_operation_log(user_id);
CREATE INDEX idx_operation_log_operation_type ON sys_operation_log(operation_type);
CREATE INDEX idx_operation_log_created_time ON sys_operation_log(created_time);

-- 任务执行日志表
CREATE TABLE IF NOT EXISTS data_task_execution_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(50) NOT NULL,
    task_id_name VARCHAR(100),
    task_type INT,
    component_id BIGINT,
    component_name VARCHAR(100),
    log_level VARCHAR(20),
    log_type VARCHAR(50),
    log_message TEXT,
    execution_phase VARCHAR(50),
    error_code VARCHAR(50),
    error_stack TEXT,
    execution_time BIGINT,
    created_by BIGINT,
    is_del INT DEFAULT 0,
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_task_execution_log_task_id ON data_task_execution_log(task_id);
CREATE INDEX idx_task_execution_log_task_type ON data_task_execution_log(task_type);
CREATE INDEX idx_task_execution_log_log_level ON data_task_execution_log(log_level);
CREATE INDEX idx_task_execution_log_created_time ON data_task_execution_log(created_time);
