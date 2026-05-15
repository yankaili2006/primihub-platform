package com.primihub.application.controller;

import com.primihub.application.controller.data.ProjectController;
import com.primihub.application.controller.data.ResourceController;
import com.primihub.application.controller.sys.*;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.sys.param.*;
import com.primihub.biz.entity.sys.po.*;
import com.primihub.biz.entity.sys.vo.*;
import com.primihub.biz.service.data.DataProjectService;
import com.primihub.biz.service.data.DataResourceService;
import com.primihub.biz.service.sys.*;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.*;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class BaseModuleControllersTest {

    // ==================== UserController ====================
    @Mock
    private SysUserService sysUserService;
    @InjectMocks
    private UserController userController;

    // ==================== WhitelistController ====================
    @Mock
    private WhitelistService whitelistService;
    @InjectMocks
    private WhitelistController whitelistController;

    // ==================== TenantController ====================
    @Mock
    private TenantService tenantService;
    @InjectMocks
    private TenantController tenantController;

    // ==================== EvidenceController ====================
    @Mock
    private EvidenceService evidenceService;
    @InjectMocks
    private EvidenceController evidenceController;

    // ==================== LogManagementController ====================
    @Mock
    private LogManagementService logManagementService;
    @InjectMocks
    private LogManagementController logManagementController;

    // ==================== RoleController ====================
    @Mock
    private SysRoleService sysRoleService;
    @InjectMocks
    private RoleController roleController;

    // ==================== MonitorController ====================
    @Mock
    private MonitorService monitorService;
    @InjectMocks
    private MonitorController monitorController;

    // ==================== ProjectController ====================
    @Mock
    private DataProjectService dataProjectService;
    @InjectMocks
    private ProjectController projectController;

    // ==================== ResourceController ====================
    @Mock
    private DataResourceService dataResourceService;
    @InjectMocks
    private ResourceController resourceController;

    // ==================== ApiManageController ====================
    @Mock
    private ApiManageService apiManageService;
    @InjectMocks
    private ApiManageController apiManageController;

    // ==================== SystemConfigController ====================
    @Mock
    private SysConfigService sysConfigService;
    @InjectMocks
    private SystemConfigController systemConfigController;

    private static final Long USER_ID = 1L;
    private static final Long VALID_ID = 100L;
    private BaseResultEntity successResult;

    @Before
    public void setUp() {
        successResult = BaseResultEntity.success();
    }

    // ================================================================
    //  UserController (需求#1-6)
    // ================================================================

    @Test
    public void userController_saveOrUpdateUser_success() {
        SaveOrUpdateUserParam param = new SaveOrUpdateUserParam();
        param.setUserId(VALID_ID);
        when(sysUserService.saveOrUpdateUser(param)).thenReturn(successResult);
        BaseResultEntity result = userController.saveOrUpdateUser(param);
        assertSame(successResult, result);
        verify(sysUserService).saveOrUpdateUser(param);
    }

    @Test
    public void userController_saveOrUpdateUser_newUser_setsRegisterType() {
        SaveOrUpdateUserParam param = new SaveOrUpdateUserParam();
        param.setUserId(null);
        when(sysUserService.saveOrUpdateUser(param)).thenReturn(successResult);
        userController.saveOrUpdateUser(param);
        assertEquals(Integer.valueOf(1), param.getRegisterType());
    }

    @Test
    public void userController_deleteSysUser_success() {
        when(sysUserService.deleteSysUser(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = userController.deleteSysUser(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void userController_deleteSysUser_nullId_returnsLackOfParam() {
        BaseResultEntity result = userController.deleteSysUser(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void userController_freezeUser_success() {
        when(sysUserService.freezeUser(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = userController.freezeUser(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void userController_freezeUser_invalidId_returnsLackOfParam() {
        BaseResultEntity result = userController.freezeUser(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(sysUserService, never()).freezeUser(anyLong());
    }

    @Test
    public void userController_unfreezeUser_success() {
        when(sysUserService.unfreezeUser(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = userController.unfreezeUser(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void userController_batchFreezeUser_success() {
        List<Long> ids = Arrays.asList(1L, 2L);
        when(sysUserService.batchFreezeUser(ids)).thenReturn(successResult);
        BaseResultEntity result = userController.batchFreezeUser(ids);
        assertSame(successResult, result);
    }

    @Test
    public void userController_batchFreezeUser_emptyList_returnsLackOfParam() {
        BaseResultEntity result = userController.batchFreezeUser(new ArrayList<>());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(sysUserService, never()).batchFreezeUser(anyList());
    }

    @Test
    public void userController_batchUnfreezeUser_success() {
        List<Long> ids = Arrays.asList(1L, 2L);
        when(sysUserService.batchUnfreezeUser(ids)).thenReturn(successResult);
        BaseResultEntity result = userController.batchUnfreezeUser(ids);
        assertSame(successResult, result);
    }

    @Test
    public void userController_findUserPage_success() {
        FindUserPageParam param = new FindUserPageParam();
        when(sysUserService.findUserPage(param, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = userController.findUserPage(param, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void userController_findUserByAccount_success() {
        when(sysUserService.findUserByAccount("admin")).thenReturn(successResult);
        BaseResultEntity result = userController.findUserByAccount("admin");
        assertSame(successResult, result);
    }

    @Test
    public void userController_findUserByAccount_empty_returnsLackOfParam() {
        BaseResultEntity result = userController.findUserByAccount("");
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void userController_logout_success() {
        when(sysUserService.logout("token", USER_ID)).thenReturn(successResult);
        BaseResultEntity result = userController.logout("token", USER_ID);
        assertSame(successResult, result);
    }

    @Test
    public void userController_relieveUserAccount_success() {
        when(sysUserService.relieveUserAccount(USER_ID)).thenReturn(successResult);
        BaseResultEntity result = userController.relieveUserAccount(USER_ID);
        assertSame(successResult, result);
    }

    @Test
    public void userController_relieveUserAccount_invalidId_returnsLackOfParam() {
        BaseResultEntity result = userController.relieveUserAccount(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void userController_initPassword_success() {
        when(sysUserService.initPassword(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = userController.initPassword(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void userController_initPassword_nullId_returnsLackOfParam() {
        BaseResultEntity result = userController.initPassword(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void userController_updatePassword_success() {
        when(sysUserService.updatePassword(VALID_ID, "newPass", "key")).thenReturn(successResult);
        BaseResultEntity result = userController.updatePassword(VALID_ID, "newPass", "key");
        assertSame(successResult, result);
    }

    @Test
    public void userController_updatePassword_missingPassword_returnsLackOfParam() {
        BaseResultEntity result = userController.updatePassword(VALID_ID, "", "key");
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(sysUserService, never()).updatePassword(anyLong(), anyString(), anyString());
    }

    // ================================================================
    //  WhitelistController (需求#7-11)
    // ================================================================

    @Test
    public void whitelistController_addWhitelist_success() {
        Whitelist wl = new Whitelist();
        when(whitelistService.addWhitelist(wl)).thenReturn(successResult);
        BaseResultEntity result = whitelistController.addWhitelist(wl);
        assertSame(successResult, result);
    }

    @Test
    public void whitelistController_addWhitelist_null_returnsLackOfParam() {
        BaseResultEntity result = whitelistController.addWhitelist(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void whitelistController_deleteWhitelist_success() {
        when(whitelistService.deleteWhitelist(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = whitelistController.deleteWhitelist(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void whitelistController_deleteWhitelist_null_returnsLackOfParam() {
        BaseResultEntity result = whitelistController.deleteWhitelist(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void whitelistController_findWhitelistPage_success() {
        when(whitelistService.findWhitelistPage("kw", "IP", 1, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = whitelistController.findWhitelistPage("kw", "IP", 1, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void whitelistController_saveWhitelistConfig_success() {
        List<WhitelistConfig> configs = new ArrayList<>();
        configs.add(new WhitelistConfig());
        when(whitelistService.saveWhitelistConfig(configs)).thenReturn(successResult);
        BaseResultEntity result = whitelistController.saveWhitelistConfig(configs);
        assertSame(successResult, result);
    }

    @Test
    public void whitelistController_saveWhitelistConfig_emptyList_returnsLackOfParam() {
        BaseResultEntity result = whitelistController.saveWhitelistConfig(new ArrayList<>());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void whitelistController_findWhitelistAccessLogPage_success() {
        when(whitelistService.findWhitelistAccessLogPage("ip", "url", "deny", null, null, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = whitelistController.findWhitelistAccessLogPage("ip", "url", "deny", null, null, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void whitelistController_cleanExpiredLogs_success() {
        when(whitelistService.cleanExpiredLogs(30)).thenReturn(successResult);
        BaseResultEntity result = whitelistController.cleanExpiredLogs(30);
        assertSame(successResult, result);
    }

    @Test
    public void whitelistController_cleanExpiredLogs_invalidDays_returnsLackOfParam() {
        BaseResultEntity result = whitelistController.cleanExpiredLogs(0);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void whitelistController_updateWhitelist_missingId_returnsLackOfParam() {
        Whitelist wl = new Whitelist();
        BaseResultEntity result = whitelistController.updateWhitelist(wl);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    // ================================================================
    //  TenantController (需求#12-19)
    // ================================================================

    @Test
    public void tenantController_addTenant_success() {
        Tenant tenant = new Tenant();
        when(tenantService.addTenant(tenant)).thenReturn(successResult);
        BaseResultEntity result = tenantController.addTenant(tenant);
        assertSame(successResult, result);
    }

    @Test
    public void tenantController_addTenant_null_returnsLackOfParam() {
        BaseResultEntity result = tenantController.addTenant(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void tenantController_deleteTenant_success() {
        when(tenantService.deleteTenant(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = tenantController.deleteTenant(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void tenantController_deleteTenant_null_returnsLackOfParam() {
        BaseResultEntity result = tenantController.deleteTenant(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void tenantController_freezeTenant_success() {
        when(tenantService.freezeTenant(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = tenantController.freezeTenant(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void tenantController_freezeTenant_null_returnsLackOfParam() {
        BaseResultEntity result = tenantController.freezeTenant(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void tenantController_unfreezeTenant_success() {
        when(tenantService.unfreezeTenant(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = tenantController.unfreezeTenant(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void tenantController_findTenantPage_success() {
        when(tenantService.findTenantPage("kw", 1, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = tenantController.findTenantPage("kw", 1, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void tenantController_getTenantStatistics_success() {
        when(tenantService.getTenantStatistics()).thenReturn(successResult);
        BaseResultEntity result = tenantController.getTenantStatistics();
        assertSame(successResult, result);
    }

    @Test
    public void tenantController_updateTenant_missingId_returnsLackOfParam() {
        Tenant tenant = new Tenant();
        BaseResultEntity result = tenantController.updateTenant(tenant);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void tenantController_getAvailableResources_success() {
        when(tenantService.getAvailableResources(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = tenantController.getAvailableResources(VALID_ID);
        assertSame(successResult, result);
    }

    // ================================================================
    //  EvidenceController (需求#20-24)
    // ================================================================

    @Test
    public void evidenceController_findEvidencePage_success() {
        when(evidenceService.findEvidencePage("kw", "done", null, null, null, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = evidenceController.findEvidencePage("kw", "done", null, null, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_createEvidence_success() {
        Map<String, Object> data = new HashMap<>();
        data.put("hash", "abc123");
        when(evidenceService.createEvidence(data)).thenReturn(successResult);
        BaseResultEntity result = evidenceController.createEvidence(data);
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_verifyEvidence_success() {
        Map<String, Object> data = new HashMap<>();
        data.put("id", VALID_ID);
        when(evidenceService.verifyEvidence(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = evidenceController.verifyEvidence(data);
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_getEvidenceConfig_success() {
        when(evidenceService.getEvidenceConfig()).thenReturn(successResult);
        BaseResultEntity result = evidenceController.getEvidenceConfig();
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_saveEvidenceConfig_success() {
        Map<String, Object> data = new HashMap<>();
        when(evidenceService.saveEvidenceConfig(data)).thenReturn(successResult);
        BaseResultEntity result = evidenceController.saveEvidenceConfig(data);
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_exportEvidence_success() {
        Map<String, Object> data = new HashMap<>();
        when(evidenceService.exportEvidence(data)).thenReturn(successResult);
        BaseResultEntity result = evidenceController.exportEvidence(data);
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_applyTimestamp_success() {
        Map<String, Object> data = new HashMap<>();
        when(evidenceService.applyTimestamp(data)).thenReturn(successResult);
        BaseResultEntity result = evidenceController.applyTimestamp(data);
        assertSame(successResult, result);
    }

    @Test
    public void evidenceController_getChainList_returnsStaticData() {
        BaseResultEntity result = evidenceController.getChainList();
        assertEquals(Integer.valueOf(0), result.getCode());
        assertNotNull(result.getResult());
    }

    // ================================================================
    //  LogManagementController (需求#25-31)
    // ================================================================

    @Test
    public void logController_addOperationLogDefinition_success() {
        OperationLogDefinition def = new OperationLogDefinition();
        when(logManagementService.addOperationLogDefinition(def)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.addOperationLogDefinition(def);
        assertSame(successResult, result);
    }

    @Test
    public void logController_addOperationLogDefinition_null_returnsLackOfParam() {
        BaseResultEntity result = logManagementController.addOperationLogDefinition(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void logController_addScheduleLogDefinition_success() {
        ScheduleLogDefinition def = new ScheduleLogDefinition();
        when(logManagementService.addScheduleLogDefinition(def)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.addScheduleLogDefinition(def);
        assertSame(successResult, result);
    }

    @Test
    public void logController_addComputeLogDefinition_success() {
        ComputeLogDefinition def = new ComputeLogDefinition();
        when(logManagementService.addComputeLogDefinition(def)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.addComputeLogDefinition(def);
        assertSame(successResult, result);
    }

    @Test
    public void logController_deleteOperationLogDefinition_success() {
        when(logManagementService.deleteOperationLogDefinition(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.deleteOperationLogDefinition(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void logController_deleteOperationLogDefinition_null_returnsLackOfParam() {
        BaseResultEntity result = logManagementController.deleteOperationLogDefinition(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void logController_updateOperationLogDefinitionStatus_success() {
        when(logManagementService.updateOperationLogDefinitionStatus(VALID_ID, 1)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.updateOperationLogDefinitionStatus(VALID_ID, 1);
        assertSame(successResult, result);
    }

    @Test
    public void logController_updateOperationLogDefinitionStatus_nullId_returnsLackOfParam() {
        BaseResultEntity result = logManagementController.updateOperationLogDefinitionStatus(null, 1);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void logController_findOperationLogPage_success() {
        when(logManagementService.findOperationLogPage(any(), any(), any(), any(), any(), any(), any(), any(), anyInt(), anyInt())).thenReturn(successResult);
        BaseResultEntity result = logManagementController.findOperationLogPage("L001", null, null, null, null, null, null, null, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void logController_findScheduleLogDefinitionPage_success() {
        when(logManagementService.findScheduleLogDefinitionPage("kw", "type", null, null, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.findScheduleLogDefinitionPage("kw", "type", null, null, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void logController_findComputeLogDefinitionPage_success() {
        when(logManagementService.findComputeLogDefinitionPage("kw", "type", null, null, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = logManagementController.findComputeLogDefinitionPage("kw", "type", null, null, 1, 10);
        assertSame(successResult, result);
    }

    // ================================================================
    //  RoleController (需求#32-37)
    // ================================================================

    @Test
    public void roleController_saveOrUpdateRole_success() {
        SaveOrUpdateRoleParam param = new SaveOrUpdateRoleParam();
        param.setRoleId(VALID_ID);
        param.setRoleName("admin");
        when(sysRoleService.saveOrUpdateRole(param)).thenReturn(successResult);
        BaseResultEntity result = roleController.saveOrUpdateRole(param);
        assertSame(successResult, result);
    }

    @Test
    public void roleController_saveOrUpdateRole_newRole_noIdIsOk() {
        SaveOrUpdateRoleParam param = new SaveOrUpdateRoleParam();
        param.setRoleName("new-role");
        when(sysRoleService.saveOrUpdateRole(param)).thenReturn(successResult);
        BaseResultEntity result = roleController.saveOrUpdateRole(param);
        assertSame(successResult, result);
    }

    @Test
    public void roleController_deleteSysRole_success() {
        when(sysRoleService.deleteSysRole(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = roleController.deleteSysRole(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void roleController_deleteSysRole_null_returnsLackOfParam() {
        BaseResultEntity result = roleController.deleteSysRole(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void roleController_getRoleAuthTree_success() {
        when(sysRoleService.getRoleAuthTree(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = roleController.getRoleAuthTree(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void roleController_getRoleAuthTree_null_returnsLackOfParam() {
        BaseResultEntity result = roleController.getRoleAuthTree(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void roleController_findRolePage_success() {
        when(sysRoleService.findRolePage("admin", 1, 10)).thenReturn(successResult);
        BaseResultEntity result = roleController.findRolePage("admin", 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void roleController_findRolePage_nullName_success() {
        when(sysRoleService.findRolePage(null, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = roleController.findRolePage(null, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void roleController_saveOrUpdateRole_invalidRoleId_returnsParamInvalidation() {
        SaveOrUpdateRoleParam param = new SaveOrUpdateRoleParam();
        param.setRoleId(0L);
        BaseResultEntity result = roleController.saveOrUpdateRole(param);
        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), result.getCode());
        verify(sysRoleService, never()).saveOrUpdateRole(any());
    }

    // ================================================================
    //  MonitorController (需求#38-43)
    // ================================================================

    @Test
    public void monitorController_getSystemMonitor_success() {
        when(monitorService.getSystemMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getSystemMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getCpuMonitor_success() {
        when(monitorService.getCpuMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getCpuMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getMemoryMonitor_success() {
        when(monitorService.getMemoryMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getMemoryMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getDiskMonitor_success() {
        when(monitorService.getDiskMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getDiskMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getDatabaseMonitor_success() {
        when(monitorService.getDatabaseMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getDatabaseMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getJvmMonitor_success() {
        when(monitorService.getJvmMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getJvmMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getRedisMonitor_success() {
        when(monitorService.getRedisMonitor()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getRedisMonitor();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getMonitorHistory_success() {
        when(monitorService.getMonitorHistory("cpu", null, null)).thenReturn(successResult);
        BaseResultEntity result = monitorController.getMonitorHistory("cpu", null, null);
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_getAlertConfig_success() {
        when(monitorService.getAlertConfig()).thenReturn(successResult);
        BaseResultEntity result = monitorController.getAlertConfig();
        assertSame(successResult, result);
    }

    @Test
    public void monitorController_saveAlertConfig_success() {
        Map<String, Object> data = new HashMap<>();
        when(monitorService.saveAlertConfig(data)).thenReturn(successResult);
        BaseResultEntity result = monitorController.saveAlertConfig(data);
        assertSame(successResult, result);
    }

    // ================================================================
    //  ProjectController (需求#44-51)
    // ================================================================

    @Test
    public void projectController_saveOrUpdateProject_success() {
        DataProjectReq req = new DataProjectReq();
        req.setId(VALID_ID);
        when(dataProjectService.saveOrUpdateProject(req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = projectController.saveOrUpdateProject(req, USER_ID);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_saveOrUpdateProject_newProject_missingName_returnsLackOfParam() {
        DataProjectReq req = new DataProjectReq();
        BaseResultEntity result = projectController.saveOrUpdateProject(req, USER_ID);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataProjectService, never()).saveOrUpdateProject(any(), anyLong());
    }

    @Test
    public void projectController_getProjectList_success() {
        DataProjectQueryReq req = new DataProjectQueryReq();
        when(dataProjectService.getProjectList(req)).thenReturn(successResult);
        BaseResultEntity result = projectController.getProjectList(req);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_getProjectDetails_success() {
        when(dataProjectService.getProjectDetails(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = projectController.getProjectDetails(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_getProjectDetails_null_returnsLackOfParam() {
        BaseResultEntity result = projectController.getProjectDetails(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void projectController_approval_success() {
        DataProjectApprovalReq req = new DataProjectApprovalReq();
        req.setId(VALID_ID);
        req.setType(1);
        req.setAuditStatus(1);
        when(dataProjectService.approval(req)).thenReturn(successResult);
        BaseResultEntity result = projectController.approval(req);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_approval_nullFields_returnsLackOfParam() {
        DataProjectApprovalReq req = new DataProjectApprovalReq();
        BaseResultEntity result = projectController.approval(req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void projectController_closeProject_success() {
        when(dataProjectService.closeProject(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = projectController.closeProject(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_closeProject_null_returnsLackOfParam() {
        BaseResultEntity result = projectController.closeProject(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void projectController_openProject_success() {
        when(dataProjectService.openProject(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = projectController.openProject(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_removeResource_success() {
        when(dataProjectService.removeResource(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = projectController.removeResource(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void projectController_getResourceList_missingOrganId_returnsLackOfParam() {
        OrganResourceReq req = new OrganResourceReq();
        req.setModelId(1L);
        BaseResultEntity result = projectController.getResourceList(req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    // ================================================================
    //  ResourceController (需求#68-83)
    // ================================================================

    @Test
    public void resourceController_getResourceTags_success() {
        when(dataResourceService.getResourceTags()).thenReturn(successResult);
        BaseResultEntity result = resourceController.getResourceTags();
        assertSame(successResult, result);
    }

    @Test
    public void resourceController_getDataResourceList_success() {
        DataResourceReq req = new DataResourceReq();
        when(dataResourceService.getDataResourceList(req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = resourceController.getDataResourceList(USER_ID, req);
        assertSame(successResult, result);
    }

    @Test
    public void resourceController_saveDataResource_newResource_success() {
        DataResourceReq req = new DataResourceReq();
        req.setResourceName("test-res");
        req.setResourceDesc("desc");
        req.setResourceAuthType(1);
        req.setResourceSource(1);
        req.setFileId(10L);
        req.setTags(Arrays.asList("tag1"));
        DataResourceFieldReq field = new DataResourceFieldReq();
        field.setFieldName("col1");
        req.setFieldList(Arrays.asList(field));
        when(dataResourceService.saveDataResource(req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = resourceController.saveDataResource(req, USER_ID);
        assertSame(successResult, result);
    }

    @Test
    public void resourceController_saveDataResource_missingName_returnsLackOfParam() {
        DataResourceReq req = new DataResourceReq();
        BaseResultEntity result = resourceController.saveDataResource(req, USER_ID);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void resourceController_deleteDataResource_success() {
        when(dataResourceService.deleteDataResource(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = resourceController.deleteDataResource(VALID_ID);
        assertSame(successResult, result);
    }

    @Test
    public void resourceController_deleteDataResource_null_returnsLackOfParam() {
        BaseResultEntity result = resourceController.deleteDataResource(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void resourceController_resourceStatusChange_success() {
        when(dataResourceService.resourceStatusChange(VALID_ID, 1)).thenReturn(successResult);
        BaseResultEntity result = resourceController.resourceStatusChange(VALID_ID, 1);
        assertSame(successResult, result);
    }

    @Test
    public void resourceController_resourceStatusChange_nullResourceId_returnsLackOfParam() {
        BaseResultEntity result = resourceController.resourceStatusChange(0L, 1);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void resourceController_resourceStatusChange_nullState_returnsLackOfParam() {
        BaseResultEntity result = resourceController.resourceStatusChange(VALID_ID, null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void resourceController_getDataResourceFieldPage_success() {
        PageReq req = new PageReq();
        when(dataResourceService.getDataResourceFieldPage(VALID_ID, req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = resourceController.getDataResourceFieldPage(USER_ID, VALID_ID, req);
        assertSame(successResult, result);
    }

    @Test
    public void resourceController_getDataResourceFieldPage_nullResourceId_returnsLackOfParam() {
        BaseResultEntity result = resourceController.getDataResourceFieldPage(USER_ID, 0L, new PageReq());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void resourceController_displayDatabaseSourceType_success() {
        when(dataResourceService.displayDatabaseSourceType()).thenReturn(successResult);
        BaseResultEntity result = resourceController.displayDatabaseSourceType();
        assertSame(successResult, result);
    }

    // ================================================================
    //  ApiManageController (需求#84-89)
    // ================================================================

    @Test
    public void apiController_findApiPage_success() {
        when(apiManageService.findApiPage("kw", "active", 1, 10)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.findApiPage("kw", "active", 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_addApi_success() {
        Map<String, Object> data = new HashMap<>();
        data.put("name", "test-api");
        when(apiManageService.addApi(data)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.addApi(data);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_addApi_null_returnsLackOfParam() {
        BaseResultEntity result = apiManageController.addApi(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void apiController_updateApi_success() {
        Map<String, Object> data = new HashMap<>();
        when(apiManageService.updateApi(data)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.updateApi(data);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_deleteApi_success() {
        Map<String, Object> data = new HashMap<>();
        data.put("id", VALID_ID);
        when(apiManageService.deleteApi(VALID_ID)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.deleteApi(data);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_addApiAuth_success() {
        Map<String, Object> data = new HashMap<>();
        when(apiManageService.addApiAuth(data)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.addApiAuth(data);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_addApiAuth_null_returnsLackOfParam() {
        BaseResultEntity result = apiManageController.addApiAuth(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void apiController_validateApiAuth_success() {
        Map<String, Object> data = new HashMap<>();
        when(apiManageService.validateApiAuth(data)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.validateApiAuth(data);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_findApiLogPage_success() {
        when(apiManageService.findApiLogPage("/path", null, null, 1, 10)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.findApiLogPage("/path", null, null, 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_findApiAuthPage_success() {
        when(apiManageService.findApiAuthPage("kw", 1, 10)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.findApiAuthPage("kw", 1, 10);
        assertSame(successResult, result);
    }

    @Test
    public void apiController_getApiStatistics_success() {
        when(apiManageService.getApiStatistics(null, null)).thenReturn(successResult);
        BaseResultEntity result = apiManageController.getApiStatistics(null, null);
        assertSame(successResult, result);
    }

    // ================================================================
    //  SystemConfigController (需求#61-67)
    // ================================================================

    @Test
    public void systemConfigController_getNetworkConfig_success() {
        when(sysConfigService.getNetworkConfig()).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.getNetworkConfig();
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_saveNetworkConfig_success() {
        NetworkConfigVO vo = new NetworkConfigVO();
        when(sysConfigService.saveNetworkConfig(vo)).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.saveNetworkConfig(vo);
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_saveNetworkConfig_null_returnsLackOfParam() {
        BaseResultEntity result = systemConfigController.saveNetworkConfig(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void systemConfigController_getTimeConfig_success() {
        when(sysConfigService.getTimeConfig()).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.getTimeConfig();
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_saveTimeConfig_success() {
        TimeConfigVO vo = new TimeConfigVO();
        when(sysConfigService.saveTimeConfig(vo)).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.saveTimeConfig(vo);
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_getLoginRestriction_success() {
        when(sysConfigService.getLoginRestriction()).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.getLoginRestriction();
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_saveLoginRestriction_success() {
        LoginRestrictionVO vo = new LoginRestrictionVO();
        when(sysConfigService.saveLoginRestriction(vo)).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.saveLoginRestriction(vo);
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_getPersonalizationConfig_success() {
        when(sysConfigService.getPersonalizationConfig()).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.getPersonalizationConfig();
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_savePersonalizationConfig_success() {
        PersonalizationConfigVO vo = new PersonalizationConfigVO();
        when(sysConfigService.savePersonalizationConfig(vo)).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.savePersonalizationConfig(vo);
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_getFtpConfig_success() {
        when(sysConfigService.getFtpConfig()).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.getFtpConfig();
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_saveFtpConfig_success() {
        FtpConfigVO vo = new FtpConfigVO();
        when(sysConfigService.saveFtpConfig(vo)).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.saveFtpConfig(vo);
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_testFtpConnection_success() {
        FtpConfigVO vo = new FtpConfigVO();
        when(sysConfigService.testFtpConnection(vo)).thenReturn(successResult);
        BaseResultEntity result = systemConfigController.testFtpConnection(vo);
        assertSame(successResult, result);
    }

    @Test
    public void systemConfigController_saveLoginRestriction_null_returnsLackOfParam() {
        BaseResultEntity result = systemConfigController.saveLoginRestriction(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }
}
