-- 初始化系统用户表
INSERT INTO sys_user (user_id, user_account, user_password, user_name, nick_name, user_email, user_phone, head_portrait, gender, user_state, register_type, is_del, c_time, u_time) VALUES
(1, 'admin', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '管理员', '管理员', 'admin@primihub.com', '13800138000', '', 0, 0, 1, 0, NOW(), NOW());

-- 初始化系统角色
INSERT INTO sys_role (role_id, role_name, role_code, role_desc, is_del, c_time, u_time) VALUES
(1, '超级管理员', 'SUPER_ADMIN', '拥有所有权限', 0, NOW(), NOW()),
(2, '普通用户', 'USER', '普通用户权限', 0, NOW(), NOW());

-- 分配角色给管理员
INSERT INTO sys_user_role (id, user_id, role_id, is_del, c_time, u_time) VALUES
(1, 1, 1, 0, NOW(), NOW());

-- 初始化机构信息
INSERT INTO sys_organ (organ_id, organ_name, gateway_address, public_key, private_key, pin_code, organ_status, is_del, c_time, u_time) VALUES
('organ1', '默认机构', 'http://localhost:8090', 'public_key_1', 'private_key_1', '123456', 1, 0, NOW(), NOW());

-- 初始化权限节点
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, auth_url, p_auth_id, auth_index, is_show, is_del, c_time, u_time) VALUES
(1, '系统管理', 'SYS_MANAGE', 1, '', 0, 1, 1, 0, NOW(), NOW()),
(2, '用户管理', 'USER_MANAGE', 2, '/user/**', 1, 1, 1, 0, NOW(), NOW()),
(3, '角色管理', 'ROLE_MANAGE', 2, '/role/**', 1, 2, 1, 0, NOW(), NOW()),
(4, '权限管理', 'AUTH_MANAGE', 2, '/auth/**', 1, 3, 1, 0, NOW(), NOW());

-- 分配权限给超级管理员角色
INSERT INTO sys_role_auth (id, role_id, auth_id, is_del, c_time, u_time) VALUES
(1, 1, 1, 0, NOW(), NOW()),
(2, 1, 2, 0, NOW(), NOW()),
(3, 1, 3, 0, NOW(), NOW()),
(4, 1, 4, 0, NOW(), NOW());

-- 初始化项目表
INSERT INTO data_project (project_id, project_name, project_desc, server_address, server_port, server_use_ssl, server_ca_path, server_cert_path, server_key_path, is_del, create_date, update_date) VALUES
(1, '默认项目', '系统默认项目', 'localhost', 50050, 0, '', '', '', 0, NOW(), NOW());

-- 初始化资源表
INSERT INTO data_resource (resource_id, resource_name, resource_desc, resource_type, resource_source, resource_auth_type, fusions, fusions_map, resource_rows_count, resource_column_count, resource_column_name_list, resource_column_type_list, resource_state, is_del, create_date, update_date, user_id, organ_id) VALUES
(1, '示例数据集', '用于演示的数据集', 1, 1, 1, '[]', '{}', 1000, 10, '["id","name","age","gender","income","education","city","job","credit_score","loan_amount"]', '["INTEGER","STRING","INTEGER","STRING","DOUBLE","STRING","STRING","STRING","INTEGER","DOUBLE"]', 0, 0, NOW(), NOW(), 1, 'organ1');