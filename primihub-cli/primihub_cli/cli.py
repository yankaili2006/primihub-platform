"""Main CLI entry point for PrimiHub CLI."""

import click

from .commands.auth import auth
from .commands.user import user
from .commands.organ import organ
from .commands.project import project
from .commands.resource import resource
from .commands.psi import psi
from .commands.pir import pir
from .commands.fl import fl
from .commands.task import task
from .commands.node import node
from .commands.config import config
from .commands.data import data
from .commands.system import system
from .commands.fusion import fusion
from .commands.share import share
from .commands.log import log
from .commands.monitor import monitor


@click.group()
@click.version_option(version='2.0.0', prog_name='primihub')
@click.pass_context
def cli(ctx):
    """
    PrimiHub CLI - Modern command-line interface for PrimiHub operations.

    A modular CLI tool for managing privacy-preserving computation tasks,
    including PSI, PIR, and Federated Learning operations.
    """
    # Ensure context object exists
    ctx.ensure_object(dict)


# Register command groups
cli.add_command(auth, name='auth')
cli.add_command(user, name='user')
cli.add_command(organ, name='organ')
cli.add_command(project, name='project')
cli.add_command(resource, name='resource')
cli.add_command(psi, name='psi')
cli.add_command(pir, name='pir')
cli.add_command(fl, name='fl')
cli.add_command(task, name='task')
cli.add_command(node, name='node')
cli.add_command(config, name='config')
cli.add_command(data, name='data')
cli.add_command(system, name='system')
cli.add_command(fusion, name='fusion')
cli.add_command(share, name='share')
cli.add_command(log, name='log')
cli.add_command(monitor, name='monitor')

# Add individual auth commands to top level for convenience
cli.add_command(auth.commands['login'])
cli.add_command(auth.commands['logout'])
cli.add_command(auth.commands['whoami'])
cli.add_command(auth.commands['status'])


if __name__ == '__main__':
    cli()
