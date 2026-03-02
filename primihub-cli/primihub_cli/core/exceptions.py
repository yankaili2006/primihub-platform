"""Custom exceptions for PrimiHub CLI."""


class PrimiHubError(Exception):
    """Base exception for all PrimiHub CLI errors."""
    pass


class APIError(PrimiHubError):
    """Base exception for API-related errors."""

    def __init__(self, message, status_code=None, response=None):
        super().__init__(message)
        self.status_code = status_code
        self.response = response


class AuthenticationError(APIError):
    """Raised when authentication fails."""
    pass


class AuthorizationError(APIError):
    """Raised when user lacks permission for an operation."""
    pass


class NetworkError(APIError):
    """Raised when network communication fails."""
    pass


class ServerError(APIError):
    """Raised when server returns 5xx error."""
    pass


class NotFoundError(APIError):
    """Raised when requested resource is not found (404)."""
    pass


class ValidationError(PrimiHubError):
    """Raised when input validation fails."""
    pass


class ConfigError(PrimiHubError):
    """Raised when configuration is invalid or missing."""
    pass


class SessionError(PrimiHubError):
    """Raised when session management fails."""
    pass


class ProfileNotFoundError(ConfigError):
    """Raised when specified profile doesn't exist."""
    pass
