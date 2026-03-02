"""Organization management commands."""

import click

from ..api.organ import OrganAPI
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
def organ():
    """Organization management commands."""
    pass


@organ.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, format):
    """List all organizations."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        organ_api = OrganAPI(client)

        response = organ_api.list_organs(page_no=page, page_size=size)
        result = response.get('result', {})
        organs = result.get('list', [])

        formatter = get_formatter(config)

        if organs:
            display_organs = []
            for o in organs:
                display_organs.append({
                    'Organ ID': o.get('organId'),
                    'Name': o.get('organName'),
                    'Description': o.get('organDesc', ''),
                })
            click.echo(formatter.format(display_organs))
        else:
            click.echo("No organizations found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@organ.command()
@click.argument('organ_id', type=int)
def get(organ_id):
    """Get organization details by ID."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        organ_api = OrganAPI(client)

        response = organ_api.get_organ(organ_id)
        organ_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(organ_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@organ.command()
@click.option('--name', '-n', required=True, help='Organization name')
@click.option('--desc', '-d', help='Organization description')
def create(name, desc):
    """Create a new organization."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        organ_api = OrganAPI(client)

        response = organ_api.create_organ(organ_name=name, organ_desc=desc)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Organization '{name}' created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@organ.command()
@click.argument('organ_id', type=int)
@click.option('--name', '-n', help='New organization name')
@click.option('--desc', '-d', help='New organization description')
def update(organ_id, name, desc):
    """Update organization information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        organ_api = OrganAPI(client)

        response = organ_api.update_organ(
            organ_id=organ_id,
            organ_name=name,
            organ_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Organization {organ_id} updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@organ.command()
@click.argument('organ_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this organization?')
def delete(organ_id):
    """Delete an organization."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        organ_api = OrganAPI(client)

        response = organ_api.delete_organ(organ_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Organization {organ_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
