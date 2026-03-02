"""PIR task management commands."""

import click

from ..api.pir import PIRAPI
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
def pir():
    """PIR (Private Information Retrieval) task management commands."""
    pass


@pir.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--status', type=click.Choice(['pending', 'running', 'success', 'failed']), help='Filter by status')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, status, format):
    """List all PIR tasks."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        pir_api = PIRAPI(client)

        status_map = {'pending': 0, 'running': 1, 'success': 2, 'failed': 3}
        status_code = status_map.get(status) if status else None

        response = pir_api.list_tasks(page_no=page, page_size=size, status=status_code)
        result = response.get('result', {})
        tasks = result.get('list', [])

        formatter = get_formatter(config)

        if tasks:
            status_names = {0: 'Pending', 1: 'Running', 2: 'Success', 3: 'Failed'}
            display_tasks = []
            for t in tasks:
                display_tasks.append({
                    'Task ID': t.get('taskId'),
                    'Project ID': t.get('projectId'),
                    'Resource ID': t.get('resourceId', ''),
                    'Status': status_names.get(t.get('taskState'), 'Unknown'),
                    'Created': t.get('createDate', ''),
                })
            click.echo(formatter.format(display_tasks))
        else:
            click.echo("No PIR tasks found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@pir.command()
@click.argument('task_id')
def status(task_id):
    """Get PIR task status and details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        pir_api = PIRAPI(client)

        response = pir_api.get_task(task_id)
        task_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(task_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@pir.command()
@click.option('--project-id', '-p', required=True, type=int, help='Project ID')
@click.option('--resource-id', '-r', required=True, type=int, help='Resource ID')
@click.option('--query', '-q', required=True, help='Query parameters (JSON format)')
def create(project_id, resource_id, query):
    """Create a new PIR task."""
    try:
        import json

        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        pir_api = PIRAPI(client)

        query_params = json.loads(query)

        response = pir_api.create_task(
            project_id=project_id,
            resource_id=resource_id,
            query_params=query_params
        )

        result = response.get('result', {})
        task_id = result.get('taskId', 'Unknown')

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"PIR task created successfully"))
        click.echo(f"Task ID: {task_id}")

    except json.JSONDecodeError:
        click.echo(click.style("Error: Invalid JSON format for query parameters", fg='red'), err=True)
        raise click.Abort()
    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@pir.command()
@click.argument('task_id')
@click.confirmation_option(prompt='Are you sure you want to cancel this task?')
def cancel(task_id):
    """Cancel a PIR task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        pir_api = PIRAPI(client)

        response = pir_api.cancel_task(task_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"PIR task {task_id} cancelled successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@pir.command()
@click.argument('task_id')
def download(task_id):
    """Download PIR task result."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        pir_api = PIRAPI(client)

        response = pir_api.download_result(task_id)
        result_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(result_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
