"""Task management commands (general tasks across PSI/PIR/FL)."""

import click

from ..api.task import TaskAPI
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
def task():
    """General task management commands."""
    pass


@task.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--type', type=click.Choice(['psi', 'pir', 'fl']), help='Filter by task type')
@click.option('--status', type=click.Choice(['pending', 'running', 'success', 'failed']), help='Filter by status')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, type, status, format):
    """List all tasks."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        status_map = {'pending': 0, 'running': 1, 'success': 2, 'failed': 3}
        status_code = status_map.get(status) if status else None

        response = task_api.list_tasks(
            page_no=page,
            page_size=size,
            task_type=type,
            status=status_code
        )
        result = response.get('result', {})
        tasks = result.get('list', [])

        formatter = get_formatter(config)

        if tasks:
            status_names = {0: 'Pending', 1: 'Running', 2: 'Success', 3: 'Failed'}
            display_tasks = []
            for t in tasks:
                display_tasks.append({
                    'Task ID': t.get('taskId'),
                    'Type': t.get('taskType', '').upper(),
                    'Project ID': t.get('projectId'),
                    'Status': status_names.get(t.get('taskState'), 'Unknown'),
                    'Created': t.get('createDate', ''),
                })
            click.echo(formatter.format(display_tasks))
        else:
            click.echo("No tasks found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@task.command()
@click.argument('task_id')
def get(task_id):
    """Get task details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        response = task_api.get_task(task_id)
        task_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(task_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@task.command()
@click.argument('task_id')
def status(task_id):
    """Get task status."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        response = task_api.get_task_status(task_id)
        status_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(status_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@task.command()
@click.argument('task_id')
@click.option('--lines', '-n', default=100, help='Number of log lines to retrieve')
def logs(task_id, lines):
    """Get task logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        response = task_api.get_task_logs(task_id, lines=lines)
        logs_data = response.get('result', {})

        formatter = get_formatter(config)

        # If logs are in a specific format, display them directly
        if isinstance(logs_data, dict) and 'logs' in logs_data:
            click.echo(logs_data['logs'])
        else:
            click.echo(formatter.format(logs_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@task.command()
@click.argument('task_id')
@click.confirmation_option(prompt='Are you sure you want to cancel this task?')
def cancel(task_id):
    """Cancel a task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        response = task_api.cancel_task(task_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Task {task_id} cancelled successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@task.command()
@click.argument('task_id')
def retry(task_id):
    """Retry a failed task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        response = task_api.retry_task(task_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Task {task_id} retry initiated"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@task.command()
@click.argument('task_id')
@click.confirmation_option(prompt='Are you sure you want to delete this task?')
def delete(task_id):
    """Delete a task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        task_api = TaskAPI(client)

        response = task_api.delete_task(task_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Task {task_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
