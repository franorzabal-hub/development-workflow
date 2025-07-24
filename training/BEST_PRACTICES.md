# 📋 Best Practices Guide

## 🎯 Development Workflow Best Practices

This guide outlines the best practices for using the Development Workflow system effectively, maintaining high code quality, and ensuring smooth team collaboration.

## 📋 Table of Contents

- [Project Management Best Practices](#project-management-best-practices)
- [Git and Branch Management](#git-and-branch-management)
- [Code Quality Standards](#code-quality-standards)
- [Testing Guidelines](#testing-guidelines)
- [Security Best Practices](#security-best-practices)
- [Performance Optimization](#performance-optimization)
- [Documentation Standards](#documentation-standards)
- [Team Collaboration](#team-collaboration)
- [Troubleshooting and Debugging](#troubleshooting-and-debugging)
- [Continuous Improvement](#continuous-improvement)

## 📊 Project Management Best Practices

### Linear Issue Management

#### ✅ DO: Issue Creation and Management
```markdown
✅ Write clear, descriptive issue titles
✅ Include acceptance criteria in issue descriptions
✅ Add appropriate labels and priorities
✅ Estimate effort accurately
✅ Link related issues when applicable
✅ Update issue status regularly
✅ Include screenshots/mockups for UI changes
✅ Break large features into smaller issues
```

#### ❌ DON'T: Common Pitfalls
```markdown
❌ Create vague or unclear issue titles
❌ Start work without acceptance criteria
❌ Skip effort estimation
❌ Forget to update issue status
❌ Work on multiple major issues simultaneously
❌ Ignore issue dependencies
❌ Create oversized issues that take weeks
```

#### Example: Well-Written Issue
```markdown
Title: 🔧 Add retry logic with exponential backoff to API calls

Description:
## Problem
API calls occasionally fail due to rate limiting or temporary outages, 
causing workflow interruptions.

## Solution
Implement retry logic with exponential backoff for all API calls to 
Linear and GitHub APIs.

## Acceptance Criteria
- [ ] Retry failed API calls up to 3 times
- [ ] Use exponential backoff (1s, 2s, 4s delays)
- [ ] Log retry attempts for debugging
- [ ] Handle specific error codes (429, 502, 503)
- [ ] Add configurable retry settings
- [ ] Update error messages to be user-friendly

## Definition of Done
- [ ] Code implemented and tested
- [ ] Unit tests added with 90%+ coverage
- [ ] Documentation updated
- [ ] PR reviewed and approved
- [ ] Integration testing completed
```

### Sprint Planning

#### Sprint Scope Management
- ✅ Plan sprints based on team velocity
- ✅ Include buffer time for unexpected issues
- ✅ Balance feature work with technical debt
- ✅ Define clear sprint goals
- ✅ Review dependencies between issues

#### Daily Workflow
- ✅ Start each day by checking Linear for updates
- ✅ Update issue status before switching tasks
- ✅ Communicate blockers immediately
- ✅ Sync with team on complex issues

## 🌿 Git and Branch Management

### Branch Naming Convention

#### Standard Format
```bash
# Automated format (recommended)
username/FRA-123-feature-description

# Examples:
francisco/FRA-45-add-retry-logic
sarah/FRA-46-improve-error-handling
mike/FRA-47-update-documentation
```

#### Branch Types and Prefixes
```bash
# Feature branches (most common)
username/FRA-123-feature-name

# Bug fixes
username/FRA-123-fix-bug-description

# Documentation updates
username/FRA-123-docs-update-guide

# Refactoring
username/FRA-123-refactor-component

# Emergency hotfixes
hotfix/FRA-123-critical-security-fix
```

### Commit Message Standards

#### Conventional Commits Format
```bash
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Commit Types
| Type | Usage | Example |
|------|-------|---------|
| `feat` | New feature | `feat: add retry logic to API calls` |
| `fix` | Bug fix | `fix: resolve timeout issue in validation` |
| `docs` | Documentation | `docs: update setup instructions` |
| `style` | Code style/formatting | `style: fix linting issues in utils` |
| `refactor` | Code refactoring | `refactor: simplify error handling logic` |
| `test` | Add/update tests | `test: add unit tests for retry logic` |
| `chore` | Maintenance tasks | `chore: update dependencies` |
| `perf` | Performance improvements | `perf: optimize API call batching` |

#### Examples of Good Commit Messages
```bash
# Good: Clear and specific
feat: add exponential backoff to Linear API calls

# Good: Includes scope
fix(validation): handle empty response from GitHub API

# Good: Includes issue reference
feat: implement retry logic for API calls

Addresses rate limiting issues and improves reliability.
Includes configurable retry count and delay settings.

Closes FRA-123
```

#### Examples of Poor Commit Messages
```bash
# Poor: Too vague
fix: stuff

# Poor: Not descriptive
update files

# Poor: Missing type
Added retry logic

# Poor: Too long for title
feat: add retry logic with exponential backoff and configurable settings for handling API failures
```

### Branch Management Workflow

#### Starting Work
```bash
# 1. Always start from latest main
git checkout main
git pull origin main

# 2. Use the workflow script (recommended)
./scripts/start-development.sh FRA-123

# 3. Or create branch manually
git checkout -b francisco/FRA-123-feature-description
```

#### During Development
```bash
# Commit frequently with meaningful messages
git add specific-files  # Avoid 'git add .'
git commit -m "feat: implement basic retry logic structure"

# Push regularly to backup work
git push origin francisco/FRA-123-feature-description

# Stay up to date with main
git fetch origin
git rebase origin/main  # Preferred over merge
```

#### Before Creating PR
```bash
# Final rebase and cleanup
git checkout main
git pull origin main
git checkout francisco/FRA-123-feature-description
git rebase origin/main

# Run full validation
./scripts/test-and-validate.sh FRA-123

# Create PR using workflow
./scripts/finish-development.sh FRA-123
```

## 🏗️ Code Quality Standards

### Code Formatting and Linting

#### Python Code Standards
```python
# ✅ Good: Clear variable names and documentation
def retry_api_call(api_function, max_retries=3, base_delay=1.0):
    """
    Retry an API call with exponential backoff.
    
    Args:
        api_function: Function to call
        max_retries: Maximum number of retry attempts
        base_delay: Base delay in seconds
        
    Returns:
        API response or raises exception after all retries
    """
    for attempt in range(max_retries + 1):
        try:
            return api_function()
        except APIRateLimitError as e:
            if attempt == max_retries:
                raise
            delay = base_delay * (2 ** attempt)
            time.sleep(delay)
```

```python
# ❌ Poor: Unclear names and no documentation
def retry(f, n=3, d=1):
    for i in range(n + 1):
        try:
            return f()
        except Exception as e:
            if i == n:
                raise
            time.sleep(d * (2 ** i))
```

#### Bash Script Standards
```bash
# ✅ Good: Clear structure with error handling
#!/bin/bash
set -euo pipefail  # Strict error handling

# Function documentation
# Validates Linear API connection and retrieves issue details
validate_linear_issue() {
    local issue_id="$1"
    
    if [[ -z "$issue_id" ]]; then
        echo "❌ Error: Issue ID is required"
        return 1
    fi
    
    echo "🔍 Validating Linear issue: $issue_id"
    
    if linear_api_call "issue" "$issue_id"; then
        echo "✅ Linear issue validated successfully"
        return 0
    else
        echo "❌ Failed to validate Linear issue"
        return 1
    fi
}
```

```bash
# ❌ Poor: No error handling or documentation
validate_issue() {
    curl -s $LINEAR_API/issues/$1 > /dev/null
}
```

### Error Handling Patterns

#### Comprehensive Error Handling
```python
# ✅ Good: Specific exception handling
try:
    response = linear_api.get_issue(issue_id)
except requests.exceptions.Timeout:
    logger.error(f"Timeout when fetching issue {issue_id}")
    raise WorkflowError("Linear API timeout - please try again")
except requests.exceptions.ConnectionError:
    logger.error("Connection error to Linear API")
    raise WorkflowError("Cannot connect to Linear - check internet connection")
except LinearAPIError as e:
    if e.status_code == 404:
        raise WorkflowError(f"Issue {issue_id} not found or not accessible")
    elif e.status_code == 429:
        raise WorkflowError("Rate limited by Linear API - please wait")
    else:
        raise WorkflowError(f"Linear API error: {e.message}")
except Exception as e:
    logger.exception("Unexpected error fetching Linear issue")
    raise WorkflowError(f"Unexpected error: {str(e)}")
```

```python
# ❌ Poor: Generic exception handling
try:
    response = linear_api.get_issue(issue_id)
except Exception:
    print("Something went wrong")
    return None
```

## 🧪 Testing Guidelines

### Test Coverage Requirements

#### Coverage Targets
- **Minimum**: 90% line coverage
- **Target**: 95% line coverage
- **Critical paths**: 100% coverage

#### Testing Pyramid
```
        🔺 E2E Tests (5%)
       🔺🔺 Integration Tests (20%)
    🔺🔺🔺🔺 Unit Tests (75%)
```

### Unit Testing Best Practices

#### Test Structure (AAA Pattern)
```python
def test_retry_api_call_with_exponential_backoff():
    """Test that retry logic uses exponential backoff delays."""
    # Arrange
    mock_api = Mock(side_effect=[
        APIRateLimitError("Rate limited"),
        APIRateLimitError("Rate limited"),
        {"status": "success"}
    ])
    
    # Act
    with patch('time.sleep') as mock_sleep:
        result = retry_api_call(mock_api, max_retries=3, base_delay=1.0)
    
    # Assert
    assert result == {"status": "success"}
    assert mock_api.call_count == 3
    mock_sleep.assert_has_calls([
        call(1.0),  # First retry: 1.0 seconds
        call(2.0),  # Second retry: 2.0 seconds
    ])
```

#### Test Naming Convention
```python
# ✅ Good: Descriptive test names
def test_retry_api_call_succeeds_on_first_attempt():
def test_retry_api_call_fails_after_max_retries():
def test_retry_api_call_uses_exponential_backoff():
def test_retry_api_call_with_zero_retries_fails_immediately():

# ❌ Poor: Vague test names
def test_retry():
def test_api_call():
def test_success():
def test_failure():
```

### Integration Testing

#### Test Workflow Integration
```python
def test_complete_development_workflow():
    """Test the complete workflow from start to finish."""
    # Setup test issue in Linear
    test_issue = create_test_linear_issue()
    
    try:
        # Test start development
        result = run_command(f"./scripts/start-development.sh {test_issue.id}")
        assert result.returncode == 0
        assert f"Branch created: {expected_branch_name}" in result.stdout
        
        # Test validation
        result = run_command(f"./scripts/test-and-validate.sh {test_issue.id}")
        assert result.returncode == 0
        assert "All quality gates PASSED" in result.stdout
        
        # Test finish development
        result = run_command(f"./scripts/finish-development.sh {test_issue.id}")
        assert result.returncode == 0
        assert "Pull request created" in result.stdout
        
    finally:
        # Cleanup
        cleanup_test_issue(test_issue.id)
```

## 🔒 Security Best Practices

### Secrets Management

#### ✅ DO: Secure Secrets Handling
```bash
# Use environment variables
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"

# Mask secrets in logs
echo "Using API key: ${LINEAR_API_KEY:0:10}***"

# Validate secret format
if [[ ! "$LINEAR_API_KEY" =~ ^lin_api_ ]]; then
    echo "❌ Invalid Linear API key format"
    exit 1
fi

# Never commit secrets to git
echo "*.secret" >> .gitignore
echo ".env" >> .gitignore
```

#### ❌ DON'T: Insecure Practices
```bash
# ❌ Never hardcode secrets
LINEAR_API_KEY="lin_api_actual_key_here"

# ❌ Never log full secrets
echo "API Key: $LINEAR_API_KEY"

# ❌ Never commit secrets
git add .env
```

### Input Validation

#### Validate All Inputs
```bash
# ✅ Good: Comprehensive input validation
validate_issue_id() {
    local issue_id="$1"
    
    # Check if provided
    if [[ -z "$issue_id" ]]; then
        echo "❌ Error: Issue ID is required"
        return 1
    fi
    
    # Check format (e.g., FRA-123)
    if [[ ! "$issue_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
        echo "❌ Error: Invalid issue ID format. Expected: ABC-123"
        return 1
    fi
    
    # Check length limits
    if [[ ${#issue_id} -gt 20 ]]; then
        echo "❌ Error: Issue ID too long"
        return 1
    fi
    
    return 0
}
```

### Security Scanning

#### Automated Security Checks
```bash
# Run security scans before commits
./scripts/test-and-validate.sh FRA-123

# Expected checks:
# ✅ Bandit security scan: GRADE A
# ✅ No hardcoded secrets detected
# ✅ No SQL injection vulnerabilities
# ✅ No shell injection vulnerabilities
```

## ⚡ Performance Optimization

### Script Performance

#### Optimization Guidelines
- ✅ Scripts should complete in < 5 seconds for simple operations
- ✅ Use parallel processing where possible
- ✅ Cache API responses when appropriate
- ✅ Minimize external API calls
- ✅ Use efficient algorithms and data structures

#### Example: Optimized API Calls
```bash
# ✅ Good: Batch API calls and cache results
fetch_multiple_issues() {
    local issue_ids=("$@")
    local cache_file="/tmp/linear_issues_cache"
    
    # Check cache first
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin -5) ]]; then
        echo "📋 Using cached issue data"
        cat "$cache_file"
        return 0
    fi
    
    # Batch API call
    local query='{"query": "query { issues(filter: {id: {in: ['
    for id in "${issue_ids[@]}"; do
        query+="\"$id\","
    done
    query=${query%,}  # Remove trailing comma
    query+=']}}) { nodes { id title status { name } } } }"}'
    
    # Single API call for all issues
    curl -s "$LINEAR_API_URL" \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$query" | tee "$cache_file"
}
```

```bash
# ❌ Poor: Multiple API calls
fetch_multiple_issues() {
    for issue_id in "$@"; do
        curl -s "$LINEAR_API_URL/issues/$issue_id"
    done
}
```

## 📖 Documentation Standards

### Code Documentation

#### Function Documentation
```python
def create_pull_request(issue_id: str, branch_name: str) -> PullRequest:
    """
    Create a pull request for the given issue and branch.
    
    This function creates a GitHub pull request with comprehensive metadata
    including Linear issue details, test coverage, and quality gate results.
    
    Args:
        issue_id: Linear issue identifier (e.g., "FRA-123")
        branch_name: Git branch name containing the changes
        
    Returns:
        PullRequest object with PR details and metadata
        
    Raises:
        GitHubAPIError: If PR creation fails
        LinearAPIError: If issue details cannot be fetched
        ValidationError: If branch or issue validation fails
        
    Example:
        >>> pr = create_pull_request("FRA-123", "feature/add-retry-logic")
        >>> print(pr.url)
        https://github.com/org/repo/pull/456
    """
```

#### README Updates
```markdown
# ✅ Good: Comprehensive README sections
## 🚀 Quick Start
## 📋 Prerequisites  
## 🛠️ Installation
## 📖 Usage Examples
## 🧪 Testing
## 🤝 Contributing
## 📄 License
## 🙏 Acknowledgments
```

### Comment Guidelines

#### ✅ Good Comments
```python
# Calculate exponential backoff delay to avoid overwhelming the API
delay = base_delay * (2 ** attempt)

# Linear API returns 422 for validation errors, not 400
if response.status_code == 422:
    handle_validation_error(response)
```

#### ❌ Poor Comments
```python
# Add 1 to attempt
attempt += 1

# Call API
response = api.call()
```

## 🤝 Team Collaboration

### Pull Request Best Practices

#### PR Description Template
```markdown
## 📋 Description
Brief description of changes and motivation.

## 🔗 Linear Issue
Closes FRA-123

## 🧪 Testing
- [ ] Unit tests pass
- [ ] Integration tests pass  
- [ ] Manual testing completed
- [ ] Coverage > 90%

## 📸 Screenshots (if applicable)
[Include before/after screenshots for UI changes]

## 🔍 Review Checklist
- [ ] Code follows style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes (or clearly marked)
```

#### Review Guidelines

**For Authors:**
- ✅ Keep PRs small and focused (< 400 lines)
- ✅ Test thoroughly before requesting review
- ✅ Respond to feedback promptly
- ✅ Update documentation and tests

**For Reviewers:**
- ✅ Review within 24 hours
- ✅ Focus on logic, security, and maintainability
- ✅ Ask questions for clarity
- ✅ Approve when satisfied with quality

### Communication Standards

#### Status Updates
```markdown
# Daily standup format
## What I completed yesterday:
- ✅ Implemented retry logic for Linear API calls
- ✅ Added unit tests with 95% coverage

## What I'm working on today:
- 🔄 Adding GitHub API retry logic
- 🔄 Updating documentation

## Blockers:
- ❌ Need Linear workspace admin access for testing
```

## 🔧 Troubleshooting and Debugging

### Debug Mode Usage

#### Enable Comprehensive Debugging
```bash
# Enable debug mode for scripts
DEBUG=1 ./scripts/start-development.sh FRA-123

# Enable verbose output for specific tools
gh --debug api user
git status --verbose
```

#### Systematic Debugging Approach
1. **Reproduce the issue** consistently
2. **Check logs** for error messages
3. **Validate inputs** and environment
4. **Test components** individually
5. **Compare with working examples**
6. **Document the solution** for future reference

### Common Issue Resolution

#### Issue Resolution Template
```markdown
## Issue: [Brief description]

### Environment:
- OS: macOS 12.0
- Git version: 2.39.0
- GitHub CLI version: 2.20.0

### Steps to Reproduce:
1. Run `./scripts/start-development.sh FRA-123`
2. Script fails with error message

### Error Message:
```
❌ Error: Linear API connection failed
```

### Root Cause:
Linear API key was not set in environment

### Solution:
```bash
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"
echo 'export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"' >> ~/.bashrc
```

### Prevention:
- Update setup documentation
- Add validation check to scripts
- Create environment check command
```

## 📈 Continuous Improvement

### Metrics and Monitoring

#### Track Key Metrics
- **Development Velocity**: Issues completed per sprint
- **Code Quality**: Test coverage, linting scores
- **Process Efficiency**: Time from start to PR merge
- **Error Rates**: Failed workflows, rollbacks

#### Regular Reviews
- **Weekly**: Team retrospectives on workflow usage
- **Monthly**: Review metrics and identify improvements
- **Quarterly**: Major workflow updates and training

### Feedback Collection

#### Feedback Channels
- 📝 **Weekly surveys** on workflow effectiveness
- 💬 **Slack channel** for quick feedback and questions
- 🎯 **Retrospectives** to discuss improvements
- 📊 **Metrics dashboards** to track trends

### Process Evolution

#### Improvement Process
1. **Identify** pain points or inefficiencies
2. **Propose** solutions with clear benefits
3. **Test** changes with small group first
4. **Document** new practices and update training
5. **Roll out** to entire team with support
6. **Monitor** adoption and effectiveness

---

## 🎯 Summary Checklist

Use this checklist to ensure you're following all best practices:

### Before Starting Work
- [ ] Linear issue has clear acceptance criteria
- [ ] Dependencies are identified and resolved
- [ ] Environment is properly configured
- [ ] Latest code is pulled from main branch

### During Development
- [ ] Using descriptive commit messages
- [ ] Writing tests for new functionality
- [ ] Following code style guidelines
- [ ] Updating documentation as needed

### Before Creating PR
- [ ] All tests pass locally
- [ ] Code coverage meets requirements
- [ ] Security scan passes
- [ ] Documentation is updated
- [ ] PR description is complete

### After PR Merge
- [ ] Branch is deleted
- [ ] Linear issue is updated
- [ ] Documentation is verified
- [ ] Changes are communicated to team

---

**🎉 Following these best practices will help ensure high-quality, maintainable code and smooth team collaboration!**

*For questions or suggestions about these best practices, please create an issue or discuss with the team.*