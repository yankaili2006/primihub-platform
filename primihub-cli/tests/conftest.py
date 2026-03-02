"""Shared test fixtures for pytest."""

import pytest
import tempfile
from pathlib import Path
from unittest.mock import Mock
from primihub_cli.core.client import PrimiHubClient
from primihub_cli.core.config import Config
from primihub_cli.core.session import Session


@pytest.fixture
def temp_dir():
    """Create a temporary directory for tests."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def mock_config(temp_dir):
    """Create a mock configuration."""
    config = Config()
    config.config_file = temp_dir / 'config.yaml'
    config.config_data = {
        'default_profile': 'demo0',
        'profiles': {
            'demo0': {
                'base_url': 'http://localhost:30811/prod-api',
                'organ_id': 1,
                'organ_name': 'demo0'
            },
            'demo1': {
                'base_url': 'http://localhost:30812/prod-api',
                'organ_id': 2,
                'organ_name': 'demo1'
            }
        },
        'output': {
            'format': 'table',
            'color': True,
            'verbose': False
        }
    }
    return config


@pytest.fixture
def mock_session(temp_dir):
    """Create a mock session."""
    session_file = temp_dir / 'session'
    session = Session(session_file=str(session_file))
    return session


@pytest.fixture
def mock_client():
    """Create a mock PrimiHub client."""
    client = PrimiHubClient(
        base_url='http://localhost:30811/prod-api',
        token='test_token_123'
    )
    return client


@pytest.fixture
def mock_api_response():
    """Create a mock API response."""
    return {
        'code': 0,
        'msg': 'success',
        'result': {
            'data': 'test_data'
        }
    }


@pytest.fixture
def mock_user_info():
    """Create mock user information."""
    return {
        'userId': 1,
        'userName': 'admin',
        'userAccount': 'admin',
        'organId': 1,
        'organName': 'demo0',
        'email': 'admin@example.com'
    }


@pytest.fixture
def mock_task_list():
    """Create mock task list."""
    return {
        'code': 0,
        'msg': 'success',
        'result': {
            'list': [
                {
                    'taskId': 1,
                    'taskName': 'PSI Task 1',
                    'taskType': 'psi',
                    'taskState': 2,
                    'createTime': '2026-03-01 10:00:00'
                },
                {
                    'taskId': 2,
                    'taskName': 'PIR Task 1',
                    'taskType': 'pir',
                    'taskState': 3,
                    'createTime': '2026-03-01 11:00:00'
                }
            ],
            'total': 2,
            'pageNo': 1,
            'pageSize': 10
        }
    }


@pytest.fixture
def mock_project_list():
    """Create mock project list."""
    return {
        'code': 0,
        'msg': 'success',
        'result': {
            'list': [
                {
                    'projectId': 1,
                    'projectName': 'Test Project 1',
                    'projectType': 'psi',
                    'projectDesc': 'Test description',
                    'createTime': '2026-03-01 09:00:00'
                },
                {
                    'projectId': 2,
                    'projectName': 'Test Project 2',
                    'projectType': 'fl',
                    'projectDesc': 'FL project',
                    'createTime': '2026-03-01 09:30:00'
                }
            ],
            'total': 2
        }
    }


@pytest.fixture
def mock_resource_list():
    """Create mock resource list."""
    return {
        'code': 0,
        'msg': 'success',
        'result': {
            'list': [
                {
                    'resourceId': 1,
                    'resourceName': 'dataset1.csv',
                    'resourceType': 'csv',
                    'organId': 1,
                    'createTime': '2026-03-01 08:00:00'
                },
                {
                    'resourceId': 2,
                    'resourceName': 'dataset2.csv',
                    'resourceType': 'csv',
                    'organId': 1,
                    'createTime': '2026-03-01 08:30:00'
                }
            ],
            'total': 2
        }
    }


@pytest.fixture
def mock_login_response():
    """Create mock login response."""
    return {
        'code': 0,
        'msg': 'success',
        'result': {
            'token': 'test_token_abc123',
            'sysUser': {
                'userId': 1,
                'userName': 'admin',
                'userAccount': 'admin',
                'organId': 1,
                'organName': 'demo0'
            }
        }
    }


@pytest.fixture
def mock_error_response():
    """Create mock error response."""
    return {
        'code': 500,
        'msg': 'Internal Server Error',
        'result': None
    }


@pytest.fixture
def mock_auth_error_response():
    """Create mock authentication error response."""
    return {
        'code': 401,
        'msg': 'Unauthorized',
        'result': None
    }
