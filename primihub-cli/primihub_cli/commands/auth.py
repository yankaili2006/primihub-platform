"""Authentication commands."""

import click
from getpass import getpass

from ..api.auth import AuthAPI
from ..core.client import PrimiHubClient
from ..core.config import Config
from ..core.exceptions import PrimiHubError
from ..core.session import Session
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
def auth():
    """Authentication commands."""
    pass


@auth.command()
@click.option('--profile', default=None, help='Profile to use for login')
@click.option('--username', '-u', default=None, help='Username')
@click.option('--password', '-p', default=None, help='Password (not recommended, use prompt)')
def login(profile, username, password):
    """Login to PrimiHub platform."""
    try:
        # Load configuration
        config = Config()
        config.load()

        # Get profile configuration
        profile_config = config.get_profile(profile)
        base_url = profile_config['base_url']
        profile_name = profile or config.get_default_profile()

        # Get credentials
        if not username:
            username = click.prompt('Username')

        if not password:
            password = getpass('Password: ')

        # Create client and authenticate
        client = PrimiHubClient(base_url=base_url, config=config)
        auth_api = AuthAPI(client)

        click.echo(f"Logging in to {base_url}...")
        response = auth_api.login(username, password)

        # Extract token and user info
        result = response.get('result', {})
        token = result.get('token')
        sys_user = result.get('sysUser', {})

        if not token:
            click.echo(click.style("Login failed: No token received", fg='red'))
            return

        # Prepare user info for session
        user_info = {
            'userId': sys_user.get('userId'),
            'userName': sys_user.get('userName'),
            'organId': sys_user.get('organId'),
            'organName': sys_user.get('organName'),
        }

        # Save session
        session = Session()
        session.save(token=token, user_info=user_info, profile=profile_name)

        # Display success message
        formatter = get_formatter(config)
        click.echo(formatter.format_success(
            f"Successfully logged in as {user_info.get('userName', username)}"
        ))

        # Display user info
        display_info = {
            'User ID': user_info.get('userId'),
            'Username': user_info.get('userName'),
            'Organ ID': user_info.get('organId'),
            'Organ Name': user_info.get('organName'),
            'Profile': profile_name,
        }
        click.echo()
        click.echo(formatter.format(display_info))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
    except Exception as e:
        click.echo(click.style(f"Unexpected error: {e}", fg='red'), err=True)
        raise click.Abort()


@auth.command()
def logout():
    """Logout from PrimiHub platform."""
    try:
        # Check if session exists
        session = Session()
        if not session.is_active():
            click.echo(click.style("No active session", fg='yellow'))
            return

        # Load configuration
        config = Config()
        config.load()

        # Get client and call logout API
        try:
            client = PrimiHubClient.from_config()
            auth_api = AuthAPI(client)
            auth_api.logout()
        except Exception:
            # Ignore logout API errors, still clear local session
            pass

        # Clear session
        session.clear()

        formatter = get_formatter(config)
        click.echo(formatter.format_success("Successfully logged out"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
    except Exception as e:
        click.echo(click.style(f"Unexpected error: {e}", fg='red'), err=True)
        raise click.Abort()


@auth.command()
def whoami():
    """Display current user information."""
    try:
        # Check if session exists
        session = Session()
        if not session.is_active():
            click.echo(click.style("Not logged in", fg='yellow'))
            click.echo("Run 'primihub login' to authenticate")
            return

        # Get session info
        session_info = session.get_session_info()

        # Load configuration
        config = Config()
        config.load()

        # Display user info
        formatter = get_formatter(config)
        display_info = {
            'User ID': session_info.get('user_id'),
            'Username': session_info.get('username'),
            'Organ ID': session_info.get('organ_id'),
            'Organ Name': session_info.get('organ_name'),
            'Profile': session_info.get('profile'),
            'Session Expires In': f"{session_info.get('expires_in_hours')} hours",
        }
        click.echo(formatter.format(display_info))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
    except Exception as e:
        click.echo(click.style(f"Unexpected error: {e}", fg='red'), err=True)
        raise click.Abort()


@auth.command()
def status():
    """Display authentication status."""
    try:
        # Check if session exists
        session = Session()
        config = Config()
        config.load()
        formatter = get_formatter(config)

        if not session.is_active():
            click.echo(formatter.format_warning("Not authenticated"))
            click.echo()
            click.echo("Run 'primihub login' to authenticate")
            return

        # Get session info
        session_info = session.get_session_info()

        # Display status
        click.echo(formatter.format_success("Authenticated"))
        click.echo()

        display_info = {
            'Status': 'Active',
            'Username': session_info.get('username'),
            'Organ': session_info.get('organ_name'),
            'Profile': session_info.get('profile'),
            'Expires In': f"{session_info.get('expires_in_hours')} hours",
            'Created At': session_info.get('created_at'),
        }
        click.echo(formatter.format(display_info))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
    except Exception as e:
        click.echo(click.style(f"Unexpected error: {e}", fg='red'), err=True)
        raise click.Abort()
