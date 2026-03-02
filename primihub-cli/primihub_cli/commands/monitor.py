"""Monitoring and statistics commands."""

import click

from ..api.monitor import MonitorAPI
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
def monitor():
    """Monitoring and statistics commands."""
    pass


@monitor.command()
def dashboard():
    """Get dashboard statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_dashboard_stats()
        stats_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(stats_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='task-stats')
@click.option('--start', help='Start time (YYYY-MM-DD)')
@click.option('--end', help='End time (YYYY-MM-DD)')
@click.option('--type', '-t', type=click.Choice(['psi', 'pir', 'fl']), help='Task type filter')
def task_stats(start, end, type):
    """Get task statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_task_statistics(
            start_time=start,
            end_time=end,
            task_type=type
        )
        stats_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(stats_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='resource-usage')
@click.option('--type', '-t', help='Resource type filter')
def resource_usage(type):
    """Get resource usage statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_resource_usage(resource_type=type)
        usage_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(usage_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='node-stats')
def node_stats():
    """Get node statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_node_statistics()
        stats_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(stats_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='user-activity')
@click.option('--start', help='Start time')
@click.option('--end', help='End time')
@click.option('--user-id', type=int, help='User ID filter')
def user_activity(start, end, user_id):
    """Get user activity statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_user_activity(
            start_time=start,
            end_time=end,
            user_id=user_id
        )
        activity_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(activity_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command()
@click.option('--type', '-t', type=click.Choice(['cpu', 'memory', 'disk', 'network']), help='Metric type')
@click.option('--start', help='Start time')
@click.option('--end', help='End time')
def performance(type, start, end):
    """Get performance metrics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_performance_metrics(
            metric_type=type,
            start_time=start,
            end_time=end
        )
        metrics_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(metrics_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='error-stats')
@click.option('--start', help='Start time')
@click.option('--end', help='End time')
@click.option('--type', '-t', help='Error type filter')
def error_stats(start, end, type):
    """Get error statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_error_statistics(
            start_time=start,
            end_time=end,
            error_type=type
        )
        stats_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(stats_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='api-stats')
@click.option('--start', help='Start time')
@click.option('--end', help='End time')
def api_stats(start, end):
    """Get API call statistics."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_api_statistics(
            start_time=start,
            end_time=end
        )
        stats_data = response.get('result', {})

        formatter = get_formatter(config)
        click.echo(formatter.format(stats_data))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='set-alert')
@click.option('--name', '-n', required=True, help='Alert rule name')
@click.option('--metric', '-m', required=True, help='Metric type to monitor')
@click.option('--threshold', '-t', type=float, required=True, help='Alert threshold')
@click.option('--condition', '-c', default='greater', type=click.Choice(['greater', 'less', 'equal']), help='Condition')
@click.option('--level', '-l', default='warning', type=click.Choice(['info', 'warning', 'error']), help='Alert level')
def set_alert(name, metric, threshold, condition, level):
    """Set monitoring alert rule."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.set_alert_rule(
            rule_name=name,
            metric_type=metric,
            threshold=threshold,
            condition=condition,
            alert_level=level
        )

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Alert rule '{name}' created successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='list-alerts')
def list_alert_rules():
    """Get all alert rules."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_alert_rules()
        rules = response.get('result', [])

        formatter = get_formatter(config)

        if rules:
            display_rules = []
            for r in rules:
                display_rules.append({
                    'Rule ID': r.get('ruleId'),
                    'Name': r.get('ruleName'),
                    'Metric': r.get('metricType'),
                    'Threshold': r.get('threshold'),
                    'Condition': r.get('condition'),
                    'Level': r.get('alertLevel'),
                })
            click.echo(formatter.format(display_rules))
        else:
            click.echo("No alert rules found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command(name='delete-alert')
@click.argument('rule_id', type=int)
@click.confirmation_option(prompt='Are you sure you want to delete this alert rule?')
def delete_alert_rule(rule_id):
    """Delete an alert rule."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.delete_alert_rule(rule_id)

        formatter = get_formatter(config)
        click.echo(formatter.format_success(f"Alert rule {rule_id} deleted successfully"))

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()


@monitor.command()
@click.option('--page', default=1, help='Page number')
@click.option('--size', default=10, help='Page size')
@click.option('--level', type=click.Choice(['info', 'warning', 'error']), help='Alert level filter')
@click.option('--status', type=click.Choice(['active', 'resolved']), help='Status filter')
def alerts(page, size, level, status):
    """Get triggered alerts."""
    try:
        config = Config()
        config.load()

        client = PrimiHubClient.from_config()
        monitor_api = MonitorAPI(client)

        response = monitor_api.get_alerts(
            page_no=page,
            page_size=size,
            alert_level=level,
            status=status
        )
        result = response.get('result', {})
        alerts_list = result.get('list', [])

        formatter = get_formatter(config)

        if alerts_list:
            display_alerts = []
            for a in alerts_list:
                display_alerts.append({
                    'Alert ID': a.get('alertId'),
                    'Rule': a.get('ruleName'),
                    'Level': a.get('alertLevel'),
                    'Status': a.get('status'),
                    'Triggered': a.get('triggerTime', 'N/A'),
                })
            click.echo(formatter.format(display_alerts))
        else:
            click.echo("No alerts found")

    except PrimiHubError as e:
        click.echo(click.style(f"Error: {e}", fg='red'), err=True)
        raise click.Abort()
