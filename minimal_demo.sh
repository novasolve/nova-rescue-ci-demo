#!/usr/bin/env bash

cd /Users/seb/demo/nova-ci-rescue-demo

# Activate venv if not already activated
if [ -z "$VIRTUAL_ENV" ]; then
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f "../venv/bin/activate" ]; then
        source ../venv/bin/activate
    else
        echo "Warning: No venv found. Make sure pytest and nova are available."
    fi
fi

# Clean setup (hidden) - reset to clean state for replay
git checkout demo/latest >/dev/null 2>&1
git reset --hard origin/demo/latest >/dev/null 2>&1
cp src/calculator.py.original src/calculator.py 2>/dev/null || true

clear

# === STARTING WITH CLEAN TESTS ===
echo -e "\033[90m$ pytest tests/test_calculator.py -v -p no:pytest_httpbin\033[0m"
pytest tests/test_calculator.py -v -p no:pytest_httpbin

echo -e "\n"
sleep 2

# Introduce bugs silently
bash introduce-bugs.sh >/dev/null 2>&1

# === TESTS NOW FAILING ===
echo -e "\033[90m$ pytest tests/test_calculator.py -v -p no:pytest_httpbin\033[0m"
pytest tests/test_calculator.py -v -p no:pytest_httpbin || true

echo -e "\n"
sleep 2

# === NOVA FIXES THE TESTS ===
echo -e "\033[90m$ nova fix . --pytest-args \"tests/test_calculator.py -p no:pytest_httpbin\" --max-iters 2\033[0m"
nova fix . --pytest-args "tests/test_calculator.py -p no:pytest_httpbin" --max-iters 2 2>&1 | \
    sed '/Could not create PR/d; /You can manually create a PR/d; /Replaced file:/d; /Changes saved to branch/d'

echo -e "\n"
sleep 2

# === VERIFY ALL TESTS PASS ===
echo -e "\033[90m$ pytest tests/test_calculator.py -v -p no:pytest_httpbin\033[0m"
pytest tests/test_calculator.py -v -p no:pytest_httpbin

echo -e "\n"
sleep 1

# === SHOW WE'RE ON A SAFE BRANCH ===
echo -e "\033[90m$ git branch --show-current\033[0m"
git branch --show-current

echo -e "\n"
echo "Press ENTER to run again..."
read -r
