"""PSI (Private Set Intersection) task API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class PSIAPI:
    """PSI task API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize PSI API.

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
        List PSI tasks with pagination.

        Args:
            page_no: Page number
            page_size: Page size
            status: Filter by task status (0=pending, 1=running, 2=success, 3=failed)

        Returns:
            PSI task list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if status is not None:
            params['taskState'] = status

        response = self.client.get('/psi/getPsiTaskList', params=params)
        return response

    def get_task(self, task_id: str) -> Dict[str, Any]:
        """
        Get PSI task details.

        Args:
            task_id: Task ID

        Returns:
            PSI task details
        """
        response = self.client.get(
            '/psi/getPsiTaskDetails',
            params={'taskId': task_id}
        )
        return response

    def create_task(
        self,
        project_id: int,
        resource_ids: list,
        algorithm: str = 'dh',
    ) -> Dict[str, Any]:
        """
        Create a new PSI task.

        Args:
            project_id: Project ID
            resource_ids: List of resource IDs
            algorithm: PSI algorithm (dh, ecdh, kkrt, rr22)

        Returns:
            Create task response
        """
        data = {
            'projectId': project_id,
            'resourceIds': ','.join(map(str, resource_ids)),
            'algorithm': algorithm,
        }

        response = self.client.post('/psi/submitTask', data=data)
        return response

    def cancel_task(self, task_id: str) -> Dict[str, Any]:
        """
        Cancel a PSI task.

        Args:
            task_id: Task ID

        Returns:
            Cancel response
        """
        response = self.client.post(
            '/psi/cancelTask',
            data={'taskId': task_id}
        )
        return response

    def get_task_result(self, task_id: str) -> Dict[str, Any]:
        """
        Get PSI task result.

        Args:
            task_id: Task ID

        Returns:
            Task result
        """
        response = self.client.get(
            '/psi/getTaskResult',
            params={'taskId': task_id}
        )
        return response

    def download_result(self, task_id: str) -> Dict[str, Any]:
        """
        Download PSI task result.

        Args:
            task_id: Task ID

        Returns:
            Download URL or result data
        """
        response = self.client.get(
            '/psi/downloadResult',
            params={'taskId': task_id}
        )
        return response
