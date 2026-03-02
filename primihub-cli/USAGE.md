# PrimiHub CLI Usage Guide

Complete guide for using the PrimiHub CLI tool.

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Authentication](#authentication)
4. [Configuration Management](#configuration-management)
5. [User Management](#user-management)
6. [Organization Management](#organization-management)
7. [Project Management](#project-management)
8. [Resource Management](#resource-management)
9. [Privacy Computing Tasks](#privacy-computing-tasks)
10. [Data Management](#data-management)
11. [System Management](#system-management)
12. [Monitoring & Logs](#monitoring--logs)
13. [Advanced Features](#advanced-features)
14. [Troubleshooting](#troubleshooting)

## Installation

### From Source

```bash
cd /mnt/data1/github/primihub-platform/primihub-cli
pip3 install -r requirements.txt
```

### Running the CLI

```bash
# Run directly from project directory
python3 -m primihub_cli [command]

# Or install as package
pip3 install -e .
primihub [command]
```

## Quick Start

### 1. Login

```bash
python3 -m primihub_cli login
# Username: admin
# Password: 123456
```

### 2. Check Status

```bash
python3 -m primihub_cli status
python3 -m primihub_cli whoami
```

### 3. List Resources

```bash
python3 -m primihub_cli project list
python3 -m primihub_cli resource list
```

### 4. Create a Task

```bash
# Create a PSI task
python3 -m primihub_cli psi create \
  --project-id 1 \
  --resources "1,2" \
  --algorithm dh

# Check task status
python3 -m primihub_cli psi status TASK_ID
```

## Authentication

### Login to Platform

```bash
# Login with default profile
python3 -m primihub_cli login

# Login with specific profile
python3 -m primihub_cli login --profile demo1
```

### Check Authentication Status

```bash
# Show current authentication status
python3 -m primihub_cli status

# Show current user information
python3 -m primihub_cli whoami
```

### Logout

```bash
python3 -m primihub_cli logout
```

## Configuration Management

### View Configuration

```bash
# Show all configuration
python3 -m primihub_cli config show

# Show in JSON format
python3 -m primihub_cli config show --format json

# Show in YAML format
python3 -m primihub_cli config show --format yaml
```

### Manage Profiles

```bash
# List all profiles
python3 -m primihub_cli config profiles

# Add a new profile
python3 -m primihub_cli config add-profile demo2 \
  --base-url http://localhost:30813/prod-api \
  --organ-id 3 \
  --organ-name demo2

# Set default profile
python3 -m primihub_cli config profile demo2

# Delete a profile
python3 -m primihub_cli config delete-profile demo2
```

### Set Configuration Values

```bash
# Set output format
python3 -m primihub_cli config set output.format json

# Enable color output
python3 -m primihub_cli config set output.color true

# Get specific value
python3 -m primihub_cli config get output.format
```

### Reset Configuration

```bash
python3 -m primihub_cli config reset
```

## User Management

### List Users

```bash
# List all users
python3 -m primihub_cli user list

# With pagination
python3 -m primihub_cli user list --page 2 --size 20

# Output as JSON
python3 -m primihub_cli user list --format json
```

### Get User Details

```bash
python3 -m primihub_cli user get USER_ID
```

### Create User

```bash
python3 -m primihub_cli user create \
  --username newuser \
  --password password123 \
  --email newuser@example.com
```

### Update User

```bash
python3 -m primihub_cli user update USER_ID \
  --username updated_name \
  --email newemail@example.com
```

### Delete User

```bash
python3 -m primihub_cli user delete USER_ID
```

## Organization Management

### List Organizations

```bash
python3 -m primihub_cli organ list
python3 -m primihub_cli organ list --page 1 --size 10
```

### Get Organization Details

```bash
python3 -m primihub_cli organ get ORGAN_ID
```

### Create Organization

```bash
python3 -m primihub_cli organ create \
  --name "New Organization" \
  --desc "Organization description"
```

### Update Organization

```bash
python3 -m primihub_cli organ update ORGAN_ID \
  --name "Updated Name" \
  --desc "Updated description"
```

### Delete Organization

```bash
python3 -m primihub_cli organ delete ORGAN_ID
```

## Project Management

### List Projects

```bash
# List all projects
python3 -m primihub_cli project list

# Filter by type
python3 -m primihub_cli project list --type psi
```

### Get Project Details

```bash
python3 -m primihub_cli project get PROJECT_ID
```

### Create Project

```bash
python3 -m primihub_cli project create \
  --name "My PSI Project" \
  --type psi \
  --desc "Project for PSI tasks"
```

### Update Project

```bash
python3 -m primihub_cli project update PROJECT_ID \
  --name "Updated Project Name" \
  --desc "Updated description"
```

### Delete Project

```bash
python3 -m primihub_cli project delete PROJECT_ID
```

## Resource Management

### List Resources

```bash
# List all resources
python3 -m primihub_cli resource list

# Filter by organization
python3 -m primihub_cli resource list --organ-id 1
```

### Get Resource Details

```bash
python3 -m primihub_cli resource get RESOURCE_ID
```

### Create Resource

```bash
python3 -m primihub_cli resource create \
  --name "dataset.csv" \
  --file /path/to/dataset.csv \
  --desc "Dataset description"
```

### Update Resource

```bash
python3 -m primihub_cli resource update RESOURCE_ID \
  --name "updated_name.csv" \
  --desc "Updated description"
```

### Delete Resource

```bash
python3 -m primihub_cli resource delete RESOURCE_ID
```

## Privacy Computing Tasks

### PSI (Private Set Intersection)

```bash
# Create PSI task
python3 -m primihub_cli psi create \
  --project-id 1 \
  --resources "1,2,3" \
  --algorithm dh

# List PSI tasks
python3 -m primihub_cli psi list
python3 -m primihub_cli psi list --status running

# Get task status
python3 -m primihub_cli psi status TASK_ID

# Get task result
python3 -m primihub_cli psi result TASK_ID

# Download result
python3 -m primihub_cli psi download TASK_ID

# Cancel task
python3 -m primihub_cli psi cancel TASK_ID
```

### PIR (Private Information Retrieval)

```bash
# Create PIR task
python3 -m primihub_cli pir create \
  --project-id 1 \
  --resource-id 1 \
  --query '{"key":"value"}'

# List PIR tasks
python3 -m primihub_cli pir list

# Get task status
python3 -m primihub_cli pir status TASK_ID

# Download result
python3 -m primihub_cli pir download TASK_ID

# Cancel task
python3 -m primihub_cli pir cancel TASK_ID
```

### FL (Federated Learning)

```bash
# Create FL task
python3 -m primihub_cli fl create \
  --project-id 1 \
  --model-id 1 \
  --resources "1,2,3" \
  --algorithm xgboost

# List FL tasks
python3 -m primihub_cli fl list

# Get task status
python3 -m primihub_cli fl status TASK_ID

# View task logs
python3 -m primihub_cli fl logs TASK_ID

# View training progress
python3 -m primihub_cli fl progress TASK_ID

# Cancel task
python3 -m primihub_cli fl cancel TASK_ID

# List available models
python3 -m primihub_cli fl models

# Get model details
python3 -m primihub_cli fl model MODEL_ID
```

## Data Management

### List Datasets

```bash
python3 -m primihub_cli data list
python3 -m primihub_cli data list --page 1 --size 20
```

### Get Dataset Details

```bash
python3 -m primihub_cli data get DATASET_ID
```

### View Dataset Fields

```bash
python3 -m primihub_cli data fields DATASET_ID
```

### Preview Dataset

```bash
python3 -m primihub_cli data preview DATASET_ID --limit 10
```

### Upload Dataset

```bash
python3 -m primihub_cli data upload \
  --name "my_dataset.csv" \
  --file /path/to/dataset.csv \
  --desc "Dataset description"
```

### Get Dataset Statistics

```bash
python3 -m primihub_cli data statistics DATASET_ID
```

### Delete Dataset

```bash
python3 -m primihub_cli data delete DATASET_ID
```

## System Management

### System Information

```bash
# Get system info
python3 -m primihub_cli system info

# Get system status
python3 -m primihub_cli system status

# Get system version
python3 -m primihub_cli system version

# Health check
python3 -m primihub_cli system health
```

### System Metrics

```bash
# Get system metrics (CPU, memory, disk, network)
python3 -m primihub_cli system metrics
```

### System Configuration

```bash
# Get system configuration
python3 -m primihub_cli system config

# Update system configuration
python3 -m primihub_cli system set-config \
  --key config_key \
  --value config_value
```

### Service Management

```bash
# Get all services status
python3 -m primihub_cli system services

# Get specific service status
python3 -m primihub_cli system services --service mysql

# Restart a service
python3 -m primihub_cli system restart SERVICE_NAME
```

### Database Backup & Restore

```bash
# Backup database
python3 -m primihub_cli system backup

# Restore database
python3 -m primihub_cli system restore /path/to/backup.sql
```

## Monitoring & Logs

### Log Query

```bash
# Query system logs
python3 -m primihub_cli log query \
  --level ERROR \
  --start "2026-03-01 00:00:00" \
  --end "2026-03-02 00:00:00" \
  --keyword "error"

# Get task logs
python3 -m primihub_cli log task TASK_ID

# Get node logs
python3 -m primihub_cli log node NODE_ID --level ERROR

# Get audit logs
python3 -m primihub_cli log audit \
  --user-id 1 \
  --action "login" \
  --start "2026-03-01 00:00:00"

# Export logs
python3 -m primihub_cli log export \
  --type system \
  --format csv \
  --start "2026-03-01 00:00:00"

# Clear old logs
python3 -m primihub_cli log clear \
  --type system \
  --before "2026-02-01 00:00:00"
```

### Monitoring & Statistics

```bash
# Dashboard statistics
python3 -m primihub_cli monitor dashboard

# Task statistics
python3 -m primihub_cli monitor task-stats \
  --start 2026-03-01 \
  --end 2026-03-02 \
  --type psi

# Resource usage
python3 -m primihub_cli monitor resource-usage

# Node statistics
python3 -m primihub_cli monitor node-stats

# User activity
python3 -m primihub_cli monitor user-activity \
  --start "2026-03-01 00:00:00" \
  --user-id 1

# Performance metrics
python3 -m primihub_cli monitor performance \
  --type cpu \
  --start "2026-03-01 00:00:00"

# Error statistics
python3 -m primihub_cli monitor error-stats \
  --start "2026-03-01 00:00:00"

# API statistics
python3 -m primihub_cli monitor api-stats
```

### Alert Management

```bash
# Set alert rule
python3 -m primihub_cli monitor set-alert \
  --name "High CPU Usage" \
  --metric cpu \
  --threshold 80 \
  --condition greater \
  --level warning

# List alert rules
python3 -m primihub_cli monitor list-alerts

# Delete alert rule
python3 -m primihub_cli monitor delete-alert RULE_ID

# View triggered alerts
python3 -m primihub_cli monitor alerts \
  --level error \
  --status active
```

## Advanced Features

### Output Formats

The CLI supports multiple output formats:

```bash
# Table format (default)
python3 -m primihub_cli user list

# JSON format
python3 -m primihub_cli user list --format json

# YAML format
python3 -m primihub_cli config show --format yaml

# CSV format
python3 -m primihub_cli user list --format csv
```

### Multi-Environment Support

```bash
# Work with different environments
python3 -m primihub_cli login --profile demo0
python3 -m primihub_cli login --profile demo1
python3 -m primihub_cli login --profile demo2

# Switch between profiles
python3 -m primihub_cli config profile demo1
```

### Batch Operations

```bash
# Create multiple resources
for file in *.csv; do
  python3 -m primihub_cli resource create \
    --name "$file" \
    --file "$file"
done

# Check status of multiple tasks
for task_id in 1 2 3 4 5; do
  python3 -m primihub_cli psi status $task_id
done
```

### Scripting Examples

```bash
#!/bin/bash
# Automated workflow script

# Login
python3 -m primihub_cli login <<EOF
admin
123456
EOF

# Create project
PROJECT_ID=$(python3 -m primihub_cli project create \
  --name "Automated Project" \
  --type psi \
  --format json | jq -r '.result.projectId')

# Create PSI task
TASK_ID=$(python3 -m primihub_cli psi create \
  --project-id $PROJECT_ID \
  --resources "1,2" \
  --format json | jq -r '.result.taskId')

# Wait for completion
while true; do
  STATUS=$(python3 -m primihub_cli psi status $TASK_ID \
    --format json | jq -r '.result.taskState')

  if [ "$STATUS" == "3" ]; then
    echo "Task completed successfully"
    break
  elif [ "$STATUS" == "4" ]; then
    echo "Task failed"
    exit 1
  fi

  sleep 5
done

# Download result
python3 -m primihub_cli psi download $TASK_ID
```

## Troubleshooting

### Common Issues

#### 1. Authentication Failed

```bash
# Check credentials
python3 -m primihub_cli status

# Re-login
python3 -m primihub_cli logout
python3 -m primihub_cli login
```

#### 2. Connection Refused

```bash
# Check base URL in config
python3 -m primihub_cli config show

# Update base URL
python3 -m primihub_cli config set profiles.demo0.base_url http://localhost:30811/prod-api
```

#### 3. Token Expired

```bash
# Session expires after 24 hours, re-login
python3 -m primihub_cli login
```

#### 4. Permission Denied

```bash
# Check current user permissions
python3 -m primihub_cli whoami

# Contact administrator for access
```

### Debug Mode

```bash
# Enable verbose output
python3 -m primihub_cli config set output.verbose true

# View detailed error messages
python3 -m primihub_cli user list --format json
```

### Getting Help

```bash
# General help
python3 -m primihub_cli --help

# Command-specific help
python3 -m primihub_cli user --help
python3 -m primihub_cli psi create --help

# Version information
python3 -m primihub_cli --version
```

## Best Practices

1. **Always check authentication status before operations**
   ```bash
   python3 -m primihub_cli status
   ```

2. **Use JSON format for scripting**
   ```bash
   python3 -m primihub_cli user list --format json | jq '.result.list'
   ```

3. **Set appropriate page sizes for large datasets**
   ```bash
   python3 -m primihub_cli resource list --size 50
   ```

4. **Monitor task status regularly**
   ```bash
   python3 -m primihub_cli psi status TASK_ID
   ```

5. **Use profiles for multi-environment workflows**
   ```bash
   python3 -m primihub_cli config add-profile production --base-url https://prod.example.com/api
   ```

## Next Steps

- Explore the [API Reference](API.md) for detailed API documentation
- Read the [Architecture Guide](ARCHITECTURE.md) to understand the system design
- Check the [Contributing Guide](CONTRIBUTING.md) to contribute to the project
