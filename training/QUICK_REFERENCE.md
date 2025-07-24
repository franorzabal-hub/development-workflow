# 🚀 Quick Reference Card

## Essential Commands Cheat Sheet

### 🏁 Basic Workflow
```bash
# Start development
./scripts/start-development.sh FRA-123

# Run tests and validation
./scripts/test-and-validate.sh FRA-123

# Create PR and finish
./scripts/finish-development.sh FRA-123
```

### 🔧 With Aliases (Install first: `./scripts/claude-aliases.sh install`)
```bash
# Simplified workflow
claude-start FRA-123    # Start development
claude-test FRA-123     # Run tests
claude-finish FRA-123   # Create PR

# Status and info
claude-status           # Current workflow status
claude-issue FRA-123    # View issue details
claude-help            # Show all commands
```

## 📋 Setup Commands

### Initial Setup
```bash
# Clone repository
git clone https://github.com/franorzabal-hub/development-workflow.git
cd development-workflow

# Set permissions and configure
chmod +x scripts/*.sh
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"
./scripts/setup-linear-states.sh
./scripts/validate-dependencies.sh
```

### Verify Installation
```bash
# Check all dependencies
./scripts/validate-dependencies.sh

# Test connections
gh auth status                    # GitHub authentication
echo $LINEAR_API_KEY | head -c 20 # Linear API key (masked)
```

## 🔄 Git Commands

### Branch Management
```bash
# Check current status
git status
git branch -a

# Switch branches
git checkout main
git checkout your-branch-name

# Update branch
git pull origin main
git rebase origin/main
```

### Commit Guidelines
```bash
# Recommended commit format
git commit -m "feat: add retry logic to API calls"
git commit -m "fix: resolve timeout in validation"
git commit -m "docs: update setup instructions"

# Commit types: feat, fix, docs, style, refactor, test, chore
```

## 🧪 Testing Commands

### Run Tests
```bash
# Full validation suite
./scripts/test-and-validate.sh FRA-123

# Individual test components
pytest tests/ -v                 # Python tests
black --check scripts/          # Code formatting
flake8 scripts/                 # Linting
bandit -r scripts/              # Security scan
```

### Coverage Reports
```bash
# Generate coverage report
pytest --cov=scripts --cov-report=html tests/

# View coverage
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

## 🔍 Debugging Commands

### Debug Mode
```bash
# Enable debug output
DEBUG=1 ./scripts/start-development.sh FRA-123
DEBUG=1 ./scripts/test-and-validate.sh FRA-123

# Verbose GitHub CLI
gh --debug api user
gh --debug pr list
```

### Check Logs
```bash
# View workflow logs
tail -f ~/.claude-workflow.log

# Check git log
git log --oneline -10
git log --graph --oneline
```

## 📊 Linear Integration

### Issue Management
```bash
# View issue details (if aliases installed)
claude-issue FRA-123

# Check issue status
curl -s "https://api.linear.app/graphql" \
  -H "Authorization: $LINEAR_API_KEY" \
  -d '{"query": "{ issue(id: \"ISSUE_ID\") { title status { name } } }"}'
```

### Status Updates
| Script Phase | Linear Status |
|--------------|---------------|
| start-development | In Progress |
| test-and-validate | In Progress |
| finish-development | In Review |
| PR merged | Done |

## 🐙 GitHub Integration

### Repository Commands
```bash
# View repo status
gh repo view
gh pr list
gh pr status

# Create PR manually
gh pr create --title "Title" --body "Description"

# Check Actions status
gh run list
gh run view [run-id]
```

### PR Management
```bash
# View PRs
gh pr list --state open
gh pr view 123
gh pr diff 123

# Review PRs
gh pr review 123 --approve
gh pr review 123 --request-changes
```

## ⚙️ Environment Variables

### Required Variables
```bash
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"
export LINEAR_TODO_STATE_ID="state-id"
export LINEAR_IN_PROGRESS_STATE_ID="state-id"
export LINEAR_IN_REVIEW_STATE_ID="state-id" 
export LINEAR_DONE_STATE_ID="state-id"
```

### Optional Variables
```bash
export DEBUG=1                    # Enable debug mode
export SKIP_TESTS=1              # Skip test execution
export SKIP_FORMATTING=1         # Skip code formatting
export PARALLEL_TESTS=true       # Enable parallel testing
export MAX_PARALLEL_JOBS=4       # Set parallel job limit
```

## 🚨 Troubleshooting Quick Fixes

### Common Issues
```bash
# Permission denied
chmod +x scripts/*.sh

# GitHub not authenticated
gh auth login

# Linear API key issues
echo $LINEAR_API_KEY | head -c 20  # Check if set
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Git conflicts
git status                        # Check conflicts
git rebase --abort               # Abort rebase
git checkout main && git pull    # Start fresh
```

### Reset Workflow
```bash
# If workflow gets stuck
git checkout main
git branch -D problematic-branch
git pull origin main
# Start over with ./scripts/start-development.sh FRA-123
```

## 📁 Directory Structure

```
development-workflow/
├── scripts/                 # Main workflow scripts
│   ├── start-development.sh
│   ├── test-and-validate.sh
│   ├── finish-development.sh
│   ├── claude-aliases.sh
│   └── linear-env.sh
├── docs/                    # Documentation
├── training/               # Training materials
├── tests/                  # Test files
├── .github/               # GitHub workflows
└── README.md              # Main documentation
```

## 🎯 Quality Gates Checklist

### Before Commit
- [ ] Code formatted (Black, isort)
- [ ] Linting passes (flake8, mypy)
- [ ] Tests written and passing
- [ ] Coverage > 90%
- [ ] Security scan passes

### Before PR
- [ ] All quality gates pass
- [ ] Documentation updated
- [ ] Issue linked to PR
- [ ] Descriptive PR title/description
- [ ] Breaking changes noted

## 📞 Getting Help

### Documentation
- [Developer Workflow Guide](DEVELOPER_WORKFLOW_GUIDE.md)
- [Setup Instructions](SETUP_INSTRUCTIONS.md)
- [Best Practices](BEST_PRACTICES.md)
- [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)

### Commands for Help
```bash
# Script help
./scripts/start-development.sh --help
./scripts/test-and-validate.sh --help
./scripts/finish-development.sh --help

# Alias help (if installed)
claude-help

# GitHub CLI help
gh help
gh pr --help
```

### Support Channels
- 🐛 **GitHub Issues**: Report bugs or request features
- 📖 **Documentation**: Check docs/ directory
- 👥 **Team Chat**: Ask in team Slack/Discord
- 📧 **Email Support**: development-team@company.com

## 🔗 Useful Links

### Linear
- [Linear App](https://linear.app/)
- [Linear API Docs](https://developers.linear.app/)
- [Personal API Keys](https://linear.app/settings/api)

### GitHub
- [GitHub CLI Docs](https://cli.github.com/manual/)
- [GitHub Actions](https://github.com/features/actions)
- [Repository](https://github.com/franorzabal-hub/development-workflow)

### Development
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Python Style Guide](https://pep8.org/)
- [Git Documentation](https://git-scm.com/doc)

## 📱 Mobile Quick Access

### Essential One-Liners
```bash
# Complete workflow in 3 commands
./scripts/start-development.sh FRA-123 && \
./scripts/test-and-validate.sh FRA-123 && \
./scripts/finish-development.sh FRA-123

# With aliases
claude-start FRA-123 && claude-test FRA-123 && claude-finish FRA-123

# Emergency reset
git checkout main && git pull && git branch -D $(git branch --show-current)
```

### Status Checks
```bash
# Quick status overview
echo "Git: $(git branch --show-current)"
echo "GitHub: $(gh auth status 2>&1 | head -1)"
echo "Linear: $(test -n "$LINEAR_API_KEY" && echo "✅ Set" || echo "❌ Missing")"
```

---

## 🎯 Pro Tips

💡 **Tip 1**: Use `claude-status` to quickly check your current workflow state

💡 **Tip 2**: Always run `./scripts/validate-dependencies.sh` after system updates

💡 **Tip 3**: Keep your Linear API key in your shell profile for persistence

💡 **Tip 4**: Use `DEBUG=1` when scripts aren't behaving as expected

💡 **Tip 5**: Bookmark this quick reference for easy access during development

---

**🚀 Happy developing! Keep this reference handy for quick access to all essential commands.**

*Last updated: Sprint 4 - Production Ready*