"""Session management for PrimiHub CLI."""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Optional

from .exceptions import SessionError


class Session:
    """Manages authentication session persistence."""

    DEFAULT_SESSION_DIR = Path.home() / ".primihub"
    DEFAULT_SESSION_FILE = DEFAULT_SESSION_DIR / "session"

    def __init__(self, session_file: Optional[Path] = None):
        """Initialize session manager."""
        self.session_file = session_file or self.DEFAULT_SESSION_FILE
        self._ensure_session_dir()

    def _ensure_session_dir(self):
        """Ensure session directory exists."""
        self.session_file.parent.mkdir(parents=True, exist_ok=True)

    def save(self, token: str, user_info: Dict[str, Any], profile: str = "demo0", expires_in: int = 86400):
        """
        Save session data to file.

        Args:
            token: Authentication token
            user_info: User information dictionary
            profile: Profile name
            expires_in: Token expiration time in seconds (default: 24 hours)
        """
        try:
            session_data = {
                "token": token,
                "user_info": user_info,
                "profile": profile,
                "created_at": datetime.now().isoformat(),
                "expires_at": (datetime.now() + timedelta(seconds=expires_in)).isoformat(),
            }

            with open(self.session_file, 'w', encoding='utf-8') as f:
                json.dump(session_data, f, indent=2, ensure_ascii=False)

            # Set file permissions to 600 for security
            os.chmod(self.session_file, 0o600)

        except Exception as e:
            raise SessionError(f"Failed to save session: {e}")

    def load(self) -> Optional[Dict[str, Any]]:
        """
        Load session data from file.

        Returns:
            Session data dictionary or None if no valid session exists
        """
        if not self.session_file.exists():
            return None

        try:
            with open(self.session_file, 'r', encoding='utf-8') as f:
                session_data = json.load(f)

            # Check if session has expired
            if self._is_expired(session_data):
                self.clear()
                return None

            return session_data

        except json.JSONDecodeError:
            # Invalid session file, clear it
            self.clear()
            return None
        except Exception as e:
            raise SessionError(f"Failed to load session: {e}")

    def _is_expired(self, session_data: Dict[str, Any]) -> bool:
        """Check if session has expired."""
        try:
            expires_at = datetime.fromisoformat(session_data.get('expires_at', ''))
            return datetime.now() >= expires_at
        except (ValueError, TypeError):
            return True

    def clear(self):
        """Clear session data (logout)."""
        try:
            if self.session_file.exists():
                self.session_file.unlink()
        except Exception as e:
            raise SessionError(f"Failed to clear session: {e}")

    def is_active(self) -> bool:
        """Check if there is an active session."""
        session_data = self.load()
        return session_data is not None

    def get_token(self) -> Optional[str]:
        """Get authentication token from session."""
        session_data = self.load()
        if session_data:
            return session_data.get('token')
        return None

    def get_user_info(self) -> Optional[Dict[str, Any]]:
        """Get user information from session."""
        session_data = self.load()
        if session_data:
            return session_data.get('user_info')
        return None

    def get_profile(self) -> Optional[str]:
        """Get profile name from session."""
        session_data = self.load()
        if session_data:
            return session_data.get('profile')
        return None

    def update_token(self, token: str, expires_in: int = 86400):
        """
        Update token in existing session.

        Args:
            token: New authentication token
            expires_in: Token expiration time in seconds
        """
        session_data = self.load()
        if not session_data:
            raise SessionError("No active session to update")

        session_data['token'] = token
        session_data['expires_at'] = (datetime.now() + timedelta(seconds=expires_in)).isoformat()

        try:
            with open(self.session_file, 'w', encoding='utf-8') as f:
                json.dump(session_data, f, indent=2, ensure_ascii=False)
            os.chmod(self.session_file, 0o600)
        except Exception as e:
            raise SessionError(f"Failed to update session: {e}")

    def get_session_info(self) -> Optional[Dict[str, Any]]:
        """
        Get session information for display.

        Returns:
            Dictionary with session details or None if no session
        """
        session_data = self.load()
        if not session_data:
            return None

        user_info = session_data.get('user_info', {})
        expires_at = session_data.get('expires_at', '')

        try:
            expires_dt = datetime.fromisoformat(expires_at)
            time_remaining = expires_dt - datetime.now()
            hours_remaining = int(time_remaining.total_seconds() / 3600)
        except (ValueError, TypeError):
            hours_remaining = 0

        return {
            "user_id": user_info.get('userId'),
            "username": user_info.get('userName'),
            "organ_id": user_info.get('organId'),
            "organ_name": user_info.get('organName'),
            "profile": session_data.get('profile'),
            "expires_in_hours": hours_remaining,
            "created_at": session_data.get('created_at'),
        }
