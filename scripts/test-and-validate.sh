#!/bin/bash
# scripts/test-and-validate.sh (Enhanced Version)
# Comprehensive testing and validation with Linear integration

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
COVERAGE_THRESHOLD=90
TESTS_PASSED=0
TESTS_FAILED=0
QUALITY_SCORE=0

# Cleanup function
cleanup() {
    echo ""
    echo -e "${BLUE}🧹 Cleaning up test artifacts...${NC}"
    
    # Clean temporary test files
    rm -f .coverage.tmp test-results.tmp bandit-report.tmp
    rm -f pylint-report.tmp mypy-report.tmp
    
    # Clean __pycache__ directories
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Helper functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}🧪 Comprehensive Testing & Validation Suite${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

print_subsection() {
    echo ""
    echo -e "${CYAN}  📊 $1${NC}"
    echo "  $(printf '%.0s-' {1..40})"
}

validate_environment() {
    print_step "Validating environment..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    print_success "Git repository validated (branch: $CURRENT_BRANCH)"
    
    # Load Linear environment if available
    if [ -f "$PROJECT_ROOT/scripts/linear-env.sh" ]; then
        source "$PROJECT_ROOT/scripts/linear-env.sh" >/dev/null 2>&1
        print_success "Linear environment loaded"
    elif [ -n "$LINEAR_API_KEY" ]; then
        print_success "Linear API key found in environment"
    else
        print_warning "Linear environment not configured (some features will be skipped)"
    fi
    
    # Check for Virtual Environment
    if [ -n "$VIRTUAL_ENV" ]; then
        print_success "Python virtual environment active: $(basename "$VIRTUAL_ENV")"
    elif [ -d "$PROJECT_ROOT/venv" ]; then
        print_warning "Virtual environment found but not activated"
        echo "  Activate with: source venv/bin/activate"
    else
        print_info "No Python virtual environment detected"
    fi
}

check_code_formatting() {
    print_step "Code Quality Checks"
    
    print_subsection "Code Formatting (Black)"
    
    if command -v black >/dev/null 2>&1; then
        local src_dirs=()
        [ -d "src" ] && src_dirs+=("src")
        [ -d "tests" ] && src_dirs+=("tests")
        [ -d "scripts" ] && src_dirs+=("scripts")
        
        if [ ${#src_dirs[@]} -gt 0 ]; then
            if black --check --diff "${src_dirs[@]}" 2>/dev/null; then
                print_success "Code formatting is correct"
            else
                print_error "Code formatting issues found"
                echo ""
                echo "  Fix with: black ${src_dirs[*]}"
                echo ""
                return 1
            fi
        else
            print_info "No Python source directories found"
        fi
    else
        print_warning "Black not installed (pip install black)"
    fi
    
    print_subsection "Import Sorting (isort)"
    
    if command -v isort >/dev/null 2>&1; then
        local src_dirs=()
        [ -d "src" ] && src_dirs+=("src")
        [ -d "tests" ] && src_dirs+=("tests")
        
        if [ ${#src_dirs[@]} -gt 0 ]; then
            if isort --check-only --diff "${src_dirs[@]}" 2>/dev/null; then
                print_success "Import sorting is correct"
            else
                print_error "Import sorting issues found"
                echo ""
                echo "  Fix with: isort ${src_dirs[*]}"
                echo ""
                return 1
            fi
        else
            print_info "No Python source directories found"
        fi
    else
        print_warning "isort not installed (pip install isort)"
    fi
    
    return 0
}

run_linting() {
    print_subsection "Linting (flake8)"
    
    if command -v flake8 >/dev/null 2>&1; then
        local src_dirs=()
        [ -d "src" ] && src_dirs+=("src")
        [ -d "tests" ] && src_dirs+=("tests")
        
        if [ ${#src_dirs[@]} -gt 0 ]; then
            if flake8 "${src_dirs[@]}" --max-line-length=88 --extend-ignore=E203,W503 2>/dev/null; then
                print_success "Linting passed"
            else
                print_error "Linting errors found"
                echo ""
                echo "  Review and fix the linting errors above"
                echo ""
                return 1
            fi
        else
            print_info "No Python source directories found"
        fi
    else
        print_warning "flake8 not installed (pip install flake8)"
    fi
    
    return 0
}

run_security_checks() {
    print_subsection "Security Scanning (Bandit)"
    
    if command -v bandit >/dev/null 2>&1; then
        if [ -d "src" ]; then
            local bandit_output
            if bandit_output=$(bandit -r src/ -f json -o bandit-report.tmp 2>&1); then
                print_success "Security scan passed"
                
                # Parse results
                if [ -f "bandit-report.tmp" ]; then
                    local issue_count
                    issue_count=$(jq '.results | length' bandit-report.tmp 2>/dev/null || echo "0")
                    if [ "$issue_count" -eq 0 ]; then
                        print_info "No security issues found"
                    else
                        print_warning "$issue_count potential security issue(s) found"
                        echo "  Review: bandit-report.tmp"
                    fi
                fi
            else
                print_warning "Security scan completed with warnings"
                echo "  Output: $bandit_output"
            fi
        else
            print_info "No src/ directory found for security scanning"
        fi
    else
        print_warning "Bandit not installed (pip install bandit)"
    fi
}

run_tests() {
    print_step "Running Test Suite"
    
    if command -v pytest >/dev/null 2>&1; then
        if [ -d "tests" ] || find . -name "test_*.py" -o -name "*_test.py" | grep -q .; then
            print_subsection "Unit Tests (pytest)"
            
            local pytest_args=(
                "--cov=src"
                "--cov-report=html:htmlcov"
                "--cov-report=term-missing"
                "--cov-report=xml"
                "--junit-xml=test-results.xml"
                "--tb=short"
                "-v"
            )
            
            # Add coverage threshold if configured
            if [ $COVERAGE_THRESHOLD -gt 0 ]; then
                pytest_args+=("--cov-fail-under=$COVERAGE_THRESHOLD")
            fi
            
            local test_dirs=()
            [ -d "tests" ] && test_dirs+=("tests/")
            
            # Find test files if no tests directory
            if [ ${#test_dirs[@]} -eq 0 ]; then
                while IFS= read -r -d '' file; do
                    test_dirs+=("$file")
                done < <(find . -name "test_*.py" -o -name "*_test.py" -print0 2>/dev/null)
            fi
            
            if [ ${#test_dirs[@]} -gt 0 ]; then
                if pytest "${pytest_args[@]}" "${test_dirs[@]}"; then
                    print_success "All tests passed"
                    check_test_coverage
                else
                    print_error "Tests failed"
                    echo ""
                    echo "  Debug with: pytest ${test_dirs[*]} -v --tb=long"
                    echo ""
                    return 1
                fi
            else
                print_info "No test files found"
            fi
        else
            print_info "No tests found (create tests/ directory or test_*.py files)"
        fi
    else
        print_warning "pytest not installed (pip install pytest pytest-cov)"
    fi
    
    return 0
}

check_test_coverage() {
    print_subsection "Test Coverage Analysis"
    
    if command -v coverage >/dev/null 2>&1 && [ -f ".coverage" ]; then
        local coverage_report
        coverage_report=$(coverage report --show-missing 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            local coverage_percentage
            coverage_percentage=$(echo "$coverage_report" | tail -1 | awk '{print $4}' | sed 's/%//' 2>/dev/null || echo "0")
            
            print_info "Coverage Report:"
            echo "$coverage_report" | tail -5
            echo ""
            
            if [ "$coverage_percentage" -ge $COVERAGE_THRESHOLD ]; then
                print_success "Coverage ($coverage_percentage%) meets threshold ($COVERAGE_THRESHOLD%)"
            else
                print_warning "Coverage ($coverage_percentage%) below threshold ($COVERAGE_THRESHOLD%)"
                echo "  Add more tests to improve coverage"
                echo "  View detailed report: open htmlcov/index.html"
            fi
        else
            print_warning "Could not generate coverage report"
        fi
    else
        print_info "No coverage data available"
    fi
}

update_linear_issue_status() {
    if [ -n "$LINEAR_API_KEY" ] && [ -n "$LINEAR_ISSUE_ID" ] && [ -n "$LINEAR_IN_REVIEW_STATE_ID" ]; then
        print_step "Updating Linear issue status..."
        
        local mutation
        mutation=$(cat << 'EOF'
{
  "query": "mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) { 
    issueUpdate(id: $id, input: $input) { 
      success
    } 
  }",
  "variables": {
    "id": "%s",
    "input": {
      "stateId": "%s"
    }
  }
}
EOF
)
        
        mutation=$(printf "$mutation" "$LINEAR_ISSUE_ID" "$LINEAR_IN_REVIEW_STATE_ID")
        
        local response
        response=$(curl -s -H "Authorization: $LINEAR_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$mutation" \
            "https://api.linear.app/graphql")
        
        if echo "$response" | jq -e '.data.issueUpdate.success' >/dev/null 2>&1; then
            print_success "Linear issue updated to 'In Review'"
        else
            print_warning "Could not update Linear issue status"
        fi
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}📊 Testing & Validation Summary${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    local quality_score=$((TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED)))
    
    echo ""
    echo -e "${PURPLE}📈 Results:${NC}"
    echo "  • Tests Passed: $TESTS_PASSED"
    echo "  • Tests Failed: $TESTS_FAILED"
    echo "  • Quality Score: $quality_score%"
    echo "  • Branch: $CURRENT_BRANCH"
    
    if [ -n "$LINEAR_ISSUE_ID" ]; then
        echo "  • Linear Issue: $LINEAR_ISSUE_ID"
    fi
    
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        if [ $quality_score -ge 90 ]; then
            print_success "🎉 All tests passed with excellent quality score!"
        elif [ $quality_score -ge 75 ]; then
            print_success "✅ All tests passed with good quality score"
        else
            print_warning "⚠️  Tests passed but quality score could be improved"
        fi
        
        echo ""
        echo -e "${GREEN}📋 Next Steps:${NC}"
        echo "  1. Review test coverage report: open htmlcov/index.html"
        echo "  2. Commit your changes: git add . && git commit"
        echo "  3. Create PR: ./scripts/finish-development.sh ${LINEAR_ISSUE_ID:-'ISSUE_ID'}"
        
    else
        print_error "❌ Tests failed - fix issues before proceeding"
        echo ""
        echo -e "${RED}📋 Troubleshooting:${NC}"
        echo "  • Check test output above for specific failures"
        echo "  • Run specific test: pytest path/to/test_file.py -v"
        echo "  • Debug with: pytest tests/ --pdb"
        echo "  • Check code formatting: black src/ tests/"
        echo "  • Fix linting issues: flake8 src/ tests/"
        
        exit 1
    fi
}

# Main function
main() {
    print_header
    
    # Parse arguments
    LINEAR_ISSUE_ID="$1"
    
    if [ -n "$LINEAR_ISSUE_ID" ]; then
        print_info "Running tests for Linear issue: $LINEAR_ISSUE_ID"
    else
        print_info "Running comprehensive test suite"
    fi
    
    # Execute validation and testing pipeline
    validate_environment
    
    if ! check_code_formatting; then
        print_error "Code formatting checks failed"
        exit 1
    fi
    
    if ! run_linting; then
        print_error "Linting checks failed"
        exit 1
    fi
    
    run_security_checks
    
    if ! run_tests; then
        print_error "Unit tests failed"
        exit 1
    fi
    
    # Update Linear issue status if all tests passed
    if [ $TESTS_FAILED -eq 0 ] && [ -n "$LINEAR_ISSUE_ID" ]; then
        update_linear_issue_status
    fi
    
    # Print final summary
    print_summary
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Enhanced Testing & Validation Suite"
    echo ""
    echo "Usage: $0 [LINEAR_ISSUE_ID] [OPTIONS]"
    echo ""
    echo "Comprehensive testing pipeline including:"
    echo "  • Code formatting validation (Black, isort)"
    echo "  • Linting and code quality (flake8, mypy)"
    echo "  • Security scanning (Bandit)"
    echo "  • Unit and integration testing (pytest)"
    echo "  • Coverage analysis and reporting"
    echo "  • Linear issue status updates"
    echo ""
    echo "Arguments:"
    echo "  LINEAR_ISSUE_ID    Optional Linear issue ID for status updates"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 FRA-42                    # Run tests for specific issue"
    exit 0
fi

# Run main function
main "$@"