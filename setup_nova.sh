#!/usr/bin/env bash
set -euo pipefail

# Nova CI-Rescue Demo Setup Script
# This installs the demo version with GPT-5 and optimized settings

# Location of your repo venv (can be overridden by first argument)
VENV_DIR="${1:-.venv}"

# Path to ci-auto-rescue .env file (adjust if needed)
ENV_FILE="$HOME/clone-repos/ci-auto-rescue/.env"

# Ensure venv exists
if [ ! -d "$VENV_DIR" ]; then
  echo "⚠️  Virtualenv $VENV_DIR not found. Creating..."
  python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

echo "✅ Using Python: $(which python)"
echo "✅ Using Pip:    $(which pip)"

# Load .env if available
if [ -f "$ENV_FILE" ]; then
  echo "📦 Sourcing env vars from $ENV_FILE"
  # Export key=value pairs, ignore comments/blank lines
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "⚠️  No .env file found at $ENV_FILE (using environment variables)"
fi

# Upgrade pip & wheel (quiet in CI)
if [ -n "${CI:-}" ]; then
  pip install --quiet --upgrade pip wheel
else
  pip install --upgrade pip wheel
fi

# Install test dependencies
pip install --quiet pytest pytest-json-report

# Uninstall any existing nova first to ensure clean install
pip uninstall -y nova nova-ci-rescue 2>/dev/null || true

# Install/upgrade Nova from GitHub demo/latest branch (force reinstall, no cache)
echo "Installing Nova CI-Rescue..."
if [ -n "${CI:-}" ]; then
  pip install --quiet --force-reinstall --no-cache-dir \
    "git+https://github.com/novasolve/nova-ci-rescue.git@demo/latest"
else
  pip install --force-reinstall --no-cache-dir \
    "git+https://github.com/novasolve/nova-ci-rescue.git@demo/latest"
fi

# Show nova version
echo
if [ -x "$VENV_DIR/bin/nova" ]; then
  "$VENV_DIR/bin/nova" version || true
else
  nova version || true
fi

echo
echo "✨ Nova CI-Rescue ready!"
echo "   - GPT-5 for main operations"
echo "   - GPT-4o for PR generation"
echo "   - Demo branch with latest improvements"
