import pytest
import os
import yaml
import logging
from api_client import PrimiHubAPIClient

logger = logging.getLogger(__name__)


def load_config():
    config_path = os.environ.get(
        "TEST_CONFIG",
        os.path.join(os.path.dirname(__file__), "../config/test_config.yml")
    )
    if os.path.exists(config_path):
        with open(config_path) as f:
            return yaml.safe_load(f)
    return {}


@pytest.fixture(scope="session")
def config():
    return load_config()


@pytest.fixture(scope="session")
def api_client(config):
    base_url = os.environ.get(
        "API_BASE_URL",
        config.get("api", {}).get("base_url", "http://localhost:8080")
    )
    timeout = config.get("api", {}).get("timeout", 30)
    client = PrimiHubAPIClient(base_url, timeout=timeout)
    return client


@pytest.fixture(scope="session")
def admin_credentials(config):
    admin = config.get("test_users", {}).get("admin", {})
    return {
        "username": os.environ.get("ADMIN_USER", admin.get("username", "admin")),
        "password": os.environ.get("ADMIN_PASSWORD", admin.get("password", "123456")),
    }


@pytest.fixture(scope="session")
def authed_client(api_client, admin_credentials):
    resp = api_client.login(admin_credentials["username"], admin_credentials["password"])
    assert resp.get("code") == 0, f"Login failed: {resp.get('msg')}"
    assert api_client.token is not None, "No token returned"
    yield api_client
    try:
        api_client.logout()
    except Exception:
        pass


@pytest.fixture(scope="session")
def token(authed_client):
    return authed_client.token


@pytest.fixture(scope="session")
def user_id(authed_client):
    return authed_client.user_id
