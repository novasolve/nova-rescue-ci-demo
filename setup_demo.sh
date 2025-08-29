#!/usr/bin/env bash

# Nova Demo Setup Script
# Ensures nova is properly installed with pytest-args support

set -e

echo "Setting up Nova demo environment..."

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ] && [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
elif [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi

# Install pytest
echo "Installing pytest..."
pip install -q pytest

# Install nova from ci-auto-rescue if it exists, otherwise from PyPI
if [ -d "ci-auto-rescue" ]; then
    echo "Installing Nova from local ci-auto-rescue..."
    pip install -q -e ci-auto-rescue/
else
    echo "Installing Nova from PyPI..."
    pip install -q nova-ci-rescue
fi

# Verify installation
echo ""
echo "Checking Nova installation..."
if nova fix --help | grep -q "pytest-args"; then
    echo "✅ Nova installed successfully with pytest-args support!"
else
    echo "⚠️  Nova installed but may not have pytest-args support."
    echo "    The demo may not work as expected."
fi

echo ""
echo "Setup complete! You can now run:"
echo "  ./minimal_demo.sh    - Quick CLI demo"
echo "  ./demo_2min.sh       - Full 2-minute demo with CI"
echo "  ./unified_demo.sh    - Automated presentation demo"
