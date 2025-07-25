#!/bin/bash

# 🛡️ Disaster Recovery Assessment Script
# Comprehensive system health and recovery assessment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="logs/disaster_recovery_assessment_$(date +%Y%m%d_%H%M%S).log"
ASSESSMENT_REPORT="/tmp/dr_assessment_$(date +%Y%m%d_%H%M%S).json"

# Ensure logs directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "OK"|"PASS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING"|"WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR"|"FAIL"|"CRITICAL")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Initialize assessment report
initialize_report() {
    cat > "$ASSESSMENT_REPORT" << EOF
{
    "assessment_timestamp": "$(date -Iseconds)",
    "system_info": {},
    "connectivity": {},
    "scripts": {},
    "configurations": {},
    "data_integrity": {},
    "recovery_recommendations": [],
    "overall_status": "UNKNOWN"
}
EOF
}

# System Information Assessment
assess_system_info() {
    log "INFO" "Assessing system information..."
    print_status "INFO" "Collecting system information"
    
    local system_status="OK"
    local issues=()
    
    # Operating system info
    local os_info=$(uname -a)
    log "INFO" "OS: $os_info"
    
    # Disk space check
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        system_status="CRITICAL"
        issues+=("Disk usage critical: ${disk_usage}%")
        print_status "CRITICAL" "Disk usage critical: ${disk_usage}%"
    elif [ "$disk_usage" -gt 80 ]; then
        system_status="WARNING"
        issues+=("Disk usage high: ${disk_usage}%")
        print_status "WARNING" "Disk usage high: ${disk_usage}%"
    else
        print_status "OK" "Disk usage normal: ${disk_usage}%"
    fi
    
    # Memory check
    local memory_info=$(free -m | grep '^Mem:')
    local total_mem=$(echo "$memory_info" | awk '{print $2}')
    local used_mem=$(echo "$memory_info" | awk '{print $3}')
    local mem_usage=$((used_mem * 100 / total_mem))
    
    if [ "$mem_usage" -gt 90 ]; then
        system_status="WARNING"
        issues+=("Memory usage high: ${mem_usage}%")
        print_status "WARNING" "Memory usage high: ${mem_usage}%"
    else
        print_status "OK" "Memory usage normal: ${mem_usage}%"
    fi
    
    # Git repository status
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local git_status=$(git status --porcelain)
        if [ -n "$git_status" ]; then
            system_status="WARNING"
            issues+=("Uncommitted changes in git repository")
            print_status "WARNING" "Uncommitted changes detected"
        else
            print_status "OK" "Git repository clean"
        fi
    else
        system_status="CRITICAL"
        issues+=("Not in a git repository")
        print_status "CRITICAL" "Not in a git repository"
    fi
    
    echo "$system_status"
}

# Connectivity Assessment
assess_connectivity() {
    log "INFO" "Assessing external connectivity..."
    print_status "INFO" "Testing external API connectivity"
    
    local connectivity_status="OK"
    local issues=()
    
    # Test Linear API connectivity
    print_status "INFO" "Testing Linear API connectivity..."
    if command -v curl >/dev/null 2>&1; then
        local linear_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://api.linear.app/graphql || echo "000")
        
        if [ "$linear_response" = "200" ] || [ "$linear_response" = "400" ]; then
            print_status "OK" "Linear API accessible (HTTP $linear_response)"
        else
            connectivity_status="CRITICAL"
            issues+=("Linear API unreachable (HTTP $linear_response)")
            print_status "CRITICAL" "Linear API unreachable (HTTP $linear_response)"
        fi
    else
        connectivity_status="WARNING"
        issues+=("curl not available for connectivity testing")
        print_status "WARNING" "curl not available for connectivity testing"
    fi
    
    # Test GitHub API connectivity
    print_status "INFO" "Testing GitHub API connectivity..."
    if command -v curl >/dev/null 2>&1; then
        local github_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://api.github.com || echo "000")
        
        if [ "$github_response" = "200" ]; then
            print_status "OK" "GitHub API accessible (HTTP $github_response)"
        else
            connectivity_status="CRITICAL"
            issues+=("GitHub API unreachable (HTTP $github_response)")
            print_status "CRITICAL" "GitHub API unreachable (HTTP $github_response)"
        fi
    fi
    
    # Test GitHub CLI authentication
    print_status "INFO" "Testing GitHub CLI authentication..."
    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            print_status "OK" "GitHub CLI authenticated"
        else
            connectivity_status="WARNING"
            issues+=("GitHub CLI not authenticated")
            print_status "WARNING" "GitHub CLI not authenticated"
        fi
    else
        connectivity_status="WARNING"
        issues+=("GitHub CLI not installed")
        print_status "WARNING" "GitHub CLI not installed"
    fi
    
    echo "$connectivity_status"
}

# Scripts Assessment
assess_scripts() {
    log "INFO" "Assessing script integrity..."
    print_status "INFO" "Checking script files and permissions"
    
    local scripts_status="OK"
    local issues=()
    
    # Critical scripts to check
    local critical_scripts=(
        "scripts/start-development.sh"
        "scripts/test-and-validate.sh"
        "scripts/finish-development.sh"
        "scripts/setup-linear-states.sh"
        "scripts/validate-dependencies.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_status "OK" "Script executable: $(basename $script)"
            else
                scripts_status="WARNING"
                issues+=("Script not executable: $script")
                print_status "WARNING" "Script not executable: $(basename $script)"
            fi
        else
            scripts_status="CRITICAL"
            issues+=("Missing critical script: $script")
            print_status "CRITICAL" "Missing critical script: $(basename $script)"
        fi
    done
    
    # Check for syntax errors in shell scripts
    print_status "INFO" "Checking script syntax..."
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                log "DEBUG" "Syntax OK: $script"
            else
                scripts_status="CRITICAL"
                issues+=("Syntax error in script: $script")
                print_status "CRITICAL" "Syntax error in: $(basename $script)"
            fi
        fi
    done
    
    echo "$scripts_status"
}

# Configuration Assessment
assess_configurations() {
    log "INFO" "Assessing system configurations..."
    print_status "INFO" "Checking configuration files and environment"
    
    local config_status="OK"
    local issues=()
    
    # Check environment variables
    print_status "INFO" "Checking environment variables..."
    local required_vars=("LINEAR_API_KEY")
    
    for var in "${required_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            print_status "OK" "Environment variable set: $var"
        else
            config_status="CRITICAL"
            issues+=("Missing environment variable: $var")
            print_status "CRITICAL" "Missing environment variable: $var"
        fi
    done
    
    # Check configuration files
    local config_files=(
        ".github/workflows/test.yml"
        ".github/workflows/linear-sync.yml"
        "pytest.ini"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$config" ]; then
            print_status "OK" "Configuration exists: $(basename $config)"
        else
            config_status="WARNING"
            issues+=("Missing configuration file: $config")
            print_status "WARNING" "Missing configuration: $(basename $config)"
        fi
    done
    
    # Check Linear environment file
    if [ -f "scripts/linear-env.sh" ]; then
        print_status "OK" "Linear environment file exists"
        
        # Source and validate Linear environment
        if source scripts/linear-env.sh 2>/dev/null; then
            if [ -n "${LINEAR_IN_PROGRESS_STATE_ID:-}" ]; then
                print_status "OK" "Linear state IDs configured"
            else
                config_status="WARNING"
                issues+=("Linear state IDs not configured")
                print_status "WARNING" "Linear state IDs not configured"
            fi
        else
            config_status="CRITICAL"
            issues+=("Error sourcing Linear environment file")
            print_status "CRITICAL" "Error sourcing Linear environment file"
        fi
    else
        config_status="CRITICAL"
        issues+=("Linear environment file missing")
        print_status "CRITICAL" "Linear environment file missing"
    fi
    
    echo "$config_status"
}

# Data Integrity Assessment
assess_data_integrity() {
    log "INFO" "Assessing data integrity..."
    print_status "INFO" "Checking data consistency and integrity"
    
    local integrity_status="OK"
    local issues=()
    
    # Check git repository integrity
    print_status "INFO" "Checking git repository integrity..."
    if git fsck --full --strict >/dev/null 2>&1; then
        print_status "OK" "Git repository integrity verified"
    else
        integrity_status="CRITICAL"
        issues+=("Git repository corruption detected")
        print_status "CRITICAL" "Git repository corruption detected"
    fi
    
    # Check for required directories
    local required_dirs=(
        "scripts"
        ".github/workflows"
        "docs"
        "tests"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_status "OK" "Directory exists: $dir"
        else
            integrity_status="CRITICAL"
            issues+=("Missing required directory: $dir")
            print_status "CRITICAL" "Missing directory: $dir"
        fi
    done
    
    # Check log directory and permissions
    if [ -d "logs" ]; then
        if [ -w "logs" ]; then
            print_status "OK" "Logs directory writable"
        else
            integrity_status="WARNING"
            issues+=("Logs directory not writable")
            print_status "WARNING" "Logs directory not writable"
        fi
    else
        # Create logs directory
        mkdir -p logs
        print_status "OK" "Logs directory created"
    fi
    
    echo "$integrity_status"
}

# Generate Recovery Recommendations
generate_recommendations() {
    local overall_status="$1"
    
    log "INFO" "Generating recovery recommendations..."
    print_status "INFO" "Analyzing assessment results and generating recommendations"
    
    local recommendations=()
    
    case "$overall_status" in
        "CRITICAL")
            recommendations+=(
                "IMMEDIATE ACTION REQUIRED: System has critical issues"
                "Execute emergency recovery procedures"
                "Restore from latest backup if necessary"
                "Contact emergency response team"
                "Review disaster recovery documentation"
            )
            ;;
        "WARNING")
            recommendations+=(
                "Address warning conditions before they become critical"
                "Review recent changes and configurations"
                "Validate backup integrity"
                "Monitor system closely"
                "Consider preventive maintenance"
            )
            ;;
        "OK")
            recommendations+=(
                "System appears healthy"
                "Continue regular monitoring"
                "Verify backup schedules are running"
                "Update documentation if needed"
                "Schedule regular assessments"
            )
            ;;
    esac
    
    # Print recommendations
    echo ""
    print_status "INFO" "Recovery Recommendations:"
    for rec in "${recommendations[@]}"; do
        echo "  • $rec"
    done
    
    return 0
}

# Main assessment function
run_assessment() {
    local start_time=$(date +%s)
    
    echo "🛡️ Disaster Recovery Assessment"
    echo "==============================="
    echo "Started at: $(date)"
    echo ""
    
    # Initialize report
    initialize_report
    
    # Run assessments
    local system_result=$(assess_system_info)
    echo ""
    
    local connectivity_result=$(assess_connectivity)
    echo ""
    
    local scripts_result=$(assess_scripts)
    echo ""
    
    local config_result=$(assess_configurations)
    echo ""
    
    local integrity_result=$(assess_data_integrity)
    echo ""
    
    # Determine overall status
    local overall_status="OK"
    
    if [[ "$system_result" == "CRITICAL" ]] || [[ "$connectivity_result" == "CRITICAL" ]] || \
       [[ "$scripts_result" == "CRITICAL" ]] || [[ "$config_result" == "CRITICAL" ]] || \
       [[ "$integrity_result" == "CRITICAL" ]]; then
        overall_status="CRITICAL"
    elif [[ "$system_result" == "WARNING" ]] || [[ "$connectivity_result" == "WARNING" ]] || \
         [[ "$scripts_result" == "WARNING" ]] || [[ "$config_result" == "WARNING" ]] || \
         [[ "$integrity_result" == "WARNING" ]]; then
        overall_status="WARNING"
    fi
    
    # Generate recommendations
    generate_recommendations "$overall_status"
    
    # Final summary
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "==============================="
    echo "Assessment Summary:"
    echo "  System Info: $system_result"
    echo "  Connectivity: $connectivity_result"
    echo "  Scripts: $scripts_result"
    echo "  Configuration: $config_result"
    echo "  Data Integrity: $integrity_result"
    echo ""
    print_status "$overall_status" "Overall Status: $overall_status"
    echo ""
    echo "Assessment completed in ${duration}s"
    echo "Report available at: $ASSESSMENT_REPORT"
    echo "Logs available at: $LOG_FILE"
    
    # Exit with appropriate code
    case "$overall_status" in
        "OK") exit 0 ;;
        "WARNING") exit 1 ;;
        "CRITICAL") exit 2 ;;
    esac
}

# Help function
show_help() {
    echo "🛡️ Disaster Recovery Assessment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --quick        Run quick assessment (basic checks only)"
    echo "  --verbose      Enable verbose logging"
    echo ""
    echo "This script performs a comprehensive assessment of the development"
    echo "workflow system to identify potential issues and provide recovery"
    echo "recommendations."
    echo ""
    echo "Exit codes:"
    echo "  0 - System healthy (OK)"
    echo "  1 - Warnings detected"
    echo "  2 - Critical issues found"
}

# Parse command line arguments
QUICK_MODE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set verbose logging
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Run the assessment
if [ "$QUICK_MODE" = true ]; then
    echo "Running quick assessment mode..."
    # In quick mode, only run critical assessments
    assess_system_info >/dev/null
    assess_connectivity >/dev/null
    echo "Quick assessment completed - check logs for details"
else
    run_assessment
fi
