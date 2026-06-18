"""Tests for auth.py — 5 tests."""

import os
from unittest.mock import patch

import pytest
from fastapi import HTTPException

from clinemcp.mcp.auth import get_auth_token, verify_token_dependency


class TestTokenLoading:
    """test_token_loaded_from_env"""

    @patch.dict(os.environ, {"CLINEMCP_AUTH_TOKEN": "test-token-123"}, clear=True)
    def test_token_loaded_from_env(self):
        token = get_auth_token()
        assert token == "test-token-123"


class TestValidToken:
    """test_valid_token_passes"""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"CLINEMCP_AUTH_TOKEN": "valid-token"}, clear=True)
    async def test_valid_token_passes(self):
        result = await verify_token_dependency("Bearer valid-token")
        assert result is True


class TestInvalidToken:
    """test_invalid_token_returns_401"""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"CLINEMCP_AUTH_TOKEN": "valid-token"}, clear=True)
    async def test_invalid_token_raises_401(self):
        with pytest.raises(HTTPException) as exc_info:
            await verify_token_dependency("Bearer wrong-token")
        assert exc_info.value.status_code == 401


class TestMissingToken:
    """test_missing_token_returns_401"""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"CLINEMCP_AUTH_TOKEN": "valid-token"}, clear=True)
    async def test_missing_token_raises_401(self):
        with pytest.raises(HTTPException) as exc_info:
            await verify_token_dependency(None)
        assert exc_info.value.status_code == 401

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"CLINEMCP_AUTH_TOKEN": "valid-token"}, clear=True)
    async def test_no_bearer_prefix_raises_401(self):
        with pytest.raises(HTTPException) as exc_info:
            await verify_token_dependency("valid-token")  # No "Bearer " prefix
        assert exc_info.value.status_code == 401


class TestNoTokenConfigured:
    """When no token is configured, allow all."""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {}, clear=True)
    async def test_no_token_configured_allows_all(self):
        result = await verify_token_dependency(None)
        assert result is True
