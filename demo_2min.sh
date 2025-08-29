#!/usr/bin/env bash

# Exit on any error
set -euo pipefail

# Colors for commands (dark gray)
CMD_COLOR="\033[90m"
NC="\033[0m"

# Configuration
BRANCH_NAME="demo-nova-$(date +%Y%m%d-%H%M%S)"
BASE_BRANCH="demo/latest"
REPO_DIR="/Users/seb/demo/nova-rescue-ci-demo-github"

# Function to print commands
print_cmd() {
    echo -e "${CMD_COLOR}$ $1${NC}"
}

# Function to wait for user
wait_for_enter() {
    echo -e "\n[Press ENTER to continue]"
    read -r
}

# Clean setup (hidden)
setup() {
    cd "$REPO_DIR"
    git checkout $BASE_BRANCH >/dev/null 2>&1
    git pull origin $BASE_BRANCH >/dev/null 2>&1
    git reset --hard origin/$BASE_BRANCH >/dev/null 2>&1
    cp src/calculator.py.original src/calculator.py 2>/dev/null || true
    
    # Check if we're already in a venv, if not try to activate one
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        # Try to find and activate venv
        if [ -f "venv/bin/activate" ]; then
            source venv/bin/activate
        elif [ -f "../venv/bin/activate" ]; then
            source ../venv/bin/activate
        elif [ -f "/Users/seb/demo/venv/bin/activate" ]; then
            source /Users/seb/demo/venv/bin/activate
        else
            echo "Warning: No virtual environment found. Make sure Nova and pytest are available."
        fi
    fi
    
    which pytest &>/dev/null || pip install -q pytest
}

# Phase 1: CI Kickoff
phase1_ci_kickoff() {
    clear
    echo "=== Phase 1: CI Kickoff ==="
    echo ""
    
    # Create branch with bugs
    git checkout -b "$BRANCH_NAME" >/dev/null 2>&1
    bash introduce-bugs.sh >/dev/null 2>&1
    git add -A >/dev/null 2>&1
    git commit -m "Demo: Introduce calculator bugs" >/dev/null 2>&1
    git push origin "$BRANCH_NAME" >/dev/null 2>&1
    
    # Create PR and open in browser
    print_cmd "gh pr create --base $BASE_BRANCH --title \"Demo: Nova CI-Rescue Calculator Bugs\" --body \"This PR contains intentional bugs to test Nova CI-Rescue.\""
    
    # Unset tokens to use stored GitHub CLI auth and suppress logs
    PR_URL=$(unset GH_TOKEN; unset GITHUB_TOKEN; unset DEBUG; unset GH_DEBUG && \
        gh pr create \
        --base $BASE_BRANCH \
        --title "Demo: Nova CI-Rescue Calculator Bugs" \
        --body "This PR contains intentional bugs to test Nova CI-Rescue.

**Expected behavior:**
- GitHub Actions will detect failing tests
- Nova CI-Rescue will automatically fix them
- Tests will turn green without human intervention

Watch the magic happen! 🚀" 2>&1 | grep -E "^https://github.com" || echo "")
    
    if [ -n "$PR_URL" ]; then
        echo "$PR_URL"
        echo ""
        echo "Opening PR in browser..."
        open "$PR_URL"
    else
        echo "PR already exists or was created manually"
    fi
    
    wait_for_enter
}

# Phase 2: Local CLI Demo
phase2_cli_demo() {
    clear
    echo "=== Phase 2: Local CLI Demo ==="
    echo ""
    
    # Return to base branch for clean demo
    git checkout $BASE_BRANCH >/dev/null 2>&1
    cp src/calculator.py.original src/calculator.py 2>/dev/null || true
    
    # Show passing tests
    print_cmd "pytest tests/test_calculator.py -v -p no:pytest_httpbin"
    pytest tests/test_calculator.py -v -p no:pytest_httpbin
    
    echo -e "\n"
    sleep 1
    
    # Introduce bugs silently
    bash introduce-bugs.sh >/dev/null 2>&1
    
    # Show failing tests
    print_cmd "pytest tests/test_calculator.py -v -p no:pytest_httpbin"
    pytest tests/test_calculator.py -v -p no:pytest_httpbin || true
    
    echo -e "\n"
    sleep 1
    
    # Run Nova with proper args
    print_cmd "nova fix . --pytest-args \"tests/test_calculator.py -p no:pytest_httpbin\" --max-iters 2"
    nova fix . --pytest-args "tests/test_calculator.py -p no:pytest_httpbin" --max-iters 2 2>&1 | \
        sed '/Could not create PR/d; /You can manually create a PR/d; /Replaced file:/d; /Changes saved to branch/d'
    
    echo -e "\n"
    sleep 1
    
    # Verify tests are fixed
    print_cmd "pytest tests/test_calculator.py -v -p no:pytest_httpbin"
    pytest tests/test_calculator.py -v -p no:pytest_httpbin
    
    echo -e "\n"
    sleep 1
    
    # Show we're on a separate branch
    print_cmd "git branch --show-current"
    git branch --show-current
    
    wait_for_enter
}

# Phase 3: Return to CI
phase3_return_to_ci() {
    clear
    echo "=== Phase 3: Return to CI ==="
    echo ""
    
    # Return to demo branch
    git checkout "$BRANCH_NAME" >/dev/null 2>&1
    
    echo "Checking CI status..."
    echo ""
    
    # Show PR status
    print_cmd "gh pr view --web"
    gh pr view --web
    
    echo -e "\nThe PR should now show:"
    echo "- ✅ All checks have passed"
    echo "- 🤖 Nova's automated commits"
    echo "- Ready to merge!"
    
    wait_for_enter
}

# Main execution
main() {
    setup
    
    echo "Nova CI-Rescue 2-Minute Demo"
    echo "============================"
    echo ""
    echo "This demo will show Nova fixing failing tests both:"
    echo "1. In CI (GitHub Actions)"
    echo "2. Locally via CLI"
    echo ""
    wait_for_enter
    
    phase1_ci_kickoff
    phase2_cli_demo
    phase3_return_to_ci
    
    echo -e "\n✅ Demo complete!"
    echo ""
    echo "Nova is free, open source, and actively maintained."
    echo "Get started at: https://github.com/novasolve/ci-auto-rescue"
}

# Allow running specific phases
case "${1:-}" in
    --phase1) phase1_ci_kickoff ;;
    --phase2) phase2_cli_demo ;;
    --phase3) phase3_return_to_ci ;;
    *) main ;;
esac
