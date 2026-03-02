"""Configuration management commands."""

import click

from ..core.config import Config
from ..core.exceptions import PrimiHubError
from ..formatters.json import JSONFormatter
from ..formatters.yaml import YAMLFormatter
from ..formatters.table import TableFormatter


def get_formatter(config: Config):
    """Get formatter based on config."""
    output_format = config.get_output_format()
    color = config.is_color_enabled()

    if output_format == 'json':
        return JSONFormatter(color=color)
    elif output_format == 'yaml':
        return YAMLFormatter(color=color)
    else:
        return TableFormatter(color=color)


@click.group()
def config():
    """Configuration management commands."""
    pass


@config.command()
@click.option('--format', '-f', type=click.Choice(['table', 'json', 'yaml']), help='Output format')
def show(format):
    """Show current configuration."""
    try:
        cfg = Config()
        cfg.load()

        if format:
            cfg.set_output_format(format)

        formatter = get_formatter(cfg)

        # Get all configuration
        config_data = {
            'default_profile': cfg.get_default_profile(),
            'profiles': cfg.list_profiles(),
            'output_format': cfg.get_output_format(),
            'color_enabled': cfg.is_color_enabled(),
            'verbose': cfg.is_verbose(),
        }

        click.echo(formatter.format(config_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command()
@click.argument('key')
@click.argument('value')
def set(key, value):
    """Set a configuration value."""
    try:
        cfg = Config()
        cfg.load()

        # Handle boolean values
        if value.lower() in ('true', 'false'):
            value = value.lower() == 'true'

        # Handle numeric values
        try:
            if '.' in value:
                value = float(value)
            else:
                value = int(value)
        except ValueError:
            pass

        cfg.set(key, value)

        formatter = get_formatter(cfg)
        click.echo(formatter.format_success(f"Configuration updated: {key} = {value}"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command()
@click.confirmation_option(prompt='Are you sure you want to reset configuration to defaults?')
def reset():
    """Reset configuration to defaults."""
    try:
        cfg = Config()
        cfg.reset()

        formatter = get_formatter(cfg)
        click.echo(formatter.format_success("Configuration reset to defaults"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command()
def profiles():
    """List all available profiles."""
    try:
        cfg = Config()
        cfg.load()

        profile_list = cfg.list_profiles()
        default_profile = cfg.get_default_profile()

        formatter = get_formatter(cfg)

        profiles_data = []
        for profile_name in profile_list:
            profile_config = cfg.get_profile(profile_name)
            is_default = '✓' if profile_name == default_profile else ''
            profiles_data.append({
                'Profile': profile_name,
                'Default': is_default,
                'Base URL': profile_config.get('base_url'),
                'Organ ID': profile_config.get('organ_id'),
            })

        click.echo(formatter.format(profiles_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command(name='profile')
@click.argument('profile_name')
def set_profile(profile_name):
    """Set the default profile."""
    try:
        cfg = Config()
        cfg.load()

        cfg.set_default_profile(profile_name)

        formatter = get_formatter(cfg)
        click.echo(formatter.format_success(f"Default profile set to: {profile_name}"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command(name='get')
@click.argument('key')
def get_value(key):
    """Get a configuration value."""
    try:
        cfg = Config()
        cfg.load()

        value = cfg.get(key)

        if value is None:
            click.echo(click.style(f"Configuration key '{key}' not found", fg='yellow'))
        else:
            formatter = get_formatter(cfg)
            click.echo(formatter.format({key: value}))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command(name='add-profile')
@click.argument('profile_name')
@click.option('--base-url', required=True, help='Base URL for the profile')
@click.option('--organ-id', type=int, required=True, help='Organization ID')
@click.option('--organ-name', help='Organization name')
def add_profile(profile_name, base_url, organ_id, organ_name):
    """Add a new profile."""
    try:
        cfg = Config()
        cfg.load()

        profile_data = {
            'base_url': base_url,
            'organ_id': organ_id,
            'organ_name': organ_name or profile_name,
        }

        cfg.set_profile(profile_name, profile_data)

        formatter = get_formatter(cfg)
        click.echo(formatter.format_success(f"Profile '{profile_name}' added successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@config.command(name='delete-profile')
@click.argument('profile_name')
@click.confirmation_option(prompt='Are you sure you want to delete this profile?')
def delete_profile(profile_name):
    """Delete a profile."""
    try:
        cfg = Config()
        cfg.load()

        cfg.delete_profile(profile_name)

        formatter = get_formatter(cfg)
        click.echo(formatter.format_success(f"Profile '{profile_name}' deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
