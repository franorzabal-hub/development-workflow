#!/bin/bash

# 🔄 Recovery Procedures Script
# Automated recovery procedures for Development Workflow system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="logs/recovery_$(date +%Y%m%d_%H%M%S).log"
BACKUP_ROOT="${BACKUP_ROOT:-/tmp/backups}"
RECOVERY_ROOT="${RECOVERY_ROOT:-/tmp/recovery}"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$RECOVERY_ROOT"

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
        "OK"|"SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING"|"WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR"|"FAIL")
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

# Decrypt backup file if encrypted
decrypt_backup() {
    local encrypted_file="$1"
    local decrypted_file="${1%.enc}"
    
    if [[ "$encrypted_file" == *.enc ]]; then
        log "INFO" "Decrypting backup file: $(basename "$encrypted_file")"
        
        if [ -z "${BACKUP_ENCRYPTION_KEY:-}" ]; then
            print_status "ERROR" "BACKUP_ENCRYPTION_KEY not set for decryption"
            return 1
        fi
        
        if command -v openssl >/dev/null 2>&1; then
            if openssl enc -aes-256-cbc -d -pbkdf2 -in "$encrypted_file" -out "$decrypted_file" -k "$BACKUP_ENCRYPTION_KEY"; then
                print_status "SUCCESS" "Backup decrypted successfully"
                echo "$decrypted_file"
            else
                print_status "ERROR" "Failed to decrypt backup"
                return 1
            fi
        else
            print_status "ERROR" "OpenSSL not available for decryption"
            return 1
        fi
    else
        echo "$encrypted_file"
    fi
}

# Extract backup archive
extract_backup() {
    local backup_file="$1"
    local extract_dir="$2"
    
    log "INFO" "Extracting backup: $(basename "$backup_file")"
    print_status "INFO" "Extracting backup to: $extract_dir"
    
    mkdir -p "$extract_dir"
    
    if tar -xzf "$backup_file" -C "$extract_dir"; then
        print_status "SUCCESS" "Backup extracted successfully"
        return 0
    else
        print_status "ERROR" "Failed to extract backup"
        return 1
    fi
}

# Find latest backup
find_latest_backup() {
    local backup_type="$1"
    local pattern="${backup_type}_backup_*.tar.gz*"
    
    log "INFO" "Searching for latest $backup_type backup..."
    
    local latest_backup
    latest_backup=$(find "$BACKUP_ROOT" -name "$pattern" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        print_status "SUCCESS" "Found latest backup: $(basename "$latest_backup")"
        echo "$latest_backup"
    else
        print_status "ERROR" "No $backup_type backup found in $BACKUP_ROOT"
        return 1
    fi
}

# List available backups
list_backups() {
    local backup_type="$1"
    local pattern="${backup_type}_backup_*.tar.gz*"
    
    print_status "INFO" "Available $backup_type backups:"
    
    find "$BACKUP_ROOT" -name "$pattern" -type f -printf '%TY-%Tm-%Td %TH:%TM  %p\n' | sort -r | while read -r line; do
        echo "  $line"
    done
}

# Pre-recovery backup
create_pre_recovery_backup() {
    log "INFO" "Creating pre-recovery backup..."
    print_status "INFO" "Backing up current state before recovery"
    
    local pre_recovery_dir="$RECOVERY_ROOT/pre_recovery_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$pre_recovery_dir"
    
    # Backup current critical files
    local critical_items=(
        ".env*"
        "scripts/linear-env.sh"
        "scripts/"
        ".github/"
        "docs/"
    )
    
    for item in "${critical_items[@]}"; do
        if ls $item >/dev/null 2>&1; then
            cp -r $item "$pre_recovery_dir/" 2>/dev/null || true
            log "INFO" "Backed up: $item"
        fi
    done
    
    # Create git state backup
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git rev-parse HEAD > "$pre_recovery_dir/git_commit.txt"
        git status --porcelain > "$pre_recovery_dir/git_status.txt"
        git stash push -m "Pre-recovery stash $(date)" >/dev/null 2>&1 || true
        log "INFO" "Git state backed up"
    fi
    
    print_status "SUCCESS" "Pre-recovery backup created: $pre_recovery_dir"
    echo "$pre_recovery_dir"
}

# Level 1: Configuration Recovery
level1_config_recovery() {
    local backup_source="$1"
    
    log "INFO" "Starting Level 1: Configuration Recovery"
    print_status "INFO" "Recovering system configurations"
    
    local config_dir="$backup_source/configurations"
    
    if [ ! -d "$config_dir" ]; then
        print_status "ERROR" "Configuration backup not found in $backup_source"
        return 1
    fi
    
    # Restore environment files
    print_status "INFO" "Restoring environment files..."
    for env_file in "$config_dir"/.env*; do
        if [ -f "$env_file" ]; then
            cp "$env_file" .
            log "INFO" "Restored: $(basename "$env_file")"
        fi
    done
    
    # Restore Linear environment
    if [ -f "$config_dir/linear-env.sh" ]; then
        mkdir -p scripts
        cp "$config_dir/linear-env.sh" scripts/
        log "INFO" "Restored Linear environment"
    fi
    
    # Restore package files
    for pkg_file in "$config_dir"/requirements*.txt "$config_dir"/package.json "$config_dir"/pyproject.toml; do
        if [ -f "$pkg_file" ]; then
            cp "$pkg_file" .
            log "INFO" "Restored: $(basename "$pkg_file")"
        fi
    done
    
    # Restore configuration files
    for config in "$config_dir"/pytest.ini "$config_dir"/tox.ini "$config_dir"/.pre-commit-config.yaml; do
        if [ -f "$config" ]; then
            cp "$config" .
            log "INFO" "Restored: $(basename "$config")"
        fi
    done
    
    print_status "SUCCESS" "Configuration recovery completed"
}

# Level 2: Scripts Recovery
level2_scripts_recovery() {
    local backup_source="$1"
    
    log "INFO" "Starting Level 2: Scripts Recovery"
    print_status "INFO" "Recovering executable scripts"
    
    local scripts_dir="$backup_source/scripts"
    
    if [ ! -d "$scripts_dir" ]; then
        print_status "ERROR" "Scripts backup not found in $backup_source"
        return 1
    fi
    
    # Extract scripts archive if present
    if [ -f "$scripts_dir"/scripts_*.tar.gz ]; then
        print_status "INFO" "Extracting scripts archive..."
        tar -xzf "$scripts_dir"/scripts_*.tar.gz
        log "INFO" "Scripts archive extracted"
    fi
    
    # Restore individual critical scripts
    local critical_scripts=(
        "start-development.sh"
        "test-and-validate.sh"
        "finish-development.sh"
        "setup-linear-states.sh"
        "validate-dependencies.sh"
    )
    
    mkdir -p scripts
    for script in "${critical_scripts[@]}"; do
        if [ -f "$scripts_dir/$script" ]; then
            cp "$scripts_dir/$script" scripts/
            chmod +x "scripts/$script"
            log "INFO" "Restored script: $script"
        fi
    done
    
    print_status "SUCCESS" "Scripts recovery completed"
}

# Level 3: GitHub Configuration Recovery
level3_github_recovery() {
    local backup_source="$1"
    
    log "INFO" "Starting Level 3: GitHub Configuration Recovery"
    print_status "INFO" "Recovering GitHub workflows and templates"
    
    local github_dir="$backup_source/github"
    
    if [ ! -d "$github_dir" ]; then
        print_status "ERROR" "GitHub backup not found in $backup_source"
        return 1
    fi
    
    # Extract GitHub config archive if present
    if [ -f "$github_dir"/github_config_*.tar.gz ]; then
        print_status "INFO" "Extracting GitHub configuration archive..."
        tar -xzf "$github_dir"/github_config_*.tar.gz
        log "INFO" "GitHub configuration extracted"
    fi
    
    # Restore workflows directory
    if [ -d "$github_dir/workflows" ]; then
        mkdir -p .github
        cp -r "$github_dir/workflows" .github/
        log "INFO" "Restored GitHub workflows"
    fi
    
    # Restore issue templates
    if [ -d "$github_dir/ISSUE_TEMPLATE" ]; then
        mkdir -p .github
        cp -r "$github_dir/ISSUE_TEMPLATE" .github/
        log "INFO" "Restored issue templates"
    fi
    
    # Restore PR template
    if [ -f "$github_dir/PULL_REQUEST_TEMPLATE.md" ]; then
        mkdir -p .github
        cp "$github_dir/PULL_REQUEST_TEMPLATE.md" .github/
        log "INFO" "Restored PR template"
    fi
    
    print_status "SUCCESS" "GitHub configuration recovery completed"
}

# Level 4: Documentation Recovery
level4_documentation_recovery() {
    local backup_source="$1"
    
    log "INFO" "Starting Level 4: Documentation Recovery"
    print_status "INFO" "Recovering project documentation"
    
    local docs_dir="$backup_source/documentation"
    
    if [ ! -d "$docs_dir" ]; then
        print_status "ERROR" "Documentation backup not found in $backup_source"
        return 1
    fi
    
    # Restore core documentation files
    for doc in README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md LICENSE; do
        if [ -f "$docs_dir/$doc" ]; then
            cp "$docs_dir/$doc" .
            log "INFO" "Restored: $doc"
        fi
    done
    
    # Extract documentation archive if present
    if [ -f "$docs_dir"/docs_*.tar.gz ]; then
        print_status "INFO" "Extracting documentation archive..."
        tar -xzf "$docs_dir"/docs_*.tar.gz
        log "INFO" "Documentation archive extracted"
    fi
    
    # Extract training archive if present
    if [ -f "$docs_dir"/training_*.tar.gz ]; then
        print_status "INFO" "Extracting training archive..."
        tar -xzf "$docs_dir"/training_*.tar.gz
        log "INFO" "Training archive extracted"
    fi
    
    print_status "SUCCESS" "Documentation recovery completed"
}

# Level 5: Git Repository Recovery
level5_git_recovery() {
    local backup_source="$1"
    
    log "INFO" "Starting Level 5: Git Repository Recovery"
    print_status "INFO" "Recovering git repository state"
    
    local state_dir="$backup_source/system_state"
    
    if [ ! -d "$state_dir" ]; then
        print_status "ERROR" "System state backup not found in $backup_source"
        return 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        # Initialize new git repository if git bundle exists
        if [ -f "$state_dir"/repository_*.bundle ]; then
            print_status "INFO" "Initializing git repository from bundle..."
            git clone "$state_dir"/repository_*.bundle . --quiet
            log "INFO" "Git repository restored from bundle"
        else
            print_status "INFO" "Initializing new git repository..."
            git init --quiet
            log "INFO" "New git repository initialized"
        fi
    fi
    
    # Restore git remotes if available
    if [ -f "$state_dir/git_remotes.txt" ]; then
        print_status "INFO" "Restoring git remotes..."
        while IFS=$'\t' read -r name url; do
            if [ -n "$name" ] && [ -n "$url" ]; then
                git remote add "$name" "$url" 2>/dev/null || git remote set-url "$name" "$url"
                log "INFO" "Restored remote: $name"
            fi
        done < "$state_dir/git_remotes.txt"
    fi
    
    print_status "SUCCESS" "Git repository recovery completed"
}

# Level 6: Tests Recovery
level6_tests_recovery() {
    local backup_source="$1"
    
    log "INFO" "Starting Level 6: Tests Recovery"
    print_status "INFO" "Recovering test suites"
    
    local tests_dir="$backup_source/tests"
    
    if [ ! -d "$tests_dir" ]; then
        print_status "WARNING" "Tests backup not found in $backup_source"
        return 0
    fi
    
    # Extract tests archive if present
    if [ -f "$tests_dir"/tests_*.tar.gz ]; then
        print_status "INFO" "Extracting tests archive..."
        tar -xzf "$tests_dir"/tests_*.tar.gz
        log "INFO" "Tests archive extracted"
    fi
    
    print_status "SUCCESS" "Tests recovery completed"
}

# Validate recovery
validate_recovery() {
    log "INFO" "Validating recovery results..."
    print_status "INFO" "Validating system state after recovery"
    
    local validation_errors=0
    
    # Check critical scripts
    local critical_scripts=(
        "scripts/start-development.sh"
        "scripts/test-and-validate.sh"
        "scripts/finish-development.sh"
        "scripts/setup-linear-states.sh"
        "scripts/validate-dependencies.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            print_status "OK" "Script OK: $(basename "$script")"
        else
            print_status "ERROR" "Script missing or not executable: $(basename "$script")"
            ((validation_errors++))
        fi
    done
    
    # Check configuration files
    local config_files=(
        ".github/workflows/test.yml"
        "pytest.ini"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$config" ]; then
            print_status "OK" "Configuration OK: $(basename "$config")"
        else
            print_status "WARNING" "Configuration missing: $(basename "$config")"
        fi
    done
    
    # Check git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        print_status "OK" "Git repository OK"
    else
        print_status "ERROR" "Git repository not found"
        ((validation_errors++))
    fi
    
    # Check environment
    if [ -f "scripts/linear-env.sh" ]; then
        print_status "OK" "Linear environment file OK"
    else
        print_status "WARNING" "Linear environment file missing"
    fi
    
    # Run dependency validation if available
    if [ -f "scripts/validate-dependencies.sh" ]; then
        print_status "INFO" "Running dependency validation..."
        if ./scripts/validate-dependencies.sh --quick >/dev/null 2>&1; then
            print_status "OK" "Dependencies validation passed"
        else
            print_status "WARNING" "Dependencies validation failed"
        fi
    fi
    
    if [ $validation_errors -eq 0 ]; then
        print_status "SUCCESS" "Recovery validation passed"
        return 0
    else
        print_status "ERROR" "Recovery validation failed ($validation_errors errors)"
        return 1
    fi
}

# Quick recovery (configurations only)
quick_recovery() {
    local backup_file="$1"
    
    log "INFO" "Starting quick recovery from: $(basename "$backup_file")"
    print_status "INFO" "Performing quick configuration recovery"
    
    # Create pre-recovery backup
    local pre_backup
    pre_backup=$(create_pre_recovery_backup)
    
    # Decrypt and extract backup
    local decrypted_file
    decrypted_file=$(decrypt_backup "$backup_file")
    
    local extract_dir="$RECOVERY_ROOT/quick_recovery_$(date +%Y%m%d_%H%M%S)"
    extract_backup "$decrypted_file" "$extract_dir"
    
    # Find the actual backup directory (should be only one)
    local backup_source
    backup_source=$(find "$extract_dir" -maxdepth 1 -type d ! -path "$extract_dir" | head -1)
    
    if [ -z "$backup_source" ]; then
        print_status "ERROR" "Could not find backup data in extracted archive"
        return 1
    fi
    
    # Perform level 1 recovery only
    level1_config_recovery "$backup_source"
    
    # Validate
    if validate_recovery; then
        print_status "SUCCESS" "Quick recovery completed successfully"
        log "INFO" "Pre-recovery backup available at: $pre_backup"
        
        # Cleanup
        rm -rf "$extract_dir"
        if [ "$decrypted_file" != "$backup_file" ]; then
            rm -f "$decrypted_file"
        fi
        
        return 0
    else
        print_status "ERROR" "Quick recovery validation failed"
        return 1
    fi
}

# Full recovery (all components)
full_recovery() {
    local backup_file="$1"
    
    log "INFO" "Starting full recovery from: $(basename "$backup_file")"
    print_status "INFO" "Performing complete system recovery"
    
    local start_time=$(date +%s)
    
    # Create pre-recovery backup
    local pre_backup
    pre_backup=$(create_pre_recovery_backup)
    
    # Decrypt and extract backup
    local decrypted_file
    decrypted_file=$(decrypt_backup "$backup_file")
    
    local extract_dir="$RECOVERY_ROOT/full_recovery_$(date +%Y%m%d_%H%M%S)"
    extract_backup "$decrypted_file" "$extract_dir"
    
    # Find the actual backup directory (should be only one)
    local backup_source
    backup_source=$(find "$extract_dir" -maxdepth 1 -type d ! -path "$extract_dir" | head -1)
    
    if [ -z "$backup_source" ]; then
        print_status "ERROR" "Could not find backup data in extracted archive"
        return 1
    fi
    
    print_status "INFO" "Backup source: $backup_source"
    
    # Perform recovery levels
    level1_config_recovery "$backup_source" || return 1
    level2_scripts_recovery "$backup_source" || return 1
    level3_github_recovery "$backup_source" || return 1
    level4_documentation_recovery "$backup_source" || return 1
    level5_git_recovery "$backup_source" || return 1
    level6_tests_recovery "$backup_source" || return 1
    
    # Validate complete recovery
    if validate_recovery; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_status "SUCCESS" "Full recovery completed successfully in ${duration}s"
        log "INFO" "Pre-recovery backup available at: $pre_backup"
        
        # Cleanup
        rm -rf "$extract_dir"
        if [ "$decrypted_file" != "$backup_file" ]; then
            rm -f "$decrypted_file"
        fi
        
        return 0
    else
        print_status "ERROR" "Full recovery validation failed"
        return 1
    fi
}

# Selective recovery
selective_recovery() {
    local backup_file="$1"
    local component="$2"
    
    log "INFO" "Starting selective recovery of $component from: $(basename "$backup_file")"
    print_status "INFO" "Performing selective recovery: $component"
    
    # Create pre-recovery backup
    local pre_backup
    pre_backup=$(create_pre_recovery_backup)
    
    # Decrypt and extract backup
    local decrypted_file
    decrypted_file=$(decrypt_backup "$backup_file")
    
    local extract_dir="$RECOVERY_ROOT/selective_recovery_$(date +%Y%m%d_%H%M%S)"
    extract_backup "$decrypted_file" "$extract_dir"
    
    # Find the actual backup directory
    local backup_source
    backup_source=$(find "$extract_dir" -maxdepth 1 -type d ! -path "$extract_dir" | head -1)
    
    if [ -z "$backup_source" ]; then
        print_status "ERROR" "Could not find backup data in extracted archive"
        return 1
    fi
    
    # Perform selective recovery
    case "$component" in
        "config"|"configurations")
            level1_config_recovery "$backup_source"
            ;;
        "scripts")
            level2_scripts_recovery "$backup_source"
            ;;
        "github")
            level3_github_recovery "$backup_source"
            ;;
        "docs"|"documentation")
            level4_documentation_recovery "$backup_source"
            ;;
        "git"|"repository")
            level5_git_recovery "$backup_source"
            ;;
        "tests")
            level6_tests_recovery "$backup_source"
            ;;
        *)
            print_status "ERROR" "Unknown component: $component"
            print_status "INFO" "Available components: config, scripts, github, docs, git, tests"
            return 1
            ;;
    esac
    
    # Cleanup
    rm -rf "$extract_dir"
    if [ "$decrypted_file" != "$backup_file" ]; then
        rm -f "$decrypted_file"
    fi
    
    print_status "SUCCESS" "Selective recovery of $component completed"
    log "INFO" "Pre-recovery backup available at: $pre_backup"
}

# Emergency recovery procedures
emergency_recovery() {
    print_status "INFO" "Initiating emergency recovery procedures"
    log "INFO" "Starting emergency recovery mode"
    
    # Try to find any available backup
    local backup_file=""
    for backup_type in daily weekly snapshot; do
        if backup_file=$(find_latest_backup "$backup_type" 2>/dev/null); then
            print_status "SUCCESS" "Found $backup_type backup for emergency recovery"
            break
        fi
    done
    
    if [ -z "$backup_file" ]; then
        print_status "ERROR" "No backups found for emergency recovery"
        log "ERROR" "Emergency recovery failed - no backups available"
        return 1
    fi
    
    print_status "INFO" "Using backup: $(basename "$backup_file")"
    
    # Attempt quick recovery first
    if quick_recovery "$backup_file"; then
        print_status "SUCCESS" "Emergency quick recovery completed"
        return 0
    else
        print_status "WARNING" "Quick recovery failed, attempting full recovery"
        
        # If quick recovery fails, try full recovery
        if full_recovery "$backup_file"; then
            print_status "SUCCESS" "Emergency full recovery completed"
            return 0
        else
            print_status "ERROR" "Emergency recovery failed completely"
            return 1
        fi
    fi
}

# Show help
show_help() {
    echo "🔄 Recovery Procedures Script"
    echo ""
    echo "Usage: $0 [OPTIONS] RECOVERY_TYPE [BACKUP_FILE]"
    echo ""
    echo "Recovery Types:"
    echo "  quick BACKUP_FILE     Quick configuration recovery"
    echo "  full BACKUP_FILE      Complete system recovery"
    echo "  selective BACKUP_FILE COMPONENT  Recover specific component"
    echo "  emergency             Emergency recovery (auto-find backup)"
    echo ""
    echo "Components (for selective recovery):"
    echo "  config                System configurations"
    echo "  scripts               Executable scripts"
    echo "  github                GitHub workflows and templates"
    echo "  docs                  Documentation"
    echo "  git                   Git repository"
    echo "  tests                 Test suites"
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message"
    echo "  -l, --list TYPE       List available backups (daily/weekly/snapshot)"
    echo "  -f, --find-latest TYPE Find latest backup of type"
    echo "  --validate            Validate recovery without performing it"
    echo ""
    echo "Environment Variables:"
    echo "  BACKUP_ROOT           Backup directory (default: /tmp/backups)"
    echo "  RECOVERY_ROOT         Recovery working directory (default: /tmp/recovery)"
    echo "  BACKUP_ENCRYPTION_KEY Encryption key for encrypted backups"
    echo ""
    echo "Examples:"
    echo "  $0 quick /tmp/backups/daily_backup_20250724.tar.gz"
    echo "  $0 full /tmp/backups/weekly_backup_20250724.tar.gz"
    echo "  $0 selective /tmp/backups/daily_backup_20250724.tar.gz scripts"
    echo "  $0 emergency"
    echo "  $0 --list daily"
}

# Parse command line arguments
RECOVERY_TYPE=""
BACKUP_FILE=""
COMPONENT=""
LIST_TYPE=""
FIND_TYPE=""
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            LIST_TYPE="$2"
            shift 2
            ;;
        -f|--find-latest)
            FIND_TYPE="$2"
            shift 2
            ;;
        --validate)
            VALIDATE_ONLY=true
            shift
            ;;
        quick|full|selective|emergency)
            RECOVERY_TYPE="$1"
            shift
            
            if [[ "$RECOVERY_TYPE" != "emergency" ]]; then
                if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    BACKUP_FILE="$1"
                    shift
                    
                    if [[ "$RECOVERY_TYPE" == "selective" ]]; then
                        if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                            COMPONENT="$1"
                            shift
                        else
                            echo "Error: Component required for selective recovery"
                            exit 1
                        fi
                    fi
                else
                    echo "Error: Backup file required for $RECOVERY_TYPE recovery"
                    exit 1
                fi
            fi
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
if [ -n "$LIST_TYPE" ]; then
    # List available backups
    list_backups "$LIST_TYPE"
elif [ -n "$FIND_TYPE" ]; then
    # Find latest backup
    find_latest_backup "$FIND_TYPE"
elif [ "$VALIDATE_ONLY" = true ]; then
    # Validate current system
    validate_recovery
elif [ -n "$RECOVERY_TYPE" ]; then
    # Perform recovery
    case "$RECOVERY_TYPE" in
        "quick")
            quick_recovery "$BACKUP_FILE"
            ;;
        "full")
            full_recovery "$BACKUP_FILE"
            ;;
        "selective")
            selective_recovery "$BACKUP_FILE" "$COMPONENT"
            ;;
        "emergency")
            emergency_recovery
            ;;
    esac
else
    echo "Error: No operation specified"
    echo "Use --help for usage information"
    exit 1
fi
