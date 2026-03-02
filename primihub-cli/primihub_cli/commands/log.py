"""Log query commands."""

import click

from ..api.log import LogAPI
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
def log():
    """Log query commands."""
    pass


@log.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=100, help='Page size')
@click.option('--level', type=click.Choice(['DEBUG', 'INFO', 'WARN', 'ERROR']), help='Log level filter')
@click.option('--start', help='Start time (YYYY-MM-DD HH:MM:SS)')
@click.option('--end', help='End time (YYYY-MM-DD HH:MM:SS)')
@click.option('--keyword', '-k', help='Keyword search')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def query(page, size, level, start, end, keyword, format):
    """Query system logs."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        log_api = LogAPI(client)

        response = log_api.query_logs(
            page_no=page,
            page_size=size,
            log_level=level,
            start_time=start,
            end_time=end,
            keyword=keyword
        )
        result = response.get('result', {})
        logs = result.get('list', [])

        formatter = get_formatter(config)

        if logs:
            display_logs = []
            for l in logs:
                display_logs.append({
                    'Time': l.get('logTime', 'N/A'),
                    'Level': l.get('logLevel', 'N/A'),
                    'Message': l.get('logMessage', '')[:80],
                })
            click.echo(formatter.format(display_logs))
        else:
            click.echo("No logs found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@log.command(name='task')
@click.argument('task_id', type=int)
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=100, help='Page size')
def task_logs(task_id, page, size):
    """Get task execution logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        log_api = LogAPI(client)

        response = log_api.get_task_logs(task_id, page_no=page, page_size=size)
        result = response.get('result', {})
        logs = result.get('list', [])

        formatter = get_formatter(config)

        if logs:
            display_logs = []
            for l in logs:
                display_logs.append({
                    'Time': l.get('logTime', 'N/A'),
                    'Level': l.get('logLevel', 'N/A'),
                    'Message': l.get('logMessage', ''),
                })
            click.echo(formatter.format(display_logs))
        else:
            click.echo("No logs found for this task")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@log.command(name='node')
@click.argument('node_id', type=int)
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=100, help='Page size')
@click.option('--level', type=click.Choice(['DEBUG', 'INFO', 'WARN', 'ERROR']), help='Log level filter')
def node_logs(node_id, page, size, level):
    """Get node logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        log_api = LogAPI(client)

        response = log_api.get_node_logs(
            node_id,
            page_no=page,
            page_size=size,
            log_level=level
        )
        result = response.get('result', {})
        logs = result.get('list', [])

        formatter = get_formatter(config)

        if logs:
            display_logs = []
            for l in logs:
                display_logs.append({
                    'Time': l.get('logTime', 'N/A'),
                    'Level': l.get('logLevel', 'N/A'),
                    'Message': l.get('logMessage', '')[:80],
                })
            click.echo(formatter.format(display_logs))
        else:
            click.echo("No logs found for this node")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@log.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=100, help='Page size')
@click.option('--user-id', type=int, help='User ID filter')
@click.option('--action', help='Action type filter')
@click.option('--start', help='Start time')
@click.option('--end', help='End time')
def audit(page, size, user_id, action, start, end):
    """Get audit logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        log_api = LogAPI(client)

        response = log_api.get_audit_logs(
            page_no=page,
            page_size=size,
            user_id=user_id,
            action_type=action,
            start_time=start,
            end_time=end
        )
        result = response.get('result', {})
        logs = result.get('list', [])

        formatter = get_formatter(config)

        if logs:
            display_logs = []
            for l in logs:
                display_logs.append({
                    'Time': l.get('actionTime', 'N/A'),
                    'User': l.get('userName', l.get('userId', 'N/A')),
                    'Action': l.get('actionType', 'N/A'),
                    'Details': l.get('actionDetails', '')[:50],
                })
            click.echo(formatter.format(display_logs))
        else:
            click.echo("No audit logs found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@log.command()
@click.option('--type', '-t', default='system', type=click.Choice(['system', 'task', 'node', 'audit']), help='Log type')
@click.option('--start', help='Start time')
@click.option('--end', help='End time')
@click.option('--format', '-f', default='csv', type=click.Choice(['csv', 'json']), help='Export format')
def export(type, start, end, format):
    """Export logs to file."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        log_api = LogAPI(client)

        response = log_api.export_logs(
            log_type=type,
            start_time=start,
            end_time=end,
            format=format
        )
        result = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Logs exported successfully"))

        if result.get('downloadUrl'):
            click.echo(f"Download URL: {result.get('downloadUrl')}")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@log.command()
@click.option('--type', '-t', default='system', type=click.Choice(['system', 'task', 'node', 'audit']), help='Log type')
@click.option('--before', help='Clear logs before this time')
@click.confirmation_option(prompt='Are you sure you want to clear logs?')
def clear(type, before):
    """Clear old logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        log_api = LogAPI(client)

        response = log_api.clear_logs(log_type=type, before_time=before)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"{type.capitalize()} logs cleared successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
