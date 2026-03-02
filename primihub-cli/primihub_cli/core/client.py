"""HTTP client for PrimiHub API."""

import logging
from typing import Any, Dict, Optional
from urllib.parse import urljoin

import requests

from .config import Config
from .exceptions import (
    APIError,
    AuthenticationError,
    AuthorizationError,
    NetworkError,
    NotFoundError,
    ServerError,
)
from .session import Session
from .utils import generate_nonce, generate_timestamp, should_bypass_proxy

logger = logging.getLogger(__name__)


class PrimiHubClient:
    """Unified API client for PrimiHub platform."""

    def __init__(
        self,
        base_url: str,
        token: Optional[str] = None,
        config: Optional[Config] = None,
        session: Optional[Session] = None,
    ):
        """
        Initialize PrimiHub API client.

        Args:
            base_url: Base URL of the PrimiHub API
            token: Authentication token (optional)
            config: Configuration instance (optional)
            session: Session instance (optional)
        """
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.config = config or Config()
        self.session_manager = session or Session()
        self.http_session = requests.Session()

        # Set default headers
        self.http_session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        })

    def request(
        self,
        method: str,
        endpoint: str,
        data: Optional[Dict[str, Any]] = None,
        json_data: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        files: Optional[Dict[str, Any]] = None,
        timeout: int = 30,
        retry: int = 3,
    ) -> Dict[str, Any]:
        """
        Make HTTP request to PrimiHub API.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE)
            endpoint: API endpoint path
            data: Form data
            json_data: JSON data
            params: Query parameters
            headers: Additional headers
            files: Files to upload
            timeout: Request timeout in seconds
            retry: Number of retry attempts

        Returns:
            Response data as dictionary

        Raises:
            APIError: On API errors
            NetworkError: On network errors
        """
        # Build full URL - strip leading slash from endpoint to avoid urljoin issues
        if endpoint.startswith('/'):
            endpoint = endpoint[1:]
        url = f"{self.base_url}/{endpoint}"

        # Prepare headers
        request_headers = self.http_session.headers.copy()
        if headers:
            request_headers.update(headers)

        # Generate timestamp and nonce
        timestamp = generate_timestamp()
        nonce = generate_nonce()

        # Auto-inject token if available
        if self.token:
            request_headers['token'] = self.token
        elif self.session_manager.is_active():
            token = self.session_manager.get_token()
            if token:
                request_headers['token'] = token

        # Add timestamp and nonce for request signing
        request_headers['timestamp'] = timestamp
        request_headers['nonce'] = nonce

        # For form data requests, also add timestamp and nonce to data
        if data is not None:
            if not isinstance(data, dict):
                data = {}
            data['timestamp'] = timestamp
            data['nonce'] = nonce
            if self.token:
                data['token'] = self.token
            elif self.session_manager.is_active():
                token = self.session_manager.get_token()
                if token:
                    data['token'] = token

        # For JSON requests, add timestamp and nonce to json_data
        if json_data is not None:
            json_data['timestamp'] = timestamp
            json_data['nonce'] = nonce
            if self.token:
                json_data['token'] = self.token
            elif self.session_manager.is_active():
                token = self.session_manager.get_token()
                if token:
                    json_data['token'] = token

        # Configure proxy settings
        proxies = self._get_proxies(url)

        # Remove Content-Type header only if uploading files
        # For form data, we need to keep it or let requests set it automatically
        if files:
            request_headers.pop('Content-Type', None)
        elif data:
            # For form data, use application/x-www-form-urlencoded
            request_headers['Content-Type'] = 'application/x-www-form-urlencoded'

        # Make request with retry logic
        last_exception = None
        for attempt in range(retry):
            try:
                response = self.http_session.request(
                    method=method.upper(),
                    url=url,
                    data=data,
                    json=json_data,
                    params=params,
                    headers=request_headers,
                    files=files,
                    proxies=proxies,
                    timeout=timeout,
                )

                # Log request details if verbose
                if self.config.is_verbose():
                    logger.info(f"{method.upper()} {url} - Status: {response.status_code}")

                # Handle response
                return self._handle_response(response)

            except requests.exceptions.Timeout as e:
                last_exception = NetworkError(f"Request timeout: {e}")
                if attempt < retry - 1:
                    logger.warning(f"Request timeout, retrying ({attempt + 1}/{retry})...")
                    continue
            except requests.exceptions.ConnectionError as e:
                last_exception = NetworkError(f"Connection error: {e}")
                if attempt < retry - 1:
                    logger.warning(f"Connection error, retrying ({attempt + 1}/{retry})...")
                    continue
            except requests.exceptions.RequestException as e:
                last_exception = NetworkError(f"Request failed: {e}")
                break

        # All retries failed
        raise last_exception

    def _get_proxies(self, url: str) -> Dict[str, str]:
        """Get proxy settings, bypassing for private networks."""
        if should_bypass_proxy(url):
            return {}

        return self.config.get_proxy_settings()

    def _handle_response(self, response: requests.Response) -> Dict[str, Any]:
        """
        Handle API response and raise appropriate exceptions.

        Args:
            response: HTTP response object

        Returns:
            Response data as dictionary

        Raises:
            APIError: On API errors
        """
        # Try to parse JSON response
        try:
            data = response.json()
        except ValueError:
            data = {"message": response.text}

        # Handle error status codes
        if response.status_code == 401:
            raise AuthenticationError(
                data.get('msg', 'Authentication failed'),
                status_code=response.status_code,
                response=data,
            )
        elif response.status_code == 403:
            raise AuthorizationError(
                data.get('msg', 'Permission denied'),
                status_code=response.status_code,
                response=data,
            )
        elif response.status_code == 404:
            raise NotFoundError(
                data.get('msg', 'Resource not found'),
                status_code=response.status_code,
                response=data,
            )
        elif response.status_code >= 500:
            raise ServerError(
                data.get('msg', 'Server error'),
                status_code=response.status_code,
                response=data,
            )
        elif response.status_code >= 400:
            raise APIError(
                data.get('msg', f'API error: {response.status_code}'),
                status_code=response.status_code,
                response=data,
            )

        # Check for application-level errors
        if isinstance(data, dict):
            code = data.get('code')
            if code is not None and code != 0 and code != 200:
                raise APIError(
                    data.get('msg', f'API returned error code: {code}'),
                    status_code=response.status_code,
                    response=data,
                )

        return data

    def get(self, endpoint: str, **kwargs) -> Dict[str, Any]:
        """Make GET request."""
        return self.request('GET', endpoint, **kwargs)

    def post(self, endpoint: str, **kwargs) -> Dict[str, Any]:
        """Make POST request."""
        return self.request('POST', endpoint, **kwargs)

    def put(self, endpoint: str, **kwargs) -> Dict[str, Any]:
        """Make PUT request."""
        return self.request('PUT', endpoint, **kwargs)

    def delete(self, endpoint: str, **kwargs) -> Dict[str, Any]:
        """Make DELETE request."""
        return self.request('DELETE', endpoint, **kwargs)

    def set_token(self, token: str):
        """Set authentication token."""
        self.token = token

    def clear_token(self):
        """Clear authentication token."""
        self.token = None

    @classmethod
    def from_config(cls, profile: Optional[str] = None) -> 'PrimiHubClient':
        """
        Create client from configuration.

        Args:
            profile: Profile name (uses default if not specified)

        Returns:
            Configured PrimiHubClient instance
        """
        config = Config()
        config.load()

        profile_config = config.get_profile(profile)
        base_url = profile_config['base_url']

        session = Session()
        token = session.get_token()

        return cls(base_url=base_url, token=token, config=config, session=session)
