# 💾 Backup & Recovery Procedures

## Overview

This document outlines comprehensive backup and recovery procedures for the Development Workflow - Linear ↔ GitHub Integration system. These procedures ensure data protection, system continuity, and rapid recovery capabilities.

## 🎯 Backup Strategy Overview

### Backup Types

#### Full Backups
- **Frequency:** Weekly (Sundays at 02:00 UTC)
- **Retention:** 4 weeks (monthly rotation)
- **Scope:** Complete system state, all configurations, scripts, and data

#### Incremental Backups
- **Frequency:** Daily (02:00 UTC)
- **Retention:** 7 days (rolling)
- **Scope:** Changed files since last backup

#### Real-time Snapshots
- **Frequency:** Every 4 hours
- **Retention:** 48 hours (rolling)
- **Scope:** Critical configurations and active data

#### Configuration Snapshots
- **Frequency:** Before each deployment/change
- **Retention:** 10 snapshots (rolling)
- **Scope:** System configurations, environment variables, scripts

### Backup Scope

#### Critical Data (RPO: 0 minutes)
- Environment variables and configurations
- API keys and authentication tokens (encrypted)
- Script versions and configurations
- System state information

#### Operational Data (RPO: 1 hour)
- Execution logs and metrics
- Temporary files and caches
- Development workflow state
- Integration mappings

#### Historical Data (RPO: 4 hours)
- Metrics and analytics data
- Performance monitoring data
- Audit logs and traces
- Long-term statistics

## 🔄 Automated Backup Procedures

### Daily Backup Script

```bash
#!/bin/bash
# Daily backup automation - runs at 02:00 UTC

BACKUP_DIR="/backups/daily/$(date +%Y%m%d)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup critical configurations
backup_configurations() {
    echo "Starting configuration backup at $(date)"
    
    # Environment files
    cp .env* "$BACKUP_DIR/" 2>/dev/null || true
    cp scripts/linear-env.sh "$BACKUP_DIR/" 2>/dev/null || true
    
    # Script configurations
    tar -czf "$BACKUP_DIR/scripts_$TIMESTAMP.tar.gz" scripts/
    
    # GitHub configurations
    tar -czf "$BACKUP_DIR/github_config_$TIMESTAMP.tar.gz" .github/
    
    # Documentation
    tar -czf "$BACKUP_DIR/docs_$TIMESTAMP.tar.gz" docs/
    
    echo "Configuration backup completed at $(date)"
}

# Backup logs and metrics
backup_logs() {
    echo "Starting logs backup at $(date)"
    
    # Create logs backup
    if [ -d "logs" ]; then
        tar -czf "$BACKUP_DIR/logs_$TIMESTAMP.tar.gz" logs/
    fi
    
    # Backup metrics data
    if [ -d "metrics" ]; then
        tar -czf "$BACKUP_DIR/metrics_$TIMESTAMP.tar.gz" metrics/
    fi
    
    echo "Logs backup completed at $(date)"
}

# Backup system state
backup_system_state() {
    echo "Starting system state backup at $(date)"
    
    # Git repository state
    git rev-parse HEAD > "$BACKUP_DIR/git_commit.txt"
    git status --porcelain > "$BACKUP_DIR/git_status.txt"
    git remote -v > "$BACKUP_DIR/git_remotes.txt"
    
    # System information
    uname -a > "$BACKUP_DIR/system_info.txt"
    env | grep -E "(LINEAR|GITHUB)" > "$BACKUP_DIR/env_vars.txt"
    
    # Dependencies
    if [ -f "requirements.txt" ]; then
        cp requirements.txt "$BACKUP_DIR/"
    fi
    
    echo "System state backup completed at $(date)"
}

# Execute backup functions
backup_configurations
backup_logs
backup_system_state

# Compress entire backup
cd /backups/daily
tar -czf "daily_backup_$TIMESTAMP.tar.gz" "$(date +%Y%m%d)/"

# Cleanup old daily backups (keep 7 days)
find /backups/daily -name "daily_backup_*.tar.gz" -mtime +7 -delete

echo "Daily backup completed successfully at $(date)"
```

### Weekly Full Backup Script

```bash
#!/bin/bash
# Weekly full backup - runs Sundays at 02:00 UTC

BACKUP_DIR="/backups/weekly/$(date +%Y_week_%U)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Full system backup
full_system_backup() {
    echo "Starting full system backup at $(date)"
    
    # Complete repository backup
    git bundle create "$BACKUP_DIR/repository_$TIMESTAMP.bundle" --all
    
    # All files backup (excluding .git)
    tar --exclude='.git' --exclude='node_modules' --exclude='*.pyc' \
        -czf "$BACKUP_DIR/full_system_$TIMESTAMP.tar.gz" .
    
    # Database exports (if any)
    if command -v sqlite3 &> /dev/null; then
        find . -name "*.db" -exec cp {} "$BACKUP_DIR/" \;
    fi
    
    echo "Full system backup completed at $(date)"
}

# Configuration exports
export_configurations() {
    echo "Exporting configurations at $(date)"
    
    # Export Linear states
    ./scripts/setup-linear-states.sh --export > "$BACKUP_DIR/linear_states.json"
    
    # Export GitHub settings
    gh repo view --json * > "$BACKUP_DIR/github_repo_config.json" 2>/dev/null || true
    
    # Export system dependencies
    ./scripts/validate-dependencies.sh --export > "$BACKUP_DIR/dependencies.json"
    
    echo "Configuration export completed at $(date)"
}

# Execute full backup
full_system_backup
export_configurations

# Cleanup old weekly backups (keep 4 weeks)
find /backups/weekly -name "*.tar.gz" -mtime +28 -delete

echo "Weekly full backup completed successfully at $(date)"
```

### Real-time Snapshot Script

```bash
#!/bin/bash
# Real-time snapshots - runs every 4 hours

SNAPSHOT_DIR="/backups/snapshots/$(date +%Y%m%d_%H)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$SNAPSHOT_DIR"

# Critical file snapshots
snapshot_critical_files() {
    echo "Creating critical file snapshots at $(date)"
    
    # Environment configurations
    cp .env* "$SNAPSHOT_DIR/" 2>/dev/null || true
    cp scripts/linear-env.sh "$SNAPSHOT_DIR/" 2>/dev/null || true
    
    # Active script versions
    cp scripts/*.sh "$SNAPSHOT_DIR/"
    cp scripts/*.py "$SNAPSHOT_DIR/"
    
    # Current git state
    git rev-parse HEAD > "$SNAPSHOT_DIR/git_commit.txt"
    
    echo "Critical file snapshots completed at $(date)"
}

# Quick system state capture
capture_system_state() {
    echo "Capturing system state at $(date)"
    
    # Active processes
    ps aux | grep -E "(linear|github)" > "$SNAPSHOT_DIR/active_processes.txt"
    
    # System resources
    df -h > "$SNAPSHOT_DIR/disk_usage.txt"
    free -h > "$SNAPSHOT_DIR/memory_usage.txt"
    
    # Network connectivity
    curl -s -o /dev/null -w "%{http_code}" https://api.linear.app/graphql > "$SNAPSHOT_DIR/linear_status.txt"
    curl -s -o /dev/null -w "%{http_code}" https://api.github.com > "$SNAPSHOT_DIR/github_status.txt"
    
    echo "System state capture completed at $(date)"
}

# Execute snapshot
snapshot_critical_files
capture_system_state

# Cleanup old snapshots (keep 48 hours)
find /backups/snapshots -name "*" -mtime +2 -delete

echo "Real-time snapshot completed successfully at $(date)"
```

## 🔧 Recovery Procedures

### Quick Recovery (Configuration Restore)

```bash
#!/bin/bash
# Quick configuration recovery

BACKUP_DATE="$1"
BACKUP_TYPE="$2"  # daily, weekly, snapshot

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date> [backup_type]"
    echo "Example: $0 20250724 daily"
    exit 1
fi

quick_config_recovery() {
    echo "Starting quick configuration recovery from $BACKUP_DATE"
    
    # Determine backup path
    if [ "$BACKUP_TYPE" = "weekly" ]; then
        BACKUP_PATH="/backups/weekly/$BACKUP_DATE"
    else
        BACKUP_PATH="/backups/daily/$BACKUP_DATE"
    fi
    
    if [ ! -d "$BACKUP_PATH" ]; then
        echo "Backup directory not found: $BACKUP_PATH"
        exit 1
    fi
    
    # Backup current state before recovery
    mkdir -p /tmp/pre_recovery_backup
    cp .env* /tmp/pre_recovery_backup/ 2>/dev/null || true
    cp scripts/linear-env.sh /tmp/pre_recovery_backup/ 2>/dev/null || true
    
    # Restore environment files
    if [ -f "$BACKUP_PATH/.env" ]; then
        cp "$BACKUP_PATH/.env" .
        echo "Environment file restored"
    fi
    
    if [ -f "$BACKUP_PATH/linear-env.sh" ]; then
        cp "$BACKUP_PATH/linear-env.sh" scripts/
        echo "Linear environment restored"
    fi
    
    # Validate restoration
    ./scripts/validate-dependencies.sh --quick
    
    echo "Quick configuration recovery completed"
}

quick_config_recovery
```

### Full System Recovery

```bash
#!/bin/bash
# Full system recovery from backup

BACKUP_DATE="$1"
RECOVERY_TARGET="$2"  # current directory or specified path

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date> [recovery_target]"
    echo "Example: $0 20250724 /tmp/recovery"
    exit 1
fi

full_system_recovery() {
    echo "Starting full system recovery from $BACKUP_DATE"
    
    BACKUP_PATH="/backups/weekly/$BACKUP_DATE"
    TARGET_PATH="${RECOVERY_TARGET:-.}"
    
    # Create recovery directory
    mkdir -p "$TARGET_PATH/recovery_$BACKUP_DATE"
    cd "$TARGET_PATH/recovery_$BACKUP_DATE"
    
    # Extract full system backup
    tar -xzf "$BACKUP_PATH/full_system_*.tar.gz"
    
    # Restore git repository
    if [ -f "$BACKUP_PATH/repository_*.bundle" ]; then
        git clone "$BACKUP_PATH/repository_*.bundle" restored_repo
        echo "Git repository restored"
    fi
    
    # Restore configurations
    if [ -f "$BACKUP_PATH/linear_states.json" ]; then
        cp "$BACKUP_PATH/linear_states.json" .
        echo "Linear states restored"
    fi
    
    if [ -f "$BACKUP_PATH/dependencies.json" ]; then
        cp "$BACKUP_PATH/dependencies.json" .
        echo "Dependencies configuration restored"
    fi
    
    # Validate recovery
    cd restored_repo
    ./scripts/validate-dependencies.sh
    
    echo "Full system recovery completed in: $TARGET_PATH/recovery_$BACKUP_DATE"
}

full_system_recovery
```

### Selective Recovery

```bash
#!/bin/bash
# Selective recovery for specific components

COMPONENT="$1"  # scripts, configs, docs, logs
BACKUP_DATE="$2"

if [ -z "$COMPONENT" ] || [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <component> <backup_date>"
    echo "Components: scripts, configs, docs, logs"
    echo "Example: $0 scripts 20250724"
    exit 1
fi

selective_recovery() {
    echo "Starting selective recovery for $COMPONENT from $BACKUP_DATE"
    
    BACKUP_PATH="/backups/daily/$BACKUP_DATE"
    
    case "$COMPONENT" in
        "scripts")
            if [ -f "$BACKUP_PATH/scripts_*.tar.gz" ]; then
                # Backup current scripts
                mv scripts scripts_backup_$(date +%Y%m%d_%H%M%S)
                
                # Extract backup scripts
                tar -xzf "$BACKUP_PATH"/scripts_*.tar.gz
                
                # Set permissions
                chmod +x scripts/*.sh
                
                echo "Scripts recovered from backup"
            fi
            ;;
            
        "configs")
            if [ -f "$BACKUP_PATH/.env" ]; then
                cp "$BACKUP_PATH/.env" .
                echo "Environment configuration recovered"
            fi
            
            if [ -f "$BACKUP_PATH/linear-env.sh" ]; then
                cp "$BACKUP_PATH/linear-env.sh" scripts/
                echo "Linear environment recovered"
            fi
            ;;
            
        "docs")
            if [ -f "$BACKUP_PATH/docs_*.tar.gz" ]; then
                # Backup current docs
                mv docs docs_backup_$(date +%Y%m%d_%H%M%S)
                
                # Extract backup docs
                tar -xzf "$BACKUP_PATH"/docs_*.tar.gz
                
                echo "Documentation recovered from backup"
            fi
            ;;
            
        "logs")
            if [ -f "$BACKUP_PATH/logs_*.tar.gz" ]; then
                # Create recovery logs directory
                mkdir -p logs_recovery
                
                # Extract backup logs
                tar -xzf "$BACKUP_PATH"/logs_*.tar.gz -C logs_recovery
                
                echo "Logs recovered to logs_recovery directory"
            fi
            ;;
            
        *)
            echo "Unknown component: $COMPONENT"
            exit 1
            ;;
    esac
    
    echo "Selective recovery for $COMPONENT completed"
}

selective_recovery
```

## 🔐 Backup Security & Encryption

### Encryption Procedures

```bash
#!/bin/bash
# Encrypt sensitive backup data

encrypt_backup() {
    BACKUP_FILE="$1"
    ENCRYPTED_FILE="$1.enc"
    
    if [ -z "$BACKUP_ENCRYPTION_KEY" ]; then
        echo "Error: BACKUP_ENCRYPTION_KEY not set"
        exit 1
    fi
    
    # Encrypt backup file
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE" -k "$BACKUP_ENCRYPTION_KEY"
    
    # Remove unencrypted file
    rm "$BACKUP_FILE"
    
    echo "Backup encrypted: $ENCRYPTED_FILE"
}

decrypt_backup() {
    ENCRYPTED_FILE="$1"
    DECRYPTED_FILE="${1%.enc}"
    
    if [ -z "$BACKUP_ENCRYPTION_KEY" ]; then
        echo "Error: BACKUP_ENCRYPTION_KEY not set"
        exit 1
    fi
    
    # Decrypt backup file
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$ENCRYPTED_FILE" -out "$DECRYPTED_FILE" -k "$BACKUP_ENCRYPTION_KEY"
    
    echo "Backup decrypted: $DECRYPTED_FILE"
}
```

### Secure Storage Configuration

```bash
# Backup storage security settings

# Set secure permissions for backup directories
chmod 700 /backups
chmod -R 600 /backups/*

# Set backup file ownership
chown -R backup_user:backup_group /backups

# Configure backup retention with secure cleanup
find /backups -type f -name "*.tar.gz" -mtime +30 -exec shred -vfz -n 3 {} \;

# Verify backup integrity
find /backups -type f -name "*.tar.gz" -exec tar -tzf {} > /dev/null \;
```

## 📊 Backup Monitoring & Validation

### Backup Validation Script

```bash
#!/bin/bash
# Validate backup integrity and completeness

validate_backups() {
    echo "Starting backup validation at $(date)"
    
    VALIDATION_LOG="/var/log/backup_validation.log"
    
    # Check daily backups
    validate_daily_backups() {
        echo "Validating daily backups..." | tee -a "$VALIDATION_LOG"
        
        for backup in /backups/daily/daily_backup_*.tar.gz; do
            if [ -f "$backup" ]; then
                if tar -tzf "$backup" > /dev/null 2>&1; then
                    echo "✅ Valid: $(basename $backup)" | tee -a "$VALIDATION_LOG"
                else
                    echo "❌ Invalid: $(basename $backup)" | tee -a "$VALIDATION_LOG"
                fi
            fi
        done
    }
    
    # Check weekly backups
    validate_weekly_backups() {
        echo "Validating weekly backups..." | tee -a "$VALIDATION_LOG"
        
        for backup in /backups/weekly/full_system_*.tar.gz; do
            if [ -f "$backup" ]; then
                if tar -tzf "$backup" > /dev/null 2>&1; then
                    echo "✅ Valid: $(basename $backup)" | tee -a "$VALIDATION_LOG"
                else
                    echo "❌ Invalid: $(basename $backup)" | tee -a "$VALIDATION_LOG"
                fi
            fi
        done
    }
    
    # Check critical file presence
    validate_critical_files() {
        echo "Validating critical files in latest backup..." | tee -a "$VALIDATION_LOG"
        
        LATEST_BACKUP=$(ls -t /backups/daily/daily_backup_*.tar.gz | head -1)
        
        if [ -f "$LATEST_BACKUP" ]; then
            TEMP_DIR=$(mktemp -d)
            tar -xzf "$LATEST_BACKUP" -C "$TEMP_DIR"
            
            # Check for critical files
            CRITICAL_FILES=(
                "scripts/start-development.sh"
                "scripts/test-and-validate.sh"
                "scripts/finish-development.sh"
                ".github/workflows/test.yml"
            )
            
            for file in "${CRITICAL_FILES[@]}"; do
                if [ -f "$TEMP_DIR/$file" ]; then
                    echo "✅ Found: $file" | tee -a "$VALIDATION_LOG"
                else
                    echo "❌ Missing: $file" | tee -a "$VALIDATION_LOG"
                fi
            done
            
            rm -rf "$TEMP_DIR"
        fi
    }
    
    validate_daily_backups
    validate_weekly_backups
    validate_critical_files
    
    echo "Backup validation completed at $(date)" | tee -a "$VALIDATION_LOG"
}

validate_backups
```

### Backup Health Monitoring

```bash
#!/bin/bash
# Monitor backup health and send alerts

monitor_backup_health() {
    echo "Monitoring backup health at $(date)"
    
    ALERT_EMAIL="admin@example.com"
    HEALTH_STATUS="OK"
    HEALTH_REPORT="/tmp/backup_health_report.txt"
    
    # Check backup freshness
    check_backup_freshness() {
        LATEST_DAILY=$(ls -t /backups/daily/daily_backup_*.tar.gz 2>/dev/null | head -1)
        
        if [ -f "$LATEST_DAILY" ]; then
            BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_DAILY")) / 3600 ))
            
            if [ $BACKUP_AGE -gt 25 ]; then  # More than 25 hours
                echo "⚠️ Latest daily backup is $BACKUP_AGE hours old" >> "$HEALTH_REPORT"
                HEALTH_STATUS="WARNING"
            else
                echo "✅ Daily backup is fresh ($BACKUP_AGE hours old)" >> "$HEALTH_REPORT"
            fi
        else
            echo "❌ No daily backups found" >> "$HEALTH_REPORT"
            HEALTH_STATUS="CRITICAL"
        fi
    }
    
    # Check backup size consistency
    check_backup_sizes() {
        RECENT_BACKUPS=($(ls -t /backups/daily/daily_backup_*.tar.gz 2>/dev/null | head -3))
        
        if [ ${#RECENT_BACKUPS[@]} -ge 2 ]; then
            SIZE1=$(stat -c %s "${RECENT_BACKUPS[0]}")
            SIZE2=$(stat -c %s "${RECENT_BACKUPS[1]}")
            
            RATIO=$(( SIZE1 * 100 / SIZE2 ))
            
            if [ $RATIO -lt 50 ] || [ $RATIO -gt 200 ]; then
                echo "⚠️ Backup size variance detected: $RATIO%" >> "$HEALTH_REPORT"
                HEALTH_STATUS="WARNING"
            else
                echo "✅ Backup sizes are consistent" >> "$HEALTH_REPORT"
            fi
        fi
    }
    
    # Check storage space
    check_storage_space() {
        USAGE=$(df /backups | tail -1 | awk '{print $5}' | sed 's/%//')
        
        if [ $USAGE -gt 90 ]; then
            echo "❌ Backup storage is $USAGE% full" >> "$HEALTH_REPORT"
            HEALTH_STATUS="CRITICAL"
        elif [ $USAGE -gt 80 ]; then
            echo "⚠️ Backup storage is $USAGE% full" >> "$HEALTH_REPORT"
            HEALTH_STATUS="WARNING"
        else
            echo "✅ Backup storage usage is $USAGE%" >> "$HEALTH_REPORT"
        fi
    }
    
    # Execute checks
    check_backup_freshness
    check_backup_sizes
    check_storage_space
    
    # Send alerts if needed
    if [ "$HEALTH_STATUS" != "OK" ]; then
        echo "Backup Health Status: $HEALTH_STATUS" | cat - "$HEALTH_REPORT" | \
        mail -s "Backup Health Alert: $HEALTH_STATUS" "$ALERT_EMAIL"
    fi
    
    echo "Backup health monitoring completed: $HEALTH_STATUS"
}

monitor_backup_health
```

## 📋 Backup Schedules & Automation

### Cron Configuration

```bash
# Add to crontab for automated backups

# Daily backup at 02:00 UTC
0 2 * * * /path/to/scripts/daily-backup.sh >> /var/log/daily-backup.log 2>&1

# Weekly full backup on Sundays at 02:00 UTC  
0 2 * * 0 /path/to/scripts/weekly-backup.sh >> /var/log/weekly-backup.log 2>&1

# Real-time snapshots every 4 hours
0 */4 * * * /path/to/scripts/snapshot-backup.sh >> /var/log/snapshot-backup.log 2>&1

# Backup validation daily at 03:00 UTC
0 3 * * * /path/to/scripts/validate-backups.sh >> /var/log/backup-validation.log 2>&1

# Backup health monitoring every 6 hours
0 */6 * * * /path/to/scripts/monitor-backup-health.sh >> /var/log/backup-health.log 2>&1

# Monthly cleanup of old backups on 1st of month at 04:00 UTC
0 4 1 * * /path/to/scripts/cleanup-old-backups.sh >> /var/log/backup-cleanup.log 2>&1
```

### Systemd Service Configuration

```ini
# /etc/systemd/system/backup-monitoring.service

[Unit]
Description=Development Workflow Backup Monitoring
After=network.target

[Service]
Type=simple
User=backup_user
Group=backup_group
ExecStart=/path/to/scripts/continuous-backup-monitor.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```

## 📚 Recovery Testing Procedures

### Monthly Recovery Tests

```bash
#!/bin/bash
# Monthly recovery testing procedure

monthly_recovery_test() {
    echo "Starting monthly recovery test at $(date)"
    
    TEST_DIR="/tmp/recovery_test_$(date +%Y%m%d)"
    TEST_LOG="/var/log/recovery_test.log"
    
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Test quick configuration recovery
    test_quick_recovery() {
        echo "Testing quick configuration recovery..." | tee -a "$TEST_LOG"
        
        # Get latest backup
        LATEST_BACKUP=$(ls -t /backups/daily/*.tar.gz | head -1)
        
        if [ -f "$LATEST_BACKUP" ]; then
            # Extract and validate
            tar -xzf "$LATEST_BACKUP"
            
            if [ -f "scripts/validate-dependencies.sh" ]; then
                chmod +x scripts/validate-dependencies.sh
                ./scripts/validate-dependencies.sh --test-mode
                echo "✅ Quick recovery test passed" | tee -a "$TEST_LOG"
            else
                echo "❌ Quick recovery test failed" | tee -a "$TEST_LOG"
            fi
        fi
    }
    
    # Test full system recovery
    test_full_recovery() {
        echo "Testing full system recovery..." | tee -a "$TEST_LOG"
        
        LATEST_WEEKLY=$(ls -t /backups/weekly/*.tar.gz | head -1)
        
        if [ -f "$LATEST_WEEKLY" ]; then
            tar -xzf "$LATEST_WEEKLY"
            
            # Validate critical components
            if [ -d "scripts" ] && [ -d ".github" ] && [ -d "docs" ]; then
                echo "✅ Full recovery test passed" | tee -a "$TEST_LOG"
            else
                echo "❌ Full recovery test failed" | tee -a "$TEST_LOG"
            fi
        fi
    }
    
    test_quick_recovery
    test_full_recovery
    
    # Cleanup test directory
    rm -rf "$TEST_DIR"
    
    echo "Monthly recovery test completed at $(date)" | tee -a "$TEST_LOG"
}

monthly_recovery_test
```

## 📈 Backup Metrics & Reporting

### Key Metrics to Track

- **Backup Success Rate:** Percentage of successful backups
- **Backup Duration:** Time taken for each backup type
- **Storage Utilization:** Backup storage usage trends
- **Recovery Time:** Time taken for different recovery scenarios
- **Data Integrity:** Backup validation success rates

### Monthly Backup Report

```bash
#!/bin/bash
# Generate monthly backup report

generate_backup_report() {
    REPORT_FILE="/tmp/backup_report_$(date +%Y%m).html"
    
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Monthly Backup Report - $(date +"%B %Y")</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Monthly Backup Report - $(date +"%B %Y")</h1>
    
    <h2>Backup Statistics</h2>
    <table>
        <tr><th>Metric</th><th>Value</th><th>Status</th></tr>
        <tr><td>Daily Backups</td><td>$(ls /backups/daily/*.tar.gz 2>/dev/null | wc -l)</td><td class="success">✅</td></tr>
        <tr><td>Weekly Backups</td><td>$(ls /backups/weekly/*.tar.gz 2>/dev/null | wc -l)</td><td class="success">✅</td></tr>
        <tr><td>Storage Used</td><td>$(du -sh /backups | cut -f1)</td><td class="success">✅</td></tr>
        <tr><td>Last Backup</td><td>$(stat -c %y $(ls -t /backups/daily/*.tar.gz | head -1) | cut -d. -f1)</td><td class="success">✅</td></tr>
    </table>
    
    <h2>Recovery Tests</h2>
    <p>All recovery tests passed successfully this month.</p>
    
    <h2>Recommendations</h2>
    <ul>
        <li>Continue current backup schedule</li>
        <li>Monitor storage usage trends</li>
        <li>Validate backup integrity regularly</li>
    </ul>
</body>
</html>
EOF

    echo "Backup report generated: $REPORT_FILE"
}

generate_backup_report
```

---

**Last Updated:** July 25, 2025
**Version:** 1.0
**Owner:** Development Workflow Team
**Review Schedule:** Monthly
