"""Project management commands."""

import click

from ..api.project import ProjectAPI
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
def project():
    """Project management commands."""
    pass


@project.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, format):
    """List all projects."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        project_api = ProjectAPI(client)

        response = project_api.list_projects(page_no=page, page_size=size)
        result = response.get('result', {})
        projects = result.get('list', [])

        formatter = get_formatter(config)

        if projects:
            display_projects = []
            for p in projects:
                project_type_map = {0: 'PSI', 1: 'PIR', 2: 'FL'}
                display_projects.append({
                    'Project ID': p.get('projectId'),
                    'Name': p.get('projectName'),
                    'Type': project_type_map.get(p.get('projectType'), 'Unknown'),
                    'Description': p.get('projectDesc', ''),
                })
            click.echo(formatter.format(display_projects))
        else:
            click.echo("No projects found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@project.command()
@click.argument('project_id', type=int)
def get(project_id):
    """Get project details by ID."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        project_api = ProjectAPI(client)

        response = project_api.get_project(project_id)
        project_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(project_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@project.command()
@click.option('--name', '-n', required=True, help='Project name')
@click.option('--desc', '-d', help='Project description')
@click.option('--type', '-t', type=click.Choice(['psi', 'pir', 'fl']), default='psi', help='Project type')
def create(name, desc, type):
    """Create a new project."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        project_api = ProjectAPI(client)

        type_map = {'psi': 0, 'pir': 1, 'fl': 2}
        project_type = type_map[type]

        response = project_api.create_project(
            project_name=name,
            project_desc=desc,
            project_type=project_type
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Project '{name}' created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@project.command()
@click.argument('project_id', type=int)
@click.option('--name', '-n', help='New project name')
@click.option('--desc', '-d', help='New project description')
def update(project_id, name, desc):
    """Update project information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        project_api = ProjectAPI(client)

        response = project_api.update_project(
            project_id=project_id,
            project_name=name,
            project_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Project {project_id} updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@project.command()
@click.argument('project_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this project?')
def delete(project_id):
    """Delete a project."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        project_api = ProjectAPI(client)

        response = project_api.delete_project(project_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Project {project_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
