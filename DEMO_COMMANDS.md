# Nova Demo Commands Reference

## Available Demo Scripts

### 1. `minimal_demo.sh`

- **Purpose**: Quick CLI-only demo showing Nova fixing tests
- **Duration**: ~45 seconds
- **Features**:
  - Shows tests passing → failing → Nova fixing → passing again
  - Automatically replayable (press ENTER to run again)
  - No decorations, just commands and output
  - Commands shown in dark gray for clarity

### 2. `demo_2min.sh`

- **Purpose**: Full 2-minute demo with CI integration
- **Duration**: 2 minutes
- **Features**:
  - Phase 1: Creates PR and opens in browser
  - Phase 2: Local CLI demo
  - Phase 3: Returns to show CI is green
  - Interactive (press ENTER between phases)
  - Can run individual phases: `--phase1`, `--phase2`, `--phase3`

### 3. `unified_demo.sh`

- **Purpose**: Automated presentation demo
- **Duration**: ~3 minutes
- **Features**:
  - Fully automated with timed pauses
  - Decorative headers and status messages
  - Comprehensive error handling
  - No user interaction needed

## Key Commands Used

### Test Running

```bash
# Show verbose test results
pytest tests/test_calculator.py -v -p no:pytest_httpbin

# Quick test results
pytest tests/test_calculator.py -q -p no:pytest_httpbin
```

### Nova Fix Command

```bash
# Fix with specific pytest args and iteration limit
nova fix . --pytest-args "tests/test_calculator.py -p no:pytest_httpbin" --max-iters 2
```

### Git Commands

```bash
# Show current branch
git branch --show-current

# Create PR with GitHub CLI (suppressing token issues)
unset GH_TOKEN; unset GITHUB_TOKEN
gh pr create --base demo/latest --title "Demo: Nova CI-Rescue Calculator Bugs" --body "..."
```

## Setup Requirements

1. Virtual environment activated: `source venv/bin/activate`
2. pytest installed: `pip install pytest`
3. Nova installed: from the ci-auto-rescue repo
4. GitHub CLI authenticated: `gh auth login`
5. Working from `demo/latest` branch

## Troubleshooting

### PR Creation Issues

- The scripts unset `GH_TOKEN` and `GITHUB_TOKEN` to avoid permission conflicts
- PR errors are silenced in the output
- If PR already exists, the demo continues normally

### Test Plugin Issues

- All pytest commands use `-p no:pytest_httpbin` to disable the problematic plugin
- This prevents Flask import errors

### Branch State

- Scripts automatically reset to clean state before each run
- Uses `src/calculator.py.original` as the clean source
- Works on separate branches to avoid conflicts
