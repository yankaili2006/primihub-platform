"""Integration tests for API modules."""

import pytest
from unittest.mock import Mock, patch
from primihub_cli.api.auth import AuthAPI
from primihub_cli.api.user import UserAPI
from primihub_cli.api.project import ProjectAPI
from primihub_cli.api.psi import PSIAPI
from primihub_cli.core.client import PrimiHubClient


class TestAuthAPIIntegration:
    """Integration tests for AuthAPI."""

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_login_success(self, mock_request, mock_login_response):
        """Test successful login."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = mock_login_response
        mock_request.return_value = mock_response

        client = PrimiHubClient(base_url='http://localhost:30811/prod-api')
        auth_api = AuthAPI(client)

        response = auth_api.login('admin', '123456')
        assert response['code'] == 0
        assert 'token' in response['result']
        assert response['result']['sysUser']['userName'] == 'admin'

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_logout(self, mock_request):
        """Test logout."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {'code': 0, 'msg': 'success'}
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        auth_api = AuthAPI(client)

        response = auth_api.logout()
        assert response['code'] == 0


class TestUserAPIIntegration:
    """Integration tests for UserAPI."""

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_list_users(self, mock_request):
        """Test listing users."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {
                'list': [
                    {'userId': 1, 'userName': 'admin'},
                    {'userId': 2, 'userName': 'user1'}
                ],
                'total': 2
            }
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        user_api = UserAPI(client)

        response = user_api.list_users(page_no=1, page_size=10)
        assert response['code'] == 0
        assert len(response['result']['list']) == 2

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_create_user(self, mock_request):
        """Test creating a user."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {'userId': 3}
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        user_api = UserAPI(client)

        response = user_api.create_user(
            username='newuser',
            password='password123',
            email='newuser@example.com'
        )
        assert response['code'] == 0
        assert response['result']['userId'] == 3


class TestProjectAPIIntegration:
    """Integration tests for ProjectAPI."""

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_list_projects(self, mock_request, mock_project_list):
        """Test listing projects."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = mock_project_list
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        project_api = ProjectAPI(client)

        response = project_api.list_projects(page_no=1, page_size=10)
        assert response['code'] == 0
        assert len(response['result']['list']) == 2

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_create_project(self, mock_request):
        """Test creating a project."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {'projectId': 10}
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        project_api = ProjectAPI(client)

        response = project_api.create_project(
            project_name='New Project',
            project_type='psi',
            project_desc='Test project'
        )
        assert response['code'] == 0
        assert response['result']['projectId'] == 10


class TestPSIAPIIntegration:
    """Integration tests for PSIAPI."""

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_create_psi_task(self, mock_request):
        """Test creating a PSI task."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {'taskId': 100}
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        psi_api = PSIAPI(client)

        response = psi_api.create_task(
            project_id=1,
            resource_ids=[1, 2],
            algorithm='dh'
        )
        assert response['code'] == 0
        assert response['result']['taskId'] == 100

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_list_psi_tasks(self, mock_request, mock_task_list):
        """Test listing PSI tasks."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = mock_task_list
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        psi_api = PSIAPI(client)

        response = psi_api.list_tasks(page_no=1, page_size=10)
        assert response['code'] == 0
        assert len(response['result']['list']) == 2

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_get_task_status(self, mock_request):
        """Test getting PSI task status."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {
                'taskId': 100,
                'taskState': 3,
                'taskStatus': 'success'
            }
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        psi_api = PSIAPI(client)

        response = psi_api.get_task_status(100)
        assert response['code'] == 0
        assert response['result']['taskState'] == 3

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_cancel_task(self, mock_request):
        """Test canceling a PSI task."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success'
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        psi_api = PSIAPI(client)

        response = psi_api.cancel_task(100)
        assert response['code'] == 0


class TestAPIErrorHandling:
    """Test error handling across API modules."""

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_network_error_handling(self, mock_request):
        """Test handling of network errors."""
        mock_request.side_effect = Exception("Network error")

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        user_api = UserAPI(client)

        with pytest.raises(Exception):
            user_api.list_users()

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_api_error_response(self, mock_request):
        """Test handling of API error responses."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.json.return_value = {
            'code': 500,
            'msg': 'Internal Server Error'
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url='http://localhost:30811/prod-api',
            token='test_token'
        )
        user_api = UserAPI(client)

        from primihub_cli.core.exceptions import APIError
        with pytest.raises(APIError):
            user_api.list_users()
