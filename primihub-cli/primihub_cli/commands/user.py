"""User management commands."""

import click

from ..api.user import UserAPI
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
def user():
    """User management commands."""
    pass


@user.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, format):
    """List all users."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        user_api = UserAPI(client)

        response = user_api.list_users(page_no=page, page_size=size)
        result = response.get('result', {})
        users = result.get('list', [])

        formatter = get_formatter(config)

        if users:
            # Extract key fields for display
            display_users = []
            for u in users:
                display_users.append({
                    'User ID': u.get('userId'),
                    'Username': u.get('userName'),
                    'Email': u.get('userEmail', ''),
                    'Phone': u.get('userPhone', ''),
                    'Organ ID': u.get('organId'),
                })
            click.echo(formatter.format(display_users))
        else:
            click.echo("No users found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@user.command()
@click.argument('user_id', type=int)
def get(user_id):
    """Get user details by ID."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        user_api = UserAPI(client)

        response = user_api.get_user(user_id)
        user_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(user_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@user.command()
@click.option('--username', '-u', required=True, help='Username')
@click.option('--password', '-p', required=True, help='Password')
@click.option('--email', '-e', help='Email address')
@click.option('--phone', help='Phone number')
def create(username, password, email, phone):
    """Create a new user."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        user_api = UserAPI(client)

        response = user_api.create_user(
            username=username,
            password=password,
            email=email,
            phone=phone
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"User '{username}' created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@user.command()
@click.argument('user_id', type=int)
@click.option('--username', '-u', help='New username')
@click.option('--email', '-e', help='New email address')
@click.option('--phone', help='New phone number')
def update(user_id, username, email, phone):
    """Update user information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        user_api = UserAPI(client)

        response = user_api.update_user(
            user_id=user_id,
            username=username,
            email=email,
            phone=phone
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"User {user_id} updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@user.command()
@click.argument('user_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this user?')
def delete(user_id):
    """Delete a user."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        user_api = UserAPI(client)

        response = user_api.delete_user(user_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"User {user_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
