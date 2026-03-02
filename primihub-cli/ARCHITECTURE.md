# PrimiHub CLI Architecture

Technical architecture and design documentation for the PrimiHub CLI.

## Overview

The PrimiHub CLI is a modern, modular command-line interface built with Python that provides comprehensive access to the PrimiHub platform's 200+ API endpoints. The architecture follows clean code principles with clear separation of concerns.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         CLI Layer                            │
│  (Click Commands - User Interface)                          │
│  - auth, user, organ, project, resource                     │
│  - psi, pir, fl, task, node                                 │
│  - data, system, fusion, share, log, monitor, config        │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                    Command Layer                             │
│  (Command Handlers - Business Logic)                        │
│  - Input validation                                         │
│  - API orchestration                                        │
│  - Output formatting                                        │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                      API Layer                               │
│  (API Modules - HTTP Communication)                         │
│  - AuthAPI, UserAPI, ProjectAPI, PSIAPI, etc.              │
│  - Request construction                                     │
│  - Response parsing                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                     Core Layer                               │
│  - PrimiHubClient (HTTP client)                            │
│  - Config (configuration management)                        │
│  - Session (authentication persistence)                     │
│  - Exceptions (error handling)                              │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  Formatter Layer                             │
│  - TableFormatter (Rich tables)                             │
│  - JSONFormatter (JSON output)                              │
│  - YAMLFormatter (YAML output)                              │
│  - CSVFormatter (CSV output)                                │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
primihub-cli/
├── primihub_cli/              # Main package
│   ├── __init__.py
│   ├── __main__.py            # Entry point
│   ├── cli.py                 # CLI root command
│   │
│   ├── core/                  # Core modules (4 files)
│   │   ├── client.py          # HTTP client
│   │   ├── config.py          # Configuration management
│   │   ├── session.py         # Session persistence
│   │   ├── exceptions.py      # Custom exceptions
│   │   └── utils.py           # Utility functions
│   │
│   ├── api/                   # API modules (18 files)
│   │   ├── auth.py            # Authentication
│   │   ├── user.py            # User management
│   │   ├── organ.py           # Organization management
│   │   ├── project.py         # Project management
│   │   ├── resource.py        # Resource management
│   │   ├── psi.py             # PSI tasks
│   │   ├── pir.py             # PIR tasks
│   │   ├── fl.py              # Federated learning
│   │   ├── task.py            # General tasks
│   │   ├── node.py            # Node management
│   │   ├── data.py            # Data management
│   │   ├── system.py          # System management
│   │   ├── fusion.py          # Fusion resources
│   │   ├── share.py           # Data sharing
│   │   ├── log.py             # Log query
│   │   ├── monitor.py         # Monitoring
│   │   ├── model.py           # Model management
│   │   └── common.py          # Common utilities
│   │
│   ├── commands/              # Command handlers (17 files)
│   │   ├── auth.py            # Auth commands
│   │   ├── user.py            # User commands
│   │   ├── organ.py           # Organ commands
│   │   ├── project.py         # Project commands
│   │   ├── resource.py        # Resource commands
│   │   ├── psi.py             # PSI commands
│   │   ├── pir.py             # PIR commands
│   │   ├── fl.py              # FL commands
│   │   ├── task.py            # Task commands
│   │   ├── node.py            # Node commands
│   │   ├── data.py            # Data commands
│   │   ├── system.py          # System commands
│   │   ├── fusion.py          # Fusion commands
│   │   ├── share.py           # Share commands
│   │   ├── log.py             # Log commands
│   │   ├── monitor.py         # Monitor commands
│   │   └── config.py          # Config commands
│   │
│   └── formatters/            # Output formatters (5 files)
│       ├── base.py            # Base formatter
│       ├── table.py           # Table output
│       ├── json.py            # JSON output
│       ├── yaml.py            # YAML output
│       └── csv.py             # CSV output
│
├── tests/                     # Test suite
│   ├── conftest.py            # Test fixtures
│   ├── test_client.py         # Client tests
│   ├── test_config.py         # Config tests
│   ├── test_session.py        # Session tests
│   ├── test_formatters.py     # Formatter tests
│   └── test_api_integration.py # Integration tests
│
├── setup.py                   # Package setup
├── requirements.txt           # Dependencies
├── requirements-test.txt      # Test dependencies
├── pytest.ini                 # Pytest configuration
├── README.md                  # Quick start guide
├── USAGE.md                   # Detailed usage guide
├── ARCHITECTURE.md            # This file
└── CONTRIBUTING.md            # Contribution guide
```

## Core Components

### 1. PrimiHubClient (core/client.py)

The HTTP client is the foundation of all API communication.

**Key Features:**
- Unified request/response handling
- Automatic token injection
- Smart proxy detection for private networks
- Automatic retry on network errors (up to 3 times)
- Request/response logging
- Error handling and exception mapping

**Design Decisions:**
- Uses `requests.Session` for connection pooling
- Form data encoding for most endpoints (not JSON)
- URL construction: `base_url + endpoint` (not urljoin)
- Content-Type: `application/x-www-form-urlencoded`

**Example:**
```python
client = PrimiHubClient(
    base_url='http://localhost:30811/prod-api',
    token='abc123'
)
response = client.post('/user/login', data={
    'userAccount': 'admin',
    'userPassword': '123456'
})
```

### 2. Config (core/config.py)

Configuration management with multi-profile support.

**Key Features:**
- YAML-based configuration (~/.primihub/config.yaml)
- Multiple environment profiles (demo0, demo1, demo2)
- Output format preferences (table, json, yaml, csv)
- Profile switching
- Default values

**Configuration Structure:**
```yaml
default_profile: demo0

profiles:
  demo0:
    base_url: http://localhost:30811/prod-api
    organ_id: 1
    organ_name: demo0

output:
  format: table
  color: true
  verbose: false
```

### 3. Session (core/session.py)

Session persistence for authentication tokens.

**Key Features:**
- Token storage (~/.primihub/session)
- Expiration tracking (24 hours default)
- Automatic validation
- Secure file permissions (600)
- Profile association

**Session Structure:**
```json
{
  "token": "abc123...",
  "user_info": {
    "userId": 1,
    "userName": "admin",
    "organId": 1
  },
  "profile": "demo0",
  "expires_at": "2026-03-03T10:00:00"
}
```

### 4. Exception Hierarchy (core/exceptions.py)

Custom exception hierarchy for error handling.

```
PrimiHubError (base)
├── APIError
│   ├── AuthenticationError (401)
│   ├── PermissionError (403)
│   └── NotFoundError (404)
├── ConfigError
├── SessionError
└── ValidationError
```

## API Layer Design

Each API module follows a consistent pattern:

```python
class ExampleAPI:
    def __init__(self, client: PrimiHubClient):
        self.client = client

    def list_items(self, page_no: int = 1, page_size: int = 10):
        response = self.client.get('/example/list', params={
            'pageNo': page_no,
            'pageSize': page_size
        })
        return response

    def create_item(self, name: str, desc: Optional[str] = None):
        data = {'name': name}
        if desc:
            data['desc'] = desc
        response = self.client.post('/example/create', data=data)
        return response
```

**Design Principles:**
- One API module per functional domain
- Methods map directly to API endpoints
- Type hints for all parameters
- Optional parameters with defaults
- Return raw API response (no transformation)

## Command Layer Design

Command handlers bridge the CLI and API layers:

```python
@click.group()
def example():
    """Example commands."""
    pass

@example.command()
@click.option('--name', required=True)
def create(name):
    """Create an example item."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        api = ExampleAPI(client)

        response = api.create_item(name)

        formatter = get_formatter(config)
        click.echo(formatter.format_success("Created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
```

**Design Principles:**
- Click decorators for argument parsing
- Config loading for each command
- Client creation from config
- Formatter selection based on config
- Consistent error handling
- User-friendly output

## Formatter Layer Design

Formatters provide flexible output options:

```python
class BaseFormatter:
    def format(self, data):
        raise NotImplementedError

    def format_success(self, message):
        raise NotImplementedError

    def format_error(self, message):
        raise NotImplementedError
```

**Implementations:**
- **TableFormatter**: Rich tables with colors
- **JSONFormatter**: Pretty-printed JSON
- **YAMLFormatter**: Human-readable YAML
- **CSVFormatter**: Spreadsheet-compatible CSV

## Data Flow

### 1. Authentication Flow

```
User Input → Login Command → AuthAPI.login()
  → PrimiHubClient.post('/user/login')
  → API Response
  → Session.save(token, user_info)
  → Success Message
```

### 2. List Operation Flow

```
User Input → List Command → API.list_items()
  → PrimiHubClient.get('/items/list')
  → API Response
  → Formatter.format(data)
  → Terminal Output
```

### 3. Create Operation Flow

```
User Input → Create Command → API.create_item()
  → PrimiHubClient.post('/items/create')
  → API Response
  → Formatter.format_success()
  → Terminal Output
```

## Security Considerations

### 1. Token Storage

- Stored in `~/.primihub/session`
- File permissions: 600 (owner read/write only)
- Automatic expiration after 24 hours
- Cleared on logout

### 2. Password Handling

- Never stored or logged
- Passed directly to API
- Cleared from memory after use

### 3. Network Security

- HTTPS support
- Proxy bypass for private networks
- No credential transmission over insecure channels

### 4. Input Validation

- Type checking via Click
- Required parameter enforcement
- Format validation (email, URLs, etc.)

## Performance Optimizations

### 1. Connection Pooling

- `requests.Session` for persistent connections
- Reduces connection overhead
- Improves response time

### 2. Smart Proxy Detection

- Automatic bypass for private networks
- Reduces latency for local deployments
- Configurable proxy settings

### 3. Lazy Loading

- Config loaded only when needed
- Session loaded only when needed
- Formatters instantiated on demand

### 4. Efficient Output

- Streaming for large datasets
- Pagination support
- Configurable page sizes

## Error Handling Strategy

### 1. Network Errors

- Automatic retry (up to 3 times)
- Exponential backoff
- Clear error messages

### 2. API Errors

- Status code mapping to exceptions
- Detailed error messages from API
- User-friendly error display

### 3. Validation Errors

- Early validation in commands
- Clear parameter requirements
- Helpful error messages

### 4. Configuration Errors

- Default values for missing config
- Validation on config load
- Reset to defaults option

## Testing Strategy

### 1. Unit Tests

- Core modules (client, config, session)
- Formatters
- Utility functions
- Mock external dependencies

### 2. Integration Tests

- API modules with mocked HTTP
- Command handlers with mocked APIs
- End-to-end workflows

### 3. Test Coverage

- Target: >80% code coverage
- Focus on critical paths
- Edge cases and error conditions

### 4. Test Fixtures

- Shared test data
- Mock responses
- Temporary directories

## Extension Points

### 1. Adding New Commands

```python
# 1. Create API module
class NewAPI:
    def __init__(self, client):
        self.client = client

# 2. Create command handler
@click.group()
def new():
    """New commands."""
    pass

# 3. Register in cli.py
from .commands.new import new
cli.add_command(new, name='new')
```

### 2. Adding New Formatters

```python
# 1. Inherit from BaseFormatter
class CustomFormatter(BaseFormatter):
    def format(self, data):
        # Custom formatting logic
        pass

# 2. Register in formatter factory
FORMATTERS = {
    'custom': CustomFormatter
}
```

### 3. Adding New Profiles

```bash
primihub config add-profile production \
  --base-url https://prod.example.com/api \
  --organ-id 1
```

## Dependencies

### Core Dependencies

- **Click 8.0+**: Command-line framework
- **Rich 13.0+**: Terminal formatting
- **PyYAML 6.0+**: Configuration files
- **Requests 2.28+**: HTTP client

### Test Dependencies

- **pytest 7.0+**: Testing framework
- **pytest-cov 4.0+**: Coverage reporting
- **pytest-mock 3.10+**: Mocking utilities

## Future Enhancements

### Phase 7 (Potential)

1. **Interactive REPL Mode**
   - Command history
   - Auto-completion
   - Context-aware suggestions

2. **Plugin System**
   - Third-party extensions
   - Custom commands
   - Custom formatters

3. **GUI Mode**
   - Textual-based TUI
   - Interactive forms
   - Real-time monitoring

4. **Performance Improvements**
   - Async HTTP requests
   - Parallel operations
   - Caching layer

5. **Enhanced Monitoring**
   - Real-time dashboards
   - Alert notifications
   - Performance profiling

## Conclusion

The PrimiHub CLI architecture is designed for:
- **Modularity**: Clear separation of concerns
- **Extensibility**: Easy to add new features
- **Maintainability**: Clean code structure
- **Testability**: Comprehensive test coverage
- **Usability**: Intuitive command structure
- **Performance**: Efficient operations

The architecture supports the current 200+ API endpoints and can easily scale to accommodate future growth.
