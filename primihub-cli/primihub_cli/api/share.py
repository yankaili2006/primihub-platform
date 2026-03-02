"""Data sharing management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class ShareAPI:
    """Data sharing management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize share API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_share_requests(
        self,
        page_no: int = 1,
        page_size: int = 10,
        status: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        List data sharing requests.

        Args:
            page_no: Page number
            page_size: Page size
            status: Request status filter (0=pending, 1=approved, 2=rejected)

        Returns:
            Share request list response
        """
        params = {
            'pageNo': page_no,
            'pageSize': page_size,
        }
        if status is not None:
            params['status'] = status

        response = self.client.get('/share/getShareRequestList', params=params)
        return response

    def get_share_request(self, request_id: int) -> Dict[str, Any]:
        """
        Get share request details.

        Args:
            request_id: Share request ID

        Returns:
            Share request details
        """
        response = self.client.get(
            '/share/getShareRequest',
            params={'requestId': request_id}
        )
        return response

    def create_share_request(
        self,
        resource_id: int,
        target_organ_id: int,
        share_type: str = 'read',
        share_desc: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a data sharing request.

        Args:
            resource_id: Resource ID to share
            target_organ_id: Target organization ID
            share_type: Share type (read, write, full)
            share_desc: Share request description

        Returns:
            Create response
        """
        data = {
            'resourceId': resource_id,
            'targetOrganId': target_organ_id,
            'shareType': share_type,
        }
        if share_desc:
            data['shareDesc'] = share_desc

        response = self.client.post('/share/createShareRequest', data=data)
        return response

    def approve_share_request(self, request_id: int) -> Dict[str, Any]:
        """
        Approve a share request.

        Args:
            request_id: Share request ID

        Returns:
            Approval response
        """
        response = self.client.post(
            '/share/approveShareRequest',
            data={'requestId': request_id}
        )
        return response

    def reject_share_request(
        self,
        request_id: int,
        reject_reason: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Reject a share request.

        Args:
            request_id: Share request ID
            reject_reason: Rejection reason

        Returns:
            Rejection response
        """
        data = {'requestId': request_id}
        if reject_reason:
            data['rejectReason'] = reject_reason

        response = self.client.post('/share/rejectShareRequest', data=data)
        return response

    def cancel_share_request(self, request_id: int) -> Dict[str, Any]:
        """
        Cancel a share request.

        Args:
            request_id: Share request ID

        Returns:
            Cancel response
        """
        response = self.client.post(
            '/share/cancelShareRequest',
            data={'requestId': request_id}
        )
        return response

    def list_shared_resources(
        self,
        page_no: int = 1,
        page_size: int = 10,
    ) -> Dict[str, Any]:
        """
        List shared resources.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            Shared resource list
        """
        response = self.client.get(
            '/share/getSharedResourceList',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def revoke_share(self, share_id: int) -> Dict[str, Any]:
        """
        Revoke a data share.

        Args:
            share_id: Share ID

        Returns:
            Revoke response
        """
        response = self.client.post(
            '/share/revokeShare',
            data={'shareId': share_id}
        )
        return response

    def get_share_permissions(self, resource_id: int) -> Dict[str, Any]:
        """
        Get resource share permissions.

        Args:
            resource_id: Resource ID

        Returns:
            Share permissions
        """
        response = self.client.get(
            '/share/getSharePermissions',
            params={'resourceId': resource_id}
        )
        return response

    def update_share_permissions(
        self,
        share_id: int,
        share_type: str,
    ) -> Dict[str, Any]:
        """
        Update share permissions.

        Args:
            share_id: Share ID
            share_type: New share type (read, write, full)

        Returns:
            Update response
        """
        response = self.client.post(
            '/share/updateSharePermissions',
            data={
                'shareId': share_id,
                'shareType': share_type,
            }
        )
        return response
