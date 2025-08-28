# Nova CI-Rescue GitHub Actions Demo

This repository demonstrates Nova CI-Rescue integration with GitHub Actions for automated test fixing in CI/CD pipelines.

## 🚀 Quick Start

### Prerequisites

- Completed main demo in `../nova-ci-rescue-demo/`
- GitHub account with repository access
- `gh` CLI installed and authenticated
- OpenAI API key

### Setup

```bash
# Ensure you're in this directory
cd ~/demo/nova-rescue-ci-demo-github/

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."  # Or use gh auth login
```

## 📋 Demo Scripts

### 1. **test_ci_flow.sh** - Main CI Demo

```bash
bash test_ci_flow.sh
```

- Creates a test branch
- Introduces bugs
- Pushes to trigger GitHub Actions
- Nova automatically fixes tests in CI

### 2. **test_local_demo.sh** - Local Testing

```bash
bash test_local_demo.sh
```

- Test the flow locally before pushing
- Verify Nova fixes work as expected

### 3. **introduce-bugs.sh** - Bug Introduction

```bash
bash introduce-bugs.sh
```

- Introduces specific bugs for testing
- Used by other scripts

## 🔧 GitHub Actions Workflow

The workflow (`.github/workflows/nova-ci-rescue.yml`) automatically:

1. Detects failing tests in PRs
2. Runs Nova to generate fixes
3. Commits fixes back to the PR
4. Re-runs tests to verify

## 📁 Repository Structure

```
nova-rescue-ci-demo-github/
├── .github/
│   └── workflows/
│       └── nova-ci-rescue.yml    # GitHub Actions workflow
├── src/
│   └── calculator.py             # Code to be fixed
├── tests/
│   └── test_calculator.py        # Test suite
├── test_ci_flow.sh              # Main demo script
├── introduce-bugs.sh            # Bug introduction
└── requirements.txt             # Dependencies
```

## 🚨 Common Issues

### Authentication

```bash
# If gh auth fails
unset GITHUB_TOKEN
unset GH_TOKEN
gh auth login
```

### Workflow Permissions

Ensure your repository has:

- Actions enabled
- Workflow permissions to write

## 🎯 Next Steps

1. Fork this repository
2. Enable GitHub Actions
3. Add `OPENAI_API_KEY` to repository secrets
4. Create a PR with failing tests
5. Watch Nova fix them automatically!

## 🔗 Related

- **Main Demo**: See `../nova-ci-rescue-demo/agents.md`
- **Nova Core**: [ci-auto-rescue](https://github.com/novasolve/ci-auto-rescue)
- **GitHub Repo**: [nova-rescue-ci-demo](https://github.com/novasolve/nova-rescue-ci-demo)
