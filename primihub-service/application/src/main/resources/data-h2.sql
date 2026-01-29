-- H2数据库测试数据初始化
-- 使用小写表名以匹配schema

-- 插入系统数据
-- 系统用户 (密码: admin)
INSERT INTO sys_user (user_id, user_account, user_password, user_name, role_id_list, is_forbid, is_editable, is_del, register_type) VALUES
(1, 'admin', 'a0f34ffac5a82245e4fca2e21f358a42', '管理员', '1', 0, 1, 0, 1);

-- 系统机构
INSERT INTO sys_organ (organ_id, organ_name, gateway_address, public_key, private_key, pin_code, organ_status, is_del) VALUES
('organ1', '默认机构', 'http://localhost:8090', 'public_key_dev', 'private_key_dev', '123456', 1, 0);

-- 系统角色
INSERT INTO sys_role (role_id, role_name, role_code, is_del) VALUES
(1, '管理员', 'admin', 0),
(2, '普通用户', 'user', 0);

-- 系统权限
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
-- 主菜单权限
(1, '隐匿查询', 'PrivateSearch', 1, 0, 1, '1', '', 'own', 1, 0, 1, 1, 0),
(2, '隐私求交', 'PSI', 1, 0, 2, '2', '', 'own', 2, 0, 1, 1, 0),
(3, '项目管理', 'Project', 1, 0, 3, '3', '', 'own', 3, 0, 1, 1, 0),
(4, '模型管理', 'Model', 1, 0, 4, '4', '', 'own', 4, 0, 1, 1, 0),
(5, '服务管理', 'ModelReasoning', 1, 0, 5, '5', '', 'own', 5, 0, 1, 1, 0),
(6, '资源管理', 'ResourceMenu', 1, 0, 6, '6', '', 'own', 6, 0, 1, 1, 0),
(7, '系统设置', 'Setting', 1, 0, 7, '7', '', 'own', 7, 0, 1, 1, 0),
(8, '日志管理', 'Log', 1, 0, 8, '8', '', 'own', 8, 0, 1, 1, 0),
-- 系统设置子菜单权限
(91, '用户管理', 'UserManage', 2, 7, 7, '7,91', '/setting/user', 'own', 1, 1, 1, 1, 0),
(92, '角色管理', 'RoleManage', 2, 7, 7, '7,92', '/setting/role', 'own', 2, 1, 1, 1, 0),
(93, '节点管理', 'CenterManage', 2, 7, 7, '7,93', '/setting/center', 'own', 3, 1, 1, 1, 0),
-- 白名单管理权限（调整为一级菜单）
(101, '白名单管理', 'WhitelistManage', 1, 0, 101, '101', '', 'own', 9, 0, 1, 1, 0),
(102, '白名单列表', 'WhitelistList', 2, 101, 101, '101,102', '/whitelist/findWhitelistPage', 'own', 1, 1, 1, 1, 0),
(103, '新增白名单', 'WhitelistAdd', 3, 101, 101, '101,102,103', '/whitelist/saveOrUpdateWhitelist', 'own', 2, 2, 1, 1, 0),
(104, '编辑白名单', 'WhitelistEdit', 3, 101, 101, '101,102,104', '/whitelist/saveOrUpdateWhitelist', 'own', 3, 2, 1, 1, 0),
(105, '删除白名单', 'WhitelistDelete', 3, 101, 101, '101,102,105', '/whitelist/deleteWhitelist', 'own', 4, 2, 1, 1, 0),
-- 日志管理子权限
(111, '日志列表', 'LogList', 2, 8, 8, '8,111', '/log/findOperationLogPage', 'own', 1, 1, 1, 1, 0);

-- 角色权限关联
INSERT INTO sys_ra (ra_id, role_id, auth_id, is_del) VALUES
-- 管理员拥有所有主菜单权限
(1, 1, 1, 0),  -- 隐匿查询
(2, 1, 2, 0),  -- 隐私求交
(3, 1, 3, 0),  -- 项目管理
(4, 1, 4, 0),  -- 模型管理
(5, 1, 5, 0),  -- 服务管理
(6, 1, 6, 0),  -- 资源管理
(7, 1, 7, 0),  -- 系统设置
(8, 1, 8, 0),  -- 日志管理
-- 系统设置子菜单权限
(14, 1, 91, 0), -- 用户管理
(15, 1, 92, 0), -- 角色管理
(16, 1, 93, 0), -- 节点管理
-- 白名单管理权限
(9, 1, 101, 0),
(10, 1, 102, 0),
(11, 1, 103, 0),
(12, 1, 104, 0),
(13, 1, 105, 0),
-- 日志管理子权限
(17, 1, 111, 0);

-- 用户角色关联
INSERT INTO sys_ur (ur_id, user_id, role_id, is_del) VALUES
(1, 1, 1, 0);

-- 用户白名单测试数据
INSERT INTO sys_user_whitelist (whitelist_id, whitelist_type, whitelist_value, whitelist_desc, status, is_del, creator_id, creator_name) VALUES
(1, 1, 'admin@primihub.com', '管理员邮箱', 1, 0, 1, '管理员'),
(2, 1, 'test@example.com', '测试用户邮箱', 1, 0, 1, '管理员'),
(3, 2, '13800138000', '测试手机号', 1, 0, 1, '管理员'),
(4, 1, 'disabled@test.com', '已禁用的邮箱', 0, 0, 1, '管理员');

-- 插入测试项目
INSERT INTO data_project (project_id, project_name, project_desc, created_organ_id, created_organ_name, created_username, resource_num, provider_organ_names, status, is_del) VALUES
('proj-001', '医疗数据联合分析项目', '基于多方医疗数据的隐私计算联合分析', 'org-001', '医院A', 'admin', 3, '医院A,医院B,医院C', 1, 0),
('proj-002', '金融风控模型训练', '跨机构金融风控模型联邦学习', 'org-002', '银行X', 'admin', 2, '银行X,银行Y', 1, 0),
('proj-003', '广告效果评估', '多方数据广告效果隐私求交分析', 'org-003', '广告公司M', 'admin', 4, '广告公司M,媒体N,平台P', 0, 0);

-- 插入测试资源
INSERT INTO data_resource (resource_name, resource_desc, resource_type, resource_source, resource_auth_type, resource_rows_count, resource_column_count, resource_column_name_list, resource_column_type_list, resource_state, user_id, organ_id) VALUES
('患者就诊数据', '医院A的患者就诊记录', 1, 1, 1, 10000, 10, 'patient_id,visit_date,diagnosis,treatment,cost', 'STRING,DATE,STRING,STRING,DOUBLE', 0, 1, 'org-001'),
('信用卡交易数据', '银行X的信用卡交易记录', 1, 1, 1, 50000, 8, 'card_no,transaction_date,amount,merchant,category', 'STRING,DATE,DOUBLE,STRING,STRING', 0, 1, 'org-002'),
('用户浏览数据', '广告平台的用户浏览记录', 1, 1, 1, 200000, 6, 'user_id,page_url,view_time,device', 'STRING,STRING,TIMESTAMP,STRING', 0, 1, 'org-003');

-- 插入测试PSI任务
INSERT INTO data_psi_task (task_id, task_name, task_desc, task_state, resource_id, resource_name, organ_id, organ_name) VALUES
('psi-001', '患者数据求交', '医院A和医院B患者数据隐私求交', 2, 'res-001', '患者就诊数据', 'org-001', '医院A'),
('psi-002', '用户匹配分析', '广告平台用户数据匹配', 1, 'res-003', '用户浏览数据', 'org-003', '广告公司M');

-- 插入测试PIR任务
INSERT INTO data_pir_task (task_id, task_name, task_desc, task_state, resource_id, resource_name, organ_id, organ_name) VALUES
('pir-001', '医疗记录查询', '隐私保护的医疗记录查询', 2, 'res-001', '患者就诊数据', 'org-001', '医院A'),
('pir-002', '交易记录检索', '匿踪信用卡交易查询', 1, 'res-002', '信用卡交易数据', 'org-002', '银行X');

-- 插入测试PSI主表数据
INSERT INTO data_psi (result_name, other_organ_id, tag) VALUES
('医院患者匹配结果', 'org-002', '医疗数据'),
('广告用户匹配结果', 'org-003', '用户数据');

-- 插入测试任务数据
INSERT INTO data_task (task_id_name, task_name, task_start_time, task_end_time) VALUES
('task-001', 'PSI任务1', '2024-01-01 10:00:00', '2024-01-01 11:00:00'),
('task-002', 'PSI任务2', '2024-01-02 14:00:00', '2024-01-02 15:00:00');

-- 插入测试项目机构关联数据
INSERT INTO data_project_organ (po_id, project_id, organ_id, initiate_organ_id, participation_identity, audit_status) VALUES
('po-001', 'proj-001', 'org-001', 'org-001', 1, 1),
('po-002', 'proj-001', 'org-002', 'org-001', 2, 1),
('po-003', 'proj-001', 'org-003', 'org-001', 2, 1),
('po-004', 'proj-002', 'org-002', 'org-002', 1, 1),
('po-005', 'proj-002', 'org-003', 'org-002', 2, 1);

-- 插入测试项目资源关联数据
INSERT INTO data_project_resource (pr_id, project_id, initiate_organ_id, organ_id, participation_identity, resource_id, audit_status) VALUES
('pr-001', 'proj-001', 'org-001', 'org-001', 1, 'res-001', 1),
('pr-002', 'proj-001', 'org-001', 'org-002', 2, 'res-002', 1),
('pr-003', 'proj-001', 'org-001', 'org-003', 2, 'res-003', 1),
('pr-004', 'proj-002', 'org-002', 'org-002', 1, 'res-002', 1),
('pr-005', 'proj-002', 'org-002', 'org-003', 2, 'res-003', 1);

-- 插入测试PSI主表数据
INSERT INTO DATA_PSI (result_name, other_organ_id, tag) VALUES
('医院患者匹配结果', 'org-002', '医疗数据'),
('广告用户匹配结果', 'org-003', '用户数据');

-- 插入测试任务数据
INSERT INTO DATA_TASK (task_id_name, task_name, task_start_time, task_end_time) VALUES
('task-001', 'PSI任务1', '2024-01-01 10:00:00', '2024-01-01 11:00:00'),
('task-002', 'PSI任务2', '2024-01-02 14:00:00', '2024-01-02 15:00:00');