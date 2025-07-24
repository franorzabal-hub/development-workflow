# 🚀 Deployment Guide

## 📋 Overview

Esta guía proporciona instrucciones detalladas para deployar el **Development Workflow - Linear ↔ GitHub Integration** desde cero hasta producción.

## 🎯 Prerequisites

### **Environment Requirements:**
- **Unix/Linux/macOS** - Terminal con bash/zsh
- **Git** - Versión 2.0+ 
- **GitHub CLI (`gh`)** - Para integration con GitHub
- **Python** - 3.8+ (recomendado 3.11)
- **curl/wget** - Para API calls

### **Access Requirements:**
- **GitHub Account** - Con permisos de admin en repositorio
- **Linear Account** - Con API access
- **Linear API Key** - Con permisos de read/write en workspace

## 🔧 Step 1: Repository Setup

### **1.1 Clone Repository:**
```bash
git clone https://github.com/franorzabal-hub/development-workflow.git
cd development-workflow
```

### **1.2 Verify Repository Structure:**
```bash
# Check all required directories exist
ls -la
# Should see: scripts/, tests/, .github/, docs/

# Verify scripts are present
ls scripts/
# Should see: start-development.sh, test-and-validate.sh, finish-development.sh, etc.
```

### **1.3 Set Script Permissions:**
```bash
# Make all shell scripts executable
chmod +x scripts/*.sh

# Verify permissions
ls -la scripts/*.sh
# All should show -rwxr-xr-x permissions
```

## 🔑 Step 2: API Configuration

### **2.1 Linear API Setup:**

#### **Obtain Linear API Key:**
1. Go to Linear → Settings → API
2. Create new Personal API Key
3. Copy the key (starts with `lin_api_`)

#### **Configure Linear API:**
```bash
# Set environment variable
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxxxxxxxxxxxxx"

# Verify API access
curl -H "Authorization: $LINEAR_API_KEY" \
     -H "Content-Type: application/json" \
     https://api.linear.app/graphql \
     -d '{"query":"{ viewer { id name email } }"}'
```

### **2.2 GitHub Configuration:**

#### **GitHub CLI Setup:**
```bash
# Install GitHub CLI (if not installed)
# macOS: brew install gh
# Ubuntu: sudo apt install gh

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

#### **Repository Permissions:**
```bash
# Verify repository access
gh repo view franorzabal-hub/development-workflow

# Check if you have admin permissions
gh api repos/franorzabal-hub/development-workflow | jq .permissions
```

## ⚙️ Step 3: Initial Setup & Validation

### **3.1 Setup Linear States:**
```bash
# Run Linear states setup
./scripts/setup-linear-states.sh

# This will:
# - Connect to Linear API
# - Discover available states
# - Create environment configuration
# - Save state IDs for workflow use
```

### **3.2 Validate Dependencies:**
```bash
# Run comprehensive dependency validation
./scripts/validate-dependencies.sh

# This checks:
# - All required tools are installed
# - API keys are configured
# - Permissions are correct
# - Network connectivity works
```

### **3.3 Test Basic Workflow:**
```bash
# Test with a simple issue (replace FRA-XX with actual issue)
./scripts/start-development.sh FRA-XX

# This should:
# - Fetch issue details from Linear
# - Create GitHub branch
# - Update Linear issue status
# - Provide next steps
```

## 🔐 Step 4: GitHub Actions Configuration

### **4.1 Configure Repository Secrets:**

#### **Navigate to Repository Settings:**
1. Go to GitHub repository: `franorzabal-hub/development-workflow`
2. Settings → Secrets and Variables → Actions
3. Add repository secrets:

#### **Required Secrets:**
```bash
LINEAR_API_KEY = "lin_api_xxxxxxxxxxxxxxxxxxxxxxxx"
LINEAR_IN_PROGRESS_STATE_ID = "11abbfd9-26f9-4ccc-8faf-60897b2fa7a4"
LINEAR_IN_REVIEW_STATE_ID = "e3196231-7a66-462c-a3b8-2d901632478b"
LINEAR_DONE_STATE_ID = "115f3eb3-657a-460c-995b-05b3bbca7795"
```

### **4.2 Enable GitHub Actions:**
```bash
# Verify Actions are enabled
gh api repos/franorzabal-hub/development-workflow | jq .has_actions

# If not enabled, enable via Settings → Actions → General
```

### **4.3 Test GitHub Actions:**
```bash
# Trigger test workflow manually
gh workflow run "test-ultra-basic.yml"

# Monitor workflow execution
gh run list --limit 5

# Check specific run status
gh run view [RUN_ID]
```

## 🧪 Step 5: Testing & Validation

### **5.1 Run Local Tests:**
```bash
# Install test dependencies
pip install -r requirements-test-minimal.txt

# Run basic tests
python -m pytest tests/test_ultra_basic.py -v

# Run comprehensive tests
python -m pytest tests/ -v
```

### **5.2 Test Integration Workflow:**
```bash
# Create test Linear issue first, then:

# 1. Start development
./scripts/start-development.sh [ISSUE_ID]

# 2. Make sample changes
echo "# Test change" >> README.md

# 3. Run validation
./scripts/test-and-validate.sh

# 4. Finish development
./scripts/finish-development.sh [ISSUE_ID]
```

### **5.3 Verify GitHub Actions Execution:**
```bash
# Check latest workflow runs
gh run list

# Verify all workflows pass:
# - ✅ Ultra Basic Tests
# - ✅ Comprehensive Testing
# - ⚠️ Linear Sync (skip if no secrets)
# - ✅ Security Scanning
# - ✅ Documentation
```

## 📊 Step 6: Monitoring Setup

### **6.1 Performance Monitoring:**
```bash
# Start performance monitoring
python3 scripts/performance-monitoring.py &

# This provides real-time monitoring of:
# - System resources
# - API response times
# - Script execution performance
```

### **6.2 Metrics Dashboard:**
```bash
# Generate metrics dashboard
python3 scripts/enhanced-metrics-dashboard.py --action dashboard

# Open generated dashboard
open metrics_dashboard.html
```

### **6.3 Weekly Reporting:**
```bash
# Setup automated weekly reports
python3 scripts/weekly-reporting-automation.py --setup

# Test report generation
python3 scripts/weekly-reporting-automation.py --action generate
```

## 🔄 Step 7: Production Deployment

### **7.1 Environment Configuration:**
```bash
# Create production environment file
cat > .env.production << EOF
ENVIRONMENT=production
LINEAR_API_KEY=${LINEAR_API_KEY}
GITHUB_TOKEN=${GITHUB_TOKEN}
LOG_LEVEL=INFO
MONITORING_ENABLED=true
PERFORMANCE_TRACKING=true
EOF
```

### **7.2 Production Validation:**
```bash
# Run production readiness checklist
./scripts/validate-dependencies.sh --production

# Verify all systems are operational:
# ✅ Linear API connectivity
# ✅ GitHub API connectivity  
# ✅ All scripts executable
# ✅ Monitoring systems active
# ✅ Security scans passing
```

### **7.3 Team Training Setup:**
```bash
# Generate team aliases
source scripts/claude-aliases.sh

# This provides simplified commands:
# - start_dev [ISSUE_ID]
# - run_tests
# - finish_dev [ISSUE_ID]
# - check_status
```

## ✅ Step 8: Go-Live Checklist

### **Pre-Launch Verification:**
- [ ] ✅ **Repository Access** - All team members have access
- [ ] ✅ **API Keys Configured** - Linear and GitHub APIs working
- [ ] ✅ **Scripts Executable** - All permissions set correctly
- [ ] ✅ **GitHub Actions Passing** - All workflows green
- [ ] ✅ **Monitoring Active** - Performance monitoring running
- [ ] ✅ **Documentation Complete** - All guides available
- [ ] ✅ **Team Trained** - All users know the workflow

### **Launch Day Activities:**
```bash
# 1. Final validation
./scripts/validate-dependencies.sh --comprehensive

# 2. Start monitoring
python3 scripts/performance-monitoring.py &

# 3. Generate baseline metrics
python3 scripts/enhanced-metrics-dashboard.py --action both

# 4. Announce go-live to team
echo "🚀 Development Workflow is LIVE!"
```

## 🔧 Step 9: Post-Deployment Configuration

### **9.1 Ongoing Monitoring:**
```bash
# Setup cron jobs for monitoring (optional)
crontab -e

# Add these lines:
# */15 * * * * cd /path/to/development-workflow && python3 scripts/performance-monitoring.py --check
# 0 9 * * 1 cd /path/to/development-workflow && python3 scripts/weekly-reporting-automation.py --action email
```

### **9.2 Regular Maintenance:**
```bash
# Weekly maintenance tasks:
# 1. Update dependencies
pip install -r requirements-test.txt --upgrade

# 2. Run security scans
./scripts/test-and-validate.sh --security-only

# 3. Performance review
python3 scripts/enhanced-metrics-dashboard.py --action analyze

# 4. Documentation updates
# Review and update docs/ as needed
```

## 🚨 Troubleshooting Common Issues

### **Issue: Linear API Connection Failed**
```bash
# Verify API key
echo $LINEAR_API_KEY

# Test API directly
curl -H "Authorization: $LINEAR_API_KEY" https://api.linear.app/graphql -d '{"query":"{ viewer { name } }"}'

# Common solutions:
# - Regenerate API key in Linear
# - Check API key permissions
# - Verify network connectivity
```

### **Issue: GitHub Actions Not Running**
```bash
# Check repository settings
gh api repos/franorzabal-hub/development-workflow | jq .has_actions

# Verify workflow files
ls .github/workflows/

# Manual trigger
gh workflow run "test-ultra-basic.yml"

# Common solutions:
# - Enable Actions in repository settings
# - Check workflow YAML syntax
# - Verify branch protection rules
```

### **Issue: Scripts Not Executable**
```bash
# Fix permissions
chmod +x scripts/*.sh

# Verify
ls -la scripts/*.sh

# If still issues, check file encoding:
file scripts/start-development.sh
```

## 📞 Support & Escalation

### **Self-Service Troubleshooting:**
1. **Check logs:** `scripts/logs/` directory
2. **Run diagnostics:** `./scripts/validate-dependencies.sh --verbose`
3. **Review documentation:** `docs/TROUBLESHOOTING.md`

### **Escalation Path:**
1. **Level 1:** Review troubleshooting guide
2. **Level 2:** Check GitHub Issues/Discussions
3. **Level 3:** Contact system administrator

## 🎯 Success Criteria

### **Deployment Success Indicators:**
- [ ] ✅ **All scripts execute without errors**
- [ ] ✅ **GitHub Actions passing consistently**
- [ ] ✅ **Linear-GitHub sync working bidirectionally**
- [ ] ✅ **Performance monitoring operational**
- [ ] ✅ **Team can use workflow independently**

### **Production Ready Metrics:**
- **Script execution time:** < 5 seconds average
- **GitHub Actions success rate:** > 95%
- **API response time:** < 1 second average
- **System uptime:** > 99% availability
- **Team satisfaction:** > 8/10 rating

---

## 🎉 Congratulations!

If you've completed all steps successfully, your **Development Workflow - Linear ↔ GitHub Integration** is now fully deployed and production-ready! 

Your team now has access to:
- ✅ **Automated development workflow**
- ✅ **Bidirectional Linear-GitHub sync**
- ✅ **Comprehensive quality gates**
- ✅ **Real-time monitoring**
- ✅ **Performance analytics**

Welcome to accelerated, quality-driven development! 🚀

---

*Deployment Guide v1.0 - Sprint 4: Production Ready*
*Last Updated: 24 de julio, 2025*
