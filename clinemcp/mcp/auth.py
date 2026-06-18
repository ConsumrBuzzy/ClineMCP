"""Bearer token authentication (ported from TOBOR)."""

import os
import secrets
from typing import Annotated

from fastapi import HTTPException, Header


def get_auth_token() -> str:
    """Get auth token from environment."""
    token = os.environ.get("CLINEMCP_AUTH_TOKEN", "")
    if not token:
        # Fallback for development
        token = os.environ.get("DUGGERBOT_AUTH_TOKEN", "")
    return token


async def verify_token_dependency(
    authorization: Annotated[str | None, Header()] = None,
) -> bool:
    """FastAPI dependency to verify Bearer token.

    Returns True if token valid or no token configured.
    Raises HTTPException 401 if token invalid.
    """
    expected_token = get_auth_token()
    if not expected_token:
        # No token configured - allow all (development mode)
        return True

    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")

    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Bearer token required")

    provided_token = authorization[7:].strip()  # Remove "Bearer " prefix

    if not secrets.compare_digest(provided_token.encode(), expected_token.encode()):
        raise HTTPException(status_code=401, detail="Invalid token")

    return True
