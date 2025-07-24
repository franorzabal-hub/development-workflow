# Contributing to Development Workflow - Linear ↔ GitHub Integration

## 🙌 Welcome Contributors!

Thank you for your interest in contributing to our development workflow project! This guide will help you get started with contributing effectively and efficiently.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Style Guidelines](#style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Security Guidelines](#security-guidelines)

## 📜 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

## 🚀 Getting Started

### 📋 Prerequisites

- **Git:** Version 2.28 or higher
- **GitHub CLI:** Latest version (`gh` command)
- **Python:** 3.10 or higher (for testing)
- **Shell:** Bash, Zsh, or compatible shell
- **Linear Account:** Access to the project workspace

### 🛠️ Setup Development Environment

1. **Fork the repository**
   ```bash
   gh repo fork franorzabal-hub/development-workflow
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/development-workflow.git
   cd development-workflow
   ```

3. **Set up the workflow**
   ```bash
   # Validate dependencies
   ./scripts/validate-dependencies.sh
   
   # Setup Linear integration
   ./scripts/setup-linear-states.sh
   
   # Install Claude aliases (optional)
   ./scripts/claude-aliases.sh install
   ```

4. **Configure environment**
   ```bash
   # Required environment variables
   export LINEAR_API_KEY="your_linear_api_key"
   export LINEAR_TEAM_KEY="FRA"  # or your team key
   
   # Source the environment
   source scripts/linear-env.sh
   ```

## 🔄 Development Workflow

### 📝 Creating Issues

1. **Check existing issues** to avoid duplicates
2. **Use appropriate templates:**
   - 🐛 [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml)
   - ✨ [Feature Request](.github/ISSUE_TEMPLATE/feature_request.yml)
   - 📚 [Documentation](.github/ISSUE_TEMPLATE/documentation.yml)
   - 🔒 [Security Issue](.github/ISSUE_TEMPLATE/security.yml)
   - ❓ [Question](.github/ISSUE_TEMPLATE/question.yml)

3. **Link to Linear:** Include Linear issue ID if applicable

### 🌿 Branch Strategy

```bash
# Create feature branch
git checkout -b feature/FRA-XXX-short-description

# Create bugfix branch  
git checkout -b bugfix/FRA-XXX-fix-description

# Create hotfix branch
git checkout -b hotfix/FRA-XXX-urgent-fix
```

### 💻 Development Process

1. **Start development** (if using our workflow)
   ```bash
   ./scripts/start-development.sh FRA-XXX
   ```

2. **Make your changes**
   - Follow our [Style Guidelines](#style-guidelines)
   - Write tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   ./scripts/test-and-validate.sh FRA-XXX
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat(FRA-XXX): Add new feature description"
   ```

## 🔀 Pull Request Process

### 📝 Creating Pull Requests

1. **Use our PR template** - it will be automatically populated
2. **Link Linear issue** in the format: `FRA-XXX`
3. **Complete all checklist items** in the template
4. **Ensure all checks pass:**
   - ✅ All tests passing
   - ✅ Code coverage ≥ 90%
   - ✅ Security scan grade A
   - ✅ No linting errors

### 🏆 Quality Gates

Your PR must meet these requirements:

| Check | Requirement | Status |
|-------|-------------|--------|
| **Tests** | All tests pass | Required |
| **Coverage** | ≥ 90% code coverage | Required |
| **Security** | Grade A security scan | Required |
| **Linting** | No linting errors | Required |
| **Documentation** | Updated if needed | Required |
| **Linear Link** | Issue properly linked | Required |

### 👀 Review Process

1. **Automated checks** run first
2. **Manual review** by maintainers
3. **Address feedback** promptly
4. **Final approval** and merge

### ✅ Merge Criteria

- All automated checks pass
- At least one approving review
- All conversations resolved
- No merge conflicts
- Documentation updated

## 📋 Issue Guidelines

### 🐛 Bug Reports

- Use the bug report template
- Provide detailed reproduction steps
- Include environment information
- Add relevant logs or screenshots

### ✨ Feature Requests

- Clearly describe the problem being solved
- Provide detailed acceptance criteria
- Consider alternative solutions
- Explain the business value

### 📚 Documentation Issues

- Specify the exact location needing improvement
- Suggest specific changes
- Consider the target audience

## 🎨 Style Guidelines

### 🐚 Shell Scripts

```bash
#!/bin/bash
# Use bash shebang
# Add comprehensive error handling
set -euo pipefail

# Use meaningful variable names
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LINEAR_API_KEY="${LINEAR_API_KEY:-}"

# Function documentation
# Description: This function does something important
# Arguments:
#   $1 - First argument description
#   $2 - Second argument description
# Returns:
#   0 on success, 1 on failure
function_name() {
    local arg1="$1"
    local arg2="$2"
    
    # Implementation
}
```

### 🐍 Python Code

```python
#!/usr/bin/env python3
"""Module docstring."""

import os
import sys
from typing import Dict, List, Optional

# Use type hints
def process_data(items: List[str]) -> Dict[str, int]:
    """Process data and return results.
    
    Args:
        items: List of items to process
        
    Returns:
        Dictionary mapping items to counts
    """
    return {item: len(item) for item in items}
```

### 📝 Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
# Format: type(scope): description
feat(FRA-XXX): add new Linear sync functionality
fix(FRA-XXX): resolve authentication issue
docs(FRA-XXX): update setup instructions
test(FRA-XXX): add integration tests
refactor(FRA-XXX): improve error handling
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `ci`: CI/CD changes
- `chore`: Maintenance tasks

### 📁 File Organization

```
development-workflow/
├── .github/
│   ├── workflows/          # GitHub Actions
│   ├── ISSUE_TEMPLATE/     # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md
├── scripts/                # Core workflow scripts
├── docs/                   # Additional documentation
├── tests/                  # Test files
└── README.md
```

## 🧪 Testing Requirements

### 🔧 Test Types

1. **Unit Tests**
   ```bash
   # Test individual script functions
   pytest tests/unit/ -v
   ```

2. **Integration Tests**
   ```bash
   # Test API integrations
   pytest tests/integration/ -v
   ```

3. **End-to-End Tests**
   ```bash
   # Test complete workflows
   ./scripts/test-and-validate.sh FRA-XXX
   ```

### 📊 Coverage Requirements

- **Minimum Coverage:** 90%
- **New Code:** 100% coverage required
- **Critical Paths:** Must be thoroughly tested

### 🧪 Writing Tests

```python
# tests/test_example.py
import unittest
import os
import sys

class TestScriptFunctionality(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures."""
        self.test_data = "sample_data"
        
    def test_script_exists(self):
        """Test that required scripts exist."""
        script_path = "scripts/start-development.sh"
        self.assertTrue(os.path.exists(script_path))
        self.assertTrue(os.access(script_path, os.X_OK))
        
    def test_environment_handling(self):
        """Test environment variable handling."""
        # Test implementation
        pass
        
    def tearDown(self):
        """Clean up after tests."""
        pass
```

## 🔒 Security Guidelines

### 🔐 Security Checklist

- [ ] No secrets or API keys in code
- [ ] Input validation implemented
- [ ] Error messages don't leak sensitive info
- [ ] Dependencies are up to date
- [ ] Security scan passes (Grade A)

### 🛡️ Security Best Practices

1. **Secrets Management**
   ```bash
   # ❌ Don't do this
   LINEAR_API_KEY="lin_api_12345"
   
   # ✅ Do this instead
   LINEAR_API_KEY="${LINEAR_API_KEY:-}"
   if [ -z "$LINEAR_API_KEY" ]; then
       echo "Error: LINEAR_API_KEY environment variable required"
       exit 1
   fi
   ```

2. **Input Validation**
   ```bash
   validate_linear_id() {
       local linear_id="$1"
       
       if [[ ! "$linear_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
           echo "Invalid Linear ID format: $linear_id"
           return 1
       fi
   }
   ```

3. **Error Handling**
   ```bash
   # Always use error handling
   set -euo pipefail
   
   # Trap errors
   trap 'echo "Error on line $LINENO"' ERR
   ```

## 📚 Documentation Standards

### 📖 Documentation Types

1. **README Files**
   - Clear, concise overview
   - Installation instructions
   - Usage examples
   - Contributing guidelines

2. **Code Comments**
   ```bash
   # Function: process_linear_issue
   # Description: Processes a Linear issue and updates its status
   # Arguments:
   #   $1 - Linear issue ID (e.g., FRA-43)
   #   $2 - New status (optional)
   # Returns:
   #   0 on success, 1 on failure
   # Example:
   #   process_linear_issue "FRA-43" "In Progress"
   ```

3. **API Documentation**
   - Clear endpoint descriptions
   - Request/response examples
   - Error codes and handling

### ✍️ Writing Guidelines

- **Clear and Concise:** Use simple, direct language
- **Examples:** Provide practical examples
- **Structure:** Use headings, lists, and formatting
- **Updates:** Keep documentation current with code changes

## 🎯 Review Guidelines

### 👀 For Reviewers

When reviewing PRs, check:

- [ ] **Functionality:** Does it work as intended?
- [ ] **Code Quality:** Is it well-written and maintainable?
- [ ] **Tests:** Are there adequate tests?
- [ ] **Documentation:** Is documentation updated?
- [ ] **Security:** Are there any security concerns?
- [ ] **Performance:** Will it impact performance?

### 📝 Review Comments

- Be constructive and specific
- Suggest improvements with examples
- Ask questions for clarification
- Acknowledge good practices

## 🚀 Release Process

### 📦 Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR:** Breaking changes
- **MINOR:** New features (backward compatible)
- **PATCH:** Bug fixes (backward compatible)

### 🏷️ Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated
- [ ] Security scan passes
- [ ] Performance benchmarks met

## 🤝 Community Guidelines

### 💬 Communication

- **Be Respectful:** Treat everyone with respect
- **Be Patient:** Help newcomers learn
- **Be Collaborative:** Work together toward solutions
- **Be Inclusive:** Welcome diverse perspectives

### 🎉 Recognition

We appreciate all contributions:

- **Contributors:** Listed in CONTRIBUTORS.md
- **Major Features:** Highlighted in release notes
- **Bug Fixes:** Acknowledged in changelogs
- **Documentation:** Credited in documentation

## 📞 Getting Help

### 🆘 Where to Get Help

1. **Documentation:** Check existing docs first
2. **Issues:** Search existing issues
3. **Discussions:** Use GitHub Discussions
4. **Questions:** Use the question issue template

### 📧 Contact

- **Maintainers:** @franorzabal
- **Security Issues:** Use security issue template
- **General Questions:** Create an issue

## 📈 Contribution Metrics

We track and celebrate:

- **Pull Requests:** Number and quality of contributions
- **Issues:** Problem identification and solutions
- **Documentation:** Improvements and additions
- **Community:** Helping others and participation

## 🔄 Continuous Improvement

This project continuously evolves:

- **Feedback:** We welcome suggestions for improvement
- **Processes:** We refine our workflows based on experience
- **Tools:** We adopt new tools that improve our workflow
- **Community:** We grow and learn together

---

## 📜 Agreement

By contributing, you agree that:

- Your contributions will be licensed under the project license
- You have the right to submit your contributions
- You follow our Code of Conduct and guidelines

---

**Thank you for contributing to our development workflow project! 🎉**

---

**Last Updated:** July 24, 2025  
**Version:** 1.0  
**Next Review:** October 24, 2025