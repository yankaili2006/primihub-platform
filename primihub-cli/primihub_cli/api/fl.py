"""FL (Federated Learning) task API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class FLAPI:
    """Federated Learning task API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize FL API.

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
        List FL tasks with pagination.

        Args:
            page_no: Page number
            page_size: Page size
            status: Filter by task status

        Returns:
            FL task list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if status is not None:
            params['taskState'] = status

        response = self.client.get('/model/getModelTaskList', params=params)
        return response

    def get_task(self, task_id: str) -> Dict[str, Any]:
        """
        Get FL task details.

        Args:
            task_id: Task ID

        Returns:
            FL task details
        """
        response = self.client.get(
            '/model/getModelTaskDetails',
            params={'taskId': task_id}
        )
        return response

    def create_task(
        self,
        project_id: int,
        model_id: int,
        resource_ids: list,
        algorithm: str = 'xgboost',
    ) -> Dict[str, Any]:
        """
        Create a new FL task.

        Args:
            project_id: Project ID
            model_id: Model ID
            resource_ids: List of resource IDs
            algorithm: FL algorithm (xgboost, logistic_regression, etc.)

        Returns:
            Create task response
        """
        data = {
            'projectId': project_id,
            'modelId': model_id,
            'resourceIds': ','.join(map(str, resource_ids)),
            'algorithm': algorithm,
        }

        response = self.client.post('/model/runModel', data=data)
        return response

    def cancel_task(self, task_id: str) -> Dict[str, Any]:
        """
        Cancel a FL task.

        Args:
            task_id: Task ID

        Returns:
            Cancel response
        """
        response = self.client.post(
            '/model/cancelTask',
            data={'taskId': task_id}
        )
        return response

    def get_task_logs(self, task_id: str) -> Dict[str, Any]:
        """
        Get FL task logs.

        Args:
            task_id: Task ID

        Returns:
            Task logs
        """
        response = self.client.get(
            '/model/getTaskLogs',
            params={'taskId': task_id}
        )
        return response

    def get_training_progress(self, task_id: str) -> Dict[str, Any]:
        """
        Get FL training progress.

        Args:
            task_id: Task ID

        Returns:
            Training progress
        """
        response = self.client.get(
            '/model/getTrainingProgress',
            params={'taskId': task_id}
        )
        return response

    def list_models(self, page_no: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        List FL models.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            Model list response
        """
        response = self.client.get(
            '/model/getmodellist',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_model(self, model_id: int) -> Dict[str, Any]:
        """
        Get model details.

        Args:
            model_id: Model ID

        Returns:
            Model details
        """
        response = self.client.get(
            '/model/getModelDetails',
            params={'modelId': model_id}
        )
        return response
