"""PSI task management commands."""

import click

from ..api.psi import PSIAPI
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
def psi():
    """PSI (Private Set Intersection) task management commands."""
    pass


@psi.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--status', type=click.Choice(['pending', 'running', 'success', 'failed']), help='Filter by status')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, status, format):
    """List all PSI tasks."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        psi_api = PSIAPI(client)

        status_map = {'pending': 0, 'running': 1, 'success': 2, 'failed': 3}
        status_code = status_map.get(status) if status else None

        response = psi_api.list_tasks(page_no=page, page_size=size, status=status_code)
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
                    'Algorithm': t.get('algorithm', ''),
                    'Status': status_names.get(t.get('taskState'), 'Unknown'),
                    'Created': t.get('createDate', ''),
                })
            click.echo(formatter.format(display_tasks))
        else:
            click.echo("No PSI tasks found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@psi.command()
@click.argument('task_id')
def status(task_id):
    """Get PSI task status and details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        psi_api = PSIAPI(client)

        response = psi_api.get_task(task_id)
        task_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(task_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@psi.command()
@click.option('--project-id', '-p', required=True, type=int, help='Project ID')
@click.option('--resources', '-r', required=True, help='Comma-separated resource IDs')
@click.option('--algorithm', '-a', default='dh', type=click.Choice(['dh', 'ecdh', 'kkrt', 'rr22']), help='PSI algorithm')
def create(project_id, resources, algorithm):
    """Create a new PSI task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        psi_api = PSIAPI(client)

        resource_ids = [int(r.strip()) for r in resources.split(',')]

        response = psi_api.create_task(
            project_id=project_id,
            resource_ids=resource_ids,
            algorithm=algorithm
        )

        result = response.get('result', {})
        task_id = result.get('taskId', 'Unknown')

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"PSI task created successfully"))
        click.echo(f"Task ID: {task_id}")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@psi.command()
@click.argument('task_id')
@click.confirmation_option(prompt='Are you sure you want to cancel this task?')
def cancel(task_id):
    """Cancel a PSI task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        psi_api = PSIAPI(client)

        response = psi_api.cancel_task(task_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"PSI task {task_id} cancelled successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@psi.command()
@click.argument('task_id')
def result(task_id):
    """Get PSI task result."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        psi_api = PSIAPI(client)

        response = psi_api.get_task_result(task_id)
        result_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(result_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@psi.command()
@click.argument('task_id')
def download(task_id):
    """Download PSI task result."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        psi_api = PSIAPI(client)

        response = psi_api.download_result(task_id)
        result_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(result_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
