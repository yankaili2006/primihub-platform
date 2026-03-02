"""Data sharing management commands."""

import click

from ..api.share import ShareAPI
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
def share():
    """Data sharing management commands."""
    pass


@share.command(name='list-requests')
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--status', type=click.Choice(['0', '1', '2']), help='Status filter (0=pending, 1=approved, 2=rejected)')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list_requests(page, size, status, format):
    """List data sharing requests."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        status_int = int(status) if status else None
        response = share_api.list_share_requests(
            page_no=page,
            page_size=size,
            status=status_int
        )
        result = response.get('result', {})
        requests = result.get('list', [])

        formatter = get_formatter(config)

        if requests:
            display_requests = []
            for r in requests:
                status_map = {0: 'Pending', 1: 'Approved', 2: 'Rejected'}
                display_requests.append({
                    'Request ID': r.get('requestId'),
                    'Resource ID': r.get('resourceId'),
                    'Target Organ': r.get('targetOrganName', r.get('targetOrganId')),
                    'Type': r.get('shareType'),
                    'Status': status_map.get(r.get('status'), 'Unknown'),
                    'Created': r.get('createTime', 'N/A'),
                })
            click.echo(formatter.format(display_requests))
        else:
            click.echo("No share requests found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command(name='get-request')
@click.argument('request_id', type=int)
def get_request(request_id):
    """Get share request details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.get_share_request(request_id)
        request_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(request_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command(name='create-request')
@click.option('--resource-id', '-r', type=int, required=True, help='Resource ID to share')
@click.option('--target-organ', '-t', type=int, required=True, help='Target organization ID')
@click.option('--type', default='read', type=click.Choice(['read', 'write', 'full']), help='Share type')
@click.option('--desc', '-d', help='Share request description')
def create_request(resource_id, target_organ, type, desc):
    """Create a data sharing request."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.create_share_request(
            resource_id=resource_id,
            target_organ_id=target_organ,
            share_type=type,
            share_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success("Share request created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command()
@click.argument('request_id', type=int)
def approve(request_id):
    """Approve a share request."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.approve_share_request(request_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Share request {request_id} approved successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command()
@click.argument('request_id', type=int)
@click.option('--reason', '-r', help='Rejection reason')
def reject(request_id, reason):
    """Reject a share request."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.reject_share_request(request_id, reject_reason=reason)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Share request {request_id} rejected successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command()
@click.argument('request_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to cancel this share request?')
def cancel(request_id):
    """Cancel a share request."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.cancel_share_request(request_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Share request {request_id} cancelled successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command(name='list-shared')
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list_shared(page, size, format):
    """List shared resources."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.list_shared_resources(page_no=page, page_size=size)
        result = response.get('result', {})
        shared = result.get('list', [])

        formatter = get_formatter(config)

        if shared:
            display_shared = []
            for s in shared:
                display_shared.append({
                    'Share ID': s.get('shareId'),
                    'Resource ID': s.get('resourceId'),
                    'Resource Name': s.get('resourceName'),
                    'Shared With': s.get('targetOrganName', s.get('targetOrganId')),
                    'Type': s.get('shareType'),
                    'Created': s.get('createTime', 'N/A'),
                })
            click.echo(formatter.format(display_shared))
        else:
            click.echo("No shared resources found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command()
@click.argument('share_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to revoke this share?')
def revoke(share_id):
    """Revoke a data share."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.revoke_share(share_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Share {share_id} revoked successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command()
@click.argument('resource_id', type=int)
def permissions(resource_id):
    """Get resource share permissions."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.get_share_permissions(resource_id)
        permissions_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(permissions_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@share.command(name='update-permissions')
@click.argument('share_id', type=int)
@click.option('--type', '-t', required=True, type=click.Choice(['read', 'write', 'full']), help='New share type')
def update_permissions(share_id, type):
    """Update share permissions."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        share_api = ShareAPI(client)

        response = share_api.update_share_permissions(share_id, share_type=type)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Share {share_id} permissions updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
