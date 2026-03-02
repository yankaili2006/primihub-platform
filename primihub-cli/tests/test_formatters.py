"""Tests for formatters."""

import pytest
from io import StringIO
from primihub_cli.formatters.table import TableFormatter
from primihub_cli.formatters.json import JSONFormatter
from primihub_cli.formatters.yaml import YAMLFormatter
from primihub_cli.formatters.csv import CSVFormatter


class TestTableFormatter:
    """Test cases for TableFormatter."""

    def test_format_dict(self):
        """Test formatting a dictionary."""
        formatter = TableFormatter(color=False)
        data = {'key1': 'value1', 'key2': 'value2'}
        result = formatter.format(data)
        assert 'key1' in result
        assert 'value1' in result

    def test_format_list_of_dicts(self):
        """Test formatting a list of dictionaries."""
        formatter = TableFormatter(color=False)
        data = [
            {'id': 1, 'name': 'test1'},
            {'id': 2, 'name': 'test2'}
        ]
        result = formatter.format(data)
        assert 'test1' in result
        assert 'test2' in result

    def test_format_success_message(self):
        """Test formatting success message."""
        formatter = TableFormatter(color=False)
        result = formatter.format_success("Operation successful")
        assert "Operation successful" in result

    def test_format_error_message(self):
        """Test formatting error message."""
        formatter = TableFormatter(color=False)
        result = formatter.format_error("Operation failed")
        assert "Operation failed" in result

    def test_format_with_color(self):
        """Test formatting with color enabled."""
        formatter = TableFormatter(color=True)
        data = {'key': 'value'}
        result = formatter.format(data)
        assert result is not None


class TestJSONFormatter:
    """Test cases for JSONFormatter."""

    def test_format_dict(self):
        """Test formatting a dictionary as JSON."""
        formatter = JSONFormatter(color=False)
        data = {'key1': 'value1', 'key2': 'value2'}
        result = formatter.format(data)
        assert '"key1"' in result
        assert '"value1"' in result

    def test_format_list(self):
        """Test formatting a list as JSON."""
        formatter = JSONFormatter(color=False)
        data = [{'id': 1}, {'id': 2}]
        result = formatter.format(data)
        assert '"id"' in result
        assert '1' in result

    def test_format_with_indent(self):
        """Test JSON formatting with indentation."""
        formatter = JSONFormatter(color=False)
        data = {'key': 'value'}
        result = formatter.format(data)
        # Should have indentation (pretty print)
        assert '\n' in result

    def test_format_success_message(self):
        """Test formatting success message as JSON."""
        formatter = JSONFormatter(color=False)
        result = formatter.format_success("Success")
        assert '"status"' in result
        assert '"success"' in result

    def test_format_error_message(self):
        """Test formatting error message as JSON."""
        formatter = JSONFormatter(color=False)
        result = formatter.format_error("Error occurred")
        assert '"status"' in result
        assert '"error"' in result


class TestYAMLFormatter:
    """Test cases for YAMLFormatter."""

    def test_format_dict(self):
        """Test formatting a dictionary as YAML."""
        formatter = YAMLFormatter(color=False)
        data = {'key1': 'value1', 'key2': 'value2'}
        result = formatter.format(data)
        assert 'key1:' in result
        assert 'value1' in result

    def test_format_list(self):
        """Test formatting a list as YAML."""
        formatter = YAMLFormatter(color=False)
        data = [{'id': 1, 'name': 'test1'}, {'id': 2, 'name': 'test2'}]
        result = formatter.format(data)
        assert '- id: 1' in result or '- id:' in result
        assert 'test1' in result

    def test_format_nested_structure(self):
        """Test formatting nested structure as YAML."""
        formatter = YAMLFormatter(color=False)
        data = {
            'parent': {
                'child1': 'value1',
                'child2': 'value2'
            }
        }
        result = formatter.format(data)
        assert 'parent:' in result
        assert 'child1:' in result

    def test_format_success_message(self):
        """Test formatting success message as YAML."""
        formatter = YAMLFormatter(color=False)
        result = formatter.format_success("Operation completed")
        assert 'status:' in result
        assert 'success' in result


class TestCSVFormatter:
    """Test cases for CSVFormatter."""

    def test_format_list_of_dicts(self):
        """Test formatting list of dictionaries as CSV."""
        formatter = CSVFormatter(color=False)
        data = [
            {'id': 1, 'name': 'test1', 'value': 100},
            {'id': 2, 'name': 'test2', 'value': 200}
        ]
        result = formatter.format(data)
        assert 'id,name,value' in result
        assert '1,test1,100' in result
        assert '2,test2,200' in result

    def test_format_empty_list(self):
        """Test formatting empty list as CSV."""
        formatter = CSVFormatter(color=False)
        data = []
        result = formatter.format(data)
        assert result == "No data to display"

    def test_format_single_dict(self):
        """Test formatting single dictionary as CSV."""
        formatter = CSVFormatter(color=False)
        data = {'key1': 'value1', 'key2': 'value2'}
        result = formatter.format(data)
        assert 'key1,key2' in result or 'Key,Value' in result

    def test_format_with_special_characters(self):
        """Test CSV formatting with special characters."""
        formatter = CSVFormatter(color=False)
        data = [
            {'id': 1, 'name': 'test,with,comma'},
            {'id': 2, 'name': 'test"with"quotes'}
        ]
        result = formatter.format(data)
        # CSV should properly escape special characters
        assert result is not None

    def test_format_success_message(self):
        """Test formatting success message as CSV."""
        formatter = CSVFormatter(color=False)
        result = formatter.format_success("Success")
        assert 'Success' in result

    def test_format_with_missing_fields(self):
        """Test CSV formatting with missing fields in some rows."""
        formatter = CSVFormatter(color=False)
        data = [
            {'id': 1, 'name': 'test1', 'value': 100},
            {'id': 2, 'name': 'test2'}  # missing 'value'
        ]
        result = formatter.format(data)
        # Should handle missing fields gracefully
        assert 'id,name,value' in result
        assert '2,test2' in result


class TestFormatterFactory:
    """Test formatter selection based on format type."""

    def test_get_table_formatter(self):
        """Test getting table formatter."""
        from primihub_cli.formatters.table import TableFormatter
        formatter = TableFormatter()
        assert isinstance(formatter, TableFormatter)

    def test_get_json_formatter(self):
        """Test getting JSON formatter."""
        from primihub_cli.formatters.json import JSONFormatter
        formatter = JSONFormatter()
        assert isinstance(formatter, JSONFormatter)

    def test_get_yaml_formatter(self):
        """Test getting YAML formatter."""
        from primihub_cli.formatters.yaml import YAMLFormatter
        formatter = YAMLFormatter()
        assert isinstance(formatter, YAMLFormatter)

    def test_get_csv_formatter(self):
        """Test getting CSV formatter."""
        from primihub_cli.formatters.csv import CSVFormatter
        formatter = CSVFormatter()
        assert isinstance(formatter, CSVFormatter)
