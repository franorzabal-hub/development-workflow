# 🚀 Developer Workflow Training Guide

## 📋 Table of Contents

- [Welcome to the Development Workflow](#welcome-to-the-development-workflow)
- [Prerequisites](#prerequisites)
- [Quick Start Tutorial](#quick-start-tutorial)
- [Complete Workflow Walkthrough](#complete-workflow-walkthrough)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Frequently Asked Questions](#frequently-asked-questions)

## 🎯 Welcome to the Development Workflow

This guide will teach you how to use our automated development workflow that integrates Linear project management with GitHub development processes. By the end of this training, you'll be able to:

- Start development work from Linear issues
- Run comprehensive tests automatically
- Create pull requests with rich metadata
- Maintain high code quality standards
- Handle errors and rollbacks effectively

## ⚙️ Prerequisites

Before starting, ensure you have:

### Required Tools
- ✅ **Git** - Version control system
- ✅ **GitHub CLI** - Authenticated with your GitHub account
- ✅ **Linear API Key** - For issue synchronization
- ✅ **Bash Shell** - Linux/macOS terminal or WSL on Windows

### Optional Tools (for advanced features)
- 📦 **Python 3.10+** - For advanced monitoring and analytics
- 🐳 **Docker** - For containerized testing (if applicable)
- 🔧 **VSCode** - Recommended IDE with Git integration

### Verification Commands
```bash
# Verify Git installation
git --version

# Verify GitHub CLI authentication
gh auth status

# Verify Linear API key (should be set)
echo $LINEAR_API_KEY | grep -q "lin_api" && echo "✅ Linear API key configured" || echo "❌ Linear API key missing"

# Verify bash shell
echo $SHELL
```

## 🚀 Quick Start Tutorial

### Step 1: Clone and Setup

```bash
# Clone the development workflow repository
git clone https://github.com/franorzabal-hub/development-workflow.git
cd development-workflow

# Make scripts executable
chmod +x scripts/*.sh

# Set your Linear API key
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Run initial setup
./scripts/setup-linear-states.sh

# Validate all dependencies
./scripts/validate-dependencies.sh
```

### Step 2: Your First Workflow

Let's walk through developing a simple feature:

```bash
# 1. Start development for a Linear issue (replace FRA-XX with your issue)
./scripts/start-development.sh FRA-XX

# 2. Make your changes
# Edit files, implement features, etc.

# 3. Test your changes
./scripts/test-and-validate.sh FRA-XX

# 4. Create pull request and finish
./scripts/finish-development.sh FRA-XX
```

### Step 3: Install Convenient Aliases (Optional)

```bash
# Install workflow aliases for easier commands
./scripts/claude-aliases.sh install

# Source the aliases
source ~/.bashrc  # or ~/.zshrc depending on your shell

# Now you can use simplified commands:
claude-start FRA-XX    # Start development
claude-test FRA-XX     # Run tests
claude-finish FRA-XX   # Create PR
```

## 📖 Complete Workflow Walkthrough

### Phase 1: Starting Development

#### Command: `./scripts/start-development.sh FRA-XX`

**What happens:**
1. **Linear Issue Validation**
   - Fetches issue details from Linear
   - Validates issue exists and is accessible
   - Displays issue information for confirmation

2. **Branch Management**
   - Creates a new branch from main
   - Branch naming: `username/FRA-XX-issue-title-slug`
   - Switches to the new branch

3. **Environment Setup**
   - Updates Linear issue status to "In Progress"
   - Creates implementation plan
   - Sets up development environment

**Output Example:**
```
🚀 Starting development for FRA-42: Sprint 1 Core Scripts Development

✅ Linear issue validated
✅ Branch 'franorzabal/fra-42-sprint-1-core-scripts-development' created
✅ Linear status updated to 'In Progress'
✅ Implementation plan generated

📋 Implementation Plan:
- Enhance start-development.sh with error handling
- Improve test-and-validate.sh with coverage
- Add rollback capabilities to finish-development.sh

🎯 Ready to start development!
```

### Phase 2: Development Work

During development, you can:

#### Check Status
```bash
# Check current workflow status
claude-status

# View current Linear issue details
claude-issue FRA-XX
```

#### Make Changes
- Edit files using your preferred editor
- Commit changes regularly with good commit messages
- Use conventional commit formats: `feat:`, `fix:`, `docs:`, etc.

#### Example Development Session
```bash
# Make your changes
vim scripts/start-development.sh

# Commit your changes
git add scripts/start-development.sh
git commit -m "feat: add comprehensive error handling to start-development script"

# Push changes (optional, will be done automatically later)
git push origin franorzabal/fra-42-sprint-1-core-scripts-development
```

### Phase 3: Testing and Validation

#### Command: `./scripts/test-and-validate.sh FRA-XX`

**What happens:**
1. **Code Quality Checks**
   - Code formatting with Black and isort
   - Linting with flake8 and mypy
   - Security scanning with Bandit

2. **Automated Testing**
   - Unit tests with pytest
   - Integration tests if available
   - Coverage reporting (target: 90%+)

3. **Validation Reports**
   - Quality gate validation
   - Performance benchmarks
   - Security scan results

**Quality Gates:**
- ✅ Code coverage > 90%
- ✅ All linting checks pass
- ✅ Security scan grade A
- ✅ All tests pass
- ✅ No breaking changes

**Output Example:**
```
🧪 Running comprehensive validation for FRA-42

📋 Code Quality Checks:
✅ Black formatting: PASSED
✅ isort imports: PASSED
✅ flake8 linting: PASSED
✅ mypy type checking: PASSED
✅ Bandit security: GRADE A

🧪 Test Execution:
✅ Unit tests: 45/45 PASSED
✅ Integration tests: 12/12 PASSED
✅ Coverage: 94.2% (Target: 90%+)

🎯 All quality gates PASSED! Ready for PR creation.
```

### Phase 4: Pull Request and Completion

#### Command: `./scripts/finish-development.sh FRA-XX`

**What happens:**
1. **Final Validation**
   - Runs complete test suite one more time
   - Ensures all commits are properly formatted
   - Validates branch is up to date

2. **Pull Request Creation**
   - Creates PR with comprehensive metadata
   - Links to Linear issue automatically
   - Includes coverage reports and test results

3. **Linear Integration**
   - Updates Linear issue status to "In Review"
   - Adds PR link to Linear issue
   - Creates rich completion report

**PR Template includes:**
- Linear issue details and links
- Implementation summary
- Test coverage report
- Quality gate results
- Breaking change indicators
- Review checklist

**Output Example:**
```
🏁 Finishing development for FRA-42

✅ Final validation: PASSED
✅ Pull request created: #123
✅ Linear issue updated to 'In Review'
✅ PR linked to Linear issue

🔗 Pull Request: https://github.com/franorzabal-hub/development-workflow/pull/123
📋 Linear Issue: https://linear.app/franorzabal/issue/FRA-42

🎉 Development workflow completed successfully!
```

## 🔄 Advanced Features

### Rollback Capabilities

If something goes wrong, you can rollback:

```bash
# Rollback to previous state
claude-rollback FRA-XX

# This will:
# - Reset branch to last known good state
# - Update Linear issue status
# - Clean up any temporary changes
```

### Custom Validation

Add custom validation rules:

```bash
# Create custom validation script
vim scripts/custom-validation.sh

# The test framework will automatically include it
./scripts/test-and-validate.sh FRA-XX
```

### Performance Monitoring

Monitor script performance:

```bash
# Generate performance report
claude-performance FRA-XX

# View metrics dashboard (if Python is available)
python3 scripts/enhanced-metrics-dashboard.py
```

### Batch Operations

Work with multiple issues:

```bash
# Start multiple issues
claude-start FRA-XX FRA-YY FRA-ZZ

# Test multiple branches
claude-test-all

# Create PRs for multiple issues
claude-finish-all
```

## 📝 Best Practices

### Issue Management
- ✅ Always start from a valid Linear issue
- ✅ Keep issue titles descriptive and clear
- ✅ Update issue status regularly
- ✅ Link related issues when appropriate

### Branch Management
- ✅ Use the automated branch naming convention
- ✅ Keep branches focused on single issues
- ✅ Regularly sync with main branch
- ✅ Delete branches after PR merge

### Commit Messages
- ✅ Use conventional commit format
- ✅ Write clear, descriptive messages
- ✅ Reference Linear issue in commits
- ✅ Keep commits atomic and focused

### Testing
- ✅ Run tests before committing
- ✅ Maintain > 90% code coverage
- ✅ Write tests for new features
- ✅ Include integration tests when applicable

### Code Quality
- ✅ Follow project coding standards
- ✅ Use automated formatting tools
- ✅ Address all linting warnings
- ✅ Ensure security scan passes

### Pull Requests
- ✅ Fill out PR template completely
- ✅ Include screenshots for UI changes
- ✅ Request appropriate reviewers
- ✅ Respond to review feedback promptly

## 🐛 Troubleshooting

### Common Issues and Solutions

#### Issue: "Linear API key not found"
```bash
# Solution: Set your Linear API key
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Or add to your shell profile
echo 'export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"' >> ~/.bashrc
source ~/.bashrc
```

#### Issue: "GitHub CLI not authenticated"
```bash
# Solution: Authenticate with GitHub
gh auth login

# Follow the prompts to authenticate
```

#### Issue: "Linear issue not found"
```bash
# Verify issue ID is correct
claude-issue FRA-XX

# Check if you have access to the Linear workspace
# Verify API key has proper permissions
```

#### Issue: "Tests failing on coverage"
```bash
# Check which files need more coverage
./scripts/test-and-validate.sh FRA-XX --coverage-report

# Add tests for uncovered code
# Re-run validation
```

#### Issue: "Branch conflicts with main"
```bash
# Update your branch with latest main
git checkout main
git pull origin main
git checkout your-branch-name
git rebase main

# Resolve any conflicts
# Re-run tests
./scripts/test-and-validate.sh FRA-XX
```

#### Issue: "Script permissions denied"
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Or fix specific script
chmod +x scripts/start-development.sh
```

### Getting Help

1. **Check Documentation**
   - Review [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
   - Check [API_REFERENCE.md](../API_REFERENCE.md)

2. **Use Debug Mode**
   ```bash
   # Run scripts with debug output
   DEBUG=1 ./scripts/start-development.sh FRA-XX
   ```

3. **Check Logs**
   ```bash
   # View workflow logs
   tail -f ~/.claude-workflow.log
   ```

4. **Contact Support**
   - Create GitHub issue with error details
   - Include script output and environment info

## ❓ Frequently Asked Questions

### Q: Can I use this workflow with private repositories?
**A:** Yes, the workflow supports both public and private repositories. Ensure your GitHub CLI is authenticated with appropriate permissions.

### Q: What if I need to work on multiple issues simultaneously?
**A:** You can work on multiple issues by creating separate branches for each. Use the branch switching capabilities in your IDE or Git commands.

### Q: How do I customize the PR template?
**A:** Edit the `.github/pull_request_template.md` file in your repository to customize the PR template.

### Q: Can I skip certain quality checks?
**A:** While not recommended, you can use environment variables to skip specific checks:
```bash
SKIP_FORMATTING=1 ./scripts/test-and-validate.sh FRA-XX
```

### Q: How do I handle breaking changes?
**A:** Mark breaking changes in your commit messages and PR description. The workflow will automatically flag them for additional review.

### Q: What if Linear is down or unavailable?
**A:** The workflow includes graceful degradation. You can continue development and sync with Linear once it's available.

### Q: How do I update to the latest workflow version?
**A:** Pull the latest changes from the main branch:
```bash
git checkout main
git pull origin main
```

## 🎓 Training Completion

Congratulations! You've completed the Developer Workflow Training. You should now be able to:

- ✅ Start development from Linear issues
- ✅ Run comprehensive testing pipelines
- ✅ Create pull requests with rich metadata
- ✅ Handle common issues and troubleshoot problems
- ✅ Follow best practices for quality and collaboration

### Next Steps

1. **Practice** - Try the workflow with a test issue
2. **Customize** - Adapt the workflow to your team's needs
3. **Share** - Help other team members learn the workflow
4. **Improve** - Contribute back improvements and suggestions

### Additional Resources

- 📖 [Setup Instructions](SETUP_INSTRUCTIONS.md)
- 📋 [Best Practices Guide](BEST_PRACTICES.md)
- 🔧 [Quick Reference Card](QUICK_REFERENCE.md)
- 🎯 [Training Modules](TRAINING_MODULES.md)

---

**Happy Developing! 🚀**

*For questions or support, please create an issue in the repository or contact the development team.*