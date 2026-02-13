# DevBox Debugging Guide

**A comprehensive guide to troubleshooting and debugging DevBox installations.**

This document helps you diagnose and fix issues when DevBox doesn't work as expected. It covers common problems, debugging techniques, and detailed log analysis.

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Common Issues](#common-issues)
3. [Exit Code Reference](#exit-code-reference)
4. [Log Analysis](#log-analysis)
5. [Manual Verification](#manual-verification)
6. [Docker-Specific Issues](#docker-specific-issues)
7. [Advanced Debugging](#advanced-debugging)
8. [Getting Help](#getting-help)

---

## Quick Diagnostics

### Basic Health Check

Run these commands to quickly identify issues:

```bash
# 1. Check if script is executable
ls -l devbox.sh
# Should show: -rwxr-xr-x

# 2. Check library files exist
ls -la lib/
# Should show: docker.sh, logging.sh, packages.sh

# 3. Check logs directory
ls -la logs/
# Should exist after first run

# 4. View the latest log
tail -50 logs/devbox_$(date '+%Y-%m-%d').log

# 5. Check if running as root
whoami
# Should return: root (when running with sudo)
```

### One-Liner Status Check

```bash
# Run all checks at once
echo "Script: $(ls -l devbox.sh 2>&1)" && \
echo "Libraries: $(ls lib/*.sh 2>&1 | wc -l) files" && \
echo "User: $(whoami)" && \
echo "Last exit: $?"
```

---

## Common Issues

### 1. Permission Denied

#### Symptom
```
bash: ./devbox.sh: Permission denied
```

#### Cause
Script is not executable.

#### Solution
```bash
chmod +x devbox.sh
# Also fix library permissions
chmod +x lib/*.sh
```

#### Verification
```bash
ls -l devbox.sh
# Should show: -rwxr-xr-x
```

---

### 2. Must Be Run as Root

#### Symptom
```
Error: This script must be run as root
```

#### Cause
Script requires root privileges but wasn't run with `sudo`.

#### Solution
```bash
# ❌ Wrong
./devbox.sh install

# ✅ Correct
sudo ./devbox.sh install
```

#### Debug Check
```bash
# Verify sudo access
sudo -v
# Should prompt for password or succeed silently

# Check your user's sudo privileges
sudo -l
```

---

### 3. Library Loading Failure

#### Symptom
```
Error: Required library not found: /path/to/devbox/lib/logging.sh
Error: Failed to load logging library
```

#### Cause
- Missing library files
- Incorrect directory structure
- Files in wrong location

#### Solution
```bash
# 1. Verify directory structure
tree -L 2
# Should show:
# .
# ├── devbox.sh
# ├── lib
# │   ├── docker.sh
# │   ├── logging.sh
# │   └── packages.sh

# 2. Check if files exist
ls -la lib/

# 3. Verify file permissions
chmod +x lib/*.sh

# 4. Check script directory detection
grep SCRIPT_DIR devbox.sh
# Should see: readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

#### Advanced Debug
```bash
# Test library loading manually
SCRIPT_DIR="$(pwd)"
source lib/logging.sh
# Should not produce errors
```

---

### 4. Package Installation Failures

#### Symptom
```
git is not installed, installing now...
git installation failed
Error: Failed to install essential packages
```

#### Cause
- Network connectivity issues
- APT repository problems
- Package not available in repositories
- Disk space issues

#### Solution

**Step 1: Check network connectivity**
```bash
ping -c 3 8.8.8.8
curl -I https://archive.ubuntu.com
```

**Step 2: Update package lists**
```bash
sudo apt update
# Look for errors in output
```

**Step 3: Check disk space**
```bash
df -h
# / should have at least 1GB free
```

**Step 4: Try manual installation**
```bash
# Test if the package exists
apt-cache search git-all

# Try installing manually
sudo apt install git-all -y
```

**Step 5: Check APT logs**
```bash
tail -50 /var/log/apt/history.log
tail -50 /var/log/apt/term.log
```

#### Common Package-Specific Issues

**neovim not found:**
```bash
# Older Ubuntu versions may not have neovim
# Check availability
apt-cache policy neovim

# Fallback: install vim
sudo apt install vim -y
```

**build-essential fails:**
```bash
# Usually due to broken dependencies
sudo apt --fix-broken install
sudo apt update
sudo apt install build-essential -y
```

---

### 5. Docker Installation Failures

#### Symptom
```
Docker installation failed
```

#### Cause
- Network issues downloading Docker script
- Conflicting Docker installations
- Unsupported architecture

#### Solution

**Step 1: Check for existing Docker**
```bash
which docker
docker --version
# If installed, uninstall first:
sudo apt remove docker docker-engine docker.io containerd runc
```

**Step 2: Test Docker script download**
```bash
curl -fsSL https://get.docker.com -o /tmp/test-docker.sh
cat /tmp/test-docker.sh
# Should show Docker installation script
```

**Step 3: Check architecture support**
```bash
uname -m
# Supported: x86_64, aarch64, armv7l
```

**Step 4: Manual Docker installation**
```bash
# Follow official Docker docs
sudo apt update
sudo apt install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

---

### 6. Docker Service Won't Start

#### Symptom
```
Failed to start Docker service
```

#### Cause
- Systemd issues
- Docker daemon conflicts
- Kernel module problems

#### Solution

**Step 1: Check service status**
```bash
sudo systemctl status docker
# Look for error messages
```

**Step 2: Check Docker daemon logs**
```bash
sudo journalctl -u docker.service -n 50 --no-pager
```

**Step 3: Try manual start with verbose logging**
```bash
sudo dockerd --debug &
# Watch for errors
```

**Step 4: Check kernel modules**
```bash
lsmod | grep overlay
lsmod | grep bridge
# Should show loaded modules
```

**Step 5: Restart Docker**
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```

---

### 7. Docker Compose Segmentation Fault

#### Symptom
```
Segmentation fault (core dumped)
Docker or Docker Compose installation verification failed
```

#### Cause
- Corrupted binary
- Architecture mismatch
- Library dependency issues

#### Solution

**DevBox v1.0+ uses Docker Compose plugin to avoid this issue.**

**Step 1: Remove standalone docker-compose**
```bash
sudo rm -f /usr/local/bin/docker-compose
```

**Step 2: Verify plugin installation**
```bash
docker compose version
# Should work without segfault
```

**Step 3: Manual plugin installation if needed**
```bash
COMPOSE_VERSION="v2.24.5"
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -fsSL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

**Step 4: Test**
```bash
docker compose version
docker compose --help
```

---

### 8. User Not in Docker Group

#### Symptom
```bash
docker ps
# permission denied while trying to connect to the Docker daemon socket
```

#### Cause
- User not added to docker group
- Group changes not yet active in session

#### Solution

**Step 1: Verify group membership**
```bash
groups $USER
# Should include 'docker'

# Or check specific user
groups pavara
```

**Step 2: Add user if missing**
```bash
sudo usermod -aG docker $USER
```

**Step 3: Activate group changes**
```bash
# Option 1: Log out and back in (recommended)

# Option 2: Force group refresh (temporary)
newgrp docker

# Option 3: Restart session
exec su -l $USER
```

**Step 4: Verify**
```bash
docker run hello-world
# Should work without sudo
```

---

## Exit Code Reference

DevBox uses specific exit codes to identify exactly where failures occur:

| Code | Error Type | Component | Debug Strategy |
|------|------------|-----------|----------------|
| `0` | Success | - | No action needed |
| `1` | No root permission | Main script | Run with `sudo` |
| `2` | No argument | Main script | Check command syntax |
| `3` | Invalid argument | Main script | Use `--help` for valid commands |
| `4` | Library loading | Main script | Check `lib/` directory and permissions |
| `5` | Package installation | packages.sh | Check network, APT, disk space |
| `6` | Docker installation | docker.sh | Check network, architecture, conflicts |
| `7` | Docker service | docker.sh | Check systemd, kernel modules, logs |
| `8` | Docker group | docker.sh | Verify user exists, check usermod logs |
| `9` | Compose installation | docker.sh | Check network, architecture, permissions |
| `10` | Docker verification | docker.sh | Test `docker --version` manually |

### Using Exit Codes for Debugging

```bash
# Run script and capture exit code
sudo ./devbox.sh install --plus-docker
echo "Exit code: $?"

# Or in a script
if sudo ./devbox.sh install; then
    echo "Success!"
else
    EXIT_CODE=$?
    echo "Failed with exit code: $EXIT_CODE"
    case $EXIT_CODE in
        5) echo "Check network and APT configuration" ;;
        6) echo "Check Docker installation logs" ;;
        7) echo "Check Docker service status" ;;
        *) echo "See DEBUGGING.md for details" ;;
    esac
fi
```

---

## Log Analysis

### Understanding Log Files

Logs are created at: `logs/devbox_YYYY-MM-DD.log`

**Log Structure:**
```
script started at Thu Feb 14 10:30:45 UTC 2026    ← Timestamp
command: devbox install --plus-docker              ← Full command
------------------------------
10:30:45 [INFO] Script started with command: install
10:30:46 [DEBUG] Checking if git is installed...
10:30:47 [INFO] git installation successful
10:35:20 [ERROR] Docker installation failed        ← Error location
------------------------------
Script ended at Thu Feb 14 10:35:22 UTC 2026 exit_code=6 duration=277.543s
==============================
```

### Log Levels

| Level | Purpose | When to Investigate |
|-------|---------|---------------------|
| `DEBUG` | Detailed operations | When INFO isn't enough detail |
| `INFO` | Normal operations | To verify expected flow |
| `WARN` | Non-critical issues | May indicate future problems |
| `ERROR` | Failures | Always investigate these |

### Analyzing Logs

**Find all errors:**
```bash
grep ERROR logs/devbox_*.log
```

**Find what happened before an error:**
```bash
grep -B 5 ERROR logs/devbox_$(date '+%Y-%m-%d').log
```

**Find package installation attempts:**
```bash
grep "install" logs/devbox_*.log | grep -v "installed successfully"
```

**Check execution duration:**
```bash
grep "duration=" logs/devbox_*.log
```

**View full execution flow:**
```bash
cat logs/devbox_$(date '+%Y-%m-%d').log | grep -E "\[(INFO|ERROR)\]"
```

### Log Patterns to Watch For

**Successful package installation:**
```
10:30:46 [DEBUG] Checking if git is installed...
10:30:46 [INFO] git not installed
10:30:47 [DEBUG] Running apt install git-all
10:30:52 [INFO] git installation successful
```

**Failed package installation:**
```
10:30:46 [DEBUG] Checking if curl is installed...
10:30:46 [INFO] curl not installed
10:30:47 [DEBUG] Running apt install curl
10:30:50 [ERROR] curl installation failed          ← Problem here
```

**Docker installation flow:**
```
10:35:00 [DEBUG] Setting up Docker environment...
10:35:01 [DEBUG] Checking if Docker is installed...
10:35:01 [INFO] Docker not installed
10:35:01 [DEBUG] Running Docker installation commands
10:35:20 [INFO] Docker installation successful
10:35:21 [DEBUG] Starting Docker service...
10:35:22 [INFO] Docker service started successfully
10:35:23 [INFO] Docker service enabled on boot successfully
```

---

## Manual Verification

### Verify Package Installations

```bash
# Check each essential package
command -v git && echo "✓ git" || echo "✗ git"
command -v curl && echo "✓ curl" || echo "✗ curl"
command -v wget && echo "✓ wget" || echo "✗ wget"
command -v htop && echo "✓ htop" || echo "✗ htop"
command -v tmux && echo "✓ tmux" || echo "✗ tmux"
command -v nvim && echo "✓ neovim" || echo "✗ neovim"
command -v unzip && echo "✓ unzip" || echo "✗ unzip"
command -v tree && echo "✓ tree" || echo "✗ tree"
command -v gcc && echo "✓ build-essential" || echo "✗ build-essential"
```

### Verify Docker Installation

```bash
# 1. Check Docker binary
which docker
docker --version

# 2. Check Docker service
sudo systemctl status docker

# 3. Check Docker Compose
docker compose version

# 4. Check Docker group
groups $USER | grep docker

# 5. Test Docker functionality
docker run hello-world

# 6. Check Docker info
docker info
```

### Complete System Check Script

Create a file `verify.sh`:

```bash
#!/bin/bash

echo "=== DevBox Verification ==="
echo ""

# Check essentials
echo "Essential Packages:"
for cmd in git curl wget htop tmux nvim unzip tree gcc; do
    if command -v $cmd &> /dev/null; then
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd (MISSING)"
    fi
done
echo ""

# Check Docker
echo "Docker:"
if command -v docker &> /dev/null; then
    echo "  ✓ Docker $(docker --version | cut -d' ' -f3)"
    
    if systemctl is-active --quiet docker; then
        echo "  ✓ Docker service running"
    else
        echo "  ✗ Docker service not running"
    fi
else
    echo "  ✗ Docker not installed"
fi

if docker compose version &> /dev/null; then
    echo "  ✓ Docker Compose $(docker compose version --short)"
else
    echo "  ✗ Docker Compose not available"
fi

if groups $USER | grep -q docker; then
    echo "  ✓ User in docker group"
else
    echo "  ✗ User NOT in docker group"
fi
echo ""

# Check logs
echo "Logs:"
if [ -d logs ]; then
    log_count=$(ls logs/*.log 2>/dev/null | wc -l)
    echo "  ✓ $log_count log file(s)"
    latest=$(ls -t logs/*.log 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        echo "  Latest: $latest"
    fi
else
    echo "  ✗ No logs directory"
fi

echo ""
echo "=== Verification Complete ==="
```

Run it:
```bash
chmod +x verify.sh
./verify.sh
```

---

## Docker-Specific Issues

### Issue: Docker Socket Permission Denied

```bash
# Error
docker: Got permission denied while trying to connect to the Docker daemon socket

# Quick fix
sudo chmod 666 /var/run/docker.sock

# Permanent fix
sudo usermod -aG docker $USER
# Then log out and back in
```

### Issue: Docker Daemon Not Running

```bash
# Check status
sudo systemctl status docker

# Start daemon
sudo systemctl start docker

# Enable auto-start
sudo systemctl enable docker

# If still failing, check logs
sudo journalctl -xeu docker.service
```

### Issue: Docker Compose Command Not Found

```bash
# Check plugin
docker compose version

# If missing, check plugin directory
ls -la /usr/local/lib/docker/cli-plugins/

# Verify permissions
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Test
docker compose --help
```

### Issue: Cannot Connect to Docker Daemon

```bash
# Check if daemon is running
ps aux | grep dockerd

# Check socket
ls -la /var/run/docker.sock

# Try restarting
sudo systemctl restart docker
sudo systemctl status docker

# Check for port conflicts
sudo netstat -tlnp | grep docker
```

### Issue: Docker Build Fails

```bash
# Clear build cache
docker builder prune -a

# Check disk space
df -h
docker system df

# Clean up unused resources
docker system prune -a
```

---

## Advanced Debugging

### Enable Verbose Logging

Modify `lib/logging.sh` to output to console:

```bash
log() {
    local level=$1
    shift
    local line="$(date +%H:%M:%S) [$level] $*"
    
    echo "$line"               # console (uncomment this line)
    echo "$line" >> "$logfile"  # file
}
```

### Run in Debug Mode

```bash
# Enable bash debugging
bash -x devbox.sh install 2>&1 | tee debug.log

# With sudo
sudo bash -x devbox.sh install --plus-docker 2>&1 | tee debug.log
```

### Test Individual Functions

```bash
# Load libraries manually
SCRIPT_DIR="$(pwd)"
TIMESTAMP=$(date '+%Y-%m-%d')
START_TIME=$(date +%s%3N)

source lib/logging.sh
source lib/packages.sh

# Test specific function
check_and_install_apt git git-all
```

### Trace Function Calls

Add to top of each function in libraries:

```bash
function_name() {
    echo "TRACE: Entering function_name" >&2
    # ... function code ...
    echo "TRACE: Exiting function_name" >&2
}
```

### Monitor System Resources During Installation

```bash
# In one terminal
watch -n 1 'df -h; echo ""; free -h; echo ""; ps aux | grep -E "apt|docker" | grep -v grep'

# In another terminal
sudo ./devbox.sh install --plus-docker
```

---

## Environment-Specific Issues

### Running in Docker Container

If running DevBox inside a Docker container:

```bash
# Check if inside container
if [ -f /.dockerenv ]; then
    echo "Running inside Docker"
fi

# systemctl may not work
# Use alternative Docker installation method
```

### Running in WSL (Windows Subsystem for Linux)

```bash
# Check if WSL
if grep -q Microsoft /proc/version; then
    echo "Running in WSL"
fi

# Known issues:
# - systemctl may not work → use service docker start
# - Docker Desktop integration may conflict
```

### Running in VM

```bash
# Check if VM
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name

# Common VM issues:
# - Limited disk space
# - Network configuration
# - Nested virtualization for Docker
```

---

## Performance Issues

### Slow Package Installation

```bash
# 1. Check mirror speed
curl -w "@/dev/stdout" -o /dev/null -s http://archive.ubuntu.com

# 2. Switch to faster mirror
sudo sed -i 's|http://archive.ubuntu.com|http://mirror.example.com|g' /etc/apt/sources.list

# 3. Clean APT cache
sudo apt clean
sudo apt update
```

### Slow Docker Download

```bash
# Use Docker mirror
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": ["https://mirror.gcr.io"]
}
EOF
sudo systemctl restart docker
```

---

## Getting Help

### Before Asking for Help

1. **Check this document** - Most issues are covered here
2. **Read the logs** - They contain detailed error information
3. **Run manual verification** - Use the verification script above
4. **Search existing issues** - Someone may have had the same problem

### Reporting Issues

When reporting issues, include:

```bash
# 1. System information
uname -a
cat /etc/os-release

# 2. DevBox version
head -1 devbox.sh | grep "DevBox"

# 3. Full command run
echo "Command: sudo ./devbox.sh install --plus-docker"

# 4. Exit code
echo "Exit code: $?"

# 5. Relevant log excerpt
tail -100 logs/devbox_$(date '+%Y-%m-%d').log

# 6. Verification output
./verify.sh
```

### Community Support

- **GitHub Issues**: [Report bugs and feature requests](https://github.com/yourusername/devbox/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/yourusername/devbox/discussions)
- **Documentation**: [README.md](README.md)

---

## Debugging Checklist

Before concluding there's a bug, verify:

- [ ] Running with `sudo`
- [ ] All library files exist and are executable
- [ ] Disk has >1GB free space
- [ ] Network connectivity works
- [ ] No conflicting software installed
- [ ] System is Ubuntu 20.04+ or compatible
- [ ] Logs have been reviewed
- [ ] Manual verification attempted
- [ ] Searched existing issues

---

**Last Updated**: 2026-02-14  
**DevBox Version**: 1.0  
**Maintainer**: Pavara Mirihagalla