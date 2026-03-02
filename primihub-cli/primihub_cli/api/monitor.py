"""Monitoring and statistics API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class MonitorAPI:
    """Monitoring and statistics API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize monitor API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def get_dashboard_stats(self) -> Dict[str, Any]:
        """
        Get dashboard statistics.

        Returns:
            Dashboard statistics (tasks, resources, nodes, etc.)
        """
        response = self.client.get('/monitor/getDashboardStats')
        return response

    def get_task_statistics(
        self,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
        task_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get task statistics.

        Args:
            start_time: Start time (format: YYYY-MM-DD)
            end_time: End time (format: YYYY-MM-DD)
            task_type: Task type filter (psi, pir, fl)

        Returns:
            Task statistics
        """
        params = {}
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time
        if task_type:
            params['taskType'] = task_type

        response = self.client.get('/monitor/getTaskStatistics', params=params)
        return response

    def get_resource_usage(
        self,
        resource_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get resource usage statistics.

        Args:
            resource_type: Resource type filter

        Returns:
            Resource usage statistics
        """
        params = {}
        if resource_type:
            params['resourceType'] = resource_type

        response = self.client.get('/monitor/getResourceUsage', params=params)
        return response

    def get_node_statistics(self) -> Dict[str, Any]:
        """
        Get node statistics.

        Returns:
            Node statistics (online, offline, total)
        """
        response = self.client.get('/monitor/getNodeStatistics')
        return response

    def get_user_activity(
        self,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
        user_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Get user activity statistics.

        Args:
            start_time: Start time
            end_time: End time
            user_id: User ID filter

        Returns:
            User activity statistics
        """
        params = {}
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time
        if user_id:
            params['userId'] = user_id

        response = self.client.get('/monitor/getUserActivity', params=params)
        return response

    def get_performance_metrics(
        self,
        metric_type: Optional[str] = None,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get performance metrics.

        Args:
            metric_type: Metric type (cpu, memory, disk, network)
            start_time: Start time
            end_time: End time

        Returns:
            Performance metrics
        """
        params = {}
        if metric_type:
            params['metricType'] = metric_type
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time

        response = self.client.get('/monitor/getPerformanceMetrics', params=params)
        return response

    def get_error_statistics(
        self,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
        error_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get error statistics.

        Args:
            start_time: Start time
            end_time: End time
            error_type: Error type filter

        Returns:
            Error statistics
        """
        params = {}
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time
        if error_type:
            params['errorType'] = error_type

        response = self.client.get('/monitor/getErrorStatistics', params=params)
        return response

    def get_api_statistics(
        self,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get API call statistics.

        Args:
            start_time: Start time
            end_time: End time

        Returns:
            API statistics
        """
        params = {}
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time

        response = self.client.get('/monitor/getApiStatistics', params=params)
        return response

    def set_alert_rule(
        self,
        rule_name: str,
        metric_type: str,
        threshold: float,
        condition: str = 'greater',
        alert_level: str = 'warning',
    ) -> Dict[str, Any]:
        """
        Set monitoring alert rule.

        Args:
            rule_name: Alert rule name
            metric_type: Metric type to monitor
            threshold: Alert threshold
            condition: Condition (greater, less, equal)
            alert_level: Alert level (info, warning, error)

        Returns:
            Set alert rule response
        """
        data = {
            'ruleName': rule_name,
            'metricType': metric_type,
            'threshold': threshold,
            'condition': condition,
            'alertLevel': alert_level,
        }

        response = self.client.post('/monitor/setAlertRule', data=data)
        return response

    def get_alert_rules(self) -> Dict[str, Any]:
        """
        Get all alert rules.

        Returns:
            Alert rules list
        """
        response = self.client.get('/monitor/getAlertRules')
        return response

    def delete_alert_rule(self, rule_id: int) -> Dict[str, Any]:
        """
        Delete an alert rule.

        Args:
            rule_id: Alert rule ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/monitor/deleteAlertRule',
            data={'ruleId': rule_id}
        )
        return response

    def get_alerts(
        self,
        page_no: int = 1,
        page_size: int = 10,
        alert_level: Optional[str] = None,
        status: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get triggered alerts.

        Args:
            page_no: Page number
            page_size: Page size
            alert_level: Alert level filter
            status: Status filter (active, resolved)

        Returns:
            Alerts list
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if alert_level:
            params['alertLevel'] = alert_level
        if status:
            params['status'] = status

        response = self.client.get('/monitor/getAlerts', params=params)
        return response
