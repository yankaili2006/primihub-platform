"""Tests for core session module."""

import pytest
import tempfile
import json
from pathlib import Path
from datetime import datetime, timedelta
from unittest.mock import patch, mock_open
from primihub_cli.core.session import Session
from primihub_cli.core.exceptions import SessionError


class TestSession:
    """Test cases for Session."""

    def test_session_initialization(self):
        """Test session initialization."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))
            assert session.session_file == session_file

    def test_save_session(self):
        """Test saving session data."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            token = "test_token_123"
            user_info = {
                'userId': 1,
                'userName': 'admin',
                'organId': 1
            }

            session.save(token, user_info, profile='demo0', expires_in=86400)

            # Verify file was created
            assert session_file.exists()

            # Verify content
            with open(session_file, 'r') as f:
                data = json.load(f)
                assert data['token'] == token
                assert data['user_info']['userId'] == 1
                assert data['profile'] == 'demo0'
                assert 'expires_at' in data

    def test_load_session(self):
        """Test loading session data."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save first
            token = "test_token_123"
            user_info = {'userId': 1, 'userName': 'admin'}
            session.save(token, user_info)

            # Load
            loaded_data = session.load()
            assert loaded_data['token'] == token
            assert loaded_data['user_info']['userId'] == 1

    def test_load_nonexistent_session(self):
        """Test loading session when file doesn't exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'nonexistent_session'
            session = Session(session_file=str(session_file))

            loaded_data = session.load()
            assert loaded_data is None

    def test_clear_session(self):
        """Test clearing session data."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save first
            session.save("test_token", {'userId': 1})
            assert session_file.exists()

            # Clear
            session.clear()
            assert not session_file.exists()

    def test_is_valid_with_valid_session(self):
        """Test checking if session is valid."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save with future expiration
            expires_at = datetime.now() + timedelta(hours=1)
            session.save(
                "test_token",
                {'userId': 1},
                expires_in=3600
            )

            assert session.is_valid() is True

    def test_is_valid_with_expired_session(self):
        """Test checking if expired session is invalid."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save with past expiration
            session_data = {
                'token': 'test_token',
                'user_info': {'userId': 1},
                'profile': 'demo0',
                'expires_at': (datetime.now() - timedelta(hours=1)).isoformat()
            }

            with open(session_file, 'w') as f:
                json.dump(session_data, f)

            assert session.is_valid() is False

    def test_is_valid_with_no_session(self):
        """Test checking validity when no session exists."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'nonexistent_session'
            session = Session(session_file=str(session_file))

            assert session.is_valid() is False

    def test_get_token(self):
        """Test getting token from session."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            token = "test_token_123"
            session.save(token, {'userId': 1})

            assert session.get_token() == token

    def test_get_token_from_invalid_session(self):
        """Test getting token from invalid session returns None."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save expired session
            session_data = {
                'token': 'test_token',
                'user_info': {'userId': 1},
                'expires_at': (datetime.now() - timedelta(hours=1)).isoformat()
            }

            with open(session_file, 'w') as f:
                json.dump(session_data, f)

            assert session.get_token() is None

    def test_get_user_info(self):
        """Test getting user info from session."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            user_info = {
                'userId': 1,
                'userName': 'admin',
                'organId': 1
            }
            session.save("test_token", user_info)

            loaded_info = session.get_user_info()
            assert loaded_info['userId'] == 1
            assert loaded_info['userName'] == 'admin'

    def test_get_profile(self):
        """Test getting profile from session."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            session.save("test_token", {'userId': 1}, profile='demo1')

            assert session.get_profile() == 'demo1'

    def test_update_token(self):
        """Test updating token in existing session."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save initial session
            session.save("old_token", {'userId': 1})

            # Update token
            session.update_token("new_token")

            # Verify
            loaded_data = session.load()
            assert loaded_data['token'] == "new_token"
            assert loaded_data['user_info']['userId'] == 1

    def test_session_file_permissions(self):
        """Test that session file has correct permissions (600)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            session.save("test_token", {'userId': 1})

            # Check file permissions (should be 600 - owner read/write only)
            import stat
            file_stat = session_file.stat()
            permissions = stat.filemode(file_stat.st_mode)
            # On Unix systems, should be -rw-------
            assert file_stat.st_mode & 0o777 == 0o600

    def test_corrupted_session_file(self):
        """Test handling of corrupted session file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Write invalid JSON
            with open(session_file, 'w') as f:
                f.write("invalid json content {{{")

            # Should return None instead of raising exception
            loaded_data = session.load()
            assert loaded_data is None

    def test_session_expiration_calculation(self):
        """Test that expiration time is calculated correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            session_file = Path(tmpdir) / 'session'
            session = Session(session_file=str(session_file))

            # Save with 1 hour expiration
            before_save = datetime.now()
            session.save("test_token", {'userId': 1}, expires_in=3600)
            after_save = datetime.now()

            # Load and check expiration
            loaded_data = session.load()
            expires_at = datetime.fromisoformat(loaded_data['expires_at'])

            # Should be approximately 1 hour from now
            expected_min = before_save + timedelta(hours=1)
            expected_max = after_save + timedelta(hours=1)

            assert expected_min <= expires_at <= expected_max
