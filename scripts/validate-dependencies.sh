#!/bin/bash
# scripts/validate-dependencies.sh
# Comprehensive dependency validation for Linear-GitHub development workflow

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Global variables
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}🔧 Development Workflow Dependency Validation${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((VALIDATION_WARNINGS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((VALIDATION_ERRORS++))
}

print_info() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_section() {
    echo ""
    echo -e "${PURPLE}🔍 $1${NC}"
    echo "$(printf '%.0s-' {1..50})"
}

check_system_tools() {
    print_section "System Tools"
    
    local required_tools=("git" "curl" "jq" "grep" "awk" "sed")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version
            case "$tool" in
                "git")
                    version=$(git --version 2>/dev/null | awk '{print $3}')
                    ;;
                "curl")
                    version=$(curl --version 2>/dev/null | head -1 | awk '{print $2}')
                    ;;
                "jq")
                    version=$(jq --version 2>/dev/null | sed 's/jq-//')
                    ;;
                *)
                    version="installed"
                    ;;
            esac
            print_success "$tool: $version"
        else
            missing_tools+=("$tool")
            print_error "$tool: not found"
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo ""
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Install missing tools:"
        echo "  macOS: brew install ${missing_tools[*]}"
        echo "  Ubuntu: sudo apt-get install ${missing_tools[*]}"
    fi
}

check_github_cli() {
    print_section "GitHub CLI"
    
    if ! command -v gh >/dev/null 2>&1; then
        print_error "GitHub CLI (gh) not found"
        echo ""
        echo "Install GitHub CLI:"
        echo "  macOS: brew install gh"
        echo "  Ubuntu: sudo apt-get install gh"
        echo "  Or visit: https://cli.github.com"
        return
    fi
    
    local gh_version
    gh_version=$(gh --version 2>/dev/null | head -1 | awk '{print $3}')
    print_success "GitHub CLI: $gh_version"
    
    # Check authentication
    if gh auth status >/dev/null 2>&1; then
        local gh_user
        gh_user=$(gh api user --jq .login 2>/dev/null)
        print_success "GitHub authentication: $gh_user"
    else
        print_error "GitHub CLI not authenticated"
        echo ""
        echo "Authenticate with: gh auth login"
    fi
}

check_environment_variables() {
    print_section "Environment Variables"
    
    # Required variables
    local required_vars=("LINEAR_API_KEY")
    local optional_vars=("LINEAR_TEAM_KEY" "LINEAR_TODO_STATE_ID" "LINEAR_IN_PROGRESS_STATE_ID" "LINEAR_IN_REVIEW_STATE_ID" "LINEAR_DONE_STATE_ID")
    
    # Check required variables
    for var in "${required_vars[@]}"; do
        if [ -n "${!var}" ]; then
            # Mask sensitive values
            local masked_value
            if [[ "$var" == *"KEY"* ]] || [[ "$var" == *"TOKEN"* ]]; then
                masked_value="$(echo "${!var}" | cut -c1-8)***"
            else
                masked_value="${!var}"
            fi
            print_success "$var: $masked_value"
        else
            print_error "$var: not set"
        fi
    done
    
    # Check optional variables
    for var in "${optional_vars[@]}"; do
        if [ -n "${!var}" ]; then
            print_success "$var: ${!var}"
        else
            print_warning "$var: not set (run setup-linear-states.sh)"
        fi
    done
    
    # Check for configuration files
    if [ -f ".env" ]; then
        print_success ".env file found"
    else
        print_warning ".env file not found"
    fi
    
    if [ -f "scripts/linear-env.sh" ]; then
        print_success "scripts/linear-env.sh found"
    else
        print_warning "scripts/linear-env.sh not found"
    fi
}

check_linear_api() {
    print_section "Linear API Connection"
    
    if [ -z "$LINEAR_API_KEY" ]; then
        print_error "LINEAR_API_KEY not set - cannot test Linear API"
        return
    fi
    
    print_info "Testing Linear API connection..."
    
    local response
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"query": "{ viewer { name email } }"}' \
        "https://api.linear.app/graphql" 2>/dev/null)
    
    local http_code
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    local body
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [ "$http_code" -ne 200 ]; then
        print_error "Linear API HTTP error: $http_code"
        return
    fi
    
    if echo "$body" | jq -e '.errors' >/dev/null 2>&1; then
        print_error "Linear API error:"
        echo "$body" | jq '.errors'
        return
    fi
    
    local user_name user_email
    user_name=$(echo "$body" | jq -r '.data.viewer.name // "Unknown"')
    user_email=$(echo "$body" | jq -r '.data.viewer.email // "Unknown"')
    
    print_success "Linear API connection successful"
    print_info "Connected as: $user_name ($user_email)"
}

check_github_api() {
    print_section "GitHub API Connection"
    
    if ! command -v gh >/dev/null 2>&1; then
        print_error "GitHub CLI not available - cannot test GitHub API"
        return
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        print_error "GitHub CLI not authenticated - cannot test GitHub API"
        return
    fi
    
    print_info "Testing GitHub API connection..."
    
    local user_info
    if user_info=$(gh api user --jq '{login: .login, name: .name, type: .type}' 2>/dev/null); then
        print_success "GitHub API connection successful"
        local login name type
        login=$(echo "$user_info" | jq -r '.login')
        name=$(echo "$user_info" | jq -r '.name // "No name set"')
        type=$(echo "$user_info" | jq -r '.type')
        print_info "Connected as: $name (@$login) - $type"
    else
        print_error "GitHub API connection failed"
        return
    fi
}

check_git_repository() {
    print_section "Git Repository"
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not a git repository"
        echo ""
        echo "Initialize git repository with:"
        echo "  git init"
        return
    fi
    
    print_success "Git repository initialized"
    
    # Check current branch
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    print_info "Current branch: $current_branch"
    
    # Check git config
    local git_user git_email
    git_user=$(git config user.name 2>/dev/null || echo "not set")
    git_email=$(git config user.email 2>/dev/null || echo "not set")
    
    if [ "$git_user" != "not set" ] && [ "$git_email" != "not set" ]; then
        print_success "Git user configured: $git_user <$git_email>"
    else
        print_warning "Git user not configured"
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    if [ "$VALIDATION_ERRORS" -eq 0 ] && [ "$VALIDATION_WARNINGS" -eq 0 ]; then
        print_success "All validations passed! 🎉"
        echo ""
        echo "You're ready to start the development workflow:"
        echo "  ./scripts/setup-linear-states.sh"
        echo "  ./scripts/start-development.sh FRA-42"
    elif [ "$VALIDATION_ERRORS" -eq 0 ]; then
        print_success "Validation completed with $VALIDATION_WARNINGS warning(s)"
        echo ""
        echo "You can proceed, but consider addressing the warnings above."
    else
        print_error "Validation failed with $VALIDATION_ERRORS error(s) and $VALIDATION_WARNINGS warning(s)"
        echo ""
        echo "Please fix the errors above before proceeding."
        exit 1
    fi
}

main() {
    print_header
    
    # Create directories if they don't exist
    mkdir -p scripts docs
    
    # Run all validation checks
    check_system_tools
    check_github_cli
    check_environment_variables
    check_linear_api
    check_github_api
    check_git_repository
    
    # Print summary
    print_summary
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Validate all dependencies for the Linear-GitHub development workflow."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --quiet        Suppress info messages (errors and warnings only)"
    echo ""
    echo "Environment Variables:"
    echo "  LINEAR_API_KEY              Your Linear API key"
    echo "  LINEAR_TEAM_KEY             Linear team key (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run full validation"
    echo "  $0 --quiet           # Run with minimal output"
    exit 0
fi

# Handle quiet mode
if [ "$1" = "--quiet" ]; then
    exec > >(grep -E "(✅|⚠️|❌)")
fi

# Run main function
main "$@"