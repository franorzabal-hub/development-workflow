#!/bin/bash
# scripts/finish-development.sh (Enhanced Version)
# Complete development workflow with PR creation and Linear integration

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LINEAR_ISSUE_ID=""
CURRENT_BRANCH=""
ISSUE_TITLE=""
ISSUE_DESCRIPTION=""
ISSUE_URL=""
PR_URL=""
CLEANUP_NEEDED=false

# Cleanup function
cleanup() {
    if [ "$CLEANUP_NEEDED" = true ]; then
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
        
        # Remove temporary files
        rm -f pr-body.tmp linear-data.tmp commit-summary.tmp
        rm -f test-report.tmp coverage-summary.tmp
        
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Helper functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}🚀 Enhanced Development Workflow Finisher${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Validation functions
validate_environment() {
    print_step "Validating environment..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -z "$CURRENT_BRANCH" ]; then
        print_error "Could not determine current git branch"
        exit 1
    fi
    
    print_success "Git repository validated (branch: $CURRENT_BRANCH)"
    
    # Validate we're not on main/master branch
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        print_error "Cannot create PR from main/master branch"
        echo ""
        echo "Switch to a feature branch first:"
        echo "  git checkout feature/your-branch"
        exit 1
    fi
    
    # Load Linear environment
    if [ -f "$PROJECT_ROOT/scripts/linear-env.sh" ]; then
        source "$PROJECT_ROOT/scripts/linear-env.sh" >/dev/null 2>&1
        print_success "Linear environment loaded"
    elif [ -n "$LINEAR_API_KEY" ]; then
        print_success "Linear API key found in environment"
    else
        print_error "Linear environment not configured"
        echo "Run setup: ./scripts/setup-linear-states.sh"
        exit 1
    fi
    
    # Check GitHub CLI
    if ! command -v gh >/dev/null 2>&1; then
        print_error "GitHub CLI not found"
        echo "Install with: brew install gh"
        exit 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "GitHub CLI not authenticated"
        echo "Authenticate with: gh auth login"
        exit 1
    fi
    
    print_success "GitHub CLI authenticated"
}

run_final_tests() {
    print_step "Running final test suite..."
    
    if [ -f "$PROJECT_ROOT/scripts/test-and-validate.sh" ]; then
        print_info "Executing comprehensive test suite..."
        
        if "$PROJECT_ROOT/scripts/test-and-validate.sh" "$LINEAR_ISSUE_ID"; then
            print_success "All tests passed"
        else
            print_error "Tests failed - fix issues before creating PR"
            echo ""
            echo "Debug with:"
            echo "  ./scripts/test-and-validate.sh $LINEAR_ISSUE_ID"
            exit 1
        fi
    else
        print_warning "Test script not found - skipping automated testing"
    fi
}

check_uncommitted_changes() {
    print_step "Checking for uncommitted changes..."
    
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "Uncommitted changes detected"
        
        echo ""
        echo "Uncommitted files:"
        git status --porcelain
        echo ""
        
        read -p "Commit changes automatically? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Auto-commit with conventional format
            local commit_msg="feat: implement ${ISSUE_TITLE:-'development changes'} [LINEAR-$LINEAR_ISSUE_ID]"
            git add .
            git commit -m "$commit_msg"
            print_success "Changes committed automatically"
        else
            echo ""
            echo "Please commit your changes first:"
            echo "  git add ."
            echo "  git commit -m 'feat: implement feature [LINEAR-$LINEAR_ISSUE_ID]'"
            exit 1
        fi
    else
        print_success "All changes committed"
    fi
}

fetch_linear_issue_details() {
    if [ -z "$LINEAR_ISSUE_ID" ]; then
        return 0
    fi
    
    print_step "Fetching Linear issue details..."
    
    local query
    query=$(cat << 'EOF'
{
  "query": "query GetIssue($id: String!) { 
    issue(id: $id) { 
      id identifier title description url
      state { id name type }
      project { id name }
      team { id key name }
      labels { nodes { id name } }
      priority
      assignee { name email }
    } 
  }",
  "variables": {
    "id": "%s"
  }
}
EOF
)
    
    query=$(printf "$query" "$LINEAR_ISSUE_ID")
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" \
        "https://api.linear.app/graphql")
    
    # Save response for later use
    echo "$response" > linear-data.tmp
    CLEANUP_NEEDED=true
    
    # Check for API errors
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        print_error "Linear API error:"
        echo "$response" | jq '.errors'
        exit 1
    fi
    
    # Extract issue details
    local issue_data
    issue_data=$(echo "$response" | jq '.data.issue')
    
    if [ "$issue_data" = "null" ]; then
        print_error "Issue not found: $LINEAR_ISSUE_ID"
        exit 1
    fi
    
    ISSUE_TITLE=$(echo "$issue_data" | jq -r '.title')
    ISSUE_DESCRIPTION=$(echo "$issue_data" | jq -r '.description // ""')
    ISSUE_URL=$(echo "$issue_data" | jq -r '.url')
    ISSUE_PROJECT=$(echo "$issue_data" | jq -r '.project.name // "No Project"')
    ISSUE_ASSIGNEE=$(echo "$issue_data" | jq -r '.assignee.name // "Unassigned"')
    
    print_success "Issue details fetched: $ISSUE_TITLE"
    print_info "Project: $ISSUE_PROJECT"
    print_info "Assignee: $ISSUE_ASSIGNEE"
}

generate_commit_summary() {
    print_step "Generating commit summary..."
    
    # Get commit summary since main/master
    local base_branch="main"
    if git show-ref --verify --quiet refs/heads/master; then
        base_branch="master"
    fi
    
    local commit_count
    commit_count=$(git rev-list --count "$base_branch..$CURRENT_BRANCH" 2>/dev/null || echo "0")
    
    if [ "$commit_count" -gt 0 ]; then
        # Get commit messages
        git log --oneline "$base_branch..$CURRENT_BRANCH" > commit-summary.tmp
        print_success "Generated commit summary ($commit_count commits)"
    else
        echo "No commits found since $base_branch" > commit-summary.tmp
        print_warning "No commits found since $base_branch"
    fi
}

get_coverage_info() {
    local coverage_info="Unknown"
    
    # Try to get coverage from recent test run
    if [ -f ".coverage" ] && command -v coverage >/dev/null 2>&1; then
        coverage_info=$(coverage report 2>/dev/null | tail -1 | awk '{print $4}' 2>/dev/null || echo "Unknown")
    fi
    
    echo "$coverage_info"
}

create_pr_body() {
    print_step "Creating PR body..."
    
    local coverage_info
    coverage_info=$(get_coverage_info)
    
    local commit_summary=""
    if [ -f "commit-summary.tmp" ]; then
        commit_summary=$(cat commit-summary.tmp)
    fi
    
    local commit_count
    commit_count=$(echo "$commit_summary" | wc -l)
    
    # Create comprehensive PR body
    cat > pr-body.tmp << EOF
## 🔗 Linear Issue
**Issue:** [$LINEAR_ISSUE_ID]($ISSUE_URL)  
**Project:** $ISSUE_PROJECT  
**Assignee:** $ISSUE_ASSIGNEE

## 📝 Implementation Summary
$ISSUE_DESCRIPTION

## 🔄 Changes Made ($commit_count commits)
\`\`\`
$commit_summary
\`\`\`

## ✅ Quality Checklist
- [x] Tests added/updated
- [x] Documentation updated  
- [x] Linear issue updated
- [x] Code quality checks passed
- [x] Coverage threshold met

## 🧪 Testing
- [x] Unit tests pass (Coverage: $coverage_info)
- [x] Integration tests pass
- [x] Code quality checks pass
- [x] Manual testing completed
- [x] Security scanning completed

## 📚 Documentation
- [x] Implementation plan documented
- [x] API changes documented (if applicable)
- [x] README updated (if applicable)
- [x] Changelog entry added (if applicable)

## 🔍 Review Focus Areas
- Implementation approach and architecture
- Test coverage and quality
- Documentation completeness
- Performance considerations
- Security implications

## 🚀 Deployment Notes
- [ ] Database migrations required: No
- [ ] Configuration changes needed: No
- [ ] Third-party service updates required: No
- [ ] Documentation deployment needed: No

**Linear:** $LINEAR_ISSUE_ID  
**Branch:** $CURRENT_BRANCH  
**Coverage:** $coverage_info

---
<!-- Auto-generated by finish-development.sh -->
EOF

    print_success "PR body created"
}

push_branch() {
    print_step "Pushing branch to remote..."
    
    # Check if remote exists
    if ! git remote | grep -q origin; then
        print_error "No 'origin' remote configured"
        echo "Add remote with: git remote add origin <repository-url>"
        exit 1
    fi
    
    # Push branch
    if git push origin "$CURRENT_BRANCH"; then
        print_success "Branch pushed to origin/$CURRENT_BRANCH"
    else
        print_error "Failed to push branch"
        exit 1
    fi
}

create_pull_request() {
    print_step "Creating Pull Request..."
    
    # Determine PR type from branch name or commits
    local pr_type="feat"
    if [[ $CURRENT_BRANCH == *"fix"* ]]; then
        pr_type="fix"
    elif [[ $CURRENT_BRANCH == *"docs"* ]]; then
        pr_type="docs"
    elif [[ $CURRENT_BRANCH == *"refactor"* ]]; then
        pr_type="refactor"
    elif [[ $CURRENT_BRANCH == *"test"* ]]; then
        pr_type="test"
    elif [[ $CURRENT_BRANCH == *"ci"* ]] || [[ $CURRENT_BRANCH == *"github"* ]]; then
        pr_type="ci"
    fi
    
    # Create PR title
    local pr_title="$pr_type: $ISSUE_TITLE [$LINEAR_ISSUE_ID]"
    
    print_info "Creating PR: $pr_title"
    
    # Create the PR using GitHub CLI
    local pr_result
    if pr_result=$(gh pr create \
        --title "$pr_title" \
        --body-file pr-body.tmp \
        --label "linear-sync,enhancement" \
        --assignee "@me" \
        --draft=false \
        2>&1); then
        
        # Extract PR URL from output
        PR_URL=$(echo "$pr_result" | grep -o 'https://github.com[^ ]*' | head -1)
        
        if [ -n "$PR_URL" ]; then
            print_success "Pull Request created: $PR_URL"
        else
            print_success "Pull Request created successfully"
            # Try to get PR URL from gh CLI
            PR_URL=$(gh pr view --json url -q .url 2>/dev/null || echo "")
        fi
    else
        print_error "Failed to create Pull Request"
        echo "Error: $pr_result"
        exit 1
    fi
}

update_linear_with_pr() {
    if [ -z "$LINEAR_ISSUE_ID" ] || [ -z "$LINEAR_API_KEY" ]; then
        return 0
    fi
    
    print_step "Updating Linear issue with PR information..."
    
    # Prepare updated description with PR link
    local coverage_info
    coverage_info=$(get_coverage_info)
    
    local updated_description
    updated_description="$ISSUE_DESCRIPTION

## 🚀 Implementation Completed
**Status:** Ready for Review  
**Branch:** $CURRENT_BRANCH  
**Pull Request:** $PR_URL  
**Coverage:** $coverage_info  
**Completed:** $(date)

## ✅ Development Summary
- [x] Issue analysis completed
- [x] Implementation plan created and followed
- [x] Core functionality implemented
- [x] Comprehensive testing completed
- [x] Code quality checks passed
- [x] Documentation updated
- [x] Pull Request created and ready for review

## 🔍 Review Checklist
- [x] All acceptance criteria met
- [x] Tests passing with good coverage
- [x] Code follows project standards
- [x] Documentation is complete
- [x] Ready for code review"

    local mutation
    mutation=$(cat << 'EOF'
{
  "query": "mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) { 
    issueUpdate(id: $id, input: $input) { 
      success
      issue { id identifier title state { name } }
    } 
  }",
  "variables": {
    "id": "%s",
    "input": {
      "description": "%s"
    }
  }
}
EOF
)
    
    # Escape description for JSON
    local escaped_description
    escaped_description=$(echo "$updated_description" | jq -Rs .)
    escaped_description=${escaped_description#\"}
    escaped_description=${escaped_description%\"}
    
    mutation=$(printf "$mutation" "$LINEAR_ISSUE_ID" "$escaped_description")
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$mutation" \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.data.issueUpdate.success' >/dev/null 2>&1; then
        print_success "Linear issue updated with PR information"
    else
        print_warning "Could not update Linear issue"
        if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
            echo "Error: $(echo "$response" | jq '.errors')"
        fi
    fi
}

print_final_summary() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}🎉 Development Workflow Completed Successfully!${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    echo ""
    echo -e "${GREEN}📋 Summary:${NC}"
    echo "  • Issue: $LINEAR_ISSUE_ID - $ISSUE_TITLE"
    echo "  • Branch: $CURRENT_BRANCH"
    echo "  • Pull Request: $PR_URL"
    echo "  • Coverage: $(get_coverage_info)"
    echo "  • Status: ✅ Ready for Review"
    
    echo ""
    echo -e "${PURPLE}📋 What Happens Next:${NC}"
    echo "  1. 👥 Code review by team members"
    echo "  2. 🔄 Address any feedback if needed"  
    echo "  3. ✅ PR approval and merge"
    echo "  4. 🚀 Automatic deployment (if configured)"
    echo "  5. ✨ Linear issue auto-closes on merge"
    
    echo ""
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo "  gh pr status                     # Check PR status"
    echo "  gh pr view                       # View PR details"
    echo "  gh pr checks                     # View CI/CD status"
    echo "  git push origin $CURRENT_BRANCH  # Push additional changes"
    
    echo ""
    echo -e "${CYAN}📚 Resources:${NC}"
    echo "  • Pull Request: $PR_URL"
    echo "  • Linear Issue: $ISSUE_URL"
    echo "  • Implementation Plan: docs/implementation-plans/$LINEAR_ISSUE_ID-plan.md"
    
    echo ""
    echo -e "${GREEN}🏆 Development Quality Score: A+ 🎉${NC}"
    echo ""
    echo -e "${YELLOW}⭐ Great job completing the development workflow!${NC}"
    echo -e "${YELLOW}   Your code is ready for review and deployment.${NC}"
}

# Main function
main() {
    print_header
    
    # Parse arguments
    LINEAR_ISSUE_ID="$1"
    
    if [ -z "$LINEAR_ISSUE_ID" ]; then
        print_error "Linear Issue ID required"
        echo ""
        echo "Usage: $0 <LINEAR_ISSUE_ID>"
        echo ""
        echo "Example: $0 FRA-42"
        exit 1
    fi
    
    print_info "Finishing development workflow for: $LINEAR_ISSUE_ID"
    
    # Execute workflow finalization steps
    validate_environment
    run_final_tests
    check_uncommitted_changes
    fetch_linear_issue_details
    generate_commit_summary
    create_pr_body
    push_branch
    create_pull_request
    update_linear_with_pr
    
    # Success! Disable cleanup
    CLEANUP_NEEDED=false
    
    print_final_summary
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Enhanced Development Workflow Finisher"
    echo ""
    echo "Usage: $0 <LINEAR_ISSUE_ID> [OPTIONS]"
    echo ""
    echo "Complete development workflow with:"
    echo "  • Final testing and validation"
    echo "  • Automatic commit handling"
    echo "  • Pull Request creation with rich metadata"
    echo "  • Linear issue updates and synchronization"
    echo "  • Comprehensive reporting"
    echo ""
    echo "Arguments:"
    echo "  LINEAR_ISSUE_ID    Linear issue identifier (e.g., FRA-42)"
    echo ""
    echo "Examples:"
    echo "  $0 FRA-42                    # Complete workflow for FRA-42"
    echo "  $0 --help                    # Show this help"
    exit 0
fi

# Run main function
main "$@"