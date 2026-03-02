"""PIR (Private Information Retrieval) task API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class PIRAPI:
    """PIR task API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize PIR API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_tasks(
        self,
        page_no: int = 1,
        page_size: int = 10,
        status: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        List PIR tasks with pagination.

        Args:
            page_no: Page number
            page_size: Page size
            status: Filter by task status

        Returns:
            PIR task list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if status is not None:
            params['taskState'] = status

        response = self.client.get('/pir/getPirTaskList', params=params)
        return response

    def get_task(self, task_id: str) -> Dict[str, Any]:
        """
        Get PIR task details.

        Args:
            task_id: Task ID

        Returns:
            PIR task details
        """
        response = self.client.get(
            '/pir/getPirTaskDetails',
            params={'taskId': task_id}
        )
        return response

    def create_task(
        self,
        project_id: int,
        resource_id: int,
        query_params: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Create a new PIR task.

        Args:
            project_id: Project ID
            resource_id: Resource ID
            query_params: Query parameters

        Returns:
            Create task response
        """
        data = {
            'projectId': project_id,
            'resourceId': resource_id,
            **query_params,
        }

        response = self.client.post('/pir/pirSubmitTask', data=data)
        return response

    def cancel_task(self, task_id: str) -> Dict[str, Any]:
        """
        Cancel a PIR task.

        Args:
            task_id: Task ID

        Returns:
            Cancel response
        """
        response = self.client.post(
            '/pir/cancelTask',
            data={'taskId': task_id}
        )
        return response

    def download_result(self, task_id: str) -> Dict[str, Any]:
        """
        Download PIR task result.

        Args:
            task_id: Task ID

        Returns:
            Download URL or result data
        """
        response = self.client.get(
            '/pir/downloadPirTask',
            params={'taskId': task_id}
        )
        return response
