#!/bin/bash
# scripts/setup-linear-states.sh
# Script to setup Linear workflow state IDs for the development workflow

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🔧 Linear Workflow States Setup${NC}"
    echo -e "${BLUE}=================================${NC}"
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

check_dependencies() {
    print_info "Checking required dependencies..."
    
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Install with:"
        echo "  macOS: brew install ${missing_deps[*]}"
        echo "  Ubuntu: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All dependencies available"
}

check_linear_api_key() {
    print_info "Checking Linear API key..."
    
    if [ -z "$LINEAR_API_KEY" ]; then
        print_error "LINEAR_API_KEY environment variable not set"
        echo ""
        echo "Please set your Linear API key:"
        echo "  export LINEAR_API_KEY=\"lin_api_xxxxxxxxxxxxx\""
        echo ""
        echo "Get your API key from: https://linear.app/settings/api"
        exit 1
    fi
    
    print_success "Linear API key configured"
}

test_linear_connection() {
    print_info "Testing Linear API connection..."
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"query": "{ viewer { name email } }"}' \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        print_error "Linear API connection failed"
        echo "Response: $(echo "$response" | jq '.errors')"
        exit 1
    fi
    
    local user_name user_email
    user_name=$(echo "$response" | jq -r '.data.viewer.name')
    user_email=$(echo "$response" | jq -r '.data.viewer.email')
    
    print_success "Connected to Linear as: $user_name ($user_email)"
}

get_workflow_states() {
    local team_key="${1:-FRA}"
    
    print_info "Fetching workflow states for team: $team_key"
    
    local response
    response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "query": "query { 
                workflowStates { 
                    nodes { 
                        id name type 
                        team { key } 
                    } 
                } 
            }"
        }' \
        "https://api.linear.app/graphql")
    
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        print_error "Failed to fetch workflow states"
        echo "Response: $(echo "$response" | jq '.errors')"
        exit 1
    fi
    
    # Smart state ID extraction
    local todo_id in_progress_id in_review_id done_id
    
    # Try to find states by type first, then by name
    todo_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and .type == \"backlog\") | .id" | head -1)
    in_progress_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and .type == \"started\") | .id" | head -1)
    done_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and .type == \"completed\") | .id" | head -1)
    
    # Fallback to name-based matching
    if [ "$todo_id" = "null" ] || [ -z "$todo_id" ]; then
        todo_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and (.name | test(\"backlog|todo\"; \"i\"))) | .id" | head -1)
    fi
    
    if [ "$in_progress_id" = "null" ] || [ -z "$in_progress_id" ]; then
        in_progress_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and (.name | test(\"progress|doing|started\"; \"i\"))) | .id" | head -1)
    fi
    
    if [ "$done_id" = "null" ] || [ -z "$done_id" ]; then
        done_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and (.name | test(\"done|completed\"; \"i\"))) | .id" | head -1)
    fi
    
    # Find in_review_id (optional)
    in_review_id=$(echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\" and (.name | test(\"review\"; \"i\"))) | .id" | head -1)
    
    # Validate essential states
    if [ "$todo_id" = "null" ] || [ -z "$todo_id" ] || [ "$in_progress_id" = "null" ] || [ -z "$in_progress_id" ] || [ "$done_id" = "null" ] || [ -z "$done_id" ]; then
        print_error "Could not automatically detect all required workflow states for team: $team_key"
        echo ""
        echo "Available states:"
        echo "$response" | jq -r ".data.workflowStates.nodes[] | select(.team.key == \"$team_key\") | \"  \(.name): \(.id) (\(.type))\""
        echo ""
        echo "Please manually set the state IDs or check team configuration."
        exit 1
    fi
    
    # Generate configuration
    generate_env_config "$team_key" "$todo_id" "$in_progress_id" "$in_review_id" "$done_id"
    
    print_success "Linear workflow states setup completed!"
    echo ""
    echo -e "${GREEN}📋 Configuration Summary:${NC}"
    echo "  Team: $team_key"
    echo "  Todo/Backlog: $todo_id"
    echo "  In Progress: $in_progress_id"
    echo "  In Review: ${in_review_id:-'(not found)'}"
    echo "  Done: $done_id"
    
    return 0
}

generate_env_config() {
    local team_key="$1"
    local todo_id="$2"
    local in_progress_id="$3"
    local in_review_id="$4"
    local done_id="$5"
    
    print_info "Generating environment configuration..."
    
    # Create .env file
    cat > .env << EOF
# Linear Development Workflow Configuration
# Generated on: $(date)

# Linear API Configuration
LINEAR_API_KEY="$LINEAR_API_KEY"

# Team Configuration
LINEAR_TEAM_KEY="$team_key"

# Workflow State IDs
LINEAR_TODO_STATE_ID="$todo_id"
LINEAR_IN_PROGRESS_STATE_ID="$in_progress_id"
LINEAR_IN_REVIEW_STATE_ID="$in_review_id"
LINEAR_DONE_STATE_ID="$done_id"
EOF
    
    # Create shell export file
    cat > scripts/linear-env.sh << EOF
#!/bin/bash
# Linear Development Workflow Environment Variables
# Generated on: $(date)
# Source this file: source scripts/linear-env.sh

export LINEAR_API_KEY="$LINEAR_API_KEY"
export LINEAR_TEAM_KEY="$team_key"
export LINEAR_TODO_STATE_ID="$todo_id"
export LINEAR_IN_PROGRESS_STATE_ID="$in_progress_id"
export LINEAR_IN_REVIEW_STATE_ID="$in_review_id"
export LINEAR_DONE_STATE_ID="$done_id"

echo "✅ Linear environment variables loaded"
EOF
    
    chmod +x scripts/linear-env.sh
    
    print_success "Configuration files created:"
    echo "  📄 .env - Environment file"
    echo "  📄 scripts/linear-env.sh - Shell export script"
}

print_usage_instructions() {
    echo ""
    echo -e "${BLUE}📋 Usage Instructions:${NC}"
    echo ""
    echo "1. Load environment variables:"
    echo "   source scripts/linear-env.sh"
    echo ""
    echo "2. Verify setup:"
    echo "   ./scripts/validate-dependencies.sh"
    echo ""
    echo "3. Start development workflow:"
    echo "   ./scripts/start-development.sh FRA-42"
    echo ""
}

main() {
    print_header
    
    # Create scripts directory if it doesn't exist
    mkdir -p scripts
    
    # Check dependencies
    check_dependencies
    
    # Check Linear API key
    check_linear_api_key
    
    # Test connection
    test_linear_connection
    
    # Get team (use FRA as default, but allow override)
    local team_key="${1:-FRA}"
    
    # Get workflow states and configure
    get_workflow_states "$team_key"
    
    print_usage_instructions
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [TEAM_KEY]"
    echo ""
    echo "Setup Linear workflow state IDs for development workflow automation."
    echo ""
    echo "Arguments:"
    echo "  TEAM_KEY    Linear team key (default: FRA)"
    echo ""
    echo "Environment Variables:"
    echo "  LINEAR_API_KEY    Your Linear API key (required)"
    echo ""
    echo "Examples:"
    echo "  $0              # Use default team (FRA)"
    echo "  $0 MYTEAM       # Use specific team"
    exit 0
fi

# Run main function
main "$@"