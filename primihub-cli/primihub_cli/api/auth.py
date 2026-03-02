"""Authentication API module."""

from typing import Dict, Any

from ..core.client import PrimiHubClient


class AuthAPI:
    """Authentication API operations."""

    def __init__(self, client: PrimiHubClient):
        """
        Initialize authentication API.

        Args:
            client: PrimiHub API client
        """
        self.client = client

    def login(self, username: str, password: str) -> Dict[str, Any]:
        """
        Login to PrimiHub platform.

        Args:
            username: Username
            password: Password

        Returns:
            Login response with token and user info
        """
        response = self.client.post(
            '/user/login',
            data={
                'userAccount': username,
                'userPassword': password,
            }
        )
        return response

    def logout(self) -> Dict[str, Any]:
        """
        Logout from PrimiHub platform.

        Returns:
            Logout response
        """
        response = self.client.post('/sys/user/logout')
        return response

    def get_user_info(self) -> Dict[str, Any]:
        """
        Get current user information.

        Returns:
            User information
        """
        response = self.client.get('/sys/user/getUserInfo')
        return response

    def get_auth_list(self) -> Dict[str, Any]:
        """
        Get authentication list (public endpoint).

        Returns:
            Authentication list
        """
        response = self.client.get('/oauth/getAuthList')
        return response
