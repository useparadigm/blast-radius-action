# Paradigm Blast Radius Action

A GitHub Action that analyzes the blast radius of a pull request using [Paradigm](https://useparadigm.app) code intelligence. It identifies which methods are changed and which downstream methods are affected, posts a sticky summary comment on the PR, and optionally fails the check if critical issues are found.

## Quick Start

```yaml
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

1. A [Paradigm](https://useparadigm.app) account with an indexed project.
2. A GitHub Personal Access Token (PAT) with the `read:user` scope, linked to your Paradigm account.
3. Store the PAT as a repository secret (e.g. `PARADIGM_PAT`).
