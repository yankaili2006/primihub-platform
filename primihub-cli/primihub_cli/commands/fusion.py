"""Fusion resource management commands."""

import click

from ..api.fusion import FusionAPI
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
def fusion():
    """Fusion resource management commands."""
    pass


@fusion.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--type', '-t', 'resource_type', type=click.Choice(['psi', 'pir', 'fl']), help='Resource type filter')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, resource_type, format):
    """List all fusion resources."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.list_fusion_resources(
            page_no=page,
            page_size=size,
            resource_type=resource_type
        )
        result = response.get('result', {})
        fusions = result.get('list', [])

        formatter = get_formatter(config)

        if fusions:
            display_fusions = []
            for f in fusions:
                display_fusions.append({
                    'Fusion ID': f.get('fusionId'),
                    'Name': f.get('fusionName'),
                    'Type': f.get('fusionType'),
                    'Status': f.get('status', 'Unknown'),
                    'Created': f.get('createTime', 'N/A'),
                })
            click.echo(formatter.format(display_fusions))
        else:
            click.echo("No fusion resources found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.argument('fusion_id', type=int)
def get(fusion_id):
    """Get fusion resource details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.get_fusion_resource(fusion_id)
        fusion_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(fusion_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.option('--name', '-n', required=True, help='Fusion resource name')
@click.option('--resources', '-r', required=True, help='Comma-separated resource IDs')
@click.option('--type', '-t', default='psi', type=click.Choice(['psi', 'pir', 'fl']), help='Fusion type')
@click.option('--desc', '-d', help='Fusion resource description')
def create(name, resources, type, desc):
    """Create a fusion resource."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        resource_ids = [int(r.strip()) for r in resources.split(',')]

        response = fusion_api.create_fusion_resource(
            fusion_name=name,
            resource_ids=resource_ids,
            fusion_type=type,
            fusion_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Fusion resource '{name}' created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.argument('fusion_id', type=int)
@click.option('--name', '-n', help='New fusion resource name')
@click.option('--desc', '-d', help='New fusion resource description')
def update(fusion_id, name, desc):
    """Update fusion resource."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.update_fusion_resource(
            fusion_id=fusion_id,
            fusion_name=name,
            fusion_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Fusion resource {fusion_id} updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.argument('fusion_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this fusion resource?')
def delete(fusion_id):
    """Delete a fusion resource."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.delete_fusion_resource(fusion_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Fusion resource {fusion_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.argument('fusion_id', type=int)
def status(fusion_id):
    """Get fusion resource status."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.get_fusion_status(fusion_id)
        status_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(status_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.argument('fusion_id', type=int)
def execute(fusion_id):
    """Execute a fusion resource."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.execute_fusion(fusion_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Fusion resource {fusion_id} execution started"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@fusion.command()
@click.argument('fusion_id', type=int)
def result(fusion_id):
    """Get fusion execution result."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        fusion_api = FusionAPI(client)

        response = fusion_api.get_fusion_result(fusion_id)
        result_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(result_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
