"""Resource management commands."""

import click

from ..api.resource import ResourceAPI
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
def resource():
    """Resource management commands."""
    pass


@resource.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--organ-id', type=int, help='Filter by organization ID')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, organ_id, format):
    """List all resources."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        resource_api = ResourceAPI(client)

        response = resource_api.list_resources(
            page_no=page,
            page_size=size,
            organ_id=organ_id
        )
        result = response.get('result', {})
        resources = result.get('list', [])

        formatter = get_formatter(config)

        if resources:
            display_resources = []
            for r in resources:
                display_resources.append({
                    'Resource ID': r.get('resourceId'),
                    'Name': r.get('resourceName'),
                    'Organ ID': r.get('organId'),
                    'Description': r.get('resourceDesc', ''),
                })
            click.echo(formatter.format(display_resources))
        else:
            click.echo("No resources found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@resource.command()
@click.argument('resource_id', type=int)
def get(resource_id):
    """Get resource details by ID."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        resource_api = ResourceAPI(client)

        response = resource_api.get_resource(resource_id)
        resource_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(resource_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@resource.command()
@click.option('--name', '-n', required=True, help='Resource name')
@click.option('--desc', '-d', help='Resource description')
@click.option('--file', '-f', type=click.Path(exists=True), help='Path to resource file')
def create(name, desc, file):
    """Create a new resource."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        resource_api = ResourceAPI(client)

        response = resource_api.create_resource(
            resource_name=name,
            resource_desc=desc,
            file_path=file
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Resource '{name}' created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@resource.command()
@click.argument('resource_id', type=int)
@click.option('--name', '-n', help='New resource name')
@click.option('--desc', '-d', help='New resource description')
def update(resource_id, name, desc):
    """Update resource information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        resource_api = ResourceAPI(client)

        response = resource_api.update_resource(
            resource_id=resource_id,
            resource_name=name,
            resource_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Resource {resource_id} updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@resource.command()
@click.argument('resource_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this resource?')
def delete(resource_id):
    """Delete a resource."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        resource_api = ResourceAPI(client)

        response = resource_api.delete_resource(resource_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Resource {resource_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
