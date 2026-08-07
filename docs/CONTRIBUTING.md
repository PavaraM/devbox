# Contributing to DevBox

Thank you for considering contributing to DevBox! This document provides guidelines and instructions for contributing.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Development Setup](#development-setup)
4. [Coding Standards](#coding-standards)
5. [Commit Guidelines](#commit-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Testing](#testing)
8. [Documentation](#documentation)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Expected Behavior

- Be respectful and constructive
- Accept constructive criticism gracefully
- Focus on what's best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

**Required Information:**
- DevBox version (`head -5 devbox.sh`)
- OS version (`lsb_release -a`)
- Command that caused the issue
- Expected behavior vs actual behavior
- Relevant logs from `logs/devbox_*.log`
- Exit code (`echo $?`)
- Output from `sudo ./devbox.sh doctor`

**Bug Report Template:**
```markdown
**Description:**
Brief description of the bug

**Steps to Reproduce:**
1. Run command: `sudo ./devbox.sh install`
2. ...

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happened

**Environment:**
- DevBox version: 2.0.0
- OS: Ubuntu 24.04
- Kernel: 6.17.0

**Logs:**
```
[Paste relevant log entries]
```

**Exit Code:** 5
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- Clear description of the feature
- Why it would be useful
- Potential implementation approach (if applicable)
- Examples of how it would work

### Contributing Code

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## Development Setup

### Prerequisites

- One of the supported distributions: Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine
- Bash 4.0+
- Root/sudo access for testing
- Git

### Setup Instructions

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/devbox.git
cd devbox

# 3. Add upstream remote
git remote add upstream https://github.com/PavaraM/devbox.git

# 4. Create a branch for your work
git checkout -b feature/your-feature-name

# 5. Make the script executable
chmod +x devbox.sh bootstrap.sh lib/*.sh conf/hooks/*/*.sh

# 6. Test your changes
sudo ./devbox.sh install
sudo ./devbox.sh doctor
```

### Testing Environment

Recommended: Use a VM or container for testing to avoid affecting your main system.

```bash
# Using Docker for testing (the project's CI runs the same matrix)
docker run -it --rm ubuntu:24.04 bash
docker run -it --rm fedora:latest bash
docker run -it --rm archlinux:latest bash
docker run -it --rm alpine:latest bash

# Or use a VM with your target distribution
```

---

## Coding Standards

### Shell Scripting Style

#### Error Handling
```bash
# Use set flags
set -euo pipefail

# Check return values
if ! my_function; then
    log ERROR "Operation failed"
    return 1
fi
```

#### Variable Naming
```bash
# Constants (readonly)
readonly SCRIPT_VERSION="1.0"

# Global variables
global_var="value"

# Local variables
local local_var="value"

# Quote all variables
echo "$variable"
```

#### Function Structure
```bash
# Function with documentation
# my_function - Brief description
#
# Parameters:
#   $1 - param1 description
#
# Returns:
#   0 - Success
#   1 - Failure
my_function() {
    local param1=$1
    
    log DEBUG "Starting my_function"
    
    # Implementation
    
    return 0
}
```

#### Conditionals
```bash
# Use [[ ]] not [ ]
if [[ "$var" == "value" ]]; then
    # Do something
fi

# Prefer case for multiple conditions
case "$var" in
    option1)
        # Handle option1
        ;;
    option2)
        # Handle option2
        ;;
esac
```

### Logging Requirements

Add appropriate log messages:

```bash
# INFO - User-facing milestones
log INFO "Starting installation"

# DEBUG - Technical details
log DEBUG "Checking if package $pkg is installed"

# ERROR - Failures with context
log ERROR "Failed to install $pkg: $error_message"

# WARN - Non-critical issues
log WARN "Internet connectivity unavailable"
```

### Exit Codes

Use appropriate exit codes:

| Range | Purpose |
|-------|---------|
| 0 | Success |
| 1-10 | Core errors |
| 11-14 | Diagnostic errors |
| 15-17 | Security errors (SSH, firewall, deploy user) |
| 18-19 | v2 feature errors (version manager, JSON report) |
| 20-29 | Custom module errors (use for new features) |

```bash
# Define custom exit codes
readonly ERR_CUSTOM_FEATURE=20

my_new_function() {
    if ! check_something; then
        return $ERR_CUSTOM_FEATURE
    fi
    return 0
}
```

### File Organization

- Place new library functions in appropriate `lib/*.sh` files
- Library files are: `logging.sh`, `distro.sh`, `pkgmap.sh`, `packages.sh`, `docker.sh`, `security.sh`, `config.sh`, `profiles.sh`, `hooks.sh`, `state.sh`, `version-manager.sh`, `diagnostics.sh`, `reporting.sh`
- Keep `devbox.sh` focused on orchestration
- Configuration goes in `conf/*.conf`, not inline
- Document new exit codes in help text and README

---

## Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code formatting (no functional changes)
- **refactor**: Code refactoring
- **test**: Adding tests
- **chore**: Maintenance tasks

### Examples

```bash
feat: Add support for Fedora-based distributions

- Detect Fedora/RHEL systems
- Use dnf instead of apt where appropriate
- Add Fedora to compatibility matrix

Closes #42

fix: Resolve Docker group permission issue

The script now properly detects when user is already
in the docker group before attempting to add them.

Fixes #38

docs: Update QUICKREF with custom package examples

Added section showing how to use pkg.conf for
custom package installation.
```

### Best Practices

- Keep commits focused and atomic
- Write clear, descriptive messages
- Reference issues when applicable
- Keep subject line under 50 characters
- Wrap body at 72 characters

---

## Pull Request Process

### Before Submitting

1. **Test your changes thoroughly**
   ```bash
   # Test on a fresh target distribution (CI runs ubuntu/fedora/archlinux/alpine)
   sudo ./devbox.sh install
   sudo ./devbox.sh install --plus-docker
   sudo ./devbox.sh install --profile python-dev
   sudo ./devbox.sh install --resume --dist-upgrade
   sudo ./devbox.sh doctor
   sudo ./devbox.sh doctor --json
   ```

2. **Check for errors**
   ```bash
   # Run shellcheck (if available)
   shellcheck --severity=error devbox.sh bootstrap.sh lib/*.sh tests/*.sh

   # Check syntax
   bash -n devbox.sh
   bash -n bootstrap.sh
   bash -n lib/*.sh
   bash -n tests/*.sh
   ```

3. **Update documentation**
   - Update README.md if adding features
   - Update API.md if changing APIs
   - Update exit codes if adding new ones
   - Update QUICKREF.md, DEBUGGING.md, FILE_STRUCTURE.md as applicable

4. **Verify logs**
   ```bash
   grep ERROR logs/devbox_*.log
   ```

### Submitting a Pull Request

1. Push your branch to your fork
   ```bash
   git push origin feature/your-feature-name
   ```

2. Create a pull request on GitHub

3. Fill out the PR template (if provided)

4. Wait for review

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Tested on a supported distribution
- [ ] Tested install command
- [ ] Tested doctor command
- [ ] Tested with Docker option
- [ ] Tested with profiles (--profile)
- [ ] Verified logs

## Checklist
- [ ] Code follows project style guidelines
- [ ] Added appropriate log messages
- [ ] Updated documentation (README, API, DEBUGGING, QUICKREF, FILE_STRUCTURE)
- [ ] No shellcheck warnings
- [ ] All tests pass

## Related Issues
Closes #XX
```

### Review Process

- Maintainers will review your PR
- Address any requested changes
- Once approved, your PR will be merged

---

## Testing

### Manual Testing

```bash
# Test basic installation
sudo ./devbox.sh install

# Test Docker installation
sudo ./devbox.sh install --plus-docker

# Test profiles
sudo ./devbox.sh install --profile python-dev --profile node-dev

# Test diagnostics
sudo ./devbox.sh doctor
sudo ./devbox.sh doctor --json

# Test resume
sudo ./devbox.sh install --resume

# Test with network issues (simulate)
# Disable network temporarily and test error handling

# Check logs
tail -f logs/devbox_$(date +%Y-%m-%d).log
grep ERROR logs/devbox_*.log
```

### Testing Checklist

- [ ] Fresh install on a supported distribution
- [ ] Install command works
- [ ] Idempotency — run `install` twice; second run must exit 0 with no modifications
- [ ] Install with Docker works
- [ ] Install with profiles works
- [ ] Resume skips completed steps (`install --resume`)
- [ ] Doctor command works
- [ ] Doctor `--json` produces valid JSON
- [ ] Error handling works correctly
- [ ] Logs are created with correct ownership
- [ ] Exit codes are correct
- [ ] Help text is accurate

### Edge Cases to Test
- Run with no internet connection
- Run with insufficient disk space
- Run as non-root (should fail gracefully)
- Invalid command line arguments
- Interrupted installation (Ctrl+C)

---

## Documentation

### What to Document

When adding features, update:

1. **README.md**
   - Features list
   - Usage examples
   - Commands section
   - Exit codes (if new)

2. **API.md**
   - New functions
   - Modified APIs
   - New exit codes

3. **DEBUGGING.md**
   - New error conditions
   - Troubleshooting steps

4. **QUICKREF.md**
   - Quick reference for new features

5. **FILE_STRUCTURE.md**
   - File layout changes (new libs, confs, hooks, profiles)

### Documentation Style

- Be clear and concise
- Include examples
- Use code blocks for commands
- Test all examples before documenting

---

## Questions?

If you have questions:

- Open an issue with the "question" label
- Email: pavaramirihagalla@icloud.com
- Check existing issues and discussions

---

## Recognition

Contributors will be:
- Listed in release notes
- Acknowledged in the project

Thank you for contributing to DevBox! 🎉