"""Task management API module (general tasks across PSI/PIR/FL)."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class TaskAPI:
    """General task management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize task API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_tasks(
        self,
        page_no: int = 1,
        page_size: int = 10,
        task_type: Optional[str] = None,
        status: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        List all tasks with pagination.

        Args:
            page_no: Page number
            page_size: Page size
            task_type: Filter by task type (psi, pir, fl)
            status: Filter by task status

        Returns:
            Task list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if task_type:
            params['taskType'] = task_type
        if status is not None:
            params['taskState'] = status

        response = self.client.get('/task/getTaskList', params=params)
        return response

    def get_task(self, task_id: str) -> Dict[str, Any]:
        """
        Get task details.

        Args:
            task_id: Task ID

        Returns:
            Task details
        """
        response = self.client.get(
            '/task/getTaskDetails',
            params={'taskId': task_id}
        )
        return response

    def cancel_task(self, task_id: str) -> Dict[str, Any]:
        """
        Cancel a task.

        Args:
            task_id: Task ID

        Returns:
            Cancel response
        """
        response = self.client.post(
            '/task/cancelTask',
            data={'taskId': task_id}
        )
        return response

    def get_task_logs(self, task_id: str, lines: int = 100) -> Dict[str, Any]:
        """
        Get task logs.

        Args:
            task_id: Task ID
            lines: Number of log lines to retrieve

        Returns:
            Task logs
        """
        response = self.client.get(
            '/task/getTaskLogs',
            params={
                'taskId': task_id,
                'lines': lines,
            }
        )
        return response

    def get_task_status(self, task_id: str) -> Dict[str, Any]:
        """
        Get task status.

        Args:
            task_id: Task ID

        Returns:
            Task status
        """
        response = self.client.get(
            '/task/getTaskStatus',
            params={'taskId': task_id}
        )
        return response

    def retry_task(self, task_id: str) -> Dict[str, Any]:
        """
        Retry a failed task.

        Args:
            task_id: Task ID

        Returns:
            Retry response
        """
        response = self.client.post(
            '/task/retryTask',
            data={'taskId': task_id}
        )
        return response

    def delete_task(self, task_id: str) -> Dict[str, Any]:
        """
        Delete a task.

        Args:
            task_id: Task ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/task/deleteTask',
            data={'taskId': task_id}
        )
        return response
