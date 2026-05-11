#!/usr/bin/env python3
"""
PrimiHub API Client
Python API客户端，封装所有API调用

功能:
- 用户认证（登录/登出）
- 用户管理
- 数据资源管理
- 项目管理
- 任务管理
- 隐私计算（PSI/PIR/Model）
- 系统功能（白名单/租户/日志等）
"""

import requests
import json
import logging
import time
from typing import Dict, Any, Optional, List
from urllib.parse import urljoin


class PrimiHubAPIClient:
    """PrimiHub API客户端类"""

    def __init__(self, base_url: str = "http://localhost:8080", timeout: int = 30):
        """
        初始化API客户端

        Args:
            base_url: API基础URL
            timeout: 请求超时时间（秒）
        """
        self.base_url = base_url.rstrip('/') + '/'
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'application/json'
        })

        # 认证信息
        self.token = None
        self.user_id = None
        self.user_name = None

        # 配置日志
        self.logger = logging.getLogger(__name__)

    def _build_url(self, endpoint: str) -> str:
        """构建完整的API URL"""
        return urljoin(self.base_url, endpoint.lstrip('/'))

    def _make_request(self, method: str, endpoint: str,
                      data: Optional[Dict] = None,
                      params: Optional[Dict] = None,
                      headers: Optional[Dict] = None) -> Dict[str, Any]:
        """
        发送HTTP请求

        Args:
            method: HTTP方法 (GET, POST, PUT, DELETE)
            endpoint: API端点
            data: 请求体数据
            params: URL参数
            headers: 额外的HTTP头

        Returns:
            响应数据字典
        """
        url = self._build_url(endpoint)

        request_headers = self.session.headers.copy()
        if headers:
            request_headers.update(headers)

        # 如果已登录，添加token
        if self.token:
            request_headers['token'] = self.token

        # 生成timestamp和nonce
        timestamp = int(time.time() * 1000)
        nonce = int(time.time() * 1000) % 1000 + 1

        # 对于GET请求，timestamp和nonce添加到params
        if method.upper() == 'GET':
            if params is None:
                params = {}
            params['timestamp'] = timestamp
            params['nonce'] = nonce
            if self.token:
                params['token'] = self.token
        # 对于POST请求，timestamp和nonce添加到data
        elif method.upper() == 'POST':
            if data is not None:
                # 更新现有的data字典
                data.update({
                    'timestamp': timestamp,
                    'nonce': nonce
                })
                if self.token:
                    data['token'] = self.token
            else:
                # 如果data为None，创建新字典
                data = {
                    'timestamp': timestamp,
                    'nonce': nonce
                }
                if self.token:
                    data['token'] = self.token

        try:
            self.logger.debug(f"Request: {method} {url}")
            self.logger.debug(f"Headers: {request_headers}")
            if data:
                self.logger.debug(f"Data: {json.dumps(data, ensure_ascii=False)}")
            if params:
                self.logger.debug(f"Params: {params}")

            response = self.session.request(
                method=method,
                url=url,
                json=data if data else None,
                params=params if params else None,
                headers=request_headers,
                timeout=self.timeout
            )

            self.logger.debug(f"Response Status: {response.status_code}")
            self.logger.debug(f"Response: {response.text[:500]}")

            # 检查HTTP状态码
            response.raise_for_status()

            # 解析JSON响应
            return response.json()

        except requests.exceptions.Timeout:
            self.logger.error(f"Request timeout: {url}")
            raise
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Request failed: {e}")
            raise
        except json.JSONDecodeError as e:
            self.logger.error(f"JSON decode error: {e}, Response: {response.text[:500]}")
            raise

    # ========================================================================
    # 认证相关API
    # ========================================================================

    def login(self, username: str, password: str) -> Dict[str, Any]:
        """
        用户登录 (使用表单数据)

        Args:
            username: 用户名
            password: 密码

        Returns:
            登录响应数据
        """
        self.logger.info(f"Logging in as {username}")

        url = self._build_url("/sys/user/login")
        timestamp = int(time.time() * 1000)
        nonce = int(time.time() * 1000) % 1000 + 1
        data = {"userAccount": username, "userPassword": password,
                "timestamp": timestamp, "nonce": nonce}
        if self.token:
            data["token"] = self.token

        response = self.session.post(url, data=data,
                                      timeout=self.timeout)
        response.raise_for_status()
        response = response.json()

        # 保存认证信息
        if response.get('code') == 0 and response.get('result'):
            result = response['result']
            self.token = result.get('token')
            self.user_id = result.get('userId')
            self.user_name = result.get('userName')
            self.logger.info(f"Login successful: {self.user_name} (ID: {self.user_id})")
        else:
            self.logger.error(f"Login failed: {response}")

        return response

    def logout(self) -> Dict[str, Any]:
        """
        用户登出

        Returns:
            登出响应数据
        """
        self.logger.info("Logging out")
        response = self._make_request("GET", "/sys/user/logout")

        # 清除认证信息
        self.token = None
        self.user_id = None
        self.user_name = None

        return response

    # ========================================================================
    # 用户管理API
    # ========================================================================

    def create_user(self, user_data: Dict) -> Dict[str, Any]:
        """
        创建用户

        Args:
            user_data: 用户数据，包含：
                - userAccount: 用户账号
                - userName: 用户姓名
                - userPassword: 密码
                - userPhone: 电话
                - userEmail: 邮箱
                - organId: 机构ID（可选）

        Returns:
            创建结果
        """
        return self._make_request("POST", "/sys/user/saveOrUpdateUser", data=user_data)

    def get_user_list(self, page: int = 1, page_size: int = 10,
                      user_account: str = None) -> Dict[str, Any]:
        """
        获取用户列表

        Args:
            page: 页码
            page_size: 每页数量
            user_account: 用户账号（可选，用于搜索）

        Returns:
            用户列表
        """
        params = {
            "pageNum": page,
            "pageSize": page_size
        }
        if user_account:
            params["userAccount"] = user_account

        return self._make_request("GET", "/sys/user/findUserPage", params=params)

    def get_user_by_account(self, user_account: str) -> Dict[str, Any]:
        """
        根据账号查询用户

        Args:
            user_account: 用户账号

        Returns:
            用户信息
        """
        return self._make_request("GET", "/sys/user/findUserByAccount",
                                   params={"userAccount": user_account})

    def update_user(self, user_data: Dict) -> Dict[str, Any]:
        """
        更新用户信息

        Args:
            user_data: 用户数据（必须包含userId）

        Returns:
            更新结果
        """
        return self._make_request("POST", "/sys/user/saveOrUpdateUser", data=user_data)

    def delete_user(self, user_ids: List[int]) -> Dict[str, Any]:
        """
        删除用户

        Args:
            user_ids: 用户ID列表

        Returns:
            删除结果
        """
        return self._make_request("POST", "/sys/user/deleteSysUser",
                                   data={"userIds": user_ids})

    def freeze_user(self, user_id: int) -> Dict[str, Any]:
        """
        冻结用户

        Args:
            user_id: 用户ID

        Returns:
            冻结结果
        """
        return self._make_request("POST", "/sys/user/freezeUser",
                                   data={"userId": user_id})

    def unfreeze_user(self, user_id: int) -> Dict[str, Any]:
        """
        解冻用户

        Args:
            user_id: 用户ID

        Returns:
            解冻结果
        """
        return self._make_request("POST", "/sys/user/unfreezeUser",
                                   data={"userId": user_id})

    # ========================================================================
    # 机构管理API
    # ========================================================================

    def create_organ(self, organ_data: Dict) -> Dict[str, Any]:
        """
        创建机构

        Args:
            organ_data: 机构数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/sys/organ/saveOrgan", data=organ_data)

    def get_organ_list(self) -> Dict[str, Any]:
        """
        获取机构列表

        Returns:
            机构列表
        """
        return self._make_request("GET", "/sys/organ/getOrganList")

    # ========================================================================
    # 资源管理API
    # ========================================================================

    def create_resource(self, resource_data: Dict) -> Dict[str, Any]:
        """
        创建资源

        Args:
            resource_data: 资源数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/data/resource/saveorupdateresource",
                                   data=resource_data)

    def get_resource_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取资源列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            资源列表
        """
        return self._make_request("GET", "/data/resource/getresourcelist",
                                   params={"pageNo": page, "pageSize": page_size})

    # ========================================================================
    # 项目管理API
    # ========================================================================

    def create_project(self, project_data: Dict) -> Dict[str, Any]:
        """
        创建项目

        Args:
            project_data: 项目数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/data/project/saveOrUpdateProject",
                                   data=project_data)

    def get_project_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取项目列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            项目列表
        """
        return self._make_request("GET", "/data/project/getProjectList",
                                   params={"pageNo": page, "pageSize": page_size})

    def get_project_detail(self, project_id: int) -> Dict[str, Any]:
        """
        获取项目详情

        Args:
            project_id: 项目ID

        Returns:
            项目详情
        """
        return self._make_request("GET", "/data/project/getProjectDetails",
                                   params={"projectId": project_id})

    # ========================================================================
    # 任务管理API
    # ========================================================================

    def get_task_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取任务列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            任务列表
        """
        return self._make_request("GET", "/data/task/getTaskList",
                                   params={"pageNo": page, "pageSize": page_size})

    def get_task_detail(self, task_id: str) -> Dict[str, Any]:
        """
        获取任务详情

        Args:
            task_id: 任务ID

        Returns:
            任务详情
        """
        return self._make_request("GET", "/data/task/getTaskData",
                                   params={"taskId": task_id})

    # ========================================================================
    # PSI（隐私求交）API
    # ========================================================================

    def create_psi_task(self, psi_data: Dict) -> Dict[str, Any]:
        """
        创建PSI任务

        Args:
            psi_data: PSI任务数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/data/psi/saveDataPsi", data=psi_data)

    def get_psi_task_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取PSI任务列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            PSI任务列表
        """
        return self._make_request("GET", "/data/psi/getPsiTaskList",
                                   params={"pageNo": page, "pageSize": page_size})

    # ========================================================================
    # PIR（匿踪查询）API
    # ========================================================================

    def create_pir_task(self, pir_data: Dict) -> Dict[str, Any]:
        """
        创建PIR任务

        Args:
            pir_data: PIR任务数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/data/pir/saveDataPir", data=pir_data)

    def get_pir_task_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取PIR任务列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            PIR任务列表
        """
        return self._make_request("GET", "/data/pir/getPirList",
                                   params={"pageNo": page, "pageSize": page_size})

    # ========================================================================
    # 模型管理API
    # ========================================================================

    def create_model(self, model_data: Dict) -> Dict[str, Any]:
        """
        创建模型

        Args:
            model_data: 模型数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/data/model/saveOrUpdateModel",
                                   data=model_data)

    def get_model_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取模型列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            模型列表
        """
        return self._make_request("GET", "/data/model/getModelList",
                                   params={"pageNo": page, "pageSize": page_size})

    # ========================================================================
    # 白名单管理API
    # ========================================================================

    def create_whitelist(self, whitelist_data: Dict) -> Dict[str, Any]:
        """
        创建白名单

        Args:
            whitelist_data: 白名单数据

        Returns:
            创建结果
        """
        return self._make_request("POST", "/sys/whitelist/addWhitelist",
                                   data=whitelist_data)

    def get_whitelist_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        获取白名单列表

        Args:
            page: 页码
            page_size: 每页数量

        Returns:
            白名单列表
        """
        return self._make_request("GET", "/sys/whitelist/findWhitelistPage",
                                   params={"pageNum": page, "pageSize": page_size})

    # ========================================================================
    # 存证管理API
    # ========================================================================

    def get_evidence_page(self, page: int = 1, page_size: int = 10,
                          keyword: str = None, status: str = None) -> Dict[str, Any]:
        params = {"pageNum": page, "pageSize": page_size}
        if keyword: params["keyword"] = keyword
        if status: params["status"] = status
        return self._make_request("GET", "/evidence/findEvidencePage", params=params)

    def create_evidence(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/evidence/createEvidence", data=data)

    def verify_evidence(self, evidence_id: int) -> Dict[str, Any]:
        return self._make_request("POST", "/evidence/verifyEvidence", data={"id": evidence_id})

    def get_evidence_statistics(self) -> Dict[str, Any]:
        return self._make_request("GET", "/evidence/getEvidenceStatistics")

    def apply_timestamp(self, evidence_id: int) -> Dict[str, Any]:
        return self._make_request("POST", "/evidence/applyTimestamp", data={"evidenceId": evidence_id})

    def get_evidence_config(self) -> Dict[str, Any]:
        return self._make_request("GET", "/evidence/getEvidenceConfig")

    def save_evidence_config(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/evidence/saveEvidenceConfig", data=data)

    def regenerate_api_key(self, description: str = "") -> Dict[str, Any]:
        return self._make_request("POST", "/evidence/regenerateApiKey", data={"description": description})

    # ========================================================================
    # 监控管理API
    # ========================================================================

    def get_system_monitor(self) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getSystemMonitor")

    def get_cpu_monitor(self) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getCpuMonitor")

    def get_memory_monitor(self) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getMemoryMonitor")

    def get_disk_monitor(self) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getDiskMonitor")

    def get_jvm_monitor(self) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getJvmMonitor")

    def get_alert_config(self) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getAlertConfig")

    def save_alert_config(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/monitor/saveAlertConfig", data=data)

    def get_alert_history(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/monitor/getAlertHistory",
                                   params={"pageNum": page, "pageSize": page_size})

    def handle_alert(self, alert_id: int, remark: str = "") -> Dict[str, Any]:
        return self._make_request("POST", "/monitor/handleAlert",
                                   data={"id": alert_id, "remark": remark})

    # ========================================================================
    # 接口管理API
    # ========================================================================

    def get_api_page(self, page: int = 1, page_size: int = 10,
                     keyword: str = None) -> Dict[str, Any]:
        params = {"pageNum": page, "pageSize": page_size}
        if keyword: params["keyword"] = keyword
        return self._make_request("GET", "/apiManage/findApiPage", params=params)

    def add_api(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/apiManage/addApi", data=data)

    def update_api(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/apiManage/updateApi", data=data)

    def delete_api(self, api_id: int) -> Dict[str, Any]:
        return self._make_request("POST", "/apiManage/deleteApi", data={"id": api_id})

    def get_api_detail(self, api_id: int) -> Dict[str, Any]:
        return self._make_request("GET", "/apiManage/getApiDetail", params={"id": api_id})

    def toggle_api_status(self, api_id: int, status: int = 1) -> Dict[str, Any]:
        return self._make_request("POST", "/apiManage/toggleApiStatus",
                                   data={"id": api_id, "status": status})

    def get_api_auth_page(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/apiManage/findApiAuthPage",
                                   params={"pageNum": page, "pageSize": page_size})

    def add_api_auth(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/apiManage/addApiAuth", data=data)

    def get_api_statistics(self, start_time: str = None, end_time: str = None) -> Dict[str, Any]:
        params = {}
        if start_time: params["startTime"] = start_time
        if end_time: params["endTime"] = end_time
        return self._make_request("GET", "/apiManage/getApiStatistics", params=params)

    # ========================================================================
    # 场景定制化API - 警务数据融合
    # ========================================================================

    def create_police_task(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/policeFusion/task/create", data=data)

    def get_police_task_list(self, task_type: str = None, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        params = {"pageNo": page, "pageSize": page_size}
        if task_type: params["taskType"] = task_type
        return self._make_request("GET", "/policeFusion/task/list", params=params)

    def get_police_task_detail(self, task_id: int) -> Dict[str, Any]:
        return self._make_request("GET", "/policeFusion/task/detail", params={"taskId": task_id})

    def save_police_api(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/policeFusion/api/save", data=data)

    def get_police_api_list(self) -> Dict[str, Any]:
        return self._make_request("GET", "/policeFusion/api/list")

    def generate_police_key(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/policeFusion/key/generate", data=data)

    def encrypt_police_data(self, key_id: int, data_str: str) -> Dict[str, Any]:
        return self._make_request("POST", "/policeFusion/key/encrypt",
                                   data={"keyId": key_id, "data": data_str})

    def decrypt_police_data(self, key_id: int, encrypted_data: str) -> Dict[str, Any]:
        return self._make_request("POST", "/policeFusion/key/decrypt",
                                   data={"keyId": key_id, "encryptedData": encrypted_data})

    # ========================================================================
    # 场景定制化API - 电子证件
    # ========================================================================

    def create_cert_task(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/electronicCert/task/create", data=data)

    def get_cert_api_list(self) -> Dict[str, Any]:
        return self._make_request("GET", "/electronicCert/api/list")

    def generate_cert_key(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/electronicCert/key/generate", data=data)

    # ========================================================================
    # 联邦查询API
    # ========================================================================

    def create_federated_query(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedQuery/create", data=data)

    def get_query_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedQuery/list",
                                   params={"pageNo": page, "pageSize": page_size})

    def run_query(self, task_id: int) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedQuery/run", data={"taskId": task_id})

    def get_query_result(self, task_id: int) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedQuery/result", params={"taskId": task_id})

    def get_supported_algorithms(self) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedQuery/algorithms")

    def test_tool(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedQuery/tools/test", data=data)

    # ========================================================================
    # 联邦统计API
    # ========================================================================

    def create_stats_task(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedStatistics/task/create", data=data)

    def get_stats_task_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedStatistics/task/list",
                                   params={"pageNo": page, "pageSize": page_size})

    def run_stats_task(self, task_id: int) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedStatistics/task/run", data={"taskId": task_id})

    def get_stats_result(self, task_id: int) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedStatistics/result/list", params={"taskId": task_id})

    # ========================================================================
    # 联邦分析API
    # ========================================================================

    def validate_sql(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedAnalysis/sql/validate", data=data)

    def create_analysis_task(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedAnalysis/task/create", data=data)

    def get_analysis_task_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedAnalysis/task/list",
                                   params={"pageNo": page, "pageSize": page_size})

    def run_analysis_task(self, task_id: int) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedAnalysis/task/run", data={"taskId": task_id})

    # ========================================================================
    # 系统配置API
    # ========================================================================

    def get_network_config(self) -> Dict[str, Any]:
        return self._make_request("GET", "/systemConfig/getNetworkConfig")

    def save_network_config(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/systemConfig/saveNetworkConfig", data=data)

    def get_login_restriction(self) -> Dict[str, Any]:
        return self._make_request("GET", "/systemConfig/getLoginRestriction")

    def get_personalization_config(self) -> Dict[str, Any]:
        return self._make_request("GET", "/systemConfig/getPersonalizationConfig")

    def get_ftp_config(self) -> Dict[str, Any]:
        return self._make_request("GET", "/systemConfig/getFtpConfig")

    # ========================================================================
    # 联邦学习API
    # ========================================================================

    def create_fl_task(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedLearning/task/create", data=data)

    def get_fl_task_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedLearning/task/list",
                                   params={"pageNo": page, "pageSize": page_size})

    # ========================================================================
    # 存证/联邦查询计费API
    # ========================================================================

    def get_billing_rule_list(self, page: int = 1, page_size: int = 10) -> Dict[str, Any]:
        return self._make_request("GET", "/federatedBilling/rule/list",
                                   params={"pageNum": page, "pageSize": page_size})

    def create_billing_rule(self, data: Dict) -> Dict[str, Any]:
        return self._make_request("POST", "/federatedBilling/rule/create", data=data)

    # ========================================================================
    # 健康检查API
    # ========================================================================

    def health_check(self) -> Dict[str, Any]:
        """
        健康检查

        Returns:
            健康状态
        """
        return self._make_request("GET", "/test/healthConnection")

    # ========================================================================
    # 联邦求差API (Difference)
    # ========================================================================

    def save_data_difference(self, data: Dict) -> Dict[str, Any]:
        """创建并运行联邦求差任务"""
        return self._make_request("POST", "/difference/saveDataDifference", data=data)

    def get_difference_task_list(self, task_name: str = None, task_state: int = None,
                                  organ_id: str = None, start_date: str = None,
                                  end_date: str = None, page_no: int = 1,
                                  page_size: int = 10) -> Dict[str, Any]:
        """查询联邦求差任务列表"""
        params = {"pageNo": page_no, "pageSize": page_size}
        if task_name: params["taskName"] = task_name
        if task_state is not None: params["taskState"] = task_state
        if organ_id: params["organId"] = organ_id
        if start_date: params["startDate"] = start_date
        if end_date: params["endDate"] = end_date
        return self._make_request("GET", "/difference/getDifferenceTaskList", params=params)

    def get_difference_task_details(self, task_id: int) -> Dict[str, Any]:
        """查询联邦求差任务详情"""
        return self._make_request("GET", "/difference/getDifferenceTaskDetails",
                                   params={"taskId": task_id})

    def del_difference_task(self, task_id: int) -> Dict[str, Any]:
        """删除联邦求差任务"""
        return self._make_request("GET", "/difference/delDifferenceTask",
                                   params={"taskId": task_id})

    def cancel_difference_task(self, task_id: int) -> Dict[str, Any]:
        """取消联邦求差任务"""
        return self._make_request("GET", "/difference/cancelDifferenceTask",
                                   params={"taskId": task_id})

    # ========================================================================
    # 联邦求并API (Union)
    # ========================================================================

    def save_data_union(self, data: Dict) -> Dict[str, Any]:
        """创建并运行联邦求并任务"""
        return self._make_request("POST", "/union/saveDataUnion", data=data)

    def get_union_task_list(self, task_name: str = None, task_state: int = None,
                             organ_id: str = None, start_date: str = None,
                             end_date: str = None, page_no: int = 1,
                             page_size: int = 10) -> Dict[str, Any]:
        """查询联邦求并任务列表"""
        params = {"pageNo": page_no, "pageSize": page_size}
        if task_name: params["taskName"] = task_name
        if task_state is not None: params["taskState"] = task_state
        if organ_id: params["organId"] = organ_id
        if start_date: params["startDate"] = start_date
        if end_date: params["endDate"] = end_date
        return self._make_request("GET", "/union/getUnionTaskList", params=params)

    def get_union_task_details(self, task_id: int) -> Dict[str, Any]:
        """查询联邦求并任务详情"""
        return self._make_request("GET", "/union/getUnionTaskDetails",
                                   params={"taskId": task_id})

    def del_union_task(self, task_id: int) -> Dict[str, Any]:
        """删除联邦求并任务"""
        return self._make_request("GET", "/union/delUnionTask",
                                   params={"taskId": task_id})

    def cancel_union_task(self, task_id: int) -> Dict[str, Any]:
        """取消联邦求并任务"""
        return self._make_request("GET", "/union/cancelUnionTask",
                                   params={"taskId": task_id})

    # ========================================================================
    # 联邦分析API (增强)
    # ========================================================================

    def format_sql(self, data: Dict) -> Dict[str, Any]:
        """SQL格式化"""
        return self._make_request("POST", "/federatedAnalysis/sql/format", data=data)

    def get_sql_functions(self, category: str = None) -> Dict[str, Any]:
        """获取支持的SQL函数列表"""
        params = {}
        if category: params["category"] = category
        return self._make_request("GET", "/federatedAnalysis/sql/functions", params=params)

    def stop_analysis_task(self, task_id: int) -> Dict[str, Any]:
        """停止分析任务"""
        return self._make_request("POST", "/federatedAnalysis/task/stop",
                                   data={"taskId": task_id})

    def get_analysis_task_detail(self, task_id: int) -> Dict[str, Any]:
        """获取分析任务详情"""
        return self._make_request("GET", "/federatedAnalysis/task/detail",
                                   params={"taskId": task_id})

    def create_analysis_datasource(self, data: Dict) -> Dict[str, Any]:
        """创建分析数据源"""
        return self._make_request("POST", "/federatedAnalysis/datasource/create", data=data)

    def update_analysis_datasource(self, data: Dict) -> Dict[str, Any]:
        """更新分析数据源"""
        return self._make_request("POST", "/federatedAnalysis/datasource/update", data=data)

    def delete_analysis_datasource(self, datasource_id: int) -> Dict[str, Any]:
        """删除分析数据源"""
        return self._make_request("POST", "/federatedAnalysis/datasource/delete",
                                   data={"id": datasource_id})

    def test_analysis_datasource(self, data: Dict) -> Dict[str, Any]:
        """测试数据源连接"""
        return self._make_request("POST", "/federatedAnalysis/datasource/test", data=data)

    def get_analysis_datasource_list(self, source_type: str = None) -> Dict[str, Any]:
        """获取数据源列表"""
        params = {}
        if source_type: params["sourceType"] = source_type
        return self._make_request("GET", "/federatedAnalysis/datasource/list", params=params)

    def get_analysis_datasource_tables(self, datasource_id: int) -> Dict[str, Any]:
        """获取数据源表列表"""
        return self._make_request("GET", "/federatedAnalysis/datasource/tables",
                                   params={"datasourceId": datasource_id})

    def get_analysis_datasource_columns(self, datasource_id: int, table_name: str) -> Dict[str, Any]:
        """获取数据源表字段"""
        return self._make_request("GET", "/federatedAnalysis/datasource/columns",
                                   params={"datasourceId": datasource_id, "tableName": table_name})

    def get_rdbms_types(self) -> Dict[str, Any]:
        """获取支持的RDBMS类型"""
        return self._make_request("GET", "/federatedAnalysis/rdbms/types")

    def get_bigdata_types(self) -> Dict[str, Any]:
        """获取支持的大数据平台类型"""
        return self._make_request("GET", "/federatedAnalysis/bigdata/types")

    def get_cloud_types(self) -> Dict[str, Any]:
        """获取支持的云平台类型"""
        return self._make_request("GET", "/federatedAnalysis/cloud/types")

    # ========================================================================
    # 联邦查询计费API (增强)
    # ========================================================================

    def update_billing_rule(self, data: Dict) -> Dict[str, Any]:
        """更新计费规则"""
        return self._make_request("POST", "/federatedBilling/rule/update", data=data)

    def delete_billing_rule(self, rule_id: int) -> Dict[str, Any]:
        """删除计费规则"""
        return self._make_request("POST", "/federatedBilling/rule/delete",
                                   data={"id": rule_id})

    def toggle_billing_rule(self, rule_id: int, is_active: int = 1) -> Dict[str, Any]:
        """启用/禁用计费规则"""
        return self._make_request("POST", "/federatedBilling/rule/toggle",
                                   data={"ruleId": rule_id, "isActive": is_active})

    def get_billing_rule_detail(self, rule_id: int) -> Dict[str, Any]:
        """获取计费规则详情"""
        return self._make_request("GET", "/federatedBilling/rule/detail",
                                   params={"ruleId": rule_id})

    def get_billing_record_list(self, page_num: int = 1, page_size: int = 10,
                                 rule_id: int = None, start_time: str = None,
                                 end_time: str = None) -> Dict[str, Any]:
        """获取计费记录列表"""
        params = {"pageNum": page_num, "pageSize": page_size}
        if rule_id: params["ruleId"] = rule_id
        if start_time: params["startTime"] = start_time
        if end_time: params["endTime"] = end_time
        return self._make_request("GET", "/federatedBilling/record/list", params=params)

    def get_billing_statistics(self, start_time: str = None, end_time: str = None,
                                group_by: str = None) -> Dict[str, Any]:
        """获取计费统计"""
        params = {}
        if start_time: params["startTime"] = start_time
        if end_time: params["endTime"] = end_time
        if group_by: params["groupBy"] = group_by
        return self._make_request("GET", "/federatedBilling/record/statistics", params=params)

    # ========================================================================
    # 联邦统计API (增强)
    # ========================================================================

    def get_stats_task_detail(self, task_id: int) -> Dict[str, Any]:
        """获取统计任务详情"""
        return self._make_request("GET", "/federatedStatistics/task/detail",
                                   params={"taskId": task_id})

    def stop_stats_task(self, task_id: int) -> Dict[str, Any]:
        """停止统计任务"""
        return self._make_request("POST", "/federatedStatistics/task/stop",
                                   data={"taskId": task_id})

    def delete_stats_task(self, task_id: int) -> Dict[str, Any]:
        """删除统计任务"""
        return self._make_request("DELETE", "/federatedStatistics/task/delete",
                                   params={"taskId": task_id})

    def save_stats_result(self, data: Dict) -> Dict[str, Any]:
        """保存统计结果"""
        return self._make_request("POST", "/federatedStatistics/result/save", data=data)

    def get_stats_storage_config(self) -> Dict[str, Any]:
        """获取存储配置"""
        return self._make_request("GET", "/federatedStatistics/storage/config")

    def save_stats_storage_config(self, data: Dict) -> Dict[str, Any]:
        """保存存储配置"""
        return self._make_request("POST", "/federatedStatistics/storage/saveConfig", data=data)

    def get_stats_types(self) -> Dict[str, Any]:
        """获取支持的统计类型列表"""
        return self._make_request("GET", "/federatedStatistics/types")

    def get_stats_logs(self, page_no: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """获取统计日志"""
        return self._make_request("GET", "/federatedStatistics/logs",
                                   params={"pageNo": page_no, "pageSize": page_size})

    # ========================================================================
    # 场景定制化API (增强) - 警务数据融合
    # ========================================================================

    def get_police_key_list(self) -> Dict[str, Any]:
        """获取警务密钥列表"""
        return self._make_request("GET", "/policeFusion/key/list")

    def delete_police_key(self, key_id: int) -> Dict[str, Any]:
        """删除警务密钥"""
        return self._make_request("POST", "/policeFusion/key/delete",
                                   data={"id": key_id})

    # ========================================================================
    # 场景定制化API (增强) - 电子证件
    # ========================================================================

    def save_cert_api(self, data: Dict) -> Dict[str, Any]:
        """保存电子证件API配置"""
        return self._make_request("POST", "/electronicCert/api/save", data=data)

    def delete_cert_api(self, api_id: int) -> Dict[str, Any]:
        """删除电子证件API配置"""
        return self._make_request("POST", "/electronicCert/api/delete",
                                   data={"id": api_id})

    def get_cert_key_list(self) -> Dict[str, Any]:
        """获取电子证件密钥列表"""
        return self._make_request("GET", "/electronicCert/key/list")

    def delete_cert_key(self, key_id: int) -> Dict[str, Any]:
        """删除电子证件密钥"""
        return self._make_request("POST", "/electronicCert/key/delete",
                                   data={"id": key_id})

    # ========================================================================
    # 存证管理API (增强)
    # ========================================================================

    def get_evidence_detail(self, evidence_id: int) -> Dict[str, Any]:
        """获取存证详情"""
        return self._make_request("GET", "/evidence/getEvidenceDetail",
                                   params={"id": evidence_id})

    def find_timestamp_page(self, page_num: int = 1, page_size: int = 10,
                             keyword: str = None) -> Dict[str, Any]:
        """获取时间戳列表"""
        params = {"pageNum": page_num, "pageSize": page_size}
        if keyword: params["keyword"] = keyword
        return self._make_request("GET", "/evidence/findTimestampPage", params=params)

    def get_chain_list(self) -> Dict[str, Any]:
        """获取支持的区块链列表"""
        return self._make_request("GET", "/evidence/getChainList")

    def get_evidence_api_list(self) -> Dict[str, Any]:
        """获取存证API接口列表"""
        return self._make_request("GET", "/evidence/getApiList")

    def get_evidence_api_key(self) -> Dict[str, Any]:
        """获取存证API密钥"""
        return self._make_request("GET", "/evidence/getApiKey")

    # ========================================================================
    # 监控管理API (增强)
    # ========================================================================

    def get_database_monitor(self) -> Dict[str, Any]:
        """获取数据库监控"""
        return self._make_request("GET", "/monitor/getDatabaseMonitor")

    def get_redis_monitor(self) -> Dict[str, Any]:
        """获取Redis监控"""
        return self._make_request("GET", "/monitor/getRedisMonitor")

    def get_monitor_history(self, monitor_type: str = None, start_time: str = None,
                             end_time: str = None) -> Dict[str, Any]:
        """获取监控历史数据"""
        params = {}
        if monitor_type: params["type"] = monitor_type
        if start_time: params["startTime"] = start_time
        if end_time: params["endTime"] = end_time
        return self._make_request("GET", "/monitor/getMonitorHistory", params=params)

    def get_monitor_statistics(self) -> Dict[str, Any]:
        """获取监控统计"""
        return self._make_request("GET", "/monitor/getMonitorStatistics")

    # ========================================================================
    # 接口管理API (增强)
    # ========================================================================

    def batch_delete_api(self, api_ids: List[int]) -> Dict[str, Any]:
        """批量删除接口"""
        return self._make_request("POST", "/apiManage/batchDeleteApi",
                                   data={"ids": api_ids})

    def update_api_auth(self, data: Dict) -> Dict[str, Any]:
        """更新接口授权"""
        return self._make_request("POST", "/apiManage/updateApiAuth", data=data)

    def delete_api_auth(self, auth_id: int) -> Dict[str, Any]:
        """删除接口授权"""
        return self._make_request("POST", "/apiManage/deleteApiAuth",
                                   data={"id": auth_id})

    # ========================================================================
    # 系统配置API (增强)
    # ========================================================================

    def get_time_config(self) -> Dict[str, Any]:
        """获取时间配置"""
        return self._make_request("GET", "/systemConfig/getTimeConfig")

    def save_time_config(self, data: Dict) -> Dict[str, Any]:
        """保存时间配置"""
        return self._make_request("POST", "/systemConfig/saveTimeConfig", data=data)

    def save_login_restriction(self, data: Dict) -> Dict[str, Any]:
        """保存登录限制配置"""
        return self._make_request("POST", "/systemConfig/saveLoginRestriction", data=data)

    def save_personalization_config(self, data: Dict) -> Dict[str, Any]:
        """保存个性化配置"""
        return self._make_request("POST", "/systemConfig/savePersonalizationConfig", data=data)

    def save_ftp_config(self, data: Dict) -> Dict[str, Any]:
        """保存FTP配置"""
        return self._make_request("POST", "/systemConfig/saveFtpConfig", data=data)

    def test_ftp_connection(self, data: Dict) -> Dict[str, Any]:
        """测试FTP连接"""
        return self._make_request("POST", "/systemConfig/testFtpConnection", data=data)


if __name__ == "__main__":
    # 简单示例
    logging.basicConfig(level=logging.INFO)

    client = PrimiHubAPIClient("http://localhost:8080")

    # 测试登录
    try:
        response = client.login("admin", "Admin@123456")
        print("Login response:", json.dumps(response, indent=2, ensure_ascii=False))

        # 测试获取用户列表
        users = client.get_user_list(page=1, page_size=10)
        print("User list:", json.dumps(users, indent=2, ensure_ascii=False))

        # 登出
        client.logout()
    except Exception as e:
        print(f"Error: {e}")
