"""YAML output formatter."""

from typing import Any, List, Optional

import yaml

from .base import BaseFormatter


class YAMLFormatter(BaseFormatter):
    """Format output as YAML."""

    def format(self, data: Any, columns: Optional[List[str]] = None) -> str:
        """
        Format data as YAML.

        Args:
            data: Data to format
            columns: Ignored for YAML output

        Returns:
            YAML formatted string
        """
        normalized = self.normalize_data(data)
        return yaml.safe_dump(
            normalized,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False
        )

    def format_error(self, message: str) -> str:
        """Format error message as YAML."""
        return yaml.safe_dump({"error": message})

    def format_success(self, message: str) -> str:
        """Format success message as YAML."""
        return yaml.safe_dump({"success": True, "message": message})

    def format_warning(self, message: str) -> str:
        """Format warning message as YAML."""
        return yaml.safe_dump({"warning": message})
