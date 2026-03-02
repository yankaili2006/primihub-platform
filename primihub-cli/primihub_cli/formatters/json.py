"""JSON output formatter."""

import json
from typing import Any, List, Optional

from .base import BaseFormatter


class JSONFormatter(BaseFormatter):
    """Format output as JSON."""

    def format(self, data: Any, columns: Optional[List[str]] = None) -> str:
        """
        Format data as JSON.

        Args:
            data: Data to format
            columns: Ignored for JSON output

        Returns:
            JSON formatted string
        """
        normalized = self.normalize_data(data)
        return json.dumps(normalized, indent=2, ensure_ascii=False)

    def format_error(self, message: str) -> str:
        """Format error message as JSON."""
        return json.dumps({"error": message}, indent=2)

    def format_success(self, message: str) -> str:
        """Format success message as JSON."""
        return json.dumps({"success": True, "message": message}, indent=2)

    def format_warning(self, message: str) -> str:
        """Format warning message as JSON."""
        return json.dumps({"warning": message}, indent=2)
