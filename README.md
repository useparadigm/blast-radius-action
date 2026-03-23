# Paradigm Blast Radius

AI-powered blast radius analysis for pull requests. Uses [Paradigm](https://useparadigm.app) code intelligence to trace how your changes propagate through the codebase — across repos, modules, and service boundaries.

Reads the actual code of affected methods, verifies real impact, and proposes fixes.

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
      pull-requests: write
    steps:
      - uses: useparadigm/blast-radius-action@v1
        with:
          github-token: ${{ secrets.PARADIGM_PAT }}
          project: "My Project"
```

## Prerequisites

1. **Paradigm account** — sign up at [app.useparadigm.app](https://app.useparadigm.app)
2. **Project with indexed repos** — create a project and add your repositories
3. **GitHub PAT** with `read:user` scope, linked to your Paradigm account — add as `PARADIGM_PAT` secret

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | Yes | — | GitHub PAT linked to Paradigm account |
| `project` | Yes | — | Paradigm project name |
| `api-url` | No | `https://api.useparadigm.app` | Paradigm API URL |

## What it does

1. Sends PR info to Paradigm API (auth via your GitHub PAT)
2. Paradigm traces blast radius through the code graph (callers, overrides, DB tables, remote calls)
3. AI reads affected method bodies, verifies real impact, proposes fixes
4. Posts a concise report as a PR comment (updates on re-push, no spam)
5. Fails the check if critical issues found

## Example output

> ## Blast Radius: WARNING
>
> **Summary**: `validate_input()` signature changed — 3 controllers depend on it.
>
> ### Must address
> - **`OrderController.create_order`** in `orders/controller.py:42` — passes `user_id` as first arg which was removed.
>   **Proposed fix:**
>   ```python
>   - result = validate_input(user_id, order_data)
>   + result = validate_input(order_data)
>   ```
>
> ### Worth checking
> - **`gateway.proxy_request`** in `gateway/app.py:15` — uses return value as boolean only. Likely safe.
