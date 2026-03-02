"""Data management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class DataAPI:
    """Data management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize data API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_datasets(
        self,
        page_no: int = 1,
        page_size: int = 10,
    ) -> Dict[str, Any]:
        """
        List datasets with pagination.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            Dataset list response
        """
        response = self.client.get(
            '/data/getDatasetList',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_dataset(self, dataset_id: int) -> Dict[str, Any]:
        """
        Get dataset details.

        Args:
            dataset_id: Dataset ID

        Returns:
            Dataset details
        """
        response = self.client.get(
            '/data/getDataset',
            params={'datasetId': dataset_id}
        )
        return response

    def get_dataset_fields(self, dataset_id: int) -> Dict[str, Any]:
        """
        Get dataset field information.

        Args:
            dataset_id: Dataset ID

        Returns:
            Dataset fields
        """
        response = self.client.get(
            '/data/getDatasetFields',
            params={'datasetId': dataset_id}
        )
        return response

    def preview_dataset(
        self,
        dataset_id: int,
        limit: int = 10,
    ) -> Dict[str, Any]:
        """
        Preview dataset content.

        Args:
            dataset_id: Dataset ID
            limit: Number of rows to preview

        Returns:
            Dataset preview data
        """
        response = self.client.get(
            '/data/previewDataset',
            params={
                'datasetId': dataset_id,
                'limit': limit,
            }
        )
        return response

    def upload_dataset(
        self,
        dataset_name: str,
        file_path: str,
        dataset_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Upload a dataset.

        Args:
            dataset_name: Dataset name
            file_path: Path to dataset file
            dataset_desc: Dataset description

        Returns:
            Upload response
        """
        data = {'datasetName': dataset_name}
        if dataset_desc:
            data['datasetDesc'] = dataset_desc

        files = {'file': open(file_path, 'rb')}

        response = self.client.post(
            '/data/uploadDataset',
            data=data,
            files=files
        )

        files['file'].close()
        return response

    def delete_dataset(self, dataset_id: int) -> Dict[str, Any]:
        """
        Delete a dataset.

        Args:
            dataset_id: Dataset ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/data/deleteDataset',
            data={'datasetId': dataset_id}
        )
        return response

    def get_dataset_statistics(self, dataset_id: int) -> Dict[str, Any]:
        """
        Get dataset statistics.

        Args:
            dataset_id: Dataset ID

        Returns:
            Dataset statistics
        """
        response = self.client.get(
            '/data/getDatasetStatistics',
            params={'datasetId': dataset_id}
        )
        return response
