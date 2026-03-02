"""Table output formatter using Rich."""

from typing import Any, List, Optional

from rich.console import Console
from rich.table import Table

from .base import BaseFormatter


class TableFormatter(BaseFormatter):
    """Format output as table using Rich."""

    def __init__(self, color: bool = True):
        """Initialize table formatter."""
        super().__init__(color)
        self.console = Console(force_terminal=color, no_color=not color)

    def format(self, data: Any, columns: Optional[List[str]] = None) -> str:
        """
        Format data as table.

        Args:
            data: Data to format (dict or list of dicts)
            columns: Column names to display (optional)

        Returns:
            Table formatted string
        """
        normalized = self.normalize_data(data)

        # Handle empty data
        if not normalized:
            return "No data"

        # Handle single dict
        if isinstance(normalized, dict):
            return self._format_dict(normalized)

        # Handle list of dicts
        if isinstance(normalized, list):
            if len(normalized) == 0:
                return "No data"
            if isinstance(normalized[0], dict):
                return self._format_list_of_dicts(normalized, columns)
            else:
                return self._format_list(normalized)

        # Handle primitive types
        return str(normalized)

    def _format_dict(self, data: dict) -> str:
        """Format single dictionary as key-value table."""
        table = Table(show_header=True, header_style="bold cyan")
        table.add_column("Key", style="cyan")
        table.add_column("Value", style="white")

        for key, value in data.items():
            table.add_row(str(key), str(value))

        # Capture table output
        with self.console.capture() as capture:
            self.console.print(table)

        return capture.get().rstrip()

    def _format_list_of_dicts(self, data: List[dict], columns: Optional[List[str]] = None) -> str:
        """Format list of dictionaries as table."""
        if not data:
            return "No data"

        # Determine columns
        if columns is None:
            # Use keys from first item
            columns = list(data[0].keys())

        # Create table
        table = Table(show_header=True, header_style="bold cyan")

        for col in columns:
            table.add_column(str(col), style="white")

        # Add rows
        for item in data:
            row = [str(item.get(col, '')) for col in columns]
            table.add_row(*row)

        # Capture table output
        with self.console.capture() as capture:
            self.console.print(table)

        return capture.get().rstrip()

    def _format_list(self, data: List[Any]) -> str:
        """Format simple list."""
        return '\n'.join(str(item) for item in data)

    def format_error(self, message: str) -> str:
        """Format error message with color."""
        if self.color:
            with self.console.capture() as capture:
                self.console.print(f"[bold red]Error:[/bold red] {message}")
            return capture.get().rstrip()
        return f"Error: {message}"

    def format_success(self, message: str) -> str:
        """Format success message with color."""
        if self.color:
            with self.console.capture() as capture:
                self.console.print(f"[bold green]✓[/bold green] {message}")
            return capture.get().rstrip()
        return message

    def format_warning(self, message: str) -> str:
        """Format warning message with color."""
        if self.color:
            with self.console.capture() as capture:
                self.console.print(f"[bold yellow]Warning:[/bold yellow] {message}")
            return capture.get().rstrip()
        return f"Warning: {message}"
