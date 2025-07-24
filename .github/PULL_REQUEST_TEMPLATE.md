# Pull Request

## 📋 Overview

<!-- Brief description of what this PR does -->

### 🔗 Linear Issue
<!-- Linear issue ID (e.g., FRA-43) - this will be auto-linked by our GitHub Actions -->
**Linear Issue:** [FRA-XXX](https://linear.app/franorzabal/issue/FRA-XXX/)

### 🎯 Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation (changes to documentation only)
- [ ] 🔧 Refactoring (code change that neither fixes a bug nor adds a feature)
- [ ] ⚡ Performance improvement
- [ ] 🧪 Test addition or improvement
- [ ] 🔒 Security enhancement
- [ ] 🏗️ Build system or dependency changes

## 📝 Changes Made

<!-- Detailed description of changes -->

### 🔧 Technical Details
<!-- Technical implementation details, architecture decisions, etc. -->

### 📸 Screenshots/Demos
<!-- If applicable, add screenshots or demo links -->

## ✅ Testing

### 🧪 Test Coverage
<!-- Describe how the changes were tested -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated  
- [ ] Manual testing completed
- [ ] Performance testing completed (if applicable)

### 🔍 Test Results
<!-- Include test results, coverage reports, etc. -->

```bash
# Test commands used
npm test
# or
pytest
# or
./scripts/test-and-validate.sh
```

**Coverage:** X% (meets/exceeds 90% threshold)

## 🛡️ Security

### 🔒 Security Checklist
- [ ] No secrets or sensitive information in code
- [ ] Input validation implemented where needed
- [ ] Authentication/authorization properly handled
- [ ] Dependencies updated and scanned for vulnerabilities
- [ ] Security scan passed (Bandit/CodeQL/etc.)

### 🛡️ Security Scan Results
<!-- Include security scan results -->
- **Bandit Grade:** A/B/C/F
- **CodeQL:** No issues found / X issues found
- **Dependency Check:** Clean / X vulnerabilities found

## 📊 Quality Gates

### ✅ Pre-merge Checklist
<!-- All items must be checked before merging -->
- [ ] All tests passing ✅
- [ ] Code coverage ≥ 90% ✅
- [ ] Security scan grade A ✅
- [ ] No linting errors ✅
- [ ] Documentation updated ✅
- [ ] Linear issue linked ✅
- [ ] Reviewers assigned ✅

### 🎯 Quality Metrics
- **Code Coverage:** X%
- **Security Grade:** A
- **Performance Impact:** None/Minimal/Moderate/Significant
- **Breaking Changes:** Yes/No

## 🔄 Deployment

### 🚀 Deployment Notes
<!-- Any special deployment considerations -->
- [ ] Database migrations required
- [ ] Environment variables added/changed
- [ ] Configuration changes needed
- [ ] Dependencies updated

### 🗂️ Environment Variables
<!-- List any new or changed environment variables -->
```bash
# New variables (if any)
NEW_VAR=value
UPDATED_VAR=new_value
```

## 📚 Documentation

### 📖 Documentation Updates
- [ ] README.md updated
- [ ] API documentation updated
- [ ] Code comments added/updated
- [ ] Change log updated
- [ ] User documentation updated

### 🔗 Related Documentation
<!-- Links to relevant documentation -->

## 👥 Review

### 🎯 Review Focus Areas
<!-- Highlight specific areas that need reviewer attention -->
- [ ] Algorithm correctness
- [ ] Error handling
- [ ] Performance implications
- [ ] Security considerations
- [ ] Code maintainability

### 🤝 Reviewers
<!-- Tag specific reviewers if needed -->
@franorzabal

### 📋 Review Checklist for Reviewers
- [ ] Code follows project conventions
- [ ] Logic is sound and efficient
- [ ] Error handling is appropriate
- [ ] Tests are comprehensive
- [ ] Documentation is clear and complete
- [ ] Security considerations addressed
- [ ] Performance impact acceptable

## 🔄 Workflow Integration

### 🔗 Linear Sync
<!-- This section will be auto-populated by GitHub Actions -->
- **Linear Status:** Will be updated to "In Review" automatically
- **Linear Comments:** GitHub activity will be synced to Linear

### 🚀 CI/CD Pipeline
- [ ] All GitHub Actions passing
- [ ] Security scans completed
- [ ] Quality gates met
- [ ] Linear sync functioning

## 📝 Additional Notes

### 🤔 Alternative Approaches Considered
<!-- Describe any alternative solutions you considered and why you chose this approach -->

### 🔮 Future Improvements
<!-- Any follow-up work or improvements that could be made -->

### 🚨 Risks and Mitigation
<!-- Any potential risks and how they're mitigated -->

### 🙋 Questions for Reviewers
<!-- Any specific questions or concerns for reviewers -->

---

## 📋 Merge Checklist

**Before merging, ensure:**

- [ ] ✅ All automated checks pass
- [ ] ✅ Code review completed and approved
- [ ] ✅ Linear issue updated and linked
- [ ] ✅ Documentation is up to date
- [ ] ✅ No merge conflicts
- [ ] ✅ Target branch is correct
- [ ] ✅ Commit messages follow convention
- [ ] ✅ Breaking changes documented

**Post-merge actions:**
- [ ] Linear issue will be automatically updated to "Done"
- [ ] Release notes updated (if applicable)
- [ ] Deployment verified (if applicable)

---

**By submitting this PR, I confirm that:**
- [ ] I have read and followed the contributing guidelines
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes