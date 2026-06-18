# ClineMCP

Standalone MCP server for managing Cline CLI sessions.

## Overview

ClineMCP manages Cline CLI sessions as observable, persistent, self-reporting processes. Cline runs as a child of ClineMCP, not as a subprocess of TOBOR, allowing sessions to survive TOBOR restarts.

## Features

- Session persistence via SQLite
- Telegram notifications on completion
- Bearer token authentication
- NSSM service deployment
- One active session at a time (MVP)

## Development

```bash
uv sync
uv run pytest --tb=no -q
```

## Architecture

See `docs/adr/` for Architectural Decision Records.
