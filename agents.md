# Nova CI‑Rescue Demo CI Flow (Quick Guide)

This repo demonstrates a full CI loop that keeps a known‑good base branch green and opens a "dirty" PR on top to trigger Nova CI‑Rescue.

## Baseline policy

- **Base branch**: `demo/latest` (kept on top of `main`).
- **Installer source**: GitHub `novasolve/nova-ci-rescue@demo/latest` (not PyPI).
- **Dirty PRs**: Always created on top of `demo/latest`.

## Prerequisites

- GitHub CLI (`gh`) authenticated: `gh auth login`
- `GITHUB_TOKEN` exported in your shell (repo write scope):

```bash
export GITHUB_TOKEN=ghp_xxx
```

- Python 3.10+ if you want to verify tests locally.

## What the scripts do

### `setup_nova.sh`

- Creates `.venv`, upgrades `pip`.
- Installs Nova from: `novasolve/nova-ci-rescue@demo/latest`.
  - Ensures CLI supports flags like `--pytest-args`.

### `test_ci_flow.sh`

1. Syncs `origin/demo/latest` locally and resets to it.
2. Creates a fresh branch from `origin/demo/latest`.
3. Verifies base tests are green (protect base from “dirty on red”).
4. Introduces calculator bugs (via `introduce-bugs.sh`).
5. Ensures a diff exists (forces a tiny change if sed yields no diff).
6. Pushes the branch and opens a PR with base `demo/latest`.
7. Follows the GitHub Action, downloads logs/artifacts.

## Usage

- Full GitHub flow:

```bash
export GITHUB_TOKEN=ghp_xxx
bash test_ci_flow.sh
```

- Ensuring CI uses the correct Nova build: already wired by `setup_nova.sh` to `novasolve/nova-ci-rescue@demo/latest`.

## Keeping `demo/latest` on top of `main`

- Fast‑forward `demo/latest` to `main` when needed:

```bash
git fetch origin
MAIN_SHA=$(git rev-parse origin/main)
git push --force-with-lease origin "$MAIN_SHA":refs/heads/demo/latest
```

- Our scripts assume `origin/demo/latest` exists and is green.

## Troubleshooting

- “No such option: --pytest-args”: you’re on an old build. Ensure install points to `novasolve/nova-ci-rescue@demo/latest`.
- “working tree clean” on push: script forces a trivial change if sed yields no diff.
- Base tests failing: script aborts to avoid dirtying a red base; fix base then retry.

## Notes

- PR base is `demo/latest` by default (not `main`).
- Change `BASE_REF` in `test_ci_flow.sh` to use a different base.
