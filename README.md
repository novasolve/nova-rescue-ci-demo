# Nova Rescue CI Demo

A demonstration repository showcasing Nova CI-Rescue's ability to automatically fix failing tests.

## What This Demo Shows

This repository contains a simple calculator with intentional bugs that cause test failures. Nova CI-Rescue will:

1. **Detect failing tests** automatically via GitHub Actions
2. **Analyze the failures** using AI (GPT-5)
3. **Generate fixes** for the broken code
4. **Create a pull request** with the fixes
5. **Verify all tests pass** after the fixes

## Demo Flow

1. **Push breaking changes** to trigger CI failure
2. **Nova automatically detects** the failures
3. **Watch Nova fix the code** in real-time
4. **Review the generated PR** with clean fixes

## Repository Structure

```
src/
├── calculator.py          # Calculator with bugs to be fixed
└── __init__.py           # Package init

tests/
├── test_calculator.py    # Comprehensive test suite
└── __init__.py          # Test package init

.github/workflows/
└── nova-ci-rescue.yml   # GitHub Action for Nova CI-Rescue
```

## Running Locally

```bash
# Install dependencies
pip install pytest

# Run tests (will fail initially)
pytest tests/ -v

# After Nova fixes the code, tests will pass
pytest tests/ -v
```

---

*This demo showcases [Nova CI-Rescue](https://github.com/novasolve/ci-auto-rescue) - AI-powered automated test fixing.*
