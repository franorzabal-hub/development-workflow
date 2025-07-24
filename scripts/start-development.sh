#!/bin/bash
# scripts/start-development.sh (Enhanced Version)
# Comprehensive development workflow starter with Linear integration

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
ORIGINAL_BRANCH=""
ROLLBACK_TAG=""
CLEANUP_NEEDED=false

# Cleanup function for error handling
cleanup() {
    if [ "$CLEANUP_NEEDED" = true ]; then
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up due to error...${NC}"
        
        # Restore original branch if we changed it
        if [ -n "$ORIGINAL_BRANCH" ] && [ "$ORIGINAL_BRANCH" != "$(git branch --show-current 2>/dev/null)" ]; then
            echo -e "${BLUE}🔄 Restoring original branch: $ORIGINAL_BRANCH${NC}"
            git checkout "$ORIGINAL_BRANCH" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not restore original branch${NC}"
        fi
        
        # Remove rollback tag if created
        if [ -n "$ROLLBACK_TAG" ]; then
            echo -e "${BLUE}🗑️  Removing rollback tag: $ROLLBACK_TAG${NC}"
            git tag -d "$ROLLBACK_TAG" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not remove rollback tag${NC}"
        fi
        
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Helper functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}🚀 Enhanced Development Workflow Starter${NC}"
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
        echo "Initialize with: git init"
        exit 1
    fi
    
    # Store original branch for rollback
    ORIGINAL_BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -z "$ORIGINAL_BRANCH" ]; then
        print_error "Could not determine current git branch"
        exit 1
    fi
    
    print_success "Git repository validated (current branch: $ORIGINAL_BRANCH)"
    
    # Load Linear environment
    if [ -f "$PROJECT_ROOT/scripts/linear-env.sh" ]; then
        source "$PROJECT_ROOT/scripts/linear-env.sh" >/dev/null 2>&1
        print_success "Linear environment loaded"
    elif [ -n "$LINEAR_API_KEY" ]; then
        print_success "Linear API key found in environment"
    else
        print_error "Linear environment not configured"
        echo ""
        echo "Run setup first:"
        echo "  ./scripts/setup-linear-states.sh"
        exit 1
    fi
    
    # Validate required environment variables
    local required_vars=("LINEAR_API_KEY" "LINEAR_IN_PROGRESS_STATE_ID" "LINEAR_DONE_STATE_ID")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Required environment variable not set: $var"
            echo "Run setup: ./scripts/setup-linear-states.sh"
            exit 1
        fi
    done
    
    print_success "All required environment variables configured"
}

fetch_linear_issue() {
    local issue_id="$1"
    
    print_step "Fetching Linear issue details: $issue_id"
    
    local query
    query=$(cat << 'EOF'
{
  "query": "query GetIssue($id: String!) { 
    issue(id: $id) { 
      id identifier title description url
      state { id name type }
      assignee { id name email }
      project { id name }
      team { id key name }
      labels { nodes { id name } }
      priority
      estimate
      createdAt
      updatedAt
    } 
  }",
  "variables": {
    "id": "%s"
  }
}
EOF
)
    
    query=$(printf "$query" "$issue_id")
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" \
        "https://api.linear.app/graphql")
    
    # Check for API errors
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        print_error "Linear API error:"
        echo "$response" | jq '.errors'
        exit 1
    fi
    
    # Check if issue exists
    local issue_data
    issue_data=$(echo "$response" | jq '.data.issue')
    
    if [ "$issue_data" = "null" ]; then
        print_error "Issue not found: $issue_id"
        echo ""
        echo "Available issues:"
        show_available_issues
        exit 1
    fi
    
    # Extract issue details
    ISSUE_TITLE=$(echo "$issue_data" | jq -r '.title')
    ISSUE_DESCRIPTION=$(echo "$issue_data" | jq -r '.description // ""')
    ISSUE_URL=$(echo "$issue_data" | jq -r '.url')
    ISSUE_STATE=$(echo "$issue_data" | jq -r '.state.name')
    ISSUE_PROJECT=$(echo "$issue_data" | jq -r '.project.name // "No Project"')
    ISSUE_ASSIGNEE=$(echo "$issue_data" | jq -r '.assignee.name // "Unassigned"')
    ISSUE_TEAM_KEY=$(echo "$issue_data" | jq -r '.team.key')
    
    print_success "Issue validated: $ISSUE_TITLE"
    print_info "Project: $ISSUE_PROJECT"
    print_info "State: $ISSUE_STATE"
    print_info "Assignee: $ISSUE_ASSIGNEE"
    
    return 0
}

show_available_issues() {
    print_info "Fetching available issues..."
    
    local team_key="${LINEAR_TEAM_KEY:-FRA}"
    local query
    query=$(cat << 'EOF'
{
  "query": "query GetIssues($teamKey: String!) { 
    issues(filter: { 
      team: { key: { eq: $teamKey } }, 
      state: { type: { in: [\"backlog\", \"unstarted\", \"started\"] } } 
    }, first: 10, orderBy: updatedAt) { 
      nodes { 
        id identifier title 
        state { name type }
        assignee { name }
        priority
      } 
    } 
  }",
  "variables": {
    "teamKey": "%s"
  }
}
EOF
)
    
    query=$(printf "$query" "$team_key")
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        print_error "Failed to fetch available issues"
        return 1
    fi
    
    echo ""
    echo "📋 Available issues in team $team_key:"
    echo "$response" | jq -r '.data.issues.nodes[] | "  \(.identifier): \(.title) (\(.state.name)) - \(.assignee.name // "Unassigned")"'
    echo ""
}

create_rollback_point() {
    print_step "Creating rollback point..."
    
    # Create a rollback tag
    ROLLBACK_TAG="rollback-$(date +%Y%m%d-%H%M%S)-$LINEAR_ISSUE_ID"
    
    if git tag "$ROLLBACK_TAG" 2>/dev/null; then
        print_success "Rollback point created: $ROLLBACK_TAG"
    else
        print_warning "Could not create rollback tag (non-fatal)"
        ROLLBACK_TAG=""
    fi
}

create_feature_branch() {
    print_step "Creating feature branch..."
    
    # Generate branch name
    local branch_name
    branch_name="feature/$LINEAR_ISSUE_ID-$(echo "$ISSUE_TITLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | head -c 40)"
    
    print_info "Branch name: $branch_name"
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        print_warning "Branch $branch_name already exists"
        read -p "Switch to existing branch? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout "$branch_name"
            print_success "Switched to existing branch: $branch_name"
        else
            exit 1
        fi
    else
        # Create and switch to new branch
        git checkout -b "$branch_name"
        print_success "Created and switched to branch: $branch_name"
        CLEANUP_NEEDED=true
    fi
    
    FEATURE_BRANCH="$branch_name"
}

create_implementation_plan() {
    print_step "Creating implementation plan..."
    
    # Create implementation plans directory
    local plans_dir="$PROJECT_ROOT/docs/implementation-plans"
    mkdir -p "$plans_dir"
    
    local plan_file="$plans_dir/$LINEAR_ISSUE_ID-plan.md"
    
    # Generate implementation plan
    cat > "$plan_file" << EOF
# Implementation Plan: $ISSUE_TITLE

**Linear Issue:** [$LINEAR_ISSUE_ID]($ISSUE_URL)  
**GitHub Branch:** $FEATURE_BRANCH  
**Project:** $ISSUE_PROJECT  
**Assignee:** $ISSUE_ASSIGNEE  
**Created:** $(date)

## 📝 Description
$ISSUE_DESCRIPTION

## 🎯 Acceptance Criteria
- [ ] Functionality implemented according to specification
- [ ] Unit tests added with >90% coverage
- [ ] Integration tests implemented (if applicable)
- [ ] Documentation updated
- [ ] Code review approved
- [ ] Linear issue updated

## 🏗️ Technical Approach

### Architecture Changes
- [ ] Component modifications needed
- [ ] Database schema changes (if applicable)
- [ ] API endpoints affected
- [ ] Configuration changes required

### Implementation Steps
1. [ ] Setup development environment
2. [ ] Implement core functionality
3. [ ] Add comprehensive tests
4. [ ] Update documentation
5. [ ] Code review and refinement
6. [ ] Integration testing
7. [ ] Final validation

## 🧪 Testing Strategy

### Unit Tests
- [ ] Test file locations identified
- [ ] Mock dependencies configured
- [ ] Edge cases covered
- [ ] Error scenarios tested

### Integration Tests
- [ ] End-to-end scenarios defined
- [ ] Database interactions tested
- [ ] External API calls validated
- [ ] Performance testing completed

## 📚 Documentation Updates
- [ ] API documentation updated
- [ ] User guides modified
- [ ] Architecture diagrams updated
- [ ] Changelog entry added

## ⏱️ Time Estimation
- **Development:** ___ hours
- **Testing:** ___ hours  
- **Documentation:** ___ hours
- **Code Review:** ___ hours
- **Total:** ___ hours

## 🚧 Risks and Mitigation
- **Risk 1:** Description → Mitigation strategy
- **Risk 2:** Description → Mitigation strategy

## 📋 Definition of Done
- [ ] All acceptance criteria met
- [ ] Code implemented and tested
- [ ] All tests passing (>90% coverage)
- [ ] Documentation complete and accurate
- [ ] Code reviewed and approved
- [ ] Linear issue updated to completed
- [ ] Changes deployed successfully

---
**Status:** 🚀 In Progress  
**Last Updated:** $(date)  
**Branch:** $FEATURE_BRANCH
EOF

    print_success "Implementation plan created: $plan_file"
}

update_linear_issue() {
    print_step "Updating Linear issue to 'In Progress'..."
    
    # Prepare the description update
    local updated_description
    updated_description="$ISSUE_DESCRIPTION

## 🚀 Implementation Started
**Status:** In Progress  
**Branch:** $FEATURE_BRANCH  
**Implementation Plan:** docs/implementation-plans/$LINEAR_ISSUE_ID-plan.md  
**Started:** $(date)

## 📋 Development Progress
- [x] Issue analysis completed
- [x] Implementation plan created
- [x] Development branch created
- [ ] Core functionality implementation
- [ ] Testing implementation
- [ ] Documentation updates
- [ ] Code review
- [ ] Final validation"

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
      "stateId": "%s",
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
    
    mutation=$(printf "$mutation" "$LINEAR_ISSUE_ID" "$LINEAR_IN_PROGRESS_STATE_ID" "$escaped_description")
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$mutation" \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.data.issueUpdate.success' >/dev/null 2>&1; then
        print_success "Linear issue updated to 'In Progress'"
    else
        print_warning "Could not update Linear issue status"
        if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
            echo "Error: $(echo "$response" | jq '.errors')"
        fi
    fi
}

print_next_steps() {
    echo ""
    echo -e "${BLUE}🎉 Development environment ready for $LINEAR_ISSUE_ID!${NC}"
    echo ""
    echo -e "${PURPLE}📋 Next Steps:${NC}"
    echo "1. Review implementation plan:"
    echo "   📄 docs/implementation-plans/$LINEAR_ISSUE_ID-plan.md"
    echo ""
    echo "2. Start development on branch:"
    echo "   🌿 $FEATURE_BRANCH"
    echo ""
    echo "3. Commit changes with conventional format:"
    echo "   📝 git add . && git commit -m 'feat: implement X [LINEAR-$LINEAR_ISSUE_ID]'"
    echo ""
    echo "4. Run tests during development:"
    echo "   🧪 ./scripts/test-and-validate.sh $LINEAR_ISSUE_ID"
    echo ""
    echo "5. Create PR when ready:"
    echo "   🚀 ./scripts/finish-development.sh $LINEAR_ISSUE_ID"
    echo ""
    echo -e "${GREEN}🔧 Useful commands:${NC}"
    echo "  git status                           # Check current changes"
    echo "  git log --oneline                    # View commit history"
    echo "  git push origin $FEATURE_BRANCH      # Push branch to remote"
    echo ""
    if [ -n "$ROLLBACK_TAG" ]; then
        echo -e "${YELLOW}⚠️  Rollback if needed:${NC}"
        echo "  git checkout $ORIGINAL_BRANCH && git reset --hard $ROLLBACK_TAG"
    fi
    echo ""
    echo -e "${BLUE}📚 Resources:${NC}"
    echo "  • Linear Issue: $ISSUE_URL"
    echo "  • Implementation Plan: docs/implementation-plans/$LINEAR_ISSUE_ID-plan.md"
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
        echo ""
        show_available_issues
        exit 1
    fi
    
    print_info "Starting development workflow for: $LINEAR_ISSUE_ID"
    
    # Execute workflow steps
    validate_environment
    fetch_linear_issue "$LINEAR_ISSUE_ID"
    create_rollback_point
    create_feature_branch
    create_implementation_plan
    update_linear_issue
    
    # Success! Disable cleanup
    CLEANUP_NEEDED=false
    
    print_next_steps
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Enhanced Development Workflow Starter"
    echo ""
    echo "Usage: $0 <LINEAR_ISSUE_ID> [OPTIONS]"
    echo ""
    echo "Start development workflow for a Linear issue with:"
    echo "  • Issue validation and fetching"
    echo "  • Automatic branch creation"  
    echo "  • Implementation plan generation"
    echo "  • Linear status updates"
    echo "  • Development environment setup"
    echo "  • Rollback capabilities"
    echo ""
    echo "Arguments:"
    echo "  LINEAR_ISSUE_ID    Linear issue identifier (e.g., FRA-42)"
    echo ""
    echo "Examples:"
    echo "  $0 FRA-42                    # Start development for FRA-42"
    echo "  $0 --help                    # Show this help"
    exit 0
fi

# Run main function
main "$@"