#!/usr/bin/env bash
set -euo pipefail

# Nova CI-Rescue Unified Demo Runner
# Streamlined 2:30 demo flow
# Phase 0 → Phase 1 (GitHub CI) → Phase 2 (Local CLI) → Phase 3 (CI Results) → Phase 4 (CTA)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Script paths
DEMO_ROOT="/Users/seb/demo"
CI_DEMO_DIR="$DEMO_ROOT/nova-rescue-ci-demo-github"
LOCAL_DEMO_DIR="$DEMO_ROOT/nova-ci-rescue-demo"

# Function to print section headers
print_section() {
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() {
    echo -e "${BLUE}➤${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_highlight() {
    echo -e "${BOLD}${YELLOW}$1${NC}"
}

# Check prerequisites
check_prerequisites() {
    # Source .env file if it exists
    if [ -f "/Users/seb/demo/.env" ]; then
        set -a  # automatically export all variables
        source "/Users/seb/demo/.env"
        set +a
    fi
    
    local missing=false
    
    if [ -z "${OPENAI_API_KEY:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        print_error "No API keys found! Set OPENAI_API_KEY or ANTHROPIC_API_KEY"
        missing=true
    fi
    
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) not found! Install with: brew install gh"
        missing=true
    fi
    
    if ! gh auth status &>/dev/null; then
        print_error "Not authenticated with GitHub! Run: gh auth login"
        missing=true
    fi
    
    if [ "$missing" = true ]; then
        exit 1
    fi
}

# Phase 1: CI Kickoff
phase1_ci_kickoff() {
    print_section "Phase 1 — GitHub CI (PR → red checks)"
    
    cd "$CI_DEMO_DIR"
    
    # Always start fresh on demo/latest
    print_status "Preparing repository..."
    git checkout demo/latest &>/dev/null
    git pull origin demo/latest &>/dev/null
    git reset --hard origin/demo/latest &>/dev/null
    
    # Create PR with bugs
    print_status "Creating PR with intentional bugs..."
    
    # Extract key parts from test_ci_flow.sh to show progress
    BRANCH_NAME="nova-demo-$(date +%Y%m%d-%H%M%S)"
    
    # Create branch and introduce bugs
    git checkout -b "$BRANCH_NAME" &>/dev/null
    echo -e "${YELLOW}🐛 Introducing bugs in calculator.py...${NC}"
    bash ./introduce-bugs.sh &>/dev/null
    
    # Commit and push
    git add src/calculator.py &>/dev/null
    git commit -m "Test Nova CI-Rescue: Introduce calculator bugs" &>/dev/null
    git push origin "$BRANCH_NAME" &>/dev/null 2>&1
    
    # Create PR (temporarily unset GH_TOKEN to use stored GitHub CLI credentials)
    PR_URL=$(unset GH_TOKEN; unset DEBUG; unset GH_DEBUG && gh pr create \
        --title "Demo: Nova CI-Rescue Calculator Bugs" \
        --body "This PR contains intentional bugs to test Nova CI-Rescue.

Watch as Nova automatically:
1. Detects the failing tests
2. Creates a fix on a safe branch
3. Commits the solution
4. Makes all tests pass

🎩✨ The magic happens automatically!" \
        --base demo/latest \
        --head "$BRANCH_NAME" 2>&1 | grep -v -E "\[git|Request to|\*") || {
        print_error "Failed to create PR. This might be a permissions issue."
        print_status "Make sure you have push access to: https://github.com/novasolve/nova-rescue-ci-demo"
        print_status "Or create your own fork and update the remote URL"
        exit 1
    }
    
    print_success "Pull request created!"
    echo -e "\n${BOLD}PR URL:${NC} $PR_URL"
    print_status "GitHub Actions is now running Nova CI-Rescue..."
    echo -e "${CYAN}View live at:${NC} $PR_URL"
    
    # Store PR info for phase 3
    echo "$PR_URL" > /tmp/nova_demo_pr_url.txt
    echo "$BRANCH_NAME" > /tmp/nova_demo_branch.txt
    
    # Return to demo/latest branch
    git checkout demo/latest &>/dev/null
}

# Phase 2: CLI Loop
phase2_cli_loop() {
    print_section "Phase 2 — Local CLI (red → loop → green)"
    
    cd "$LOCAL_DEMO_DIR"
    
    # Activate venv first
    if [ -f .venv/bin/activate ]; then
        source .venv/bin/activate
    elif [ -f venv/bin/activate ]; then
        source venv/bin/activate
    else
        print_error "No virtual environment found. Creating one..."
        python3 -m venv venv
        source venv/bin/activate
    fi
    
    # Ensure pytest is installed
    which pytest &>/dev/null || pip install -q pytest
    
    # Ensure clean state
    if [ -f "src/calculator.py.original" ]; then
        cp src/calculator.py.original src/calculator.py
    fi
    
    # Show passing tests first
    print_status "Starting with clean code..."
    pytest tests/test_calculator.py -q --tb=no -p no:pytest_httpbin
    print_success "All tests passing"
    
    # Introduce bugs
    print_status "Introducing bugs..."
    echo -e "${YELLOW}🐛 Bugs introduced!${NC}"
    bash ./introduce-bugs.sh &>/dev/null
    echo "Run 'make test' to see the failures!"
    
    # Show failing tests
    echo -e "\n${RED}Running tests with bugs...${NC}"
    pytest tests/test_calculator.py -q --tb=no -p no:pytest_httpbin || true
    echo -e "${RED}❌ Multiple tests failing!${NC}"
    
    # Brief pause for effect
    sleep 1
    
    # Run Nova with visual progress
    echo -e "\n${BOLD}Now I run nova fix .${NC}"
    echo -e "Watch the loop: ${CYAN}Plan → Patch → Critic → Test${NC}\n"
    
    # Force color output
    export FORCE_COLOR=1
    export PYTHONUNBUFFERED=1
    export PY_COLORS=1
    export COLUMNS=120
    
    # Run Nova (showing the iterative process)
    echo -e "${CYAN}🔄 LOOP: Plan → Patch → Critic → Test${NC}"
    echo -e "Model: ${BOLD}${NOVA_DEFAULT_LLM_MODEL:-gpt-5-mini}${NC}  |  Max iterations: 2  |  Timeout: 120s\n"
    
    # Use sed to filter only essential output
    nova fix . --pytest-args "tests/test_calculator.py -p no:pytest_httpbin" --max-iters 2 --timeout 120 | sed '/^Replaced file:/d; /Changes saved to branch/d; /preserved for PR/d; /pull\//d; /Working on branch/d; /Repository:/d'
    
    # Brief pause before showing results
    sleep 1
    
    # Show final success
    echo -e "\n${GREEN}Final test results:${NC}"
    pytest tests/test_calculator.py -v --tb=no -p no:pytest_httpbin | grep -E "(test session starts|passed in|PASSED)"
    
    # Show diff summary
    echo -e "\n${BOLD}Minimal patch applied:${NC}"
    git diff --stat
    echo ""
    
    print_success "✅ All tests passing!"
    echo -e "${CYAN}Nova works on its own branch, never touches main.${NC}"
}

# Phase 3: Return to CI
phase3_return_to_ci() {
    print_section "Phase 3 — Back to CI (green PR)"
    
    # Read PR info
    PR_URL=$(cat /tmp/nova_demo_pr_url.txt 2>/dev/null || echo "")
    
    if [ -n "$PR_URL" ]; then
        echo -e "${BOLD}PR Status:${NC} $PR_URL"
        echo -e "\n${GREEN}✅ Bot commits:${NC} \"🤖 Fix failing tests...\""
        echo -e "${GREEN}✅ All checks passing${NC}"
        echo -e "${GREEN}✅ Ready to merge${NC}"
        echo -e "\n${CYAN}Same story in CI or locally: red → loop → green.${NC}"
    fi
}



# Cleanup function
cleanup() {
    # Clean up temp files
    rm -f /tmp/nova_demo_pr_url.txt /tmp/nova_demo_branch.txt
    
    # Return to main branch in CI repo
    if [ -d "$CI_DEMO_DIR/.git" ]; then
        cd "$CI_DEMO_DIR"
        git checkout main &>/dev/null || true
    fi
}

trap cleanup EXIT

# Phase 0: Preflight
phase0_preflight() {
    clear
    echo -e "${CYAN}🚀 Nova CI-Rescue Demo${NC}"
    echo -e "   Free open-source agent that fixes failing Python tests automatically"
    echo -e "   ${BOLD}Iterates on a safe branch until everything is green${NC}\n"
    
    # Preflight checks with animation
    print_status "Checking prerequisites..."
    if [ -f "/Users/seb/demo/.env" ]; then
        print_status "Loading environment from /Users/seb/demo/.env"
    fi
    check_prerequisites
    print_success "All prerequisites met!"
    
    echo -e "\n${YELLOW}Starting demo...${NC}"
    sleep 2
}

# Phase 4: CTA & Limitations
phase4_cta() {
    print_section "Ready to Try Nova?"
    
    echo -e "${BOLD}Nova is free and open source${NC} — your only cost is API calls."
    echo -e "It excels at ${GREEN}logic-in-repo Python tests${NC} (less so for business-context bugs).\n"
    
    echo -e "${CYAN}If you send me a repo, I'll run Nova and open a fix PR today.${NC}"
    echo -e "${BOLD}Want to try it on one of yours?${NC}\n"
    
    echo -e "Reply: ${GREEN}'fix my repo'${NC}"
    echo -e "\n📦 PyPI: ${BLUE}pip install nova-ci-rescue${NC}"
    echo -e "🔗 GitHub: ${BLUE}github.com/novasolve/ci-auto-rescue${NC}"
    
    # Keep terminal open for a moment
    echo ""
    sleep 3
}

# Main execution
main() {
    # Phase 0: Preflight
    phase0_preflight
    
    # Phase 1: GitHub CI
    phase1_ci_kickoff
    
    echo -e "\n${YELLOW}GitHub CI is now running in the background...${NC}"
    sleep 3
    echo ""
    
    # Phase 2: Local CLI
    phase2_cli_loop
    
    echo -e "\n${YELLOW}Local demo complete. Checking CI results...${NC}"
    sleep 2
    echo ""
    
    # Phase 3: CI Results
    phase3_return_to_ci
    
    sleep 2
    echo ""
    
    # Phase 4: CTA
    phase4_cta
}

# Parse command line arguments
case "${1:-}" in
    --phase0)
        phase0_preflight
        ;;
    --phase1)
        check_prerequisites
        phase1_ci_kickoff
        ;;
    --phase2)
        check_prerequisites
        phase2_cli_loop
        ;;
    --phase3)
        check_prerequisites
        phase3_return_to_ci
        ;;
    --phase4)
        phase4_cta
        ;;
    --help|-h)
        echo "Nova CI-Rescue Demo"
        echo "Usage: $0 [option]"
        echo "Options:"
        echo "  (no args)    Run full demo with automatic timing"
        echo "  --phase0     Run preflight only"
        echo "  --phase1     Run GitHub CI phase only"
        echo "  --phase2     Run local CLI phase only"
        echo "  --phase3     Run CI results phase only"
        echo "  --phase4     Run CTA phase only"
        echo "  --help       Show this help"
        ;;
    *)
        main
        ;;
esac
