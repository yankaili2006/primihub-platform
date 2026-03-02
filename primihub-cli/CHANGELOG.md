# Changelog

All notable changes to PrimiHub CLI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-02

### Added

#### Phase 1: Core Framework
- Modular architecture with 60+ file structure
- Configuration management system (~/.primihub/config.yaml)
- Session persistence with token management (~/.primihub/session)
- Multi-profile support (demo0, demo1, demo2)
- Smart proxy detection for private networks
- Token-based authentication with auto-renewal
- Custom exception hierarchy for error handling
- HTTP client with automatic retry mechanism

#### Phase 2: Basic CRUD Operations
- User management commands (list, get, create, update, delete)
- Organization management commands (list, get, create, update, delete)
- Project management commands (list, get, create, update, delete)
- Resource management commands (list, get, create, update, delete)
- Pagination support for all list operations
- Multiple output formats (table, json)

#### Phase 3: Privacy Computing Tasks
- PSI task management (create, list, status, cancel, result, download)
- PIR task management (create, list, status, cancel, download)
- FL task management (create, list, status, cancel, logs, progress)
- FL model management (list models, get model details)
- Task monitoring and result retrieval
- Support for multiple algorithms (dh, ecdh, kkrt, rr22 for PSI; xgboost for FL)

#### Phase 4: Advanced Features
- YAML output formatter
- CSV output formatter
- Configuration management commands (show, set, get, reset)
- Profile management (list, add, delete, set default)
- Enhanced output format support (table/json/yaml/csv)
- Color output control
- Verbose mode

#### Phase 5: Extended API Coverage
- General task management (list, get, status, logs, cancel, retry, delete)
- Node management (list, get, status, register, update, delete, connect, disconnect, connections)
- Data management (list, get, fields, preview, upload, delete, statistics)
- System management (info, status, config, logs, metrics, health, version, services, backup, restore)
- Fusion resource management (list, get, create, update, delete, status, execute, result)
- Data sharing management (requests, approve, reject, cancel, shared resources, permissions)
- Log query (system, task, node, audit logs with filtering and export)
- Monitoring statistics (dashboard, task/resource/node stats, performance, alerts)
- Alert rule management (set, list, delete)

#### Phase 6: Testing and Documentation
- Unit tests for core modules (client, config, session)
- Unit tests for formatters (table, json, yaml, csv)
- Integration tests for API modules
- Test fixtures and shared test utilities
- Pytest configuration with coverage reporting
- Comprehensive usage guide (USAGE.md)
- Architecture documentation (ARCHITECTURE.md)
- Contribution guide (CONTRIBUTING.md)
- Test requirements file
- Code quality tools setup (flake8, black, mypy)

### Changed

- Improved URL construction to preserve /prod-api prefix
- Enhanced Content-Type header handling for form data
- Updated API endpoint paths based on actual backend implementation
- Improved error messages for better user experience
- Optimized session expiration handling

### Fixed

- URL construction bug that dropped /prod-api prefix
- Content-Type header issue preventing proper form data encoding
- Authentication endpoint path (/user/login instead of /sys/user/login)
- Response structure parsing (result.sysUser instead of result.userInfo)
- Session file permissions for security (600)

### Security

- Secure token storage with file permissions
- Automatic session expiration after 24 hours
- No password storage or logging
- Smart proxy bypass for private networks

## [1.0.0] - Legacy

### Legacy CLI (primihub-cli.py)
- Single-file CLI with 2338 lines
- Basic authentication and task management
- Limited API coverage
- No modular architecture

---

## Migration Guide from v1.0 to v2.0

### Breaking Changes

1. **Command Structure**: Commands are now organized into groups
   - Old: `primihub-cli.py --login`
   - New: `python3 -m primihub_cli login`

2. **Configuration**: New YAML-based configuration
   - Old: Command-line arguments only
   - New: ~/.primihub/config.yaml with profiles

3. **Session Management**: Automatic token persistence
   - Old: Manual token management
   - New: Automatic session storage and renewal

### New Features

- 17 command groups with 85+ commands
- 200+ API endpoint coverage
- Multiple output formats (table/json/yaml/csv)
- Multi-environment support with profiles
- Comprehensive error handling
- Extensive documentation

### Migration Steps

1. **Install new CLI**
   ```bash
   cd primihub-platform/primihub-cli
   pip3 install -r requirements.txt
   ```

2. **Configure profiles**
   ```bash
   python3 -m primihub_cli config add-profile demo0 \
     --base-url http://localhost:30811/prod-api \
     --organ-id 1
   ```

3. **Login**
   ```bash
   python3 -m primihub_cli login
   ```

4. **Update scripts**
   - Replace old command syntax with new command groups
   - Use --format json for scripting
   - Leverage session persistence

## Statistics

### Project Metrics

- **Total Files**: 51 Python files
- **Command Groups**: 17
- **Total Commands**: 85+
- **API Endpoints Covered**: 200+
- **Lines of Code**: ~15,000
- **Test Files**: 6
- **Documentation Files**: 4 (README, USAGE, ARCHITECTURE, CONTRIBUTING)

### Module Breakdown

- **Core Modules**: 5 files (client, config, session, exceptions, utils)
- **API Modules**: 18 files (auth, user, organ, project, resource, psi, pir, fl, task, node, data, system, fusion, share, log, monitor, model, common)
- **Command Handlers**: 17 files (one per command group)
- **Formatters**: 5 files (base, table, json, yaml, csv)
- **Tests**: 6 files (client, config, session, formatters, integration, fixtures)

### Command Coverage

- **Authentication**: 4 commands (login, logout, whoami, status)
- **Configuration**: 8 commands (show, set, get, reset, profiles, profile, add-profile, delete-profile)
- **User Management**: 5 commands (list, get, create, update, delete)
- **Organization Management**: 5 commands (list, get, create, update, delete)
- **Project Management**: 5 commands (list, get, create, update, delete)
- **Resource Management**: 5 commands (list, get, create, update, delete)
- **PSI Tasks**: 6 commands (create, list, status, cancel, result, download)
- **PIR Tasks**: 5 commands (create, list, status, cancel, download)
- **FL Tasks**: 7 commands (create, list, status, cancel, logs, progress, models, model)
- **General Tasks**: 7 commands (list, get, status, logs, cancel, retry, delete)
- **Node Management**: 9 commands (list, get, status, register, update, delete, connect, disconnect, connections)
- **Data Management**: 7 commands (list, get, fields, preview, upload, delete, statistics)
- **System Management**: 12 commands (info, status, config, set-config, logs, metrics, health, version, services, restart, backup, restore)
- **Fusion Resources**: 8 commands (list, get, create, update, delete, status, execute, result)
- **Data Sharing**: 10 commands (list-requests, get-request, create-request, approve, reject, cancel, list-shared, revoke, permissions, update-permissions)
- **Log Query**: 6 commands (query, task, node, audit, export, clear)
- **Monitoring**: 12 commands (dashboard, task-stats, resource-usage, node-stats, user-activity, performance, error-stats, api-stats, set-alert, list-alerts, delete-alert, alerts)

## Acknowledgments

- Built with Click, Rich, PyYAML, and Requests
- Inspired by modern CLI tools like kubectl, aws-cli, and gh
- Designed for the PrimiHub privacy-preserving computation platform

## Future Roadmap

### Potential Enhancements

- Interactive REPL mode with auto-completion
- Plugin system for third-party extensions
- Textual-based TUI for interactive operations
- Async HTTP requests for better performance
- Real-time monitoring dashboards
- Enhanced caching layer
- Multi-language support (i18n)
- Shell completion scripts (bash, zsh, fish)

---

For detailed usage instructions, see [USAGE.md](USAGE.md).

For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md).

For contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).
