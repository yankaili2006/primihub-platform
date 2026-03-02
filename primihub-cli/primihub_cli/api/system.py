"""System management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class SystemAPI:
    """System management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize system API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def get_system_info(self) -> Dict[str, Any]:
        """
        Get system information.

        Returns:
            System information
        """
        response = self.client.get('/system/getSystemInfo')
        return response

    def get_system_status(self) -> Dict[str, Any]:
        """
        Get system status.

        Returns:
            System status
        """
        response = self.client.get('/system/getSystemStatus')
        return response

    def get_system_config(self) -> Dict[str, Any]:
        """
        Get system configuration.

        Returns:
            System configuration
        """
        response = self.client.get('/system/getSystemConfig')
        return response

    def update_system_config(
        self,
        config_key: str,
        config_value: str,
    ) -> Dict[str, Any]:
        """
        Update system configuration.

        Args:
            config_key: Configuration key
            config_value: Configuration value

        Returns:
            Update response
        """
        data = {
            'configKey': config_key,
            'configValue': config_value,
        }

        response = self.client.post('/system/updateSystemConfig', data=data)
        return response

    def get_system_logs(
        self,
        log_type: Optional[str] = None,
        limit: int = 100,
    ) -> Dict[str, Any]:
        """
        Get system logs.

        Args:
            log_type: Log type filter (error, warning, info)
            limit: Number of log entries to retrieve

        Returns:
            System logs
        """
        params = {'limit': limit}
        if log_type:
            params['logType'] = log_type

        response = self.client.get('/system/getSystemLogs', params=params)
        return response

    def get_system_metrics(self) -> Dict[str, Any]:
        """
        Get system metrics.

        Returns:
            System metrics (CPU, memory, disk, network)
        """
        response = self.client.get('/system/getSystemMetrics')
        return response

    def health_check(self) -> Dict[str, Any]:
        """
        Perform system health check.

        Returns:
            Health check results
        """
        response = self.client.get('/system/healthCheck')
        return response

    def get_version(self) -> Dict[str, Any]:
        """
        Get system version information.

        Returns:
            Version information
        """
        response = self.client.get('/system/getVersion')
        return response

    def restart_service(self, service_name: str) -> Dict[str, Any]:
        """
        Restart a system service.

        Args:
            service_name: Service name to restart

        Returns:
            Restart response
        """
        response = self.client.post(
            '/system/restartService',
            data={'serviceName': service_name}
        )
        return response

    def get_service_status(self, service_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Get service status.

        Args:
            service_name: Specific service name (optional, returns all if not specified)

        Returns:
            Service status
        """
        params = {}
        if service_name:
            params['serviceName'] = service_name

        response = self.client.get('/system/getServiceStatus', params=params)
        return response

    def backup_database(self) -> Dict[str, Any]:
        """
        Trigger database backup.

        Returns:
            Backup response
        """
        response = self.client.post('/system/backupDatabase')
        return response

    def restore_database(self, backup_file: str) -> Dict[str, Any]:
        """
        Restore database from backup.

        Args:
            backup_file: Backup file path

        Returns:
            Restore response
        """
        response = self.client.post(
            '/system/restoreDatabase',
            data={'backupFile': backup_file}
        )
        return response
