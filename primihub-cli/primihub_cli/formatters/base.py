"""Base formatter for output formatting."""

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional


class BaseFormatter(ABC):
    """Abstract base class for output formatters."""

    def __init__(self, color: bool = True):
        """
        Initialize formatter.

        Args:
            color: Enable color output
        """
        self.color = color

    @abstractmethod
    def format(self, data: Any, columns: Optional[List[str]] = None) -> str:
        """
        Format data for output.

        Args:
            data: Data to format (dict, list, or primitive)
            columns: Column names for table-like output (optional)

        Returns:
            Formatted string
        """
        pass

    def format_error(self, message: str) -> str:
        """
        Format error message.

        Args:
            message: Error message

        Returns:
            Formatted error string
        """
        return f"Error: {message}"

    def format_success(self, message: str) -> str:
        """
        Format success message.

        Args:
            message: Success message

        Returns:
            Formatted success string
        """
        return message

    def format_warning(self, message: str) -> str:
        """
        Format warning message.

        Args:
            message: Warning message

        Returns:
            Formatted warning string
        """
        return f"Warning: {message}"

    @staticmethod
    def normalize_data(data: Any) -> Any:
        """
        Normalize data structure for formatting.

        Args:
            data: Raw data

        Returns:
            Normalized data
        """
        # If data is a dict with 'result' or 'data' key, extract it
        if isinstance(data, dict):
            if 'result' in data:
                return data['result']
            elif 'data' in data:
                return data['data']

        return data

    @staticmethod
    def flatten_dict(data: Dict[str, Any], parent_key: str = '', sep: str = '.') -> Dict[str, Any]:
        """
        Flatten nested dictionary.

        Args:
            data: Dictionary to flatten
            parent_key: Parent key prefix
            sep: Separator for nested keys

        Returns:
            Flattened dictionary
        """
        items = []
        for k, v in data.items():
            new_key = f"{parent_key}{sep}{k}" if parent_key else k
            if isinstance(v, dict):
                items.extend(BaseFormatter.flatten_dict(v, new_key, sep=sep).items())
            else:
                items.append((new_key, v))
        return dict(items)
