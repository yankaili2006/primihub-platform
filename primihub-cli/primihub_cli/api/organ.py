"""Organization management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class OrganAPI:
    """Organization management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize organization API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_organs(self, page_no: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        List organizations with pagination.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            Organization list response
        """
        response = self.client.get(
            '/organ/getOrganPage',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_organ(self, organ_id: int) -> Dict[str, Any]:
        """
        Get organization details.

        Args:
            organ_id: Organization ID

        Returns:
            Organization details
        """
        response = self.client.get(
            '/organ/getOrgan',
            params={'organId': organ_id}
        )
        return response

    def create_organ(
        self,
        organ_name: str,
        organ_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a new organization.

        Args:
            organ_name: Organization name
            organ_desc: Organization description

        Returns:
            Create organization response
        """
        data = {'organName': organ_name}
        if organ_desc:
            data['organDesc'] = organ_desc

        response = self.client.post('/organ/saveOrgan', data=data)
        return response

    def update_organ(
        self,
        organ_id: int,
        organ_name: Optional[str] = None,
        organ_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Update organization information.

        Args:
            organ_id: Organization ID
            organ_name: New organization name
            organ_desc: New organization description

        Returns:
            Update response
        """
        data = {'organId': organ_id}
        if organ_name:
            data['organName'] = organ_name
        if organ_desc:
            data['organDesc'] = organ_desc

        response = self.client.post('/organ/updateOrgan', data=data)
        return response

    def delete_organ(self, organ_id: int) -> Dict[str, Any]:
        """
        Delete an organization.

        Args:
            organ_id: Organization ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/organ/deleteOrgan',
            data={'organId': organ_id}
        )
        return response

    def get_organ_list(self) -> Dict[str, Any]:
        """
        Get all organizations (no pagination).

        Returns:
            Organization list
        """
        response = self.client.get('/organ/getOrganList')
        return response
