"""Data management commands."""

import click

from ..api.data import DataAPI
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
def data():
    """Data management commands."""
    pass


@data.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--format', '-f', type=click.Choice(['table', 'json']), help='Output format')
def list(page, size, format):
    """List all datasets."""
    try:
        config = Config()
        config.load()

        if format:
            config.set_output_format(format)

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.list_datasets(page_no=page, page_size=size)
        result = response.get('result', {})
        datasets = result.get('list', [])

        formatter = get_formatter(config)

        if datasets:
            display_datasets = []
            for d in datasets:
                display_datasets.append({
                    'Dataset ID': d.get('datasetId'),
                    'Name': d.get('datasetName'),
                    'Rows': d.get('rowCount', 'N/A'),
                    'Columns': d.get('columnCount', 'N/A'),
                    'Created': d.get('createTime', 'N/A'),
                })
            click.echo(formatter.format(display_datasets))
        else:
            click.echo("No datasets found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@data.command()
@click.argument('dataset_id', type=int)
def get(dataset_id):
    """Get dataset details."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.get_dataset(dataset_id)
        dataset_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(dataset_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@data.command()
@click.argument('dataset_id', type=int)
def fields(dataset_id):
    """Get dataset field information."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.get_dataset_fields(dataset_id)
        fields_data = response.get('result', [])

        formatter = get_formatter(config)

        if fields_data:
            display_fields = []
            for f in fields_data:
                display_fields.append({
                    'Field Name': f.get('fieldName'),
                    'Field Type': f.get('fieldType'),
                    'Description': f.get('fieldDesc', ''),
                })
            click.echo(formatter.format(display_fields))
        else:
            click.echo("No fields found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@data.command()
@click.argument('dataset_id', type=int)
@click.option('--limit', default=10, help='Number of rows to preview')
def preview(dataset_id, limit):
    """Preview dataset content."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.preview_dataset(dataset_id, limit=limit)
        preview_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(preview_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@data.command()
@click.option('--name', '-n', required=True, help='Dataset name')
@click.option('--file', '-f', 'file_path', required=True, type=click.Path(exists=True), help='Dataset file path')
@click.option('--desc', '-d', help='Dataset description')
def upload(name, file_path, desc):
    """Upload a dataset."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.upload_dataset(
            dataset_name=name,
            file_path=file_path,
            dataset_desc=desc
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Dataset '{name}' uploaded successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@data.command()
@click.argument('dataset_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this dataset?')
def delete(dataset_id):
    """Delete a dataset."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.delete_dataset(dataset_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Dataset {dataset_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@data.command()
@click.argument('dataset_id', type=int)
def statistics(dataset_id):
    """Get dataset statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        data_api = DataAPI(client)

        response = data_api.get_dataset_statistics(dataset_id)
        stats_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(stats_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
