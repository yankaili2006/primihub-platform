"""Tests for core client module."""

import pytest
from unittest.mock import Mock, patch, MagicMock
from primihub_cli.core.client import PrimiHubClient
from primihub_cli.core.config import Config
from primihub_cli.core.exceptions import APIError, AuthenticationError


class TestPrimiHubClient:
    """Test cases for PrimiHubClient."""

    def test_client_initialization(self):
        """Test client initialization with basic parameters."""
        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )
        assert client.base_url == "http://localhost:30811/prod-api"
        assert client.token == "test_token"

    def test_from_config(self):
        """Test client creation from config."""
        with patch('primihub_cli.core.client.Config') as mock_config_class:
            mock_config = Mock()
            mock_config.get_base_url.return_value = "http://localhost:30811/prod-api"
            mock_config.get_organ_id.return_value = 1
            mock_config_class.return_value = mock_config

            with patch('primihub_cli.core.client.Session') as mock_session_class:
                mock_session = Mock()
                mock_session.load.return_value = {
                    'token': 'test_token',
                    'user_info': {'userId': 1}
                }
                mock_session_class.return_value = mock_session

                client = PrimiHubClient.from_config()
                assert client.base_url == "http://localhost:30811/prod-api"
                assert client.token == "test_token"

    def test_url_construction(self):
        """Test URL construction for API endpoints."""
        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )

        # Test with leading slash
        url = client._construct_url("/user/login")
        assert url == "http://localhost:30811/prod-api/user/login"

        # Test without leading slash
        url = client._construct_url("user/login")
        assert url == "http://localhost:30811/prod-api/user/login"

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_successful_request(self, mock_request):
        """Test successful API request."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {'data': 'test'}
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )

        response = client.get('/test/endpoint')
        assert response['code'] == 0
        assert response['result']['data'] == 'test'

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_authentication_error(self, mock_request):
        """Test authentication error handling."""
        mock_response = Mock()
        mock_response.status_code = 401
        mock_response.json.return_value = {
            'code': 401,
            'msg': 'Unauthorized'
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="invalid_token"
        )

        with pytest.raises(AuthenticationError):
            client.get('/test/endpoint')

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_api_error(self, mock_request):
        """Test API error handling."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.json.return_value = {
            'code': 500,
            'msg': 'Internal Server Error'
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )

        with pytest.raises(APIError):
            client.get('/test/endpoint')

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_post_with_data(self, mock_request):
        """Test POST request with form data."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'code': 0,
            'msg': 'success',
            'result': {'id': 123}
        }
        mock_request.return_value = mock_response

        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )

        response = client.post('/test/create', data={'name': 'test'})
        assert response['code'] == 0
        assert response['result']['id'] == 123

    def test_proxy_detection(self):
        """Test smart proxy detection for private networks."""
        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )

        # Test localhost
        assert client._should_bypass_proxy("http://localhost:30811") is True

        # Test 127.0.0.1
        assert client._should_bypass_proxy("http://127.0.0.1:30811") is True

        # Test private network 10.x.x.x
        assert client._should_bypass_proxy("http://10.0.0.1:30811") is True

        # Test private network 172.16.x.x
        assert client._should_bypass_proxy("http://172.16.0.1:30811") is True

        # Test private network 192.168.x.x
        assert client._should_bypass_proxy("http://192.168.1.1:30811") is True

        # Test public IP
        assert client._should_bypass_proxy("http://8.8.8.8:30811") is False

    @patch('primihub_cli.core.client.requests.Session.request')
    def test_retry_on_network_error(self, mock_request):
        """Test automatic retry on network errors."""
        # First two calls fail, third succeeds
        mock_request.side_effect = [
            Exception("Connection error"),
            Exception("Connection error"),
            Mock(status_code=200, json=lambda: {'code': 0, 'result': {}})
        ]

        client = PrimiHubClient(
            base_url="http://localhost:30811/prod-api",
            token="test_token"
        )

        # Should succeed after retries
        response = client.get('/test/endpoint')
        assert response['code'] == 0
        assert mock_request.call_count == 3
