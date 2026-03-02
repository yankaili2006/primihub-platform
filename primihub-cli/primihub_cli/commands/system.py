"""System management commands."""

import click

from ..api.system import SystemAPI
from ..core.client import PrimiHubClient
from ..core.config import Config
from ..core.exceptions import PrimiHubError
from ..formatters.json import JSONFormatter
from ..formatters.table import TableFormatter


def get_formatter(config: Config):
    """Get formatter based on config."""
    output_format = config.get_output_format()
    color = config.is_color_enabled()

    if output_format == 'json':
        return JSONFormatter(color=color)
    else:
        return TableFormatter(color=color)


@click.group()
def system():
    """System management commands."""
    pass


@system.command()
def info():
    """Get system information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_system_info()
        info_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(info_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
def status():
    """Get system status."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_system_status()
        status_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(status_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
def config():
    """Get system configuration."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_system_config()
        config_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(config_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command(name='set-config')
@click.option('--key', '-k', required=True, help='Configuration key')
@click.option('--value', '-v', required=True, help='Configuration value')
def set_config(key, value):
    """Update system configuration."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.update_system_config(key, value)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Configuration '{key}' updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
@click.option('--type', '-t', 'log_type', type=click.Choice(['error', 'warning', 'info']), help='Log type filter')
@click.option('--limit', default=100, help='Number of log entries to retrieve')
def logs(log_type, limit):
    """Get system logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_system_logs(log_type=log_type, limit=limit)
        logs_data = response.get('result', [])

        formatter = get_formatter(config)

        if logs_data:
            display_logs = []
            for log in logs_data:
                display_logs.append({
                    'Time': log.get('logTime', 'N/A'),
                    'Level': log.get('logLevel', 'N/A'),
                    'Message': log.get('logMessage', 'N/A'),
                })
            click.echo(formatter.format(display_logs))
        else:
            click.echo("No logs found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
def metrics():
    """Get system metrics (CPU, memory, disk, network)."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_system_metrics()
        metrics_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(metrics_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
def health():
    """Perform system health check."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.health_check()
        health_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(health_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
def version():
    """Get system version information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_version()
        version_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(version_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
@click.option('--service', '-s', 'service_name', help='Specific service name (optional)')
def services(service_name):
    """Get service status."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.get_service_status(service_name=service_name)
        services_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(services_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
@click.argument('service_name')
@click.confirmation_option(prompt='Are you sure you want to restart this service?')
def restart(service_name):
    """Restart a system service."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.restart_service(service_name)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Service '{service_name}' restarted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
@click.confirmation_option(prompt='Are you sure you want to backup the database?')
def backup():
    """Trigger database backup."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.backup_database()
        backup_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format_success("Database backup initiated successfully"))

        if backup_data:
            click.echo(formatter.format(backup_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@system.command()
@click.argument('backup_file')
@click.confirmation_option(prompt='Are you sure you want to restore the database? This will overwrite existing data.')
def restore(backup_file):
    """Restore database from backup."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        system_api = SystemAPI(client)

        response = system_api.restore_database(backup_file)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Database restored from '{backup_file}' successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
