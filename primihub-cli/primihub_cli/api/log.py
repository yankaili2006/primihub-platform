"""Log query API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class LogAPI:
    """Log query API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize log API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def query_logs(
        self,
        page_no: int = 1,
        page_size: int = 100,
        log_level: Optional[str] = None,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
        keyword: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Query system logs.

        Args:
            page_no: Page number
            page_size: Page size
            log_level: Log level filter (DEBUG, INFO, WARN, ERROR)
            start_time: Start time (format: YYYY-MM-DD HH:MM:SS)
            end_time: End time (format: YYYY-MM-DD HH:MM:SS)
            keyword: Keyword search

        Returns:
            Log query results
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if log_level:
            params['logLevel'] = log_level
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time
        if keyword:
            params['keyword'] = keyword

        response = self.client.get('/log/queryLogs', params=params)
        return response

    def get_task_logs(
        self,
        task_id: int,
        page_no: int = 1,
        page_size: int = 100,
    ) -> Dict[str, Any]:
        """
        Get task execution logs.

        Args:
            task_id: Task ID
            page_no: Page number
            page_size: Page size

        Returns:
            Task logs
        """
        response = self.client.get(
            '/log/getTaskLogs',
            params={
                'taskId': task_id,
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_node_logs(
        self,
        node_id: int,
        page_no: int = 1,
        page_size: int = 100,
        log_level: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get node logs.

        Args:
            node_id: Node ID
            page_no: Page number
            page_size: Page size
            log_level: Log level filter

        Returns:
            Node logs
        """
        params = {
            'nodeId': node_id,
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if log_level:
            params['logLevel'] = log_level

        response = self.client.get('/log/getNodeLogs', params=params)
        return response

    def get_audit_logs(
        self,
        page_no: int = 1,
        page_size: int = 100,
        user_id: Optional[int] = None,
        action_type: Optional[str] = None,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get audit logs.

        Args:
            page_no: Page number
            page_size: Page size
            user_id: User ID filter
            action_type: Action type filter
            start_time: Start time
            end_time: End time

        Returns:
            Audit logs
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if user_id:
            params['userId'] = user_id
        if action_type:
            params['actionType'] = action_type
        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time

        response = self.client.get('/log/getAuditLogs', params=params)
        return response

    def export_logs(
        self,
        log_type: str = 'system',
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
        format: str = 'csv',
    ) -> Dict[str, Any]:
        """
        Export logs to file.

        Args:
            log_type: Log type (system, task, node, audit)
            start_time: Start time
            end_time: End time
            format: Export format (csv, json)

        Returns:
            Export response with download URL
        """
        data = {
            'logType': log_type,
            'format': format,
        }
        if start_time:
            data['startTime'] = start_time
        if end_time:
            data['endTime'] = end_time

        response = self.client.post('/log/exportLogs', data=data)
        return response

    def clear_logs(
        self,
        log_type: str = 'system',
        before_time: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Clear old logs.

        Args:
            log_type: Log type (system, task, node, audit)
            before_time: Clear logs before this time

        Returns:
            Clear response
        """
        data = {'logType': log_type}
        if before_time:
            data['beforeTime'] = before_time

        response = self.client.post('/log/clearLogs', data=data)
        return response
