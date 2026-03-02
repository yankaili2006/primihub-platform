# PrimiHub CLI v2.0

Modern command-line interface for PrimiHub platform operations.

## Quick Start

```bash
# Run from project directory
cd /mnt/data1/github/primihub-platform/primihub-cli

# Login
python3 -m primihub_cli login
# Username: admin
# Password: 123456

# Check status
python3 -m primihub_cli status

# View current user
python3 -m primihub_cli whoami

# Logout
python3 -m primihub_cli logout
```

## Features

### Phase 1 (Completed) ✅
- ✅ Modular architecture with 60+ file structure
- ✅ Configuration management (~/.primihub/config.yaml)
- ✅ Session persistence (~/.primihub/session)
- ✅ Multiple output formats (table/json)
- ✅ Authentication commands (login, logout, whoami, status)
- ✅ Smart proxy detection for private networks
- ✅ Token-based authentication with auto-renewal

### Phase 2 (Completed) ✅
- ✅ User management (list, get, create, update, delete)
- ✅ Organization management (list, get, create, update, delete)
- ✅ Project management (list, get, create, update, delete)
- ✅ Resource management (list, get, create, update, delete)
- ✅ Pagination support
- ✅ Multiple output formats

### Phase 3 (Completed) ✅
- ✅ PSI task management (create, list, status, cancel, result, download)
- ✅ PIR task management (create, list, status, cancel, download)
- ✅ FL task management (create, list, status, cancel, logs, progress)
- ✅ FL model management (list models, get model details)
- ✅ Task monitoring and result retrieval

### Phase 4 (Completed) ✅
- ✅ YAML output formatter
- ✅ CSV output formatter
- ✅ Configuration management commands (show, set, get, reset)
- ✅ Profile management (list, add, delete, set default)
- ✅ Enhanced output format support (table/json/yaml/csv)

### Phase 5 (Completed) ✅
- ✅ General task management (list, get, status, logs, cancel, retry, delete)
- ✅ Node management (list, get, status, register, update, delete, connect)
- ✅ Data management (list, get, fields, preview, upload, delete, statistics)
- ✅ System management (info, status, config, logs, metrics, health, version, services, backup, restore)
- ✅ Fusion resource management (list, get, create, update, delete, status, execute, result)
- ✅ Data sharing management (requests, approve, reject, cancel, shared resources, permissions)
- ✅ Log query (system, task, node, audit logs with filtering and export)
- ✅ Monitoring statistics (dashboard, task/resource/node stats, performance, alerts)

### Phase 6 (Completed) ✅
- ✅ Unit tests (client, config, session, formatters)
- ✅ Integration tests (API modules, command handlers)
- ✅ Test fixtures and configuration (pytest, conftest)
- ✅ Comprehensive documentation (USAGE.md, ARCHITECTURE.md, CONTRIBUTING.md)
- ✅ Test coverage setup (pytest-cov)
- ✅ Code quality tools (flake8, black, mypy)

## Architecture

```
primihub-cli/
├── primihub_cli/
│   ├── core/          # Client, config, session management
│   ├── api/           # API modules (auth, user, psi, pir, fl, etc.)
│   ├── commands/      # CLI command handlers
│   ├── formatters/    # Output formatters (table, json, yaml, csv)
│   └── interactive/   # REPL mode (future)
├── setup.py
└── requirements.txt
```

## Configuration

Default configuration is created at `~/.primihub/config.yaml`:

```yaml
default_profile: demo0

profiles:
  demo0:
    base_url: http://localhost:30811/prod-api
    organ_id: 1
    organ_name: demo0
  demo1:
    base_url: http://localhost:30812/prod-api
    organ_id: 2
    organ_name: demo1

output:
  format: table
  color: true
  verbose: false
```

## Available Commands

### Authentication
```bash
primihub login [--profile PROFILE]
primihub logout
primihub whoami
primihub status
```

### User Management
```bash
primihub user list [--page N] [--size N] [--format json]
primihub user get USER_ID
primihub user create --username NAME --password PASS [--email EMAIL]
primihub user update USER_ID [--username NAME] [--email EMAIL]
primihub user delete USER_ID
```

### Organization Management
```bash
primihub organ list [--page N] [--size N]
primihub organ get ORGAN_ID
primihub organ create --name NAME [--desc DESC]
primihub organ update ORGAN_ID [--name NAME] [--desc DESC]
primihub organ delete ORGAN_ID
```

### Project Management
```bash
primihub project list [--page N] [--size N]
primihub project get PROJECT_ID
primihub project create --name NAME [--type psi|pir|fl] [--desc DESC]
primihub project update PROJECT_ID [--name NAME] [--desc DESC]
primihub project delete PROJECT_ID
```

### Resource Management
```bash
primihub resource list [--page N] [--size N] [--organ-id ID]
primihub resource get RESOURCE_ID
primihub resource create --name NAME [--file PATH] [--desc DESC]
primihub resource update RESOURCE_ID [--name NAME] [--desc DESC]
primihub resource delete RESOURCE_ID
```

### PSI Task Management
```bash
primihub psi list [--page N] [--size N] [--status pending|running|success|failed]
primihub psi status TASK_ID
primihub psi create --project-id ID --resources "1,2,3" [--algorithm dh|ecdh|kkrt|rr22]
primihub psi cancel TASK_ID
primihub psi result TASK_ID
primihub psi download TASK_ID
```

### PIR Task Management
```bash
primihub pir list [--page N] [--size N] [--status pending|running|success|failed]
primihub pir status TASK_ID
primihub pir create --project-id ID --resource-id ID --query '{"key":"value"}'
primihub pir cancel TASK_ID
primihub pir download TASK_ID
```

### FL Task Management
```bash
primihub fl list [--page N] [--size N] [--status pending|running|success|failed]
primihub fl status TASK_ID
primihub fl create --project-id ID --model-id ID --resources "1,2,3" [--algorithm xgboost]
primihub fl cancel TASK_ID
primihub fl logs TASK_ID
primihub fl progress TASK_ID
primihub fl models [--page N] [--size N]
primihub fl model MODEL_ID
```

### Configuration Management
```bash
primihub config show [--format table|json|yaml]
primihub config get KEY
primihub config set KEY VALUE
primihub config reset
primihub config profiles
primihub config profile PROFILE_NAME
primihub config add-profile NAME --base-url URL --organ-id ID [--organ-name NAME]
primihub config delete-profile PROFILE_NAME
```

### Task Management (General)
```bash
primihub task list [--page N] [--size N] [--type psi|pir|fl] [--status pending|running|success|failed]
primihub task get TASK_ID
primihub task status TASK_ID
primihub task logs TASK_ID [--lines N]
primihub task cancel TASK_ID
primihub task retry TASK_ID
primihub task delete TASK_ID
```

### Node Management
```bash
primihub node list [--page N] [--size N]
primihub node get NODE_ID
primihub node status NODE_ID
primihub node register --name NAME --ip IP --port PORT --organ-id ID
primihub node update NODE_ID [--name NAME] [--ip IP] [--port PORT]
primihub node delete NODE_ID
primihub node connect NODE_ID TARGET_NODE_ID
primihub node disconnect NODE_ID TARGET_NODE_ID
primihub node connections NODE_ID
```

### Data Management
```bash
primihub data list [--page N] [--size N] [--format json]
primihub data get DATASET_ID
primihub data fields DATASET_ID
primihub data preview DATASET_ID [--limit N]
primihub data upload --name NAME --file PATH [--desc DESC]
primihub data delete DATASET_ID
primihub data statistics DATASET_ID
```

### System Management
```bash
primihub system info
primihub system status
primihub system config
primihub system set-config --key KEY --value VALUE
primihub system logs [--type error|warning|info] [--limit N]
primihub system metrics
primihub system health
primihub system version
primihub system services [--service NAME]
primihub system restart SERVICE_NAME
primihub system backup
primihub system restore BACKUP_FILE
```

### Fusion Resource Management
```bash
primihub fusion list [--page N] [--size N] [--type psi|pir|fl]
primihub fusion get FUSION_ID
primihub fusion create --name NAME --resources "1,2,3" [--type psi|pir|fl] [--desc DESC]
primihub fusion update FUSION_ID [--name NAME] [--desc DESC]
primihub fusion delete FUSION_ID
primihub fusion status FUSION_ID
primihub fusion execute FUSION_ID
primihub fusion result FUSION_ID
```

### Data Sharing Management
```bash
primihub share list-requests [--page N] [--size N] [--status 0|1|2]
primihub share get-request REQUEST_ID
primihub share create-request --resource-id ID --target-organ ID [--type read|write|full] [--desc DESC]
primihub share approve REQUEST_ID
primihub share reject REQUEST_ID [--reason REASON]
primihub share cancel REQUEST_ID
primihub share list-shared [--page N] [--size N]
primihub share revoke SHARE_ID
primihub share permissions RESOURCE_ID
primihub share update-permissions SHARE_ID --type read|write|full
```

### Log Query
```bash
primihub log query [--page N] [--size N] [--level DEBUG|INFO|WARN|ERROR] [--start TIME] [--end TIME] [--keyword TEXT]
primihub log task TASK_ID [--page N] [--size N]
primihub log node NODE_ID [--page N] [--size N] [--level LEVEL]
primihub log audit [--page N] [--size N] [--user-id ID] [--action TYPE] [--start TIME] [--end TIME]
primihub log export [--type system|task|node|audit] [--start TIME] [--end TIME] [--format csv|json]
primihub log clear [--type system|task|node|audit] [--before TIME]
```

### Monitoring & Statistics
```bash
primihub monitor dashboard
primihub monitor task-stats [--start DATE] [--end DATE] [--type psi|pir|fl]
primihub monitor resource-usage [--type TYPE]
primihub monitor node-stats
primihub monitor user-activity [--start TIME] [--end TIME] [--user-id ID]
primihub monitor performance [--type cpu|memory|disk|network] [--start TIME] [--end TIME]
primihub monitor error-stats [--start TIME] [--end TIME] [--type TYPE]
primihub monitor api-stats [--start TIME] [--end TIME]
primihub monitor set-alert --name NAME --metric TYPE --threshold VALUE [--condition greater|less|equal] [--level info|warning|error]
primihub monitor list-alerts
primihub monitor delete-alert RULE_ID
primihub monitor alerts [--page N] [--size N] [--level LEVEL] [--status active|resolved]
```

### Help
```bash
primihub --help
primihub --version
primihub COMMAND --help
```

## Development

Built with:
- Click 8.0+ (command framework)
- Rich 13.0+ (terminal output)
- PyYAML 6.0+ (configuration)
- Requests 2.28+ (HTTP client)

## Examples

### Complete Workflow Example

```bash
# 1. Login
python3 -m primihub_cli login

# 2. List projects
python3 -m primihub_cli project list

# 3. Create a PSI project
python3 -m primihub_cli project create --name "My PSI Project" --type psi

# 4. List resources
python3 -m primihub_cli resource list

# 5. Create a PSI task
python3 -m primihub_cli psi create --project-id 1 --resources "1,2" --algorithm dh

# 6. Check task status
python3 -m primihub_cli psi status TASK_ID

# 7. Get task result
python3 -m primihub_cli psi result TASK_ID

# 8. Logout
python3 -m primihub_cli logout
```

## Next Steps

Phase 4 implementation will add:
- Interactive REPL mode with auto-completion
- Batch operations from file
- Configuration management commands
- Enhanced error handling and user experience
