"""Node management commands."""

import click

from ..api.node import NodeAPI
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
def node():
    """Node management commands."""
    pass


@node.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, format):
    """List all nodes."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.list_nodes(page_no=page, page_size=size)
        result = response.get('result', {})
        nodes = result.get('list', [])

        formatter = get_formatter(config)

        if nodes:
            display_nodes = []
            for n in nodes:
                display_nodes.append({
                    'Node ID': n.get('nodeId'),
                    'Name': n.get('nodeName'),
                    'IP': n.get('nodeIp'),
                    'Port': n.get('nodePort'),
                    'Organ ID': n.get('organId'),
                    'Status': n.get('status', 'Unknown'),
                })
            click.echo(formatter.format(display_nodes))
        else:
            click.echo("No nodes found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
def get(node_id):
    """Get node details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.get_node(node_id)
        node_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(node_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
def status(node_id):
    """Get node status."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.get_node_status(node_id)
        status_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(status_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.option('--name', '-n', required=True, help='Node name')
@click.option('--ip', required=True, help='Node IP address')
@click.option('--port', type=int, required=True, help='Node port')
@click.option('--organ-id', type=int, required=True, help='Organization ID')
def register(name, ip, port, organ_id):
    """Register a new node."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.register_node(
            node_name=name,
            node_ip=ip,
            node_port=port,
            organ_id=organ_id
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Node '{name}' registered successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
@click.option('--name', '-n', help='New node name')
@click.option('--ip', help='New node IP address')
@click.option('--port', type=int, help='New node port')
def update(node_id, name, ip, port):
    """Update node information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.update_node(
            node_id=node_id,
            node_name=name,
            node_ip=ip,
            node_port=port
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Node {node_id} updated successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this node?')
def delete(node_id):
    """Delete a node."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.delete_node(node_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Node {node_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
@click.argument('target_node_id', type=int)
def connect(node_id, target_node_id):
    """Connect two nodes."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.connect_node(node_id, target_node_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(
            f"Node {node_id} connected to node {target_node_id}"
        ))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
@click.argument('target_node_id', type=int)
def disconnect(node_id, target_node_id):
    """Disconnect two nodes."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.disconnect_node(node_id, target_node_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(
            f"Node {node_id} disconnected from node {target_node_id}"
        ))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@node.command()
@click.argument('node_id', type=int)
def connections(node_id):
    """Get node connections."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        node_api = NodeAPI(client)

        response = node_api.get_node_connections(node_id)
        connections_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(connections_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
