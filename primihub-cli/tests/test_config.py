"""Tests for core config module."""

import pytest
import tempfile
import os
from pathlib import Path
from unittest.mock import patch, mock_open
from primihub_cli.core.config import Config
from primihub_cli.core.exceptions import ConfigError


class TestConfig:
    """Test cases for Config."""

    def test_default_config_creation(self):
        """Test default configuration values."""
        config = Config()
        assert config.config_data is not None
        assert 'default_profile' in config.config_data
        assert 'profiles' in config.config_data
        assert 'output' in config.config_data

    def test_get_base_url(self):
        """Test getting base URL from config."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {
                    'base_url': 'http://localhost:30811/prod-api',
                    'organ_id': 1
                }
            }
        }
        assert config.get_base_url() == 'http://localhost:30811/prod-api'

    def test_get_base_url_with_profile(self):
        """Test getting base URL for specific profile."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {
                    'base_url': 'http://localhost:30811/prod-api',
                    'organ_id': 1
                },
                'demo1': {
                    'base_url': 'http://localhost:30812/prod-api',
                    'organ_id': 2
                }
            }
        }
        assert config.get_base_url('demo1') == 'http://localhost:30812/prod-api'

    def test_get_organ_id(self):
        """Test getting organ ID from config."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {
                    'base_url': 'http://localhost:30811/prod-api',
                    'organ_id': 1
                }
            }
        }
        assert config.get_organ_id() == 1

    def test_get_output_format(self):
        """Test getting output format from config."""
        config = Config()
        config.config_data = {
            'output': {
                'format': 'json',
                'color': True
            }
        }
        assert config.get_output_format() == 'json'

    def test_set_output_format(self):
        """Test setting output format."""
        config = Config()
        config.config_data = {
            'output': {
                'format': 'table',
                'color': True
            }
        }
        config.set_output_format('json')
        assert config.get_output_format() == 'json'

    def test_is_color_enabled(self):
        """Test checking if color output is enabled."""
        config = Config()
        config.config_data = {
            'output': {
                'format': 'table',
                'color': True
            }
        }
        assert config.is_color_enabled() is True

    def test_get_default_profile(self):
        """Test getting default profile name."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'}
            }
        }
        assert config.get_default_profile() == 'demo0'

    def test_set_default_profile(self):
        """Test setting default profile."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'},
                'demo1': {'base_url': 'http://localhost:30812/prod-api'}
            }
        }
        config.set_default_profile('demo1')
        assert config.get_default_profile() == 'demo1'

    def test_list_profiles(self):
        """Test listing all profiles."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'},
                'demo1': {'base_url': 'http://localhost:30812/prod-api'},
                'demo2': {'base_url': 'http://localhost:30813/prod-api'}
            }
        }
        profiles = config.list_profiles()
        assert len(profiles) == 3
        assert 'demo0' in profiles
        assert 'demo1' in profiles
        assert 'demo2' in profiles

    def test_add_profile(self):
        """Test adding a new profile."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'}
            }
        }
        config.add_profile(
            'demo1',
            'http://localhost:30812/prod-api',
            2,
            'demo1'
        )
        assert 'demo1' in config.config_data['profiles']
        assert config.config_data['profiles']['demo1']['organ_id'] == 2

    def test_delete_profile(self):
        """Test deleting a profile."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'},
                'demo1': {'base_url': 'http://localhost:30812/prod-api'}
            }
        }
        config.delete_profile('demo1')
        assert 'demo1' not in config.config_data['profiles']

    def test_delete_default_profile_raises_error(self):
        """Test that deleting default profile raises error."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'}
            }
        }
        with pytest.raises(ConfigError):
            config.delete_profile('demo0')

    def test_get_profile_info(self):
        """Test getting profile information."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {
                    'base_url': 'http://localhost:30811/prod-api',
                    'organ_id': 1,
                    'organ_name': 'demo0'
                }
            }
        }
        profile_info = config.get_profile_info('demo0')
        assert profile_info['base_url'] == 'http://localhost:30811/prod-api'
        assert profile_info['organ_id'] == 1
        assert profile_info['organ_name'] == 'demo0'

    def test_get_nonexistent_profile_raises_error(self):
        """Test that getting nonexistent profile raises error."""
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'}
            }
        }
        with pytest.raises(ConfigError):
            config.get_profile_info('nonexistent')

    @patch('builtins.open', new_callable=mock_open)
    @patch('pathlib.Path.exists')
    def test_save_config(self, mock_exists, mock_file):
        """Test saving configuration to file."""
        mock_exists.return_value = True
        config = Config()
        config.config_data = {
            'default_profile': 'demo0',
            'profiles': {
                'demo0': {'base_url': 'http://localhost:30811/prod-api'}
            }
        }
        config.save()
        mock_file.assert_called_once()

    @patch('builtins.open', new_callable=mock_open, read_data='default_profile: demo0\nprofiles:\n  demo0:\n    base_url: http://localhost:30811/prod-api')
    @patch('pathlib.Path.exists')
    def test_load_config(self, mock_exists, mock_file):
        """Test loading configuration from file."""
        mock_exists.return_value = True
        config = Config()
        config.load()
        assert config.config_data is not None

    def test_reset_to_defaults(self):
        """Test resetting configuration to defaults."""
        config = Config()
        config.config_data = {
            'default_profile': 'custom',
            'profiles': {
                'custom': {'base_url': 'http://custom:8080/api'}
            }
        }
        config.reset_to_defaults()
        assert config.get_default_profile() == 'demo0'
        assert 'demo0' in config.config_data['profiles']
