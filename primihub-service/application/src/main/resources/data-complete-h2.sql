-- H2数据库完整测试数据初始化
-- 基于原始MySQL数据转换，使用小写表名

-- 插入系统用户 (密码: admin)
INSERT INTO sys_user (user_id, user_account, user_password, user_name, role_id_list, is_forbid, is_editable, is_del, register_type) VALUES
(1, 'admin', 'a0f34ffac5a82245e4fca2e21f358a42', '管理员', '1', 0, 1, 0, 1);

-- 插入系统角色
INSERT INTO sys_role (role_id, role_name, is_editable, is_del) VALUES
(1, '超级管理员', 0, 0),
(1000, '业务权限', 1, 0);

-- 插入系统权限 (包含完整的菜单权限)
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1001, '项目管理', 'Project', 1, 0, 1001, '1001', '', 'own', 1, 0, 1, 1, 0),
(1002, '项目列表', 'ProjectList', 2, 1001, 1001, '1001,1002', '/project/getProjectList', 'own', 1, 1, 1, 1, 0),
(1003, '项目详情', 'ProjectDetail', 2, 1001, 1001, '1001,1003', '/project/getProjectDetails', 'own', 2, 1, 1, 1, 0),
(1004, '创建项目', 'ProjectCreate', 2, 1001, 1001, '1001,1004', '/project/create', 'own', 3, 1, 1, 1, 0),
(1005, '创建模型', 'ModelCreate', 2, 1001, 1001, '1001,1005', '/model/create', 'own', 4, 1, 1, 1, 0),
(1006, '模型任务详情', 'ModelTaskDetail', 2, 1001, 1001, '1001,1006', '/model/taskDetail', 'own', 5, 1, 1, 1, 0),
(1007, '模型管理', 'Model', 1, 0, 1007, '1007', '/model/getmodellist', 'own', 2, 0, 1, 1, 0),
(1008, '模型列表', 'ModelList', 2, 1007, 1007, '1007,1008', '/model/getmodellist', 'own', 1, 1, 1, 1, 0),
(1009, '模型详情', 'ModelDetail', 2, 1007, 1007, '1007,1009', '/model/detail', 'own', 2, 1, 1, 1, 0),
(1010, '模型推理', 'ModelReasoning', 1, 0, 1010, '1010', '/reasoning/list', 'own', 3, 0, 1, 1, 0),
(1011, '推理列表', 'ModelReasoningList', 2, 1010, 1010, '1010,1011', '/reasoning/list', 'own', 1, 1, 1, 1, 0),
(1012, '推理任务', 'ModelReasoningTask', 2, 1010, 1010, '1010,1012', '/reasoning/task', 'own', 2, 1, 1, 1, 0),
(1013, '推理详情', 'ModelReasoningDetail', 2, 1010, 1010, '1010,1013', '/reasoning/detail', 'own', 3, 1, 1, 1, 0),
(1016, '匿踪查询', 'PrivateSearch', 1, 0, 1016, '1016', '/fusionResource/getResourceList', 'own', 4, 0, 1, 1, 0),
(1017, '检索列表', 'PrivateSearchList', 2, 1016, 1016, '1016,1017', '/pir/list', 'own', 1, 1, 1, 1, 0),
(1018, 'PIR任务', 'PIRTask', 2, 1016, 1016, '1016,1018', '/pir/task', 'own', 2, 1, 1, 1, 0),
(1019, '隐私求交', 'PSI', 1, 0, 1019, '1019', '', 'own', 5, 0, 1, 1, 0),
(1020, 'PSI任务', 'PSITask', 2, 1019, 1019, '1019,1020', '/psi/task', 'own', 1, 1, 1, 1, 0),
(1021, 'PSI列表', 'PSIList', 2, 1019, 1019, '1019,1021', '/psi/list', 'own', 2, 1, 1, 1, 0),
(1027, 'PIR详情', 'PIRDetail', 2, 1016, 1016, '1016,1027', '/pir/detail', 'own', 3, 1, 1, 1, 0),
(1028, 'PSI详情', 'PSIDetail', 2, 1019, 1019, '1019,1028', '/psi/detail', 'own', 3, 1, 1, 1, 0),
(1022, '资源管理', 'ResourceMenu', 1, 0, 1022, '1022', '', 'own', 6, 0, 1, 1, 0),
(1023, '资源概览', 'ResourceList', 2, 1022, 1022, '1022,1023', '/resource/getdataresourcelist', 'own', 1, 1, 1, 1, 0),
(1024, '联合资源', 'UnionList', 2, 1022, 1022, '1022,1024', '/resource/union', 'own', 2, 1, 1, 1, 0),
(1025, '可用资源', 'AvailableResources', 2, 1022, 1022, '1022,1025', '/resource/available', 'own', 3, 1, 1, 1, 0),
(1026, '衍生数据', 'DerivedDataList', 2, 1022, 1022, '1022,1026', '/resource/derived', 'own', 4, 1, 1, 1, 0),
(1029, '系统设置', 'Setting', 1, 0, 1029, '1029', '', 'own', 7, 0, 1, 1, 0),
(1034, '用户管理', 'UserManage', 2, 1029, 1029, '1029,1034', '/setting/user', 'own', 1, 1, 1, 1, 0),
(1035, '角色管理', 'RoleManage', 2, 1029, 1029, '1029,1035', '/setting/role', 'own', 2, 1, 1, 1, 0),
(1036, '节点管理', 'CenterManage', 2, 1029, 1029, '1029,1036', '/setting/center', 'own', 3, 1, 1, 1, 0),
(1030, '白名单管理', 'WhitelistManage', 1, 0, 1030, '1030', '', 'own', 8, 0, 1, 1, 0),
(1031, '白名单列表', 'WhitelistList', 2, 1030, 1030, '1030,1031', '/whitelist/findWhitelistPage', 'own', 1, 1, 1, 1, 0),
(1032, '新增白名单', 'WhitelistCreate', 3, 1030, 1030, '1030,1031,1032', '/whitelist/saveOrUpdateWhitelist', 'own', 2, 2, 1, 1, 0),
(1033, '删除白名单', 'WhitelistDelete', 3, 1030, 1030, '1030,1031,1033', '/whitelist/deleteWhitelist', 'own', 3, 2, 1, 1, 0),
(1037, '日志管理', 'Log', 1, 0, 1037, '1037', '', 'own', 9, 0, 1, 1, 0),
(1038, '日志列表', 'LogList', 2, 1037, 1037, '1037,1038', '/log/findOperationLogPage', 'own', 1, 1, 1, 1, 0);

-- 插入角色权限关联 (为超级管理员添加所有权限)
INSERT INTO sys_ra (id, role_id, auth_id, is_del) VALUES
(1, 1, 1001, 0),
(2, 1, 1002, 0),
(3, 1, 1003, 0),
(4, 1, 1004, 0),
(5, 1, 1005, 0),
(6, 1, 1006, 0),
(7, 1, 1007, 0),
(8, 1, 1008, 0),
(9, 1, 1009, 0),
(10, 1, 1010, 0),
(11, 1, 1011, 0),
(12, 1, 1012, 0),
(13, 1, 1013, 0),
(14, 1, 1016, 0),
(15, 1, 1017, 0),
(16, 1, 1018, 0),
(17, 1, 1019, 0),
(18, 1, 1020, 0),
(19, 1, 1021, 0),
(20, 1, 1022, 0),
(21, 1, 1023, 0),
(22, 1, 1024, 0),
(23, 1, 1025, 0),
(24, 1, 1026, 0),
(25, 1, 1027, 0),
(26, 1, 1028, 0),
(27, 1, 1029, 0),
(28, 1, 1034, 0),
(29, 1, 1035, 0),
(30, 1, 1036, 0),
(31, 1, 1030, 0),
(32, 1, 1031, 0),
(33, 1, 1032, 0),
(34, 1, 1033, 0),
(35, 1, 1037, 0),
(36, 1, 1038, 0);

-- 插入用户角色关联
INSERT INTO sys_ur (id, user_id, role_id, is_del) VALUES
(1, 1, 1, 0);

-- 插入系统机构
INSERT INTO sys_organ (id, organ_id, organ_name, organ_gateway, public_key, examine_state, enable, is_del) VALUES
(1, 'organ1', '默认机构', 'http://localhost:8090', 'public_key_dev', 1, 0, 0);

-- 插入测试项目
INSERT INTO data_project (project_id, project_name, project_desc, created_organ_id, created_organ_name, created_username, resource_num, provider_organ_names, status, is_del) VALUES
('proj-001', '医疗数据联合分析项目', '基于多方医疗数据的隐私计算联合分析', 'org-001', '医院A', 'admin', 3, '医院A,医院B,医院C', 1, 0),
('proj-002', '金融风控模型训练', '跨机构金融风控模型联邦学习', 'org-002', '银行X', 'admin', 2, '银行X,银行Y', 1, 0),
('proj-003', '广告效果评估', '多方数据广告效果隐私求交分析', 'org-003', '广告公司M', 'admin', 4, '广告公司M,媒体N,平台P', 0, 0);

-- 插入测试资源
INSERT INTO data_resource (resource_name, resource_desc, resource_sort_type, resource_auth_type, resource_source, resource_num, file_rows, file_columns, resource_state, organ_id, is_del) VALUES
('医疗患者数据', '医院A的患者就诊记录数据', 1, 1, 1, 10000, 10000, 15, 0, 1, 0),
('金融交易数据', '银行X的信用卡交易记录', 2, 1, 1, 50000, 50000, 20, 0, 2, 0),
('用户行为数据', '广告平台的用户点击行为数据', 3, 2, 1, 200000, 200000, 25, 0, 3, 0),
('保险理赔数据', '保险公司理赔记录', 4, 1, 1, 15000, 15000, 18, 0, 4, 0);

-- 插入测试任务
INSERT INTO data_task (task_id_name, task_name, task_desc, task_state, task_type, is_del) VALUES
('task-001', 'PSI求交任务', '医疗数据隐私求交', 1, 2, 0),
('task-002', '模型训练任务', '金融风控模型训练', 2, 1, 0),
('task-003', 'PIR查询任务', '匿踪查询用户数据', 1, 3, 0);

-- 插入PSI任务
INSERT INTO data_psi_task (psi_id, task_id, task_state, ascription_type, file_rows, is_del) VALUES
(1, 'psi-task-001', 2, 0, 5000, 0),
(2, 'psi-task-002', 1, 1, 8000, 0);

-- 插入PIR任务
INSERT INTO data_pir_task (task_id, server_address, provider_organ_name, resource_id, resource_name, is_del) VALUES
(3, 'http://localhost:8090', '广告公司M', 'res-003', '用户行为数据', 0);