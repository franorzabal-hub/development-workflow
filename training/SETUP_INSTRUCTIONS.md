# 🛠️ Setup Instructions

## 📋 Complete Installation Guide

This guide provides step-by-step instructions for setting up the Development Workflow system on your local machine and integrating it with Linear and GitHub.

## 📋 Table of Contents

- [System Requirements](#system-requirements)
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Installation Steps](#installation-steps)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## 💻 System Requirements

### Operating System Support
- ✅ **Linux** (Ubuntu 20.04+, CentOS 8+, any modern distribution)
- ✅ **macOS** (macOS 10.15+ / macOS Catalina or newer)
- ✅ **Windows** (Windows 10+ with WSL2 recommended)

### Hardware Requirements
- **RAM:** 4GB minimum, 8GB recommended
- **Storage:** 2GB free space
- **Network:** Internet connection required for API access

### Software Dependencies

#### Required Dependencies
| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Git** | 2.20+ | Version control | [git-scm.com](https://git-scm.com/downloads) |
| **GitHub CLI** | 2.0+ | GitHub integration | [cli.github.com](https://cli.github.com/) |
| **Bash** | 4.0+ | Script execution | Pre-installed on Linux/macOS |
| **curl** | 7.0+ | API requests | Pre-installed on most systems |

#### Optional Dependencies
| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Python** | 3.10+ | Advanced features | [python.org](https://python.org/downloads) |
| **Node.js** | 16+ | JavaScript tools | [nodejs.org](https://nodejs.org/) |
| **Docker** | 20+ | Containerization | [docker.com](https://docker.com/) |

## ✅ Pre-Installation Checklist

Before starting the installation, ensure you have:

### 1. GitHub Account Access
- [ ] Active GitHub account
- [ ] Repository access permissions
- [ ] Personal access token (if using private repos)

### 2. Linear Workspace Access
- [ ] Linear workspace member
- [ ] Linear API key generated
- [ ] Project management permissions

### 3. Development Environment
- [ ] Terminal/command line access
- [ ] Text editor or IDE installed
- [ ] Network connectivity verified

## 🚀 Installation Steps

### Step 1: Install System Dependencies

#### On Ubuntu/Debian
```bash
# Update package lists
sudo apt update

# Install required packages
sudo apt install -y git curl bash

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

# Optional: Install Python for advanced features
sudo apt install -y python3 python3-pip
```

#### On macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required packages
brew install git gh

# Optional: Install Python for advanced features
brew install python3
```

#### On Windows (WSL2)
```bash
# Enable WSL2 (run in PowerShell as Administrator)
wsl --install

# Once in WSL2, follow Ubuntu instructions above
```

### Step 2: Verify Installations

```bash
# Verify Git
git --version
# Expected: git version 2.x.x or higher

# Verify GitHub CLI
gh --version
# Expected: gh version 2.x.x or higher

# Verify Bash
bash --version
# Expected: GNU bash, version 4.x.x or higher

# Verify curl
curl --version
# Expected: curl 7.x.x or higher

# Optional: Verify Python
python3 --version
# Expected: Python 3.10.x or higher
```

### Step 3: Authenticate with Services

#### GitHub Authentication
```bash
# Authenticate with GitHub
gh auth login

# Choose authentication method:
# 1. Login with a web browser (recommended)
# 2. Paste an authentication token

# Verify authentication
gh auth status
```

#### Linear API Key Setup
```bash
# Get your Linear API key from: https://linear.app/settings/api
# Look for "Personal API keys" section

# Set environment variable (temporary)
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Make it permanent by adding to your shell profile
echo 'export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"' >> ~/.bashrc
source ~/.bashrc

# For zsh users:
echo 'export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"' >> ~/.zshrc
source ~/.zshrc
```

### Step 4: Clone and Setup Repository

```bash
# Clone the development workflow repository
git clone https://github.com/franorzabal-hub/development-workflow.git

# Navigate to the repository
cd development-workflow

# Make scripts executable
chmod +x scripts/*.sh

# Verify script permissions
ls -la scripts/
```

### Step 5: Initial Configuration

```bash
# Run setup script to configure Linear states
./scripts/setup-linear-states.sh

# Expected output:
# ✅ Linear API connection verified
# ✅ State IDs retrieved and saved
# ✅ Configuration file created: scripts/linear-env.sh

# Validate all dependencies
./scripts/validate-dependencies.sh

# Expected output:
# ✅ Git: Available
# ✅ GitHub CLI: Authenticated
# ✅ Linear API: Connected
# ✅ All dependencies: PASSED
```

## ⚙️ Configuration

### Basic Configuration

The setup script creates a configuration file at `scripts/linear-env.sh`:

```bash
# View configuration
cat scripts/linear-env.sh

# Example content:
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"
export LINEAR_TODO_STATE_ID="todo-state-id"
export LINEAR_IN_PROGRESS_STATE_ID="in-progress-state-id"
export LINEAR_IN_REVIEW_STATE_ID="in-review-state-id"
export LINEAR_DONE_STATE_ID="done-state-id"
```

### Advanced Configuration

#### Custom Team Settings
```bash
# Create team-specific configuration
cp scripts/linear-env.sh scripts/linear-env-team.sh

# Edit team configuration
vim scripts/linear-env-team.sh

# Add team-specific variables:
export LINEAR_TEAM_ID="your-team-id"
export LINEAR_PROJECT_ID="your-project-id"
```

#### Git Configuration
```bash
# Configure Git user (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Configure Git editor (optional)
git config --global core.editor "vim"  # or "code" for VSCode
```

#### GitHub CLI Configuration
```bash
# Set default editor for GitHub CLI
gh config set editor vim  # or "code" for VSCode

# Set default protocol
gh config set git_protocol https
```

### Environment Variables Reference

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `LINEAR_API_KEY` | Your Linear API key | ✅ Yes | `lin_api_abc123...` |
| `LINEAR_TODO_STATE_ID` | Linear "Todo" state ID | ✅ Yes | `state-abc123...` |
| `LINEAR_IN_PROGRESS_STATE_ID` | Linear "In Progress" state ID | ✅ Yes | `state-def456...` |
| `LINEAR_IN_REVIEW_STATE_ID` | Linear "In Review" state ID | ✅ Yes | `state-ghi789...` |
| `LINEAR_DONE_STATE_ID` | Linear "Done" state ID | ✅ Yes | `state-jkl012...` |
| `LINEAR_TEAM_ID` | Specific team ID | ❌ No | `team-abc123...` |
| `LINEAR_PROJECT_ID` | Specific project ID | ❌ No | `project-abc123...` |
| `GITHUB_TOKEN` | GitHub personal access token | ❌ No | `ghp_abc123...` |

## ✅ Verification

### Test Basic Functionality

```bash
# Test Linear connection
./scripts/test-linear-connection.sh
# Expected: ✅ Linear API connection successful

# Test GitHub connection
gh api user
# Expected: JSON response with your GitHub user info

# Test script execution
./scripts/start-development.sh --help
# Expected: Help message displaying script usage
```

### Test Complete Workflow (Optional)

```bash
# Create a test Linear issue first, then:
# Replace FRA-TEST with your test issue ID

# Test start development
./scripts/start-development.sh FRA-TEST --dry-run

# Test validation
./scripts/test-and-validate.sh FRA-TEST --dry-run

# Test finish development
./scripts/finish-development.sh FRA-TEST --dry-run
```

### Install Workflow Aliases (Recommended)

```bash
# Install convenient aliases
./scripts/claude-aliases.sh install

# Reload shell configuration
source ~/.bashrc  # or ~/.zshrc

# Test aliases
claude-help
claude-status
```

## 🐛 Troubleshooting

### Common Installation Issues

#### Issue: "Permission denied" when running scripts
```bash
# Solution: Make scripts executable
chmod +x scripts/*.sh

# Or fix all files at once
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

#### Issue: "GitHub CLI not authenticated"
```bash
# Check authentication status
gh auth status

# If not authenticated, login again
gh auth login

# If having issues, try token authentication
gh auth login --with-token < your-token-file.txt
```

#### Issue: "Linear API key invalid"
```bash
# Verify API key format (should start with "lin_api_")
echo $LINEAR_API_KEY

# Re-generate API key at: https://linear.app/settings/api
# Update environment variable and reload shell
```

#### Issue: "Command not found: gh"
```bash
# Check if GitHub CLI is in PATH
which gh

# If not found, reinstall GitHub CLI
# Follow installation instructions for your OS above
```

#### Issue: "Git authentication failed"
```bash
# Configure Git credentials
git config --global credential.helper store

# Or use SSH keys (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add the key to GitHub: https://github.com/settings/keys
```

### Advanced Troubleshooting

#### Enable Debug Mode
```bash
# Run scripts with debug output
DEBUG=1 ./scripts/start-development.sh FRA-XX

# Enable verbose GitHub CLI output
gh --debug api user
```

#### Check System Dependencies
```bash
# Verify all required tools
./scripts/validate-dependencies.sh --verbose

# Check specific tool versions
git --version && gh --version && bash --version
```

#### Network Connectivity Issues
```bash
# Test GitHub API connectivity
curl -s https://api.github.com/user -H "Authorization: token $(gh auth token)"

# Test Linear API connectivity
curl -s https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { name } }"}'
```

## 🔧 Advanced Configuration

### Team Customization

#### Custom Workflow States
```bash
# Edit Linear state configuration
vim scripts/linear-env.sh

# Add custom states
export LINEAR_BLOCKED_STATE_ID="blocked-state-id"
export LINEAR_TESTING_STATE_ID="testing-state-id"
```

#### Custom Branch Naming
```bash
# Create custom branch naming configuration
echo 'export BRANCH_PREFIX="feature"' >> scripts/custom-config.sh
echo 'export BRANCH_FORMAT="$BRANCH_PREFIX/$USER/$ISSUE_ID"' >> scripts/custom-config.sh
```

### Integration with IDEs

#### VSCode Integration
```bash
# Install recommended VSCode extensions
code --install-extension ms-vscode.vscode-json
code --install-extension ms-python.python
code --install-extension GitHub.vscode-pull-request-github

# Create VSCode workspace settings
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
    "terminal.integrated.shell.linux": "/bin/bash",
    "terminal.integrated.cwd": "${workspaceFolder}",
    "files.associations": {
        "*.sh": "shellscript"
    }
}
EOF
```

#### Git Hooks Setup
```bash
# Install pre-commit hooks
cp hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# The hook will automatically run validation before commits
```

### Performance Optimization

#### Cache Configuration
```bash
# Enable Git credential caching
git config --global credential.helper cache

# Set cache timeout (in seconds)
git config --global credential.helper 'cache --timeout=3600'
```

#### Parallel Processing
```bash
# Enable parallel test execution
echo 'export PARALLEL_TESTS=true' >> scripts/custom-config.sh
echo 'export MAX_PARALLEL_JOBS=4' >> scripts/custom-config.sh
```

## 🎯 Next Steps

After successful installation:

1. **Complete Training**
   - Read [Developer Workflow Guide](DEVELOPER_WORKFLOW_GUIDE.md)
   - Review [Best Practices](BEST_PRACTICES.md)
   - Practice with test issues

2. **Team Onboarding**
   - Share setup instructions with team
   - Customize workflow for team needs
   - Establish team conventions

3. **Monitoring and Maintenance**
   - Set up monitoring dashboards
   - Schedule regular updates
   - Monitor usage metrics

## 📞 Support

If you encounter issues during setup:

1. **Check Documentation**
   - Review [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
   - Check [FAQ section](DEVELOPER_WORKFLOW_GUIDE.md#frequently-asked-questions)

2. **Get Help**
   - Create GitHub issue with setup details
   - Include output from `./scripts/validate-dependencies.sh --verbose`
   - Contact team lead or DevOps support

3. **Community Resources**
   - GitHub Discussions
   - Team Slack channels
   - Internal documentation

---

**🎉 Congratulations! Your development workflow is now ready to use.**

*Next: Complete the [Developer Workflow Training Guide](DEVELOPER_WORKFLOW_GUIDE.md)*