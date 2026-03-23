# Paradigm Blast Radius

AI-powered blast radius analysis for pull requests. Uses [Paradigm](https://useparadigm.app) code intelligence to trace how your changes propagate through the codebase — across repos, modules, and service boundaries.

Unlike simple diff checks, this reads the actual code of affected methods, verifies real impact, and reports only what matters.

## Quick Start

```yaml
# .github/workflows/blast-radius.yml
name: Blast Radius
on:
  pull_request:

jobs:
  blast-radius:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      issues: write
    steps:
      - uses: actions/checkout@v4
      - uses: useparadigm/blast-radius-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          project: "My Project"
```

## Prerequisites

1. **Paradigm account** — sign up at [app.useparadigm.app](https://app.useparadigm.app)
2. **Project with indexed repos** — create a project and add your repositories
3. **Anthropic API key** — add as `ANTHROPIC_API_KEY` secret in your repo

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `anthropic-api-key` | Yes | — | Anthropic API key for Claude |
| `project` | Yes | — | Paradigm project name |
| `paradigm-api-url` | No | `https://api.useparadigm.app/mcp` | Paradigm MCP server URL |
| `model` | No | `claude-sonnet-4-6` | Claude model |
| `max-turns` | No | `10` | Max agent reasoning steps |

## What it does

1. Fetches blast radius graph from Paradigm (changed methods -> callers -> cross-repo impact)
2. Claude agent reads affected method bodies to verify real impact
3. Posts a concise, verified report as a PR comment
4. Updates the same comment on subsequent pushes (no spam)

## Example output

> ## Blast Radius: WARNING
>
> **Summary**: `validate_input()` signature changed — 3 controllers depend on it, 1 cross-service caller.
>
> ### Must address
> - **`OrderController.create_order`** in `orders/controller.py:42` — passes `user_id` as first arg which was removed from `validate_input`. Will raise TypeError at runtime.
>
> ### Worth checking
> - **`gateway.proxy_request`** in `gateway/app.py:15` — calls `validate_input` but only uses return value as boolean. Likely safe but verify.
