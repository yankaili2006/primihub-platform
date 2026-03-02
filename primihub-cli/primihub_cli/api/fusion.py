"""Fusion resource management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class FusionAPI:
    """Fusion resource management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize fusion API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_fusion_resources(
        self,
        page_no: int = 1,
        page_size: int = 10,
        resource_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        List fusion resources with pagination.

        Args:
            page_no: Page number
            page_size: Page size
            resource_type: Resource type filter

        Returns:
            Fusion resource list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if resource_type:
            params['resourceType'] = resource_type

        response = self.client.get('/fusion/getFusionResourceList', params=params)
        return response

    def get_fusion_resource(self, fusion_id: int) -> Dict[str, Any]:
        """
        Get fusion resource details.

        Args:
            fusion_id: Fusion resource ID

        Returns:
            Fusion resource details
        """
        response = self.client.get(
            '/fusion/getFusionResource',
            params={'fusionId': fusion_id}
        )
        return response

    def create_fusion_resource(
        self,
        fusion_name: str,
        resource_ids: list,
        fusion_type: str = 'psi',
        fusion_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a fusion resource.

        Args:
            fusion_name: Fusion resource name
            resource_ids: List of resource IDs to fuse
            fusion_type: Fusion type (psi, pir, fl)
            fusion_desc: Fusion resource description

        Returns:
            Create response
        """
        data = {
            'fusionName': fusion_name,
            'resourceIds': ','.join(map(str, resource_ids)),
            'fusionType': fusion_type,
        }
        if fusion_desc:
            data['fusionDesc'] = fusion_desc

        response = self.client.post('/fusion/createFusionResource', data=data)
        return response

    def update_fusion_resource(
        self,
        fusion_id: int,
        fusion_name: Optional[str] = None,
        fusion_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Update fusion resource.

        Args:
            fusion_id: Fusion resource ID
            fusion_name: New fusion resource name
            fusion_desc: New fusion resource description

        Returns:
            Update response
        """
        data = {'fusionId': fusion_id}
        if fusion_name:
            data['fusionName'] = fusion_name
        if fusion_desc:
            data['fusionDesc'] = fusion_desc

        response = self.client.post('/fusion/updateFusionResource', data=data)
        return response

    def delete_fusion_resource(self, fusion_id: int) -> Dict[str, Any]:
        """
        Delete a fusion resource.

        Args:
            fusion_id: Fusion resource ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/fusion/deleteFusionResource',
            data={'fusionId': fusion_id}
        )
        return response

    def get_fusion_status(self, fusion_id: int) -> Dict[str, Any]:
        """
        Get fusion resource status.

        Args:
            fusion_id: Fusion resource ID

        Returns:
            Fusion status
        """
        response = self.client.get(
            '/fusion/getFusionStatus',
            params={'fusionId': fusion_id}
        )
        return response

    def execute_fusion(self, fusion_id: int) -> Dict[str, Any]:
        """
        Execute a fusion resource.

        Args:
            fusion_id: Fusion resource ID

        Returns:
            Execution response
        """
        response = self.client.post(
            '/fusion/executeFusion',
            data={'fusionId': fusion_id}
        )
        return response

    def get_fusion_result(self, fusion_id: int) -> Dict[str, Any]:
        """
        Get fusion execution result.

        Args:
            fusion_id: Fusion resource ID

        Returns:
            Fusion result
        """
        response = self.client.get(
            '/fusion/getFusionResult',
            params={'fusionId': fusion_id}
        )
        return response
