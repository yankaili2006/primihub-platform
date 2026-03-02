"""Resource management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class ResourceAPI:
    """Resource management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize resource API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_resources(
        self,
        page_no: int = 1,
        page_size: int = 10,
        organ_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        List resources with pagination.

        Args:
            page_no: Page number
            page_size: Page size
            organ_id: Filter by organization ID

        Returns:
            Resource list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if organ_id:
            params['organId'] = organ_id

        response = self.client.get('/resource/getdataresourcelist', params=params)
        return response

    def get_resource(self, resource_id: int) -> Dict[str, Any]:
        """
        Get resource details.

        Args:
            resource_id: Resource ID

        Returns:
            Resource details
        """
        response = self.client.get(
            '/resource/getdataresource',
            params={'resourceId': resource_id}
        )
        return response

    def create_resource(
        self,
        resource_name: str,
        resource_desc: Optional[str] = None,
        file_path: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a new resource.

        Args:
            resource_name: Resource name
            resource_desc: Resource description
            file_path: Path to resource file

        Returns:
            Create resource response
        """
        data = {'resourceName': resource_name}
        if resource_desc:
            data['resourceDesc'] = resource_desc

        files = None
        if file_path:
            files = {'file': open(file_path, 'rb')}

        response = self.client.post(
            '/resource/saveorupdateresource',
            data=data,
            files=files
        )

        if files:
            files['file'].close()

        return response

    def update_resource(
        self,
        resource_id: int,
        resource_name: Optional[str] = None,
        resource_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Update resource information.

        Args:
            resource_id: Resource ID
            resource_name: New resource name
            resource_desc: New resource description

        Returns:
            Update response
        """
        data = {'resourceId': resource_id}
        if resource_name:
            data['resourceName'] = resource_name
        if resource_desc:
            data['resourceDesc'] = resource_desc

        response = self.client.post('/resource/updateresource', data=data)
        return response

    def delete_resource(self, resource_id: int) -> Dict[str, Any]:
        """
        Delete a resource.

        Args:
            resource_id: Resource ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/resource/deleteresource',
            data={'resourceId': resource_id}
        )
        return response
