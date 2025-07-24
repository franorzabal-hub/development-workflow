#!/bin/bash
# scripts/claude-aliases.sh
# Enhanced command aliases for the Claude development workflow

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define aliases
setup_aliases() {
    print_info "Setting up Claude development workflow aliases..."
    
    # Create alias definitions
    cat << 'EOF' > "$SCRIPT_DIR/claude-workflow-aliases.sh"
#!/bin/bash
# Claude Development Workflow Aliases
# Source this file: source scripts/claude-workflow-aliases.sh

# Get script directory
CLAUDE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Core workflow commands
alias claude-deps="$CLAUDE_SCRIPTS_DIR/validate-dependencies.sh"
alias claude-setup="$CLAUDE_SCRIPTS_DIR/setup-linear-states.sh"
alias claude-start="$CLAUDE_SCRIPTS_DIR/start-development.sh"
alias claude-test="$CLAUDE_SCRIPTS_DIR/test-and-validate.sh"
alias claude-finish="$CLAUDE_SCRIPTS_DIR/finish-development.sh"

# Utility commands
alias claude-env="source $CLAUDE_SCRIPTS_DIR/linear-env.sh"
alias claude-help="claude-workflow-help"
alias claude-status="claude-workflow-status"

# Extended commands
alias claude-validate="claude-deps"
alias claude-init="claude-setup"
alias claude-dev="claude-start"
alias claude-check="claude-test"
alias claude-pr="claude-finish"

# Git workflow helpers
alias claude-branch="git branch --show-current"
alias claude-commits="git log --oneline main..HEAD"
alias claude-diff="git diff main..HEAD"
alias claude-push="git push origin \$(git branch --show-current)"

# Linear helpers (if API key is available)
alias claude-issues="claude-list-issues"
alias claude-issue="claude-show-issue"

echo "✅ Claude development workflow aliases loaded"
echo ""
echo "📋 Available commands:"
echo "  claude-setup     # Setup Linear states"
echo "  claude-deps      # Validate dependencies" 
echo "  claude-start     # Start development"
echo "  claude-test      # Run tests"
echo "  claude-finish    # Create PR"
echo "  claude-help      # Show help"
echo ""
EOF

    chmod +x "$SCRIPT_DIR/claude-workflow-aliases.sh"
    
    # Create helper functions
    cat << 'EOF' > "$SCRIPT_DIR/claude-workflow-functions.sh"
#!/bin/bash
# Claude Development Workflow Helper Functions

claude-workflow-help() {
    echo "🚀 Claude Development Workflow Commands"
    echo "======================================"
    echo ""
    echo "📋 Core Workflow:"
    echo "  claude-setup     Setup Linear workflow states"
    echo "  claude-deps      Validate all dependencies"
    echo "  claude-start     Start development for issue"
    echo "  claude-test      Run comprehensive test suite"
    echo "  claude-finish    Create PR and finish workflow"
    echo ""
    echo "🔧 Utilities:"
    echo "  claude-env       Load Linear environment"
    echo "  claude-status    Show current workflow status"
    echo "  claude-help      Show this help message"
    echo ""
    echo "📝 Git Helpers:"
    echo "  claude-branch    Show current branch"
    echo "  claude-commits   Show commits since main"
    echo "  claude-diff      Show changes since main"
    echo "  claude-push      Push current branch"
    echo ""
    echo "📋 Examples:"
    echo "  claude-start FRA-42     # Start development"
    echo "  claude-test FRA-42      # Run tests"
    echo "  claude-finish FRA-42    # Create PR"
    echo ""
    echo "🔗 Full workflow:"
    echo "  claude-setup && claude-start FRA-42 && claude-test FRA-42 && claude-finish FRA-42"
}

claude-workflow-status() {
    echo "📊 Claude Development Workflow Status"
    echo "====================================="
    echo ""
    
    # Git status
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null)
        echo "🌿 Git Branch: $current_branch"
        
        if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
            local commit_count
            commit_count=$(git rev-list --count main..HEAD 2>/dev/null || git rev-list --count master..HEAD 2>/dev/null || echo "0")
            echo "📝 Commits ahead: $commit_count"
        fi
        
        # Check for uncommitted changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo "⚠️  Uncommitted changes present"
        else
            echo "✅ All changes committed"
        fi
    else
        echo "❌ Not in a git repository"
    fi
    
    echo ""
    
    # Linear environment status
    if [ -n "$LINEAR_API_KEY" ]; then
        echo "✅ Linear API key configured"
        if [ -n "$LINEAR_TEAM_KEY" ]; then
            echo "✅ Linear team: $LINEAR_TEAM_KEY"
        fi
    else
        echo "⚠️  Linear API key not configured"
    fi
    
    echo ""
    
    # Virtual environment status
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "✅ Python virtual environment active: $(basename "$VIRTUAL_ENV")"
    elif [ -d "venv" ]; then
        echo "⚠️  Virtual environment found but not active"
    else
        echo "ℹ️  No Python virtual environment"
    fi
    
    echo ""
    
    # Dependencies status
    local deps_status="Unknown"
    if command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            deps_status="✅ All core dependencies available"
        else
            deps_status="⚠️  GitHub CLI not authenticated"
        fi
    else
        deps_status="❌ Missing core dependencies"
    fi
    echo "$deps_status"
    
    echo ""
    
    # Recent test status
    if [ -f "test-results.xml" ]; then
        echo "✅ Recent test results available"
    fi
    
    if [ -f ".coverage" ]; then
        local coverage
        coverage=$(coverage report 2>/dev/null | tail -1 | awk '{print $4}' 2>/dev/null || echo "Unknown")
        echo "📊 Test coverage: $coverage"
    fi
}

claude-list-issues() {
    if [ -z "$LINEAR_API_KEY" ]; then
        echo "❌ LINEAR_API_KEY not configured"
        echo "Run: claude-setup"
        return 1
    fi
    
    local team_key="${LINEAR_TEAM_KEY:-FRA}"
    local query='{"query": "query { issues(filter: { team: { key: { eq: \"'$team_key'\" } }, state: { type: { in: [\"backlog\", \"unstarted\", \"started\"] } } }, first: 10, orderBy: updatedAt) { nodes { id identifier title state { name } assignee { name } } } }"}'
    
    echo "📋 Available issues in team $team_key:"
    echo ""
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        echo "❌ Failed to fetch issues"
        echo "$response" | jq '.errors'
        return 1
    fi
    
    echo "$response" | jq -r '.data.issues.nodes[] | "  \(.identifier): \(.title) (\(.state.name)) - \(.assignee.name // "Unassigned")"'
    echo ""
}

claude-show-issue() {
    local issue_id="$1"
    
    if [ -z "$issue_id" ]; then
        echo "Usage: claude-issue <ISSUE_ID>"
        echo "Example: claude-issue FRA-42"
        return 1
    fi
    
    if [ -z "$LINEAR_API_KEY" ]; then
        echo "❌ LINEAR_API_KEY not configured"
        echo "Run: claude-setup"
        return 1
    fi
    
    local query='{"query": "query { issue(id: \"'$issue_id'\") { id identifier title description state { name } assignee { name } project { name } url } }"}'
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        echo "❌ Failed to fetch issue"
        echo "$response" | jq '.errors'
        return 1
    fi
    
    local issue_data
    issue_data=$(echo "$response" | jq '.data.issue')
    
    if [ "$issue_data" = "null" ]; then
        echo "❌ Issue not found: $issue_id"
        return 1
    fi
    
    echo "📋 Issue Details:"
    echo "================="
    echo ""
    echo "ID: $(echo "$issue_data" | jq -r '.identifier')"
    echo "Title: $(echo "$issue_data" | jq -r '.title')"
    echo "State: $(echo "$issue_data" | jq -r '.state.name')"
    echo "Assignee: $(echo "$issue_data" | jq -r '.assignee.name // "Unassigned"')"
    echo "Project: $(echo "$issue_data" | jq -r '.project.name // "No Project"')"
    echo "URL: $(echo "$issue_data" | jq -r '.url')"
    echo ""
    
    local description
    description=$(echo "$issue_data" | jq -r '.description // ""')
    if [ -n "$description" ] && [ "$description" != "null" ]; then
        echo "Description:"
        echo "$description" | head -10
        echo ""
    fi
}

# Export functions
export -f claude-workflow-help
export -f claude-workflow-status  
export -f claude-list-issues
export -f claude-show-issue
EOF

    chmod +x "$SCRIPT_DIR/claude-workflow-functions.sh"
    
    print_success "Workflow aliases and functions created"
}

install_to_shell() {
    local shell_rc=""
    
    # Detect shell configuration file
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    else
        # Try to detect from SHELL environment variable
        case "$SHELL" in
            */zsh)
                shell_rc="$HOME/.zshrc"
                ;;
            */bash)
                shell_rc="$HOME/.bashrc"
                ;;
            *)
                shell_rc="$HOME/.profile"
                ;;
        esac
    fi
    
    local alias_line="source \"$SCRIPT_DIR/claude-workflow-aliases.sh\""
    local functions_line="source \"$SCRIPT_DIR/claude-workflow-functions.sh\""
    
    # Check if already installed
    if [ -f "$shell_rc" ] && grep -q "claude-workflow-aliases.sh" "$shell_rc"; then
        print_warning "Aliases already installed in $shell_rc"
        return 0
    fi
    
    # Install to shell configuration
    if [ -f "$shell_rc" ]; then
        echo "" >> "$shell_rc"
        echo "# Claude Development Workflow Aliases" >> "$shell_rc"
        echo "$alias_line" >> "$shell_rc"
        echo "$functions_line" >> "$shell_rc"
        
        print_success "Aliases installed to $shell_rc"
        print_info "Reload your shell or run: source $shell_rc"
    else
        print_warning "Shell configuration file not found: $shell_rc"
        print_info "Manually add these lines to your shell configuration:"
        echo "  $alias_line"
        echo "  $functions_line"
    fi
}

print_usage() {
    echo "Usage: $0 [install|help]"
    echo ""
    echo "Setup Claude development workflow aliases and functions."
    echo ""
    echo "Commands:"
    echo "  install    Install aliases to shell configuration"
    echo "  help       Show this help message"
    echo ""
    echo "Manual usage:"
    echo "  source scripts/claude-workflow-aliases.sh"
    echo "  source scripts/claude-workflow-functions.sh"
}

main() {
    local command="$1"
    
    case "$command" in
        "install")
            setup_aliases
            install_to_shell
            ;;
        "help"|"--help"|"-h")
            print_usage
            ;;
        "")
            setup_aliases
            print_info "Aliases created. Run with 'install' to add to shell configuration."
            ;;
        *)
            print_warning "Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"