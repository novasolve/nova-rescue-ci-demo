#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Branch preference functions
get_default_branch() {
    local def
    def=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||') || true
    if [ -z "$def" ]; then
        if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
            def=main
        elif git ls-remote --exit-code --heads origin master >/dev/null 2>&1; then
            def=master
        else
            def=main
        fi
    fi
    echo "$def"
}

get_preferred_branch() {
    if git show-ref --verify --quiet refs/heads/demo/latest; then
        echo "demo/latest"
        return
    fi
    if git ls-remote --exit-code --heads origin demo/latest >/dev/null 2>&1; then
        echo "demo/latest"
        return
    fi
    if git show-ref --verify --quiet refs/heads/demo/20250828; then
        echo "demo/20250828"
        return
    fi
    if git ls-remote --exit-code --heads origin demo/20250828 >/dev/null 2>&1; then
        echo "demo/20250828"
        return
    fi
    echo "$(get_default_branch)"
}

switch_to_branch() {
    local target="$1"
    # If only remote exists, create local tracking branch
    if ! git show-ref --verify --quiet "refs/heads/${target}"; then
        if git ls-remote --exit-code --heads origin "$target" >/dev/null 2>&1; then
            git checkout -B "$target" "origin/${target}" >/dev/null 2>&1 || git switch -c "$target" --track "origin/${target}" >/dev/null 2>&1 || true
        else
            # Fallback: create from default branch
            local def
            def=$(get_default_branch)
            git checkout -B "$target" "$def" >/dev/null 2>&1 || git switch -C "$target" "$def" >/dev/null 2>&1 || true
        fi
    else
        git checkout "$target" >/dev/null 2>&1 || git switch "$target" >/dev/null 2>&1 || true
    fi
}

# Get preferred branch and set up exit trap
PREFERRED_BRANCH="$(get_preferred_branch)"

on_exit() {
    # Always return to preferred branch even if demo created a temp branch
    switch_to_branch "$PREFERRED_BRANCH"
}

trap on_exit EXIT

echo -e "${BLUE}🚀 Nova CI-Rescue GitHub Actions Test (Clean Version)${NC}"
echo "================================================="
echo

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo -e "${RED}❌ Error: GITHUB_TOKEN not set${NC}"
    echo "Please set your GitHub token first:"
    echo "  export GITHUB_TOKEN=your_github_token"
    exit 1
fi

unset GH_TOKEN || true

echo -e "${BLUE}📊 Phase 1: Checking current CI status${NC}"
gh run list --workflow="Nova CI-Rescue Demo" --limit 5 || echo "No previous runs found"
echo

# Use preferred branch
BASE_REF="${PREFERRED_BRANCH}"

# Sync with origin branch
echo -e "${BLUE}🔄 Starting from branch: ${BASE_REF}${NC}"
switch_to_branch "${BASE_REF}"
git fetch origin "${BASE_REF}" >/dev/null 2>&1 || true
git pull --ff-only origin "${BASE_REF}" >/dev/null 2>&1 || true

BRANCH_NAME="test-nova-ci-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}🌿 Phase 2: Creating test branch: $BRANCH_NAME${NC}"
git checkout -b "$BRANCH_NAME"
echo

echo -e "${RED}🐛 Phase 3: Introducing bugs to trigger CI failure${NC}"

# Use the clean bug introduction script
if [ -f "./introduce-bugs-clean.sh" ]; then
    bash ./introduce-bugs-clean.sh
else
    echo -e "${RED}❌ Error: introduce-bugs-clean.sh not found${NC}"
    exit 1
fi
echo

echo -e "${BLUE}📤 Phase 4: Pushing changes to trigger GitHub Actions${NC}"
git add src/calculator.py
git commit -m "Test Nova CI-Rescue: Introduce calculator bugs

This commit intentionally breaks several calculator functions to test
Nova CI-Rescue's ability to automatically fix failing tests.

Bugs introduced:
- add() now subtracts
- subtract() now adds
- multiply() now adds  
- divide() now multiplies
- power() now multiplies
- square_root() returns input value
- percentage() calculation is wrong
- average() returns sum instead of average"

git push origin "$BRANCH_NAME"
echo

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
- \`subtract()\` now adds instead of subtracting  
- \`multiply()\` now adds instead of multiplying
- \`divide()\` now multiplies instead of dividing
- \`power()\` now multiplies instead of exponentiating
- \`square_root()\` returns input instead of square root
- \`percentage()\` multiplies by 10 instead of dividing by 100
- \`average()\` returns sum instead of average

Watch the magic happen! 🎩✨" \
    --base "${BASE_REF}" \
    --head "$BRANCH_NAME")

echo "Pull request created: $PR_URL"
echo

echo -e "${BLUE}👀 Phase 6: Monitoring GitHub Actions workflow${NC}"
echo "Waiting for workflow to start..."
sleep 10

RUN_ID=$(gh run list --workflow="Nova CI-Rescue Demo" --limit 1 --json databaseId --jq '.[0].databaseId // empty')

if [ -n "${RUN_ID:-}" ]; then
    echo "Workflow run started: #$RUN_ID"
    echo "View in browser: https://github.com/novasolve/nova-rescue-ci-demo/actions/runs/$RUN_ID"
    echo
    echo "Following workflow progress..."
    gh run watch "$RUN_ID" --interval 5
    STATUS=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    echo
    echo "📥 Downloading workflow logs..."
    LOG_FILE="nova-ci-logs-${RUN_ID}-$(date +%Y%m%d-%H%M%S).zip"
    if gh run download "$RUN_ID" --dir "logs-$RUN_ID" 2>/dev/null; then
        echo "✅ Artifacts downloaded to logs-$RUN_ID/"
    fi
    if gh run view "$RUN_ID" --log > "workflow-log-$RUN_ID.txt" 2>/dev/null; then
        echo "✅ Complete workflow log saved to workflow-log-$RUN_ID.txt"
    fi
    if [ "$STATUS" = "success" ]; then
        echo -e "${GREEN}✅ Workflow completed successfully!${NC}"
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
if [ -n "${RUN_ID:-}" ]; then
    echo "- Workflow logs: workflow-log-$RUN_ID.txt"
    echo "- Artifacts: logs-$RUN_ID/"
fi
echo
echo "Next steps:"
echo "1. Review Nova's fix PR when it's created"
echo "2. Merge the fix PR to see tests pass"
echo "3. Clean up test branches when done"

echo
echo "🔒 Final cleanup: Unsetting GitHub tokens..."
unset GH_TOKEN || true
unset GITHUB_TOKEN || true
unset TEMP_GITHUB_TOKEN || true
echo "✅ All tokens cleared"
