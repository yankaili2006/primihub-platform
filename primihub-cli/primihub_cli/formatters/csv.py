"""CSV output formatter."""

import csv
import io
from typing import Any, List, Optional

from .base import BaseFormatter


class CSVFormatter(BaseFormatter):
    """Format output as CSV."""

    def format(self, data: Any, columns: Optional[List[str]] = None) -> str:
        """
        Format data as CSV.

        Args:
            data: Data to format (list of dicts)
            columns: Column names to include

        Returns:
            CSV formatted string
        """
        normalized = self.normalize_data(data)

        # Handle empty data
        if not normalized:
            return ""

        # Handle single dict - convert to list
        if isinstance(normalized, dict):
            normalized = [normalized]

        # Handle list of dicts
        if isinstance(normalized, list) and len(normalized) > 0:
            if isinstance(normalized[0], dict):
                return self._format_list_of_dicts(normalized, columns)

        # For other types, return string representation
        return str(normalized)

    def _format_list_of_dicts(self, data: List[dict], columns: Optional[List[str]] = None) -> str:
        """Format list of dictionaries as CSV."""
        if not data:
            return ""

        # Determine columns
        if columns is None:
            columns = list(data[0].keys())

        # Create CSV in memory
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=columns, extrasaction='ignore')

        # Write header
        writer.writeheader()

        # Write rows
        for item in data:
            writer.writerow(item)

        return output.getvalue()

    def format_error(self, message: str) -> str:
        """Format error message as CSV."""
        return f"error\n{message}"

    def format_success(self, message: str) -> str:
        """Format success message as CSV."""
        return f"status,message\nsuccess,{message}"

    def format_warning(self, message: str) -> str:
        """Format warning message as CSV."""
        return f"warning\n{message}"
