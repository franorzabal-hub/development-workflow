#!/bin/bash

# 💾 System Backup Script
# Comprehensive backup solution for Development Workflow system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${BACKUP_ROOT:-/tmp/backups}"
LOG_FILE="logs/backup_$(date +%Y%m%d_%H%M%S).log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ENCRYPT_BACKUPS="${ENCRYPT_BACKUPS:-false}"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_ROOT"

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

# Backup encryption function
encrypt_file() {
    local file="$1"
    local encrypted_file="$1.enc"
    
    if [ "$ENCRYPT_BACKUPS" = "true" ] && [ -n "${BACKUP_ENCRYPTION_KEY:-}" ]; then
        log "INFO" "Encrypting backup: $(basename "$file")"
        
        if command -v openssl >/dev/null 2>&1; then
            openssl enc -aes-256-cbc -salt -pbkdf2 -in "$file" -out "$encrypted_file" -k "$BACKUP_ENCRYPTION_KEY"
            rm "$file"
            echo "$encrypted_file"
        else
            log "WARNING" "OpenSSL not available, backup not encrypted"
            echo "$file"
        fi
    else
        echo "$file"
    fi
}

# Configuration backup
backup_configurations() {
    local backup_dir="$1/configurations"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting configuration backup..."
    print_status "INFO" "Backing up system configurations"
    
    # Environment files
    log "INFO" "Backing up environment files..."
    if [ -f ".env" ]; then
        cp ".env" "$backup_dir/"
        log "INFO" "Copied .env file"
    fi
    
    # Copy all .env.* files
    for env_file in .env.*; do
        if [ -f "$env_file" ]; then
            cp "$env_file" "$backup_dir/"
            log "INFO" "Copied $env_file"
        fi
    done
    
    # Linear environment
    if [ -f "scripts/linear-env.sh" ]; then
        cp "scripts/linear-env.sh" "$backup_dir/"
        log "INFO" "Copied Linear environment file"
    fi
    
    # Git configuration
    if [ -f ".gitconfig" ]; then
        cp ".gitconfig" "$backup_dir/"
    fi
    
    # Package files
    for pkg_file in requirements*.txt package.json pyproject.toml setup.py; do
        if [ -f "$pkg_file" ]; then
            cp "$pkg_file" "$backup_dir/"
            log "INFO" "Copied $pkg_file"
        fi
    done
    
    # Configuration files
    for config in pytest.ini tox.ini .pre-commit-config.yaml; do
        if [ -f "$config" ]; then
            cp "$config" "$backup_dir/"
            log "INFO" "Copied $config"
        fi
    done
    
    print_status "SUCCESS" "Configuration backup completed"
}

# Scripts backup
backup_scripts() {
    local backup_dir="$1/scripts"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting scripts backup..."
    print_status "INFO" "Backing up executable scripts"
    
    if [ -d "scripts" ]; then
        # Create tar archive of scripts
        tar -czf "$backup_dir/scripts_$TIMESTAMP.tar.gz" scripts/
        log "INFO" "Created scripts archive: scripts_$TIMESTAMP.tar.gz"
        
        # Individual script backup for critical scripts
        local critical_scripts=(
            "scripts/start-development.sh"
            "scripts/test-and-validate.sh"
            "scripts/finish-development.sh"
            "scripts/setup-linear-states.sh"
            "scripts/validate-dependencies.sh"
        )
        
        for script in "${critical_scripts[@]}"; do
            if [ -f "$script" ]; then
                cp "$script" "$backup_dir/"
                log "INFO" "Backed up critical script: $(basename "$script")"
            fi
        done
        
        print_status "SUCCESS" "Scripts backup completed"
    else
        print_status "WARNING" "Scripts directory not found"
    fi
}

# GitHub configuration backup
backup_github_config() {
    local backup_dir="$1/github"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting GitHub configuration backup..."
    print_status "INFO" "Backing up GitHub workflows and templates"
    
    if [ -d ".github" ]; then
        # Backup entire .github directory
        tar -czf "$backup_dir/github_config_$TIMESTAMP.tar.gz" .github/
        log "INFO" "Created GitHub config archive: github_config_$TIMESTAMP.tar.gz"
        
        # Individual workflow backup
        if [ -d ".github/workflows" ]; then
            cp -r .github/workflows "$backup_dir/"
            log "INFO" "Copied workflows directory"
        fi
        
        # Templates backup
        if [ -d ".github/ISSUE_TEMPLATE" ]; then
            cp -r .github/ISSUE_TEMPLATE "$backup_dir/"
            log "INFO" "Copied issue templates"
        fi
        
        if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
            cp ".github/PULL_REQUEST_TEMPLATE.md" "$backup_dir/"
            log "INFO" "Copied PR template"
        fi
        
        print_status "SUCCESS" "GitHub configuration backup completed"
    else
        print_status "WARNING" ".github directory not found"
    fi
}

# Documentation backup
backup_documentation() {
    local backup_dir="$1/documentation"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting documentation backup..."
    print_status "INFO" "Backing up project documentation"
    
    # Core documentation files
    for doc in README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md LICENSE; do
        if [ -f "$doc" ]; then
            cp "$doc" "$backup_dir/"
            log "INFO" "Copied $doc"
        fi
    done
    
    # Docs directory
    if [ -d "docs" ]; then
        tar -czf "$backup_dir/docs_$TIMESTAMP.tar.gz" docs/
        log "INFO" "Created documentation archive: docs_$TIMESTAMP.tar.gz"
    fi
    
    # Training materials
    if [ -d "training" ]; then
        tar -czf "$backup_dir/training_$TIMESTAMP.tar.gz" training/
        log "INFO" "Created training archive: training_$TIMESTAMP.tar.gz"
    fi
    
    print_status "SUCCESS" "Documentation backup completed"
}

# System state backup
backup_system_state() {
    local backup_dir="$1/system_state"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting system state backup..."
    print_status "INFO" "Capturing current system state"
    
    # Git repository state
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git rev-parse HEAD > "$backup_dir/git_commit.txt"
        git status --porcelain > "$backup_dir/git_status.txt"
        git remote -v > "$backup_dir/git_remotes.txt"
        git branch -v > "$backup_dir/git_branches.txt"
        
        # Create git bundle for complete repository backup
        git bundle create "$backup_dir/repository_$TIMESTAMP.bundle" --all
        log "INFO" "Created git bundle backup"
    fi
    
    # System information
    uname -a > "$backup_dir/system_info.txt"
    date > "$backup_dir/backup_timestamp.txt"
    pwd > "$backup_dir/working_directory.txt"
    
    # Environment variables (filtered for security)
    env | grep -E "(LINEAR|GITHUB|PATH|USER|HOME)" | \
    sed 's/=.*API.*KEY.*/=***REDACTED***/' > "$backup_dir/environment.txt"
    
    # Process information
    ps aux | grep -E "(linear|github|python|node)" > "$backup_dir/processes.txt" || true
    
    # Network connectivity status
    echo "Connectivity Test Results:" > "$backup_dir/connectivity.txt"
    curl -s -o /dev/null -w "Linear API: %{http_code}\n" --max-time 10 https://api.linear.app/graphql >> "$backup_dir/connectivity.txt" || echo "Linear API: FAILED" >> "$backup_dir/connectivity.txt"
    curl -s -o /dev/null -w "GitHub API: %{http_code}\n" --max-time 10 https://api.github.com >> "$backup_dir/connectivity.txt" || echo "GitHub API: FAILED" >> "$backup_dir/connectivity.txt"
    
    print_status "SUCCESS" "System state backup completed"
}

# Logs and metrics backup
backup_logs_metrics() {
    local backup_dir="$1/logs_metrics"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting logs and metrics backup..."
    print_status "INFO" "Backing up logs and metrics data"
    
    # Logs backup
    if [ -d "logs" ]; then
        tar -czf "$backup_dir/logs_$TIMESTAMP.tar.gz" logs/
        log "INFO" "Created logs archive: logs_$TIMESTAMP.tar.gz"
    fi
    
    # Metrics data backup
    if [ -d "metrics" ]; then
        tar -czf "$backup_dir/metrics_$TIMESTAMP.tar.gz" metrics/
        log "INFO" "Created metrics archive: metrics_$TIMESTAMP.tar.gz"
    fi
    
    # Performance data
    if [ -d "performance" ]; then
        tar -czf "$backup_dir/performance_$TIMESTAMP.tar.gz" performance/
        log "INFO" "Created performance archive: performance_$TIMESTAMP.tar.gz"
    fi
    
    # Test results
    if [ -d "test-results" ]; then
        tar -czf "$backup_dir/test_results_$TIMESTAMP.tar.gz" test-results/
        log "INFO" "Created test results archive"
    fi
    
    print_status "SUCCESS" "Logs and metrics backup completed"
}

# Database backup (if applicable)
backup_databases() {
    local backup_dir="$1/databases"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting database backup..."
    print_status "INFO" "Backing up database files"
    
    # SQLite databases
    local db_count=0
    for db_file in *.db *.sqlite *.sqlite3; do
        if [ -f "$db_file" ]; then
            cp "$db_file" "$backup_dir/"
            log "INFO" "Backed up database: $db_file"
            ((db_count++))
        fi
    done
    
    # Look for databases in subdirectories
    find . -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" | while read -r db; do
        if [ -f "$db" ]; then
            local db_name=$(basename "$db")
            local db_dir=$(dirname "$db" | tr '/' '_')
            cp "$db" "$backup_dir/${db_dir}_${db_name}"
            log "INFO" "Backed up database: $db"
            ((db_count++))
        fi
    done
    
    if [ $db_count -eq 0 ]; then
        print_status "INFO" "No database files found"
    else
        print_status "SUCCESS" "Database backup completed ($db_count files)"
    fi
}

# Tests backup
backup_tests() {
    local backup_dir="$1/tests"
    mkdir -p "$backup_dir"
    
    log "INFO" "Starting tests backup..."
    print_status "INFO" "Backing up test suites and fixtures"
    
    if [ -d "tests" ]; then
        tar -czf "$backup_dir/tests_$TIMESTAMP.tar.gz" tests/
        log "INFO" "Created tests archive: tests_$TIMESTAMP.tar.gz"
        print_status "SUCCESS" "Tests backup completed"
    else
        print_status "INFO" "No tests directory found"
    fi
}

# Create backup manifest
create_backup_manifest() {
    local backup_dir="$1"
    local manifest_file="$backup_dir/BACKUP_MANIFEST.txt"
    
    log "INFO" "Creating backup manifest..."
    print_status "INFO" "Generating backup manifest and checksums"
    
    cat > "$manifest_file" << EOF
# Development Workflow System Backup Manifest
# Created: $(date)
# Timestamp: $TIMESTAMP
# Backup Location: $backup_dir

## Backup Components

EOF
    
    # List all backup components
    for component in configurations scripts github documentation system_state logs_metrics databases tests; do
        if [ -d "$backup_dir/$component" ]; then
            echo "### $component" >> "$manifest_file"
            find "$backup_dir/$component" -type f -exec basename {} \; | sort >> "$manifest_file"
            echo "" >> "$manifest_file"
        fi
    done
    
    # Generate checksums
    echo "## File Checksums" >> "$manifest_file"
    find "$backup_dir" -type f -not -name "BACKUP_MANIFEST.txt" -exec sha256sum {} \; >> "$manifest_file"
    
    # Backup statistics
    echo "" >> "$manifest_file"
    echo "## Backup Statistics" >> "$manifest_file"
    echo "Total files: $(find "$backup_dir" -type f | wc -l)" >> "$manifest_file"
    echo "Total size: $(du -sh "$backup_dir" | cut -f1)" >> "$manifest_file"
    echo "Creation time: $(date)" >> "$manifest_file"
    
    print_status "SUCCESS" "Backup manifest created"
}

# Compress and finalize backup
finalize_backup() {
    local backup_dir="$1"
    local final_backup="$2"
    
    log "INFO" "Finalizing backup..."
    print_status "INFO" "Compressing and finalizing backup archive"
    
    # Create final compressed archive
    local parent_dir=$(dirname "$backup_dir")
    local backup_name=$(basename "$backup_dir")
    
    cd "$parent_dir"
    tar -czf "$final_backup" "$backup_name/"
    
    # Encrypt if requested
    local final_file
    final_file=$(encrypt_file "$final_backup")
    
    # Calculate final size and checksum
    local final_size=$(du -sh "$final_file" | cut -f1)
    local final_checksum=$(sha256sum "$final_file" | cut -d' ' -f1)
    
    log "INFO" "Final backup: $final_file"
    log "INFO" "Size: $final_size"
    log "INFO" "Checksum: $final_checksum"
    
    print_status "SUCCESS" "Backup finalized: $(basename "$final_file") ($final_size)"
    
    # Cleanup temporary directory
    rm -rf "$backup_dir"
    
    echo "$final_file"
}

# Cleanup old backups
cleanup_old_backups() {
    local backup_type="$1"
    local retention_days="$2"
    
    log "INFO" "Cleaning up old $backup_type backups (older than $retention_days days)..."
    
    local pattern
    case "$backup_type" in
        "daily") pattern="daily_backup_*.tar.gz*" ;;
        "weekly") pattern="weekly_backup_*.tar.gz*" ;;
        "snapshot") pattern="snapshot_backup_*.tar.gz*" ;;
        *) pattern="*backup_*.tar.gz*" ;;
    esac
    
    local deleted_count=0
    find "$BACKUP_ROOT" -name "$pattern" -mtime +$retention_days -type f | while read -r old_backup; do
        log "INFO" "Deleting old backup: $(basename "$old_backup")"
        rm -f "$old_backup"
        ((deleted_count++))
    done
    
    if [ $deleted_count -gt 0 ]; then
        print_status "SUCCESS" "Cleaned up $deleted_count old backups"
    else
        print_status "INFO" "No old backups to clean up"
    fi
}

# Validate backup integrity
validate_backup() {
    local backup_file="$1"
    
    log "INFO" "Validating backup integrity..."
    print_status "INFO" "Validating backup file integrity"
    
    # Check if file exists
    if [ ! -f "$backup_file" ]; then
        print_status "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    # Test archive integrity
    if [[ "$backup_file" == *.enc ]]; then
        print_status "INFO" "Encrypted backup - skipping archive test"
    else
        if tar -tzf "$backup_file" >/dev/null 2>&1; then
            print_status "SUCCESS" "Backup archive integrity verified"
        else
            print_status "ERROR" "Backup archive is corrupted"
            return 1
        fi
    fi
    
    # Check file size (should be > 1KB)
    local file_size=$(stat -c%s "$backup_file")
    if [ $file_size -gt 1024 ]; then
        print_status "SUCCESS" "Backup file size acceptable ($file_size bytes)"
    else
        print_status "ERROR" "Backup file too small ($file_size bytes)"
        return 1
    fi
    
    return 0
}

# Full backup function
perform_full_backup() {
    local backup_type="$1"
    local retention_days="$2"
    
    local start_time=$(date +%s)
    log "INFO" "Starting $backup_type backup..."
    
    # Create backup directory
    local backup_dir="$BACKUP_ROOT/${backup_type}_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    print_status "INFO" "Creating $backup_type backup in: $backup_dir"
    
    # Perform all backup operations
    backup_configurations "$backup_dir"
    backup_scripts "$backup_dir"
    backup_github_config "$backup_dir"
    backup_documentation "$backup_dir"
    backup_system_state "$backup_dir"
    backup_logs_metrics "$backup_dir"
    backup_databases "$backup_dir"
    backup_tests "$backup_dir"
    
    # Create manifest
    create_backup_manifest "$backup_dir"
    
    # Finalize backup
    local final_backup="$BACKUP_ROOT/${backup_type}_backup_$TIMESTAMP.tar.gz"
    local final_file
    final_file=$(finalize_backup "$backup_dir" "$final_backup")
    
    # Validate backup
    if validate_backup "$final_file"; then
        print_status "SUCCESS" "Backup validation passed"
    else
        print_status "ERROR" "Backup validation failed"
        return 1
    fi
    
    # Cleanup old backups
    cleanup_old_backups "$backup_type" "$retention_days"
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "INFO" "$backup_type backup completed in ${duration}s"
    print_status "SUCCESS" "$backup_type backup completed successfully"
    
    echo "$final_file"
}

# Show help
show_help() {
    echo "💾 System Backup Script"
    echo ""
    echo "Usage: $0 [OPTIONS] BACKUP_TYPE"
    echo ""
    echo "Backup Types:"
    echo "  daily      Create daily backup (7 days retention)"
    echo "  weekly     Create weekly backup (4 weeks retention)"
    echo "  snapshot   Create snapshot backup (2 days retention)"
    echo "  manual     Create manual backup (no automatic cleanup)"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -v, --validate FILE  Validate existing backup file"
    echo "  -e, --encrypt        Encrypt backup (requires BACKUP_ENCRYPTION_KEY)"
    echo "  -d, --dir DIR        Set backup directory (default: /tmp/backups)"
    echo "  --cleanup-only       Only perform cleanup of old backups"
    echo ""
    echo "Environment Variables:"
    echo "  BACKUP_ROOT          Backup directory (default: /tmp/backups)"
    echo "  BACKUP_ENCRYPTION_KEY  Encryption key for backup files"
    echo "  ENCRYPT_BACKUPS      Enable backup encryption (true/false)"
    echo ""
    echo "Examples:"
    echo "  $0 daily                    # Create daily backup"
    echo "  $0 weekly --encrypt         # Create encrypted weekly backup"
    echo "  $0 --validate backup.tar.gz # Validate backup file"
}

# Parse command line arguments
BACKUP_TYPE=""
VALIDATE_FILE=""
CLEANUP_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--validate)
            VALIDATE_FILE="$2"
            shift 2
            ;;
        -e|--encrypt)
            ENCRYPT_BACKUPS=true
            shift
            ;;
        -d|--dir)
            BACKUP_ROOT="$2"
            shift 2
            ;;
        --cleanup-only)
            CLEANUP_ONLY=true
            shift
            ;;
        daily|weekly|snapshot|manual)
            BACKUP_TYPE="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
if [ -n "$VALIDATE_FILE" ]; then
    # Validate specified backup file
    if validate_backup "$VALIDATE_FILE"; then
        exit 0
    else
        exit 1
    fi
elif [ "$CLEANUP_ONLY" = true ]; then
    # Only perform cleanup
    cleanup_old_backups "daily" 7
    cleanup_old_backups "weekly" 28
    cleanup_old_backups "snapshot" 2
    exit 0
elif [ -n "$BACKUP_TYPE" ]; then
    # Perform backup
    case "$BACKUP_TYPE" in
        "daily")
            perform_full_backup "daily" 7
            ;;
        "weekly") 
            perform_full_backup "weekly" 28
            ;;
        "snapshot")
            perform_full_backup "snapshot" 2
            ;;
        "manual")
            perform_full_backup "manual" 0
            ;;
    esac
else
    echo "Error: No backup type specified"
    echo "Use --help for usage information"
    exit 1
fi
