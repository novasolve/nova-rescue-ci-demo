#!/usr/bin/env bash
set -euo pipefail

# Nova CI Flow Test Script
# Simulates: Good repo → Buggy PR → Tests fail → Nova fixes → Tests pass

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Nova CI-Rescue Demo - GitHub Action Simulation${NC}"
echo "================================================="
echo

# Unset potentially conflicting environment variables
unset PYTHONPATH
unset VIRTUAL_ENV
unset NOVA_API_KEY
unset NOVA_CONFIG
unset GIT_PYTHON_REFRESH

# Setup venv and install Nova
VENV_DIR=".venv"
echo -e "${BLUE}📦 Setting up environment...${NC}"

# Create venv if needed
if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtual environment..."
  python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# Install dependencies
echo "Installing dependencies..."
pip install --quiet --upgrade pip wheel
pip install --quiet pytest pytest-json-report

# Install Nova CI-Rescue from demo branch
echo "Installing Nova CI-Rescue..."
pip install --quiet --force-reinstall --no-cache-dir "git+https://github.com/novasolve/ci-auto-rescue.git@demo"

# Show Nova version
echo
echo "Nova version:"
nova version || echo "Nova CI-Rescue installed"
echo

# Store original calculator state
cp src/calculator.py src/calculator.py.original

# Phase 1: Pre-check (good state)
echo -e "${GREEN}✅ Phase 1: Initial state (all tests passing)${NC}"
pytest tests/test_calculator.py -q --tb=no
echo

# Phase 2: Simulate buggy PR
echo -e "${YELLOW}�� Phase 2: Introducing bugs (simulating bad PR)${NC}"

# Introduce bugs using sed
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed syntax
  sed -i '' 's/return a + b/return a - b  # BUG/' src/calculator.py
  sed -i '' 's/return a \* b/return a + b  # BUG/' src/calculator.py
  sed -i '' 's/return base \*\* exponent/return base * exponent  # BUG/' src/calculator.py
  sed -i '' 's/return (value \* percent) \/ 100/return (value * percent) * 10  # BUG/' src/calculator.py
  sed -i '' 's/return sum(seq) \/ len(seq)/return sum(seq)  # BUG/' src/calculator.py
else
  # Linux sed syntax
  sed -i 's/return a + b/return a - b  # BUG/' src/calculator.py
  sed -i 's/return a \* b/return a + b  # BUG/' src/calculator.py
  sed -i 's/return base \*\* exponent/return base * exponent  # BUG/' src/calculator.py
  sed -i 's/return (value \* percent) \/ 100/return (value * percent) * 10  # BUG/' src/calculator.py
  sed -i 's/return sum(seq) \/ len(seq)/return sum(seq)  # BUG/' src/calculator.py
fi

echo "Bugs introduced in calculator.py:"
echo "  - add() now subtracts"
echo "  - multiply() now adds"
echo "  - power() now multiplies"
echo "  - percentage() calculation is wrong"
echo "  - average() returns sum"
echo

# Phase 3: Pre-check (should fail)
echo -e "${RED}❌ Phase 3: Running tests (should fail)${NC}"
set +e
pytest tests/test_calculator.py -v --tb=short --json-report --json-report-file=test_results.json
TEST_EXIT_CODE=$?
set -e

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Tests failed as expected (exit code: $TEST_EXIT_CODE)${NC}"
    FAILED_TESTS=$(python -c "import json; data=json.load(open('test_results.json')); print(len([t for t in data['tests'] if t['outcome'] == 'failed']))")
    echo "Failed tests: $FAILED_TESTS"
else
    echo "Unexpected: tests should have failed!"
    exit 1
fi
echo

# Phase 4: Nova Rescue
echo -e "${BLUE}🤖 Phase 4: Running Nova CI-Rescue${NC}"
echo "Configuration:"
echo "  - Max iterations: 3"
echo "  - Timeout: 300 seconds"
echo "  - Model: GPT-5 (main) / GPT-4o (PR generation)"
echo

# Set environment variables for Nova
export NOVA_DEFAULT_LLM_MODEL="gpt-5"
export NOVA_PR_LLM_MODEL="gpt-4o"

# Create telemetry directory
mkdir -p telemetry

# Run Nova
nova fix . \
    --max-iters 3 \
    --timeout 300 \
    --pytest-args "tests/test_calculator.py" \
    --auto-pr

# Phase 5: Verify fix
echo
echo -e "${GREEN}✅ Phase 5: Verifying fix${NC}"
pytest tests/test_calculator.py -v --tb=short
VERIFY_EXIT_CODE=$?

if [ $VERIFY_EXIT_CODE -eq 0 ]; then
    echo
    echo -e "${GREEN}🎉 All tests pass! Nova successfully fixed the code!${NC}"
    echo
    echo "Summary:"
    echo "- Started with working code ✅"
    echo "- Introduced $FAILED_TESTS bugs ❌"
    echo "- Nova automatically fixed all issues 🤖"
    echo "- All tests pass again ✅"
    echo
    echo "Check the generated PR for the fixes!"
else
    echo -e "${RED}❌ Tests still failing after Nova fix${NC}"
    exit 1
fi

# Cleanup
echo
echo "Cleaning up..."
mv src/calculator.py.original src/calculator.py
rm -f test_results.json
echo "Done!"
