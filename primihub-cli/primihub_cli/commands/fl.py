"""FL (Federated Learning) task management commands."""

import click

from ..api.fl import FLAPI
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
def fl():
    """FL (Federated Learning) task management commands."""
    pass


@fl.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--status', type=click.Choice(['pending', 'running', 'success', 'failed']), help='Filter by status')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, status, format):
    """List all FL tasks."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        status_map = {'pending': 0, 'running': 1, 'success': 2, 'failed': 3}
        status_code = status_map.get(status) if status else None

        response = fl_api.list_tasks(page_no=page, page_size=size, status=status_code)
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
                    'Model ID': t.get('modelId', ''),
                    'Algorithm': t.get('algorithm', ''),
                    'Status': status_names.get(t.get('taskState'), 'Unknown'),
                    'Created': t.get('createDate', ''),
                })
            click.echo(formatter.format(display_tasks))
        else:
            click.echo("No FL tasks found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command()
@click.argument('task_id')
def status(task_id):
    """Get FL task status and details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        response = fl_api.get_task(task_id)
        task_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(task_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command()
@click.option('--project-id', '-p', required=True, type=int, help='Project ID')
@click.option('--model-id', '-m', required=True, type=int, help='Model ID')
@click.option('--resources', '-r', required=True, help='Comma-separated resource IDs')
@click.option('--algorithm', '-a', default='xgboost', help='FL algorithm')
def create(project_id, model_id, resources, algorithm):
    """Create a new FL task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        resource_ids = [int(r.strip()) for r in resources.split(',')]

        response = fl_api.create_task(
            project_id=project_id,
            model_id=model_id,
            resource_ids=resource_ids,
            algorithm=algorithm
        )

        result = response.get('result', {})
        task_id = result.get('taskId', 'Unknown')

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"FL task created successfully"))
        click.echo(f"Task ID: {task_id}")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command()
@click.argument('task_id')
@click.confirmation_option(prompt='Are you sure you want to cancel this task?')
def cancel(task_id):
    """Cancel a FL task."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        response = fl_api.cancel_task(task_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"FL task {task_id} cancelled successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command()
@click.argument('task_id')
def logs(task_id):
    """Get FL task logs."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        response = fl_api.get_task_logs(task_id)
        logs_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(logs_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command()
@click.argument('task_id')
def progress(task_id):
    """Get FL training progress."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        response = fl_api.get_training_progress(task_id)
        progress_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(progress_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command(name='models')
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list_models(page, size, format):
    """List all FL models."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        response = fl_api.list_models(page_no=page, page_size=size)
        result = response.get('result', {})
        models = result.get('list', [])

        formatter = get_formatter(config)

        if models:
            display_models = []
            for m in models:
                display_models.append({
                    'Model ID': m.get('modelId'),
                    'Name': m.get('modelName'),
                    'Algorithm': m.get('algorithm', ''),
                    'Description': m.get('modelDesc', ''),
                })
            click.echo(formatter.format(display_models))
        else:
            click.echo("No FL models found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fl.command(name='model')
@click.argument('model_id', type=int)
def get_model(model_id):
    """Get FL model details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fl_api = FLAPI(client)

        response = fl_api.get_model(model_id)
        model_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(model_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
