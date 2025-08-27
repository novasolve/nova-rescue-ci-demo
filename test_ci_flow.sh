
#!/usr/bin/env bash
set -euo pipefail

# Nova CI Flow Test Script
# This script tests the GitHub Actions CI workflow

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Nova CI-Rescue GitHub Actions Test${NC}"
echo "======================================"
echo

# Check if we have the required environment variables before unsetting
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo -e "${RED}❌ Error: GITHUB_TOKEN not set${NC}"
    echo "Please set your GitHub token first:"
    echo "  export GITHUB_TOKEN=your_github_token"
    exit 1
fi

# Unset GH_TOKEN as requested (but keep GITHUB_TOKEN for gh CLI)
echo "🔒 Unsetting GH_TOKEN as part of the flow (keeping GITHUB_TOKEN for GitHub CLI operations)"
unset GH_TOKEN || true

# Phase 1: Check current CI status
echo -e "${BLUE}📊 Phase 1: Checking current CI status${NC}"
gh run list --workflow="Nova CI-Rescue Demo" --limit 5 || echo "No previous runs found"
echo

# Phase 2: Create a test branch
BRANCH_NAME="test-nova-ci-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}🌿 Phase 2: Creating test branch: $BRANCH_NAME${NC}"
git checkout -b "$BRANCH_NAME"
echo

# Phase 3: Introduce bugs
echo -e "${RED}🐛 Phase 3: Introducing bugs to trigger CI failure${NC}"

# First restore calculator to clean state
if [ -f "src/calculator.py.original" ]; then
    echo "Restoring calculator.py to clean state..."
    cp src/calculator.py.original src/calculator.py
fi

# Now introduce bugs
./introduce-bugs.sh
echo

# Phase 4: Commit and push to trigger CI
echo -e "${BLUE}📤 Phase 4: Pushing changes to trigger GitHub Actions${NC}"
git add src/calculator.py
git commit -m "Test Nova CI-Rescue: Introduce calculator bugs

This commit intentionally breaks several calculator functions to test
Nova CI-Rescue's ability to automatically fix failing tests.

Bugs introduced:
- add() now subtracts
- multiply() now adds
- power() now multiplies
- percentage() calculation is wrong
- average() returns sum instead of average"

git push origin "$BRANCH_NAME"
echo

# Phase 5: Create PR to trigger workflow
echo -e "${BLUE}🔄 Phase 5: Creating pull request${NC}"
PR_URL=$(gh pr create \
    --title "Test Nova CI-Rescue: Calculator bugs" \
    --body "This PR contains intentional bugs to test Nova CI-Rescue.

## Expected behavior:
1. CI tests will fail
2. Nova CI-Rescue will detect the failures
3. Nova will create a fix PR automatically
4. All tests will pass after the fix

## Bugs introduced:
- \`add()\` now subtracts instead of adding
- \`multiply()\` now adds instead of multiplying
- \`power()\` now multiplies instead of exponentiating
- \`percentage()\` multiplies by 10 instead of dividing by 100
- \`average()\` returns sum instead of average

Watch the magic happen! 🎩✨" \
    --base main \
    --head "$BRANCH_NAME")
# The bug was a stray closing parenthesis on its own line; it is now removed.

echo "Pull request created: $PR_URL"
echo

# Phase 6: Monitor CI workflow
echo -e "${BLUE}👀 Phase 6: Monitoring GitHub Actions workflow${NC}"
echo "Waiting for workflow to start..."
sleep 10

# Get the run ID
RUN_ID=$(gh run list --workflow="Nova CI-Rescue Demo" --limit 1 --json databaseId --jq '.[0].databaseId // empty')

if [ -n "${RUN_ID:-}" ]; then
    echo "Workflow run started: #$RUN_ID"
    echo "View in browser: https://github.com/novasolve/nova-rescue-ci-demo/actions/runs/$RUN_ID"
    echo
    echo "Following workflow progress..."
    
    # Follow the workflow (this will stream logs)
    gh run watch "$RUN_ID" --interval 5
    
    # Get final status
    STATUS=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    
    if [ "$STATUS" = "success" ]; then
        echo -e "${GREEN}✅ Workflow completed successfully!${NC}"
        
        # Check for Nova's PR
        echo
        echo "Checking for Nova's fix PR..."
        NOVA_PR=$(gh pr list --search "author:app/github-actions" --limit 1 --json url --jq '.[0].url // empty')
        
        if [ -n "${NOVA_PR:-}" ]; then
            echo -e "${GREEN}🎉 Nova created a fix PR: $NOVA_PR${NC}"
        else
            echo "Nova's PR might still be creating..."
        fi
    else
        echo -e "${RED}❌ Workflow failed with status: $STATUS${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not find workflow run. Check manually at:${NC}"
    echo "https://github.com/novasolve/nova-rescue-ci-demo/actions"
fi

echo
echo -e "${BLUE}📋 Summary:${NC}"
echo "- Test branch: $BRANCH_NAME"
echo "- Pull request: $PR_URL"
echo "- Workflow: https://github.com/novasolve/nova-rescue-ci-demo/actions"
echo
echo "Next steps:"
echo "1. Review Nova's fix PR when it's created"
echo "2. Merge the fix PR to see tests pass"
echo "3. Clean up test branches when done"

# Final cleanup - unset tokens again
echo
echo "🔒 Final cleanup: Unsetting GitHub tokens..."
unset GH_TOKEN || true
unset GITHUB_TOKEN || true
unset TEMP_GITHUB_TOKEN || true
echo "✅ All tokens cleared"
