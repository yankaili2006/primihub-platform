"""Configuration management for PrimiHub CLI."""

import os
from pathlib import Path
from typing import Any, Dict, Optional

import yaml

from .exceptions import ConfigError, ProfileNotFoundError


class Config:
    """Manages PrimiHub CLI configuration."""

    DEFAULT_CONFIG_DIR = Path.home() / ".primihub"
    DEFAULT_CONFIG_FILE = DEFAULT_CONFIG_DIR / "config.yaml"

    DEFAULT_CONFIG = {
        "default_profile": "demo0",
        "profiles": {
            "demo0": {
                "base_url": "http://localhost:30811/prod-api",
                "organ_id": 1,
                "organ_name": "demo0",
            },
            "demo1": {
                "base_url": "http://localhost:30812/prod-api",
                "organ_id": 2,
                "organ_name": "demo1",
            },
            "demo2": {
                "base_url": "http://localhost:30813/prod-api",
                "organ_id": 3,
                "organ_name": "demo2",
            },
        },
        "output": {
            "format": "table",
            "color": True,
            "verbose": False,
        },
        "proxy": {
            "enabled": False,
            "http": "",
            "https": "",
        },
    }

    def __init__(self, config_file: Optional[Path] = None):
        """Initialize configuration manager."""
        self.config_file = config_file or self.DEFAULT_CONFIG_FILE
        self._config = None
        self._ensure_config_dir()

    def _ensure_config_dir(self):
        """Ensure configuration directory exists."""
        self.config_file.parent.mkdir(parents=True, exist_ok=True)

    def load(self) -> Dict[str, Any]:
        """Load configuration from file."""
        if not self.config_file.exists():
            self._config = self.DEFAULT_CONFIG.copy()
            self.save()
            return self._config

        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                self._config = yaml.safe_load(f) or {}
                # Merge with defaults to ensure all keys exist
                self._config = self._merge_with_defaults(self._config)
                return self._config
        except yaml.YAMLError as e:
            raise ConfigError(f"Failed to parse config file: {e}")
        except Exception as e:
            raise ConfigError(f"Failed to load config: {e}")

    def _merge_with_defaults(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Merge loaded config with defaults."""
        merged = self.DEFAULT_CONFIG.copy()

        # Merge top-level keys
        for key in ['default_profile', 'output', 'proxy']:
            if key in config:
                if isinstance(merged.get(key), dict):
                    merged[key].update(config[key])
                else:
                    merged[key] = config[key]

        # Merge profiles
        if 'profiles' in config:
            merged['profiles'].update(config['profiles'])

        return merged

    def save(self):
        """Save configuration to file."""
        if self._config is None:
            raise ConfigError("No configuration loaded")

        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                yaml.safe_dump(self._config, f, default_flow_style=False, allow_unicode=True)
            # Set file permissions to 600 for security
            os.chmod(self.config_file, 0o600)
        except Exception as e:
            raise ConfigError(f"Failed to save config: {e}")

    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value by key (supports dot notation)."""
        if self._config is None:
            self.load()

        keys = key.split('.')
        value = self._config

        for k in keys:
            if isinstance(value, dict):
                value = value.get(k)
                if value is None:
                    return default
            else:
                return default

        return value

    def set(self, key: str, value: Any):
        """Set configuration value by key (supports dot notation)."""
        if self._config is None:
            self.load()

        keys = key.split('.')
        config = self._config

        # Navigate to the parent of the target key
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]

        # Set the value
        config[keys[-1]] = value
        self.save()

    def get_profile(self, profile_name: Optional[str] = None) -> Dict[str, Any]:
        """Get profile configuration."""
        if self._config is None:
            self.load()

        if profile_name is None:
            profile_name = self._config.get('default_profile', 'demo0')

        profiles = self._config.get('profiles', {})
        if profile_name not in profiles:
            raise ProfileNotFoundError(f"Profile '{profile_name}' not found")

        return profiles[profile_name]

    def set_profile(self, profile_name: str, profile_data: Dict[str, Any]):
        """Set or update a profile."""
        if self._config is None:
            self.load()

        if 'profiles' not in self._config:
            self._config['profiles'] = {}

        self._config['profiles'][profile_name] = profile_data
        self.save()

    def delete_profile(self, profile_name: str):
        """Delete a profile."""
        if self._config is None:
            self.load()

        profiles = self._config.get('profiles', {})
        if profile_name not in profiles:
            raise ProfileNotFoundError(f"Profile '{profile_name}' not found")

        # Don't allow deleting the default profile
        if profile_name == self._config.get('default_profile'):
            raise ConfigError("Cannot delete the default profile")

        del self._config['profiles'][profile_name]
        self.save()

    def list_profiles(self) -> list[str]:
        """List all available profiles."""
        if self._config is None:
            self.load()

        return list(self._config.get('profiles', {}).keys())

    def get_default_profile(self) -> str:
        """Get the default profile name."""
        if self._config is None:
            self.load()

        return self._config.get('default_profile', 'demo0')

    def set_default_profile(self, profile_name: str):
        """Set the default profile."""
        if self._config is None:
            self.load()

        profiles = self._config.get('profiles', {})
        if profile_name not in profiles:
            raise ProfileNotFoundError(f"Profile '{profile_name}' not found")

        self._config['default_profile'] = profile_name
        self.save()

    def reset(self):
        """Reset configuration to defaults."""
        self._config = self.DEFAULT_CONFIG.copy()
        self.save()

    def get_output_format(self) -> str:
        """Get output format setting."""
        return self.get('output.format', 'table')

    def set_output_format(self, format: str):
        """Set output format."""
        valid_formats = ['table', 'json', 'yaml', 'csv']
        if format not in valid_formats:
            raise ConfigError(f"Invalid format. Must be one of: {', '.join(valid_formats)}")
        self.set('output.format', format)

    def is_color_enabled(self) -> bool:
        """Check if color output is enabled."""
        return self.get('output.color', True)

    def is_verbose(self) -> bool:
        """Check if verbose output is enabled."""
        return self.get('output.verbose', False)

    def get_proxy_settings(self) -> Dict[str, str]:
        """Get proxy settings."""
        proxy_config = self.get('proxy', {})
        if not proxy_config.get('enabled', False):
            return {}

        proxies = {}
        if proxy_config.get('http'):
            proxies['http'] = proxy_config['http']
        if proxy_config.get('https'):
            proxies['https'] = proxy_config['https']

        return proxies
