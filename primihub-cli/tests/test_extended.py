"""Extended unit tests for CLI modules - error handling, edge cases."""
import pytest
from unittest.mock import Mock, patch
from primihub_cli.core.client import PrimiHubClient
from primihub_cli.core.config import Config
from primihub_cli.core.exceptions import APIError, AuthenticationError


class TestClientEdgeCases:
    def test_client_initialization_with_token(self):
        client = PrimiHubClient(base_url="http://localhost:30811/prod-api", token="test_token")
        assert client.token == "test_token"

    @patch("primihub_cli.core.client.requests.Session.request")
    def test_timeout_handling(self, mock_request):
        import requests
        mock_request.side_effect = requests.Timeout("Request timed out")
        client = PrimiHubClient(base_url="http://localhost:30811/prod-api", token="t")
        with pytest.raises(APIError):
            client.get("/test/endpoint")

    def test_token_property(self):
        client = PrimiHubClient(base_url="http://localhost:30811/prod-api")
        client.token = "new_token"
        assert client.token == "new_token"

    @patch("primihub_cli.core.client.requests.Session.request")
    def test_404_raises_error(self, mock_request):
        mock_resp = Mock()
        mock_resp.status_code = 404
        mock_resp.ok = False
        mock_resp.raise_for_status.side_effect = Exception("404")
        mock_request.return_value = mock_resp

        client = PrimiHubClient(base_url="http://localhost:30811/prod-api", token="t")
        with pytest.raises(Exception):
            client.get("/notfound")


class TestConfigEdgeCases:
    def test_config_set_and_get(self):
        config = Config()
        config.set("test_key", "test_value")
        assert config.get("test_key") == "test_value"


class TestAPIErrorHandlingExtended:
    def test_api_error_with_message(self):
        err = APIError("Custom error", status_code=400)
        assert "Custom error" in str(err)
        assert err.status_code == 400

    def test_authentication_error_message(self):
        err = AuthenticationError("Token expired")
        assert "expired" in str(err)

    @patch("primihub_cli.core.client.requests.Session.request")
    def test_non_json_response(self, mock_request):
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.side_effect = ValueError("No JSON")
        mock_response.text = "plain text response"
        mock_request.return_value = mock_response
        client = PrimiHubClient(base_url="http://localhost:30811/prod-api", token="t")
        result = client.get("/test/endpoint")
        assert "message" in result
        assert result["message"] == "plain text response"


class TestFormatters:
    def test_json_format(self):
        from primihub_cli.formatters.json import JSONFormatter
        f = JSONFormatter()
        output = f.format({"success": True, "data": [1, 2, 3]})
        assert "1" in output

    def test_json_format_error(self):
        from primihub_cli.formatters.json import JSONFormatter
        f = JSONFormatter()
        output = f.format_error("not found")
        assert "not found" in output

    def test_table_format(self):
        from primihub_cli.formatters.table import TableFormatter
        f = TableFormatter()
        data = [{"id": 1, "name": "test"}, {"id": 2, "name": "test2"}]
        output = f.format(data)
        assert "id" in output or "name" in output

    def test_table_format_empty(self):
        from primihub_cli.formatters.table import TableFormatter
        f = TableFormatter()
        output = f.format([])
        assert output is not None

    def test_yaml_format(self):
        from primihub_cli.formatters.yaml import YAMLFormatter
        f = YAMLFormatter()
        output = f.format({"key": "value"})
        assert "key" in output
        assert "value" in output

    def test_csv_format(self):
        from primihub_cli.formatters.csv import CSVFormatter
        f = CSVFormatter()
        data = [{"a": 1, "b": 2}, {"a": 3, "b": 4}]
        output = f.format(data)
        assert "a" in output or "b" in output
