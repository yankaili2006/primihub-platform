"""User management API module."""

from typing import Dict, Any, Optional

from ..core.client import PrimiHubClient


class UserAPI:
    """User management API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize user API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def list_users(self, page_no: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """
        List users with pagination.

        Args:
            page_no: Page number
            page_size: Page size

        Returns:
            User list response
        """
        response = self.client.get(
            '/user/findUserPage',
            params={
                'pageNo': page_no,
                'pageSize': page_size,
            }
        )
        return response

    def get_user(self, user_id: int) -> Dict[str, Any]:
        """
        Get user details.

        Args:
            user_id: User ID

        Returns:
            User details
        """
        response = self.client.get(
            '/user/getUserById',
            params={'userId': user_id}
        )
        return response

    def create_user(
        self,
        username: str,
        password: str,
        email: Optional[str] = None,
        phone: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a new user.

        Args:
            username: Username
            password: Password
            email: Email address
            phone: Phone number

        Returns:
            Create user response
        """
        data = {
            'userName': username,
            'userPassword': password,
        }
        if email:
            data['userEmail'] = email
        if phone:
            data['userPhone'] = phone

        response = self.client.post('/user/saveUser', data=data)
        return response

    def update_user(
        self,
        user_id: int,
        username: Optional[str] = None,
        email: Optional[str] = None,
        phone: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Update user information.

        Args:
            user_id: User ID
            username: New username
            email: New email
            phone: New phone

        Returns:
            Update response
        """
        data = {'userId': user_id}
        if username:
            data['userName'] = username
        if email:
            data['userEmail'] = email
        if phone:
            data['userPhone'] = phone

        response = self.client.post('/user/updateUser', data=data)
        return response

    def delete_user(self, user_id: int) -> Dict[str, Any]:
        """
        Delete a user.

        Args:
            user_id: User ID

        Returns:
            Delete response
        """
        response = self.client.post(
            '/user/deleteUser',
            data={'userId': user_id}
        )
        return response
