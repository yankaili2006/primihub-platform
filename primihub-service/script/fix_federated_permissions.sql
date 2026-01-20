-- 修复联邦学习、联邦分析、联邦统计的权限配置
-- 确保这些菜单是项目管理(auth_id=1001)下的二级菜单
-- 需要在数据库中执行：privacy

-- ==================== 1. 更新联邦学习菜单 ====================
UPDATE sys_auth SET
    auth_type = 2,
    p_auth_id = 1001,
    r_auth_id = 1001,
    full_path = CONCAT('1001,', auth_id),
    auth_depth = 1
WHERE auth_code = 'ProjectFederatedLearning' AND is_del = 0;

-- ==================== 2. 更新联邦分析菜单 ====================
UPDATE sys_auth SET
    auth_type = 2,
    p_auth_id = 1001,
    r_auth_id = 1001,
    full_path = CONCAT('1001,', auth_id),
    auth_depth = 1
WHERE auth_code = 'ProjectFederatedAnalysis' AND is_del = 0;

-- ==================== 3. 更新联邦统计菜单 ====================
UPDATE sys_auth SET
    auth_type = 2,
    p_auth_id = 1001,
    r_auth_id = 1001,
    full_path = CONCAT('1001,', auth_id),
    auth_depth = 1
WHERE auth_code = 'ProjectFederatedStatistics' AND is_del = 0;

-- ==================== 4. 为所有角色分配联邦菜单权限 ====================
-- 首先删除可能存在的重复权限记录
DELETE FROM sys_ra WHERE auth_id IN (
    SELECT auth_id FROM sys_auth
    WHERE auth_code IN ('ProjectFederatedLearning', 'ProjectFederatedAnalysis', 'ProjectFederatedStatistics')
    AND is_del = 0
);

-- 为所有拥有项目管理权限的角色分配联邦菜单权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT DISTINCT sr.role_id, sa.auth_id, 0
FROM sys_ra sr
CROSS JOIN sys_auth sa
WHERE sr.auth_id = 1001  -- 拥有项目管理权限的角色
AND sr.is_del = 0
AND sa.auth_code IN ('ProjectFederatedLearning', 'ProjectFederatedAnalysis', 'ProjectFederatedStatistics')
AND sa.is_del = 0;

-- ==================== 5. 验证结果 ====================
SELECT auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_depth
FROM sys_auth
WHERE auth_code IN ('ProjectFederatedLearning', 'ProjectFederatedAnalysis', 'ProjectFederatedStatistics')
AND is_del = 0;

-- 查看权限分配情况
SELECT sr.role_id, r.role_name, sa.auth_name, sa.auth_code
FROM sys_ra sr
JOIN sys_auth sa ON sr.auth_id = sa.auth_id
JOIN sys_role r ON sr.role_id = r.role_id
WHERE sa.auth_code IN ('ProjectFederatedLearning', 'ProjectFederatedAnalysis', 'ProjectFederatedStatistics')
AND sr.is_del = 0 AND sa.is_del = 0;
