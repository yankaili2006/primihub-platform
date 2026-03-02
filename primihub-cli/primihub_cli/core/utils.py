"""Utility functions for PrimiHub CLI."""

import hashlib
import ipaddress
import time
import uuid
from typing import Optional
from urllib.parse import urlparse


def generate_timestamp() -> str:
    """Generate current timestamp in milliseconds."""
    return str(int(time.time() * 1000))


def generate_nonce() -> str:
    """Generate a unique nonce for request signing."""
    return str(uuid.uuid4())


def should_bypass_proxy(url: str) -> bool:
    """
    Determine if a URL should bypass proxy settings.

    Returns True for private network addresses:
    - 172.16.0.0/12
    - 10.0.0.0/8
    - 192.168.0.0/16
    - 100.64.0.0/10
    - localhost/127.0.0.1
    """
    try:
        parsed = urlparse(url)
        hostname = parsed.hostname

        if not hostname:
            return False

        # Check for localhost
        if hostname in ('localhost', '127.0.0.1', '::1'):
            return True

        # Try to parse as IP address
        try:
            ip = ipaddress.ip_address(hostname)

            # Check private network ranges
            private_ranges = [
                ipaddress.ip_network('172.16.0.0/12'),
                ipaddress.ip_network('10.0.0.0/8'),
                ipaddress.ip_network('192.168.0.0/16'),
                ipaddress.ip_network('100.64.0.0/10'),
            ]

            for network in private_ranges:
                if ip in network:
                    return True

        except ValueError:
            # Not an IP address, might be a hostname
            pass

        return False

    except Exception:
        return False


def md5_hash(text: str) -> str:
    """Generate MD5 hash of text."""
    return hashlib.md5(text.encode('utf-8')).hexdigest()


def format_file_size(size_bytes: int) -> str:
    """Format file size in human-readable format."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"


def truncate_string(text: str, max_length: int = 50, suffix: str = "...") -> str:
    """Truncate string to maximum length with suffix."""
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix


def safe_get(data: dict, *keys, default=None):
    """Safely get nested dictionary value."""
    for key in keys:
        if isinstance(data, dict):
            data = data.get(key)
            if data is None:
                return default
        else:
            return default
    return data if data is not None else default


def validate_email(email: str) -> bool:
    """Basic email validation."""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def parse_key_value(text: str, separator: str = "=") -> tuple[Optional[str], Optional[str]]:
    """Parse key=value string into tuple."""
    if separator not in text:
        return None, None
    parts = text.split(separator, 1)
    return parts[0].strip(), parts[1].strip()
