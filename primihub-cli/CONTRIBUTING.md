# Contributing to PrimiHub CLI

Thank you for your interest in contributing to PrimiHub CLI! This guide will help you get started.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Project Structure](#project-structure)
5. [Coding Standards](#coding-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Submitting Changes](#submitting-changes)
8. [Adding New Features](#adding-new-features)
9. [Documentation](#documentation)
10. [Release Process](#release-process)

## Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. Please be respectful and professional in all interactions.

## Getting Started

### Prerequisites

- Python 3.8 or higher
- Git
- Basic understanding of REST APIs
- Familiarity with Click framework (helpful but not required)

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/primihub-platform.git
cd primihub-platform/primihub-cli

# Add upstream remote
git remote add upstream https://github.com/primihub/primihub-platform.git
```

## Development Setup

### 1. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies

```bash
# Install runtime dependencies
pip install -r requirements.txt

# Install test dependencies
pip install -r requirements-test.txt

# Install in development mode
pip install -e .
```

### 3. Verify Installation

```bash
# Run tests
pytest

# Check code style
flake8 primihub_cli/
black --check primihub_cli/

# Run CLI
python3 -m primihub_cli --help
```

## Project Structure

```
primihub-cli/
├── primihub_cli/          # Main package
│   ├── core/              # Core modules (client, config, session)
│   ├── api/               # API modules (one per domain)
│   ├── commands/          # Command handlers (one per command group)
│   └── formatters/        # Output formatters
├── tests/                 # Test suite
├── docs/                  # Documentation
└── setup.py               # Package configuration
```

### Key Files

- `primihub_cli/cli.py`: Main CLI entry point
- `primihub_cli/core/client.py`: HTTP client
- `primihub_cli/core/config.py`: Configuration management
- `primihub_cli/core/session.py`: Session persistence

## Coding Standards

### Python Style Guide

We follow PEP 8 with some modifications:

- Line length: 100 characters (not 79)
- Use double quotes for strings
- Use type hints for function parameters and return values
- Use docstrings for all public functions and classes

### Code Formatting

```bash
# Format code with Black
black primihub_cli/

# Check with flake8
flake8 primihub_cli/

# Type checking with mypy
mypy primihub_cli/
```

### Naming Conventions

- **Files**: lowercase with underscores (`user_api.py`)
- **Classes**: PascalCase (`UserAPI`, `PrimiHubClient`)
- **Functions**: snake_case (`list_users`, `create_project`)
- **Constants**: UPPER_CASE (`DEFAULT_PAGE_SIZE`)
- **Private**: prefix with underscore (`_internal_method`)

### Docstring Format

```python
def create_user(username: str, password: str, email: Optional[str] = None) -> Dict[str, Any]:
    """
    Create a new user.

    Args:
        username: User's username
        password: User's password
        email: User's email address (optional)

    Returns:
        API response containing user ID

    Raises:
        APIError: If the API request fails
        ValidationError: If parameters are invalid
    """
    pass
```

## Testing Guidelines

### Writing Tests

1. **Unit Tests**: Test individual functions/methods
2. **Integration Tests**: Test API modules with mocked HTTP
3. **End-to-End Tests**: Test complete workflows

### Test Structure

```python
class TestUserAPI:
    """Test cases for UserAPI."""

    def test_list_users_success(self, mock_client):
        """Test successful user listing."""
        # Arrange
        api = UserAPI(mock_client)

        # Act
        response = api.list_users()

        # Assert
        assert response['code'] == 0
        assert 'list' in response['result']

    def test_list_users_with_pagination(self, mock_client):
        """Test user listing with pagination."""
        # Test implementation
        pass
```

### Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_client.py

# Run with coverage
pytest --cov=primihub_cli --cov-report=html

# Run specific test
pytest tests/test_client.py::TestPrimiHubClient::test_url_construction
```

### Test Coverage

- Aim for >80% code coverage
- All new features must include tests
- Critical paths must have 100% coverage

## Submitting Changes

### Branch Naming

- Feature: `feature/add-new-command`
- Bug fix: `fix/authentication-error`
- Documentation: `docs/update-usage-guide`
- Refactor: `refactor/improve-client`

### Commit Messages

Follow conventional commits format:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(user): add user deletion command

Add new command to delete users by ID with confirmation prompt.

Closes #123
```

```
fix(client): correct URL construction for API endpoints

Previously using urljoin which dropped the /prod-api prefix.
Now using string concatenation for correct URL building.

Fixes #456
```

### Pull Request Process

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. **Make changes**
   - Write code
   - Add tests
   - Update documentation

4. **Run tests and checks**
   ```bash
   pytest
   flake8 primihub_cli/
   black --check primihub_cli/
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/my-new-feature
   ```

7. **Create Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Fill in the template
   - Request review

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally
```

## Adding New Features

### Adding a New Command

1. **Create API Module** (`primihub_cli/api/example.py`)

```python
"""Example API module."""

from typing import Dict, Any
from ..core.client import PrimiHubClient

class ExampleAPI:
    """Example API operations."""

    def __init__(self, client: PrimiHubClient):
        self.client = client

    def list_items(self, page_no: int = 1, page_size: int = 10) -> Dict[str, Any]:
        """List items with pagination."""
        response = self.client.get('/example/list', params={
            'pageNo': page_no,
            'pageSize': page_size
        })
        return response
```

2. **Create Command Handler** (`primihub_cli/commands/example.py`)

```python
"""Example commands."""

import click
from ..api.example import ExampleAPI
from ..core.client import PrimiHubClient
from ..core.config import Config
from ..core.exceptions import PrimiHubError

@click.group()
def example():
    """Example commands."""
    pass

@example.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
def list(page, size):
    """List items."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        api = ExampleAPI(client)

        response = api.list_items(page_no=page, page_size=size)
        # Format and display output

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
```

3. **Register Command** (`primihub_cli/cli.py`)

```python
from .commands.example import example

cli.add_command(example, name='example')
```

4. **Add Tests** (`tests/test_example.py`)

```python
"""Tests for example module."""

import pytest
from primihub_cli.api.example import ExampleAPI

class TestExampleAPI:
    def test_list_items(self, mock_client):
        api = ExampleAPI(mock_client)
        response = api.list_items()
        assert response is not None
```

5. **Update Documentation**
   - Add to README.md
   - Add to USAGE.md
   - Update API.md

### Adding a New Formatter

1. **Create Formatter** (`primihub_cli/formatters/custom.py`)

```python
"""Custom formatter."""

from .base import BaseFormatter

class CustomFormatter(BaseFormatter):
    def format(self, data):
        """Format data in custom format."""
        # Implementation
        pass
```

2. **Register Formatter**

Update formatter factory to include new formatter.

3. **Add Tests**

```python
def test_custom_formatter():
    formatter = CustomFormatter()
    result = formatter.format({'key': 'value'})
    assert result is not None
```

## Documentation

### Documentation Standards

- All public APIs must have docstrings
- Complex logic should have inline comments
- User-facing features need usage examples
- Architecture changes need design docs

### Documentation Files

- **README.md**: Quick start and overview
- **USAGE.md**: Detailed usage guide
- **ARCHITECTURE.md**: Technical architecture
- **API.md**: API reference
- **CONTRIBUTING.md**: This file

### Updating Documentation

When adding features:
1. Update relevant .md files
2. Add code examples
3. Update command reference
4. Add troubleshooting tips if needed

## Release Process

### Version Numbers

We follow Semantic Versioning (SemVer):
- MAJOR.MINOR.PATCH (e.g., 2.0.0)
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Release Checklist

1. **Update version**
   - Update `setup.py`
   - Update `cli.py` version

2. **Update CHANGELOG**
   - Document all changes
   - Group by type (Added, Changed, Fixed, Removed)

3. **Run full test suite**
   ```bash
   pytest
   flake8 primihub_cli/
   black --check primihub_cli/
   ```

4. **Create release tag**
   ```bash
   git tag -a v2.0.0 -m "Release version 2.0.0"
   git push origin v2.0.0
   ```

5. **Build and publish**
   ```bash
   python setup.py sdist bdist_wheel
   twine upload dist/*
   ```

## Getting Help

### Resources

- **Documentation**: Read USAGE.md and ARCHITECTURE.md
- **Issues**: Check existing issues on GitHub
- **Discussions**: Join project discussions

### Asking Questions

When asking for help:
1. Search existing issues first
2. Provide clear description
3. Include error messages
4. Share relevant code snippets
5. Describe expected vs actual behavior

### Reporting Bugs

Include:
- Python version
- CLI version
- Operating system
- Steps to reproduce
- Error messages
- Expected behavior

## Code Review Guidelines

### For Contributors

- Respond to feedback promptly
- Be open to suggestions
- Explain your reasoning
- Update PR based on feedback

### For Reviewers

- Be constructive and respectful
- Explain the "why" behind suggestions
- Approve when ready
- Request changes if needed

## Best Practices

1. **Keep PRs focused**: One feature/fix per PR
2. **Write tests first**: TDD when possible
3. **Document as you go**: Don't leave it for later
4. **Ask questions**: Better to ask than assume
5. **Review your own code**: Self-review before submitting
6. **Keep commits atomic**: One logical change per commit
7. **Update dependencies carefully**: Test thoroughly

## Common Pitfalls

1. **Not reading existing code**: Understand patterns first
2. **Skipping tests**: Always write tests
3. **Ignoring style guide**: Run formatters
4. **Large PRs**: Break into smaller pieces
5. **Missing documentation**: Update docs with code

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in commit history

Thank you for contributing to PrimiHub CLI!
