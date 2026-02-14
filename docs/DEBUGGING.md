# DevBox Debugging Guide

Comprehensive troubleshooting and debugging guide for DevBox v1.0

---

## Table of Contents

1. [Quick Diagnosis](#quick-diagnosis)
2. [Exit Code Reference](#exit-code-reference)
3. [Common Issues](#common-issues)
4. [Advanced Debugging](#advanced-debugging)
5. [Log Analysis](#log-analysis)
6. [System Requirements](#system-requirements)
7. [Recovery Procedures](#recovery-procedures)

---

## Quick Diagnosis

### Start Here

```bash
# Check DevBox status
sudo ./devbox.sh doctor

# View latest log
tail -50 logs/devbox_$(date +%Y-%m-%d).log

# Check for errors
grep -E "(ERROR|FATAL)" logs/devbox_*.log
```

### Is DevBox Working?

| Symptom | Quick Check | Solution |
|---------|-------------|----------|
| Script won't run | `ls -l devbox.sh` | `chmod +x devbox.sh` |
| "Not root" error | `whoami` | Use `sudo ./devbox.sh` |
| Library not found | `ls lib/` | Re-clone or fix permissions |
| Docker commands fail | `groups` | Log out and back in |
| Logs not readable | `ls -l logs/` | Already auto-fixed by script |

---

## Exit Code Reference

DevBox uses specific exit codes to indicate what went wrong:

### Code 0: Success ✅
```bash
echo $?  # After running devbox
0
```
**Meaning:** Everything worked perfectly.

**Action:** None needed.

---

### Code 1: No Root Permission ❌
```bash
./devbox.sh install
Error: This script must be run as root
```

**Cause:** Script requires root privileges for system operations.

**Solution:**
```bash
sudo ./devbox.sh install
```

**Why:** Package installation, Docker setup, and system configuration require root access.

---

### Code 2: No Argument Provided ❌
```bash
sudo ./devbox.sh
Error: No arguments provided. Use --help for usage information.
```

**Cause:** No command specified.

**Solution:**
```bash
sudo ./devbox.sh install           # or
sudo ./devbox.sh doctor            # or
./devbox.sh --help
```

---

### Code 3: Invalid Argument ❌
```bash
sudo ./devbox.sh setup
Error: Invalid argument 'setup'
Use --help for usage information
```

**Cause:** Unknown command or option.

**Valid Commands:**
- `install`
- `install --plus-docker`
- `doctor`
- `--help`

**Solution:**
```bash
./devbox.sh --help  # See all valid commands
```

---

### Code 4: Library Loading Failure ❌
```bash
Error: Required library not found: /path/to/lib/packages.sh
```

**Cause:** Missing or corrupt library files.

**Diagnostic Steps:**
```bash
# Check library presence
ls -la lib/

# Expected files:
# - diagnostics.sh
# - docker.sh
# - logging.sh
# - packages.sh
# - reporting.sh

# Check permissions
ls -l lib/*.sh

# All should be readable (r--r--r-- or better)
```

**Solutions:**

**Option 1: Fix Permissions**
```bash
chmod +x lib/*.sh
chmod 644 lib/*.sh
```

**Option 2: Re-clone Repository**
```bash
cd ..
rm -rf devbox
git clone https://github.com/PavaraM/devbox.git
cd devbox
chmod +x devbox.sh
```

**Option 3: Manual Verification**
```bash
# Check each library loads
bash -n lib/logging.sh      # No output = syntax OK
bash -n lib/packages.sh
bash -n lib/docker.sh
bash -n lib/diagnostics.sh
bash -n lib/reporting.sh
```

---

### Code 5: Package Installation Failure ❌
```bash
Error: Failed to install essential packages
```

**Cause:** APT package installation failed.

**Diagnostic Steps:**

**1. Check which package failed:**
```bash
# View main log
grep "installation failed" logs/devbox_*.log

# Example output:
# 2026-02-14 01:45:38 [ERROR] git installation failed
```

**2. Check package-specific log:**
```bash
cat logs/apt/apt_*-git.log
# or
cat logs/apt/apt_*-curl.log
```

**Common Causes:**

**A. No Internet Connection**
```bash
# Test connectivity
ping -c 3 google.com
ping -c 3 8.8.8.8

# If DNS fails but IP works:
# Edit /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
```

**B. Repository Issues**
```bash
# Update package lists
sudo apt update

# Check for errors
sudo apt update 2>&1 | grep -E "(Error|Failed|Err:)"
```

**C. Disk Space**
```bash
# Check available space
df -h /

# Need at least 1GB free
# If low, clean up:
sudo apt clean
sudo apt autoremove
```

**D. Broken Dependencies**
```bash
# Fix broken packages
sudo dpkg --configure -a
sudo apt --fix-broken install

# Then retry DevBox
sudo ./devbox.sh install
```

**Solution:**
```bash
# After fixing the issue, re-run
sudo ./devbox.sh install

# DevBox is idempotent - it will skip already installed packages
```

---

### Code 6: Docker Installation Failure ❌
```bash
Docker installation failed
```

**Cause:** Docker convenience script failed.

**Diagnostic Steps:**

**1. Check logs:**
```bash
grep -A 10 "Docker installation" logs/devbox_*.log
```

**2. Check connectivity to Docker repositories:**
```bash
curl -fsSL https://get.docker.com -o /tmp/test-docker.sh
cat /tmp/test-docker.sh | head -20
rm /tmp/test-docker.sh
```

**3. Check for existing Docker:**
```bash
docker --version
dpkg -l | grep docker
```

**Common Causes:**

**A. Network Issues**
```bash
# Test Docker download
curl -fsSL https://get.docker.com

# Should return shell script, not error
```

**B. Existing Docker Installation Conflict**
```bash
# Remove old Docker
sudo apt remove docker docker-engine docker.io containerd runc

# Clean up
sudo apt autoremove
sudo apt autoclean

# Retry DevBox
sudo ./devbox.sh install --plus-docker
```

**C. Unsupported OS**
```bash
# Check OS
lsb_release -a

# Docker supports:
# - Ubuntu 20.04+
# - Debian 10+
# - Other distributions may fail
```

**Manual Docker Installation:**
```bash
# If DevBox fails, install manually:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify
docker --version
```

---

### Code 7: Docker Service Failure ❌
```bash
Failed to start Docker service
```

**Cause:** Docker daemon won't start or enable.

**Diagnostic Steps:**

**1. Check service status:**
```bash
sudo systemctl status docker

# Look for:
# - Active: active (running)  ✅
# - Active: failed            ❌
# - Active: inactive (dead)   ❌
```

**2. Check system logs:**
```bash
sudo journalctl -xeu docker.service

# Recent errors:
sudo journalctl -xeu docker.service --since "10 minutes ago"
```

**3. Check Docker daemon logs:**
```bash
sudo tail -50 /var/log/docker.log
# or
sudo journalctl -u docker.service -n 50
```

**Common Causes:**

**A. Systemd Not Available**
```bash
# Check init system
ps -p 1 -o comm=

# Should output: systemd
# If not, manual start:
sudo dockerd &
```

**B. Port Conflicts**
```bash
# Check if something is using Docker's ports
sudo netstat -tulpn | grep -E ':(2375|2376)'

# Kill conflicting process if found
sudo kill <PID>
```

**C. Storage Driver Issues**
```bash
# Check Docker daemon configuration
sudo cat /etc/docker/daemon.json

# If missing or invalid, create:
echo '{"storage-driver": "overlay2"}' | sudo tee /etc/docker/daemon.json

# Restart
sudo systemctl restart docker
```

**Solution:**
```bash
# Force start
sudo systemctl start docker
sudo systemctl enable docker

# Verify
sudo systemctl is-active docker
# Should output: active
```

---

### Code 8: Docker Group Setup Failure ❌
```bash
Failed to add user to docker group
```

**Cause:** User group management failed.

**Diagnostic Steps:**

**1. Check current groups:**
```bash
groups
groups $USER
```

**2. Check if docker group exists:**
```bash
getent group docker
# Should output: docker:x:999:username
```

**3. Check logs:**
```bash
grep "docker group" logs/devbox_*.log
```

**Common Causes:**

**A. Docker Group Doesn't Exist**
```bash
# Create docker group
sudo groupadd docker

# Retry adding user
sudo usermod -aG docker $USER
```

**B. Permission Issues**
```bash
# Ensure proper permissions
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock
```

**Solution:**
```bash
# Manual group addition
sudo usermod -aG docker $USER

# Verify
groups $USER | grep docker

# Apply changes (choose one):
newgrp docker           # For current session
# OR
# Log out and back in    # Permanent
```

**Verification:**
```bash
# After re-login, test without sudo
docker run hello-world

# Should work without sudo
```

---

### Code 9: Docker Compose Installation Failure ❌
```bash
Docker Compose plugin installation failed
```

**Cause:** Docker Compose plugin download or installation failed.

**Diagnostic Steps:**

**1. Check architecture support:**
```bash
uname -m

# Supported:
# - x86_64   ✅
# - aarch64  ✅
# - armv7l   ✅
# - others   ❌
```

**2. Test download:**
```bash
# Get architecture
arch=$(uname -m)
os=$(uname -s | tr '[:upper:]' '[:lower:]')

# Test URL
curl -fsSL "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-${os}-${arch}"

# Should download binary, not 404 error
```

**3. Check existing installation:**
```bash
# Plugin version
docker compose version

# Standalone version
docker-compose --version

# Installation location
which docker-compose
ls -la /usr/local/lib/docker/cli-plugins/docker-compose
```

**Common Causes:**

**A. Network Issues**
```bash
# Test GitHub connectivity
curl -I https://github.com

# Should return 200 or 301, not timeout
```

**B. Unsupported Architecture**
```bash
uname -m
# If output is not x86_64, aarch64, or armv7l
# You may need standalone docker-compose

# Install standalone
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**C. Permission Issues**
```bash
# Check plugin directory
ls -la /usr/local/lib/docker/cli-plugins/

# Create if missing
sudo mkdir -p /usr/local/lib/docker/cli-plugins
```

**Manual Installation:**
```bash
# Download plugin
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose

# Make executable
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Verify
docker compose version
```

---

### Code 10: Docker Verification Failure ❌
```bash
Docker or Docker Compose installation verification failed
```

**Cause:** Installed but not functioning.

**Diagnostic Steps:**

**1. Test Docker:**
```bash
docker --version
docker info
docker run hello-world
```

**2. Test Docker Compose:**
```bash
docker compose version
# or
docker-compose --version
```

**3. Check daemon:**
```bash
sudo systemctl status docker
docker ps
```

**Common Causes:**

**A. Docker Not Running**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**B. Permission Issues**
```bash
# Current session needs group refresh
newgrp docker

# Or log out and back in
```

**C. Incomplete Installation**
```bash
# Reinstall Docker
sudo apt remove docker-ce docker-ce-cli containerd.io
sudo apt autoremove
sudo ./devbox.sh install --plus-docker
```

---

### Code 11: Diagnostic Check Failure ❌
```bash
Diagnostic check "pkg_mgr_health" failed
```

**Cause:** System health check failed.

**Diagnostic Steps:**

**1. Check diagnostic report:**
```bash
cat diagnostic_reports/report-*.log | tail -1
```

**2. Identify failed check:**
```bash
grep ERROR diagnostic_reports/report-*.log
```

**3. Review main log:**
```bash
grep "Diagnostic check" logs/devbox_*.log
```

**Common Failed Checks:**

**A. osinfo Check**
```bash
# Usually passes, but check:
lsb_release -a
uname -r
ping -c 1 google.com
```

**B. pkg_mgr_health Check**
```bash
# Check APT
which apt
apt --version

# Check dpkg lock
sudo lsof /var/lib/dpkg/lock

# Check broken packages
sudo dpkg --audit
```

**C. toolchain_verification Check**
```bash
# List missing tools
dpkg -l | grep -E '(git|curl|wget|htop|tmux|vim|unzip|tree|net-tools|ca-certificates|build-essential|ufw|iproute2|dnsutils|nmap)'

# Install missing ones
sudo ./devbox.sh install
```

---

### Code 12: No Internet Connection ❌
```bash
No internet connection for diagnostics
```

**Cause:** Network connectivity required for checks.

**Diagnostic Steps:**
```bash
# Test connectivity
ping -c 3 8.8.8.8
ping -c 3 google.com
curl -I https://google.com

# Check network interfaces
ip addr show
ip route show

# Check DNS
cat /etc/resolv.conf
nslookup google.com
```

**Solutions:**
```bash
# If offline is expected, skip internet checks
# (Edit lib/diagnostics.sh to make internet optional)

# If should be online:
# 1. Check network cable/WiFi
# 2. Restart network manager
sudo systemctl restart NetworkManager

# 3. Check firewall
sudo ufw status
sudo ufw allow out to any

# 4. Test with different DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

---

### Code 13: Essential Tool Missing ❌
```bash
Required tool "git" is missing
```

**Cause:** Expected tool not installed.

**Solution:**
```bash
# Run installation
sudo ./devbox.sh install

# This will install all essential tools
```

---

### Code 14: APT Not Healthy ❌
```bash
APT package manager is not healthy
```

**Cause:** Package manager issues.

**Diagnostic Steps:**
```bash
# Check APT
sudo apt update
sudo apt list --upgradable

# Check locks
sudo lsof /var/lib/dpkg/lock
sudo lsof /var/lib/apt/lists/lock

# Check broken packages
sudo dpkg --audit
```

**Solutions:**
```bash
# Remove locks (if safe)
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/apt/lists/lock

# Fix broken packages
sudo dpkg --configure -a
sudo apt --fix-broken install
sudo apt update
sudo apt upgrade

# Retry diagnostic
sudo ./devbox.sh doctor
```

---

## Common Issues

### Issue: "docker: permission denied"

**Symptom:**
```bash
docker run hello-world
docker: permission denied while trying to connect to the Docker daemon socket
```

**Cause:** User not in docker group, or group change not applied.

**Solution:**
```bash
# Check groups
groups | grep docker

# If not in docker group:
sudo usermod -aG docker $USER

# Apply changes (choose one):
newgrp docker              # Current session only
# OR
logout                     # Then login again
# OR
su - $USER                 # Relogin
```

**Verification:**
```bash
groups | grep docker
docker run hello-world
# Should work without sudo
```

---

### Issue: "apt update" fails with 404 errors

**Symptom:**
```bash
E: Failed to fetch http://archive.ubuntu.com/ubuntu/...
E: Some index files failed to download
```

**Cause:** Repository configuration or network issues.

**Solution:**
```bash
# Update repository lists
sudo apt update --fix-missing

# If still failing, change mirror
sudo sed -i 's|http://archive.ubuntu.com|http://mirrors.kernel.org|g' /etc/apt/sources.list

# Or use your country mirror
sudo sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list

# Update again
sudo apt update
```

---

### Issue: Log files owned by root

**Symptom:**
```bash
cat logs/devbox_*.log
cat: logs/devbox_*.log: Permission denied
```

**Cause:** Logs created as root (shouldn't happen with DevBox v1.0).

**Solution:**
```bash
# Fix ownership (DevBox does this automatically)
sudo chown -R $USER:$USER logs/
sudo chown -R $USER:$USER diagnostic_reports/

# Verify
ls -la logs/
```

---

### Issue: "Cannot connect to Docker daemon"

**Symptom:**
```bash
docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Cause:** Docker service not running.

**Solution:**
```bash
# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Check status
sudo systemctl status docker

# Test
docker ps
```

---

## Advanced Debugging

### Enable Console Logging

Edit `lib/logging.sh`:

```bash
log() {
    local level=$1
    shift
    local line="$(date +%Y-%m-%d' '%H:%M:%S) [$level] $*"
    
    # Uncomment for console output:
    echo "$line"              # <-- Uncomment this line
    
    echo "$line" >> "$logfile"
}
```

Then run:
```bash
sudo ./devbox.sh install
# Now you'll see live progress
```

### Trace Mode

For detailed execution tracing:

```bash
# Edit devbox.sh, add after shebang:
#!/bin/bash
set -x                        # Add this line
set -euo pipefail

# Then run normally
sudo ./devbox.sh install 2>&1 | tee debug-trace.log
```

### Check Library Loading

```bash
# Test each library individually
source lib/logging.sh && echo "✅ logging.sh"
source lib/packages.sh && echo "✅ packages.sh"
source lib/docker.sh && echo "✅ docker.sh"
source lib/diagnostics.sh && echo "✅ diagnostics.sh"
source lib/reporting.sh && echo "✅ reporting.sh"
```

### Verify Checksums

```bash
# Compare with known good version
sha256sum devbox.sh lib/*.sh

# Compare with repository
git log --oneline -1
git status
```

---

## Log Analysis

### Find All Errors

```bash
# All errors today
grep ERROR logs/devbox_$(date +%Y-%m-%d).log

# All errors ever
grep ERROR logs/devbox_*.log logs/archive/devbox_*.log

# Errors with context (5 lines before/after)
grep -B 5 -A 5 ERROR logs/devbox_*.log
```

### Installation Timeline

```bash
# View installation sequence
grep -E "(Checking|installed|already)" logs/devbox_*.log

# Duration of last run
tail -1 logs/devbox_$(date +%Y-%m-%d).log | grep duration
```

### Package-Specific Issues

```bash
# Which packages failed?
grep "installation failed" logs/devbox_*.log

# Specific package details
cat logs/apt/apt_*-git.log
cat logs/apt/apt_*-docker.log
```

### Performance Analysis

```bash
# Execution times
grep "duration=" logs/devbox_*.log

# Slowest operations
grep -E "\[INFO\].*successful" logs/devbox_*.log
```

---

## System Requirements

### Minimum Requirements

- **OS**: Ubuntu 20.04 LTS or newer
- **RAM**: 1 GB (2 GB recommended)
- **Disk**: 2 GB free space (5 GB recommended)
- **Network**: Internet connection required
- **User**: sudo/root access

### Compatibility Matrix

| OS Version | DevBox Support | Notes |
|------------|----------------|-------|
| Ubuntu 24.04 | ✅ Full | Recommended |
| Ubuntu 22.04 | ✅ Full | Recommended |
| Ubuntu 20.04 | ✅ Full | Minimum version |
| Ubuntu 18.04 | ⚠️ Partial | Docker may have issues |
| Debian 11+ | ✅ Likely | Not tested |
| Debian 10 | ⚠️ Partial | Not tested |
| Other | ❌ Unknown | May need modifications |

### Docker Requirements

- **Kernel**: 3.10+ (4.0+ recommended)
- **Storage**: overlay2 filesystem support
- **Architecture**: x86_64, aarch64, or armv7

Check compatibility:
```bash
# Kernel version
uname -r
# Should be 3.10 or higher

# Verify overlay2 support
docker info 2>/dev/null | grep "Storage Driver"
# or check before Docker install:
grep overlay /proc/filesystems
```

---

## Recovery Procedures

### Complete Reset

```bash
# Remove DevBox files
cd /path/to/devbox
sudo rm -rf logs/ diagnostic_reports/

# Uninstall packages (optional)
sudo apt remove git curl wget htop tmux neovim unzip tree net-tools build-essential ufw iproute2 dnsutils nmap
sudo apt autoremove

# Remove Docker (optional)
sudo apt remove docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /usr/local/lib/docker

# Start fresh
git clone https://github.com/PavaraM/devbox.git
cd devbox
chmod +x devbox.sh
sudo ./devbox.sh install --plus-docker
```

### Repair Installation

```bash
# Check for issues
sudo ./devbox.sh doctor

# Reinstall missing packages
sudo ./devbox.sh install

# Fix Docker (if needed)
sudo systemctl restart docker
sudo usermod -aG docker $USER
newgrp docker
```

### Log Recovery

```bash
# Logs archived but needed
ls logs/archive/devbox_*.log

# Restore specific log
cp logs/archive/devbox_2026-02-13.log logs/

# View archived log
cat logs/archive/devbox_2026-02-13.log
```

---

## Getting Help

### Information to Include

When seeking help, provide:

1. **DevBox version**: `head -5 devbox.sh`
2. **OS information**: `lsb_release -a`
3. **Command run**: e.g., `sudo ./devbox.sh install --plus-docker`
4. **Exit code**: `echo $?`
5. **Relevant logs**:
   ```bash
   tail -50 logs/devbox_$(date +%Y-%m-%d).log
   ```
6. **Error messages**: Exact error text
7. **Diagnostic output**: `sudo ./devbox.sh doctor`

### Support Channels

- **GitHub Issues**: https://github.com/PavaraM/devbox/issues
- **Email**: pavaramirihagalla@icloud.com
- **Documentation**: https://github.com/PavaraM/devbox/tree/main/docs

---

## Preventive Maintenance

### Regular Checks

```bash
# Weekly health check
sudo ./devbox.sh doctor

# Monthly log cleanup (automatic, but can force)
find logs/ -type f -name "*.log" -mtime +7 -exec mv {} logs/archive/ \;

# Check for updates
cd /path/to/devbox
git pull origin main
```

### Best Practices

1. **Always use sudo**: `sudo ./devbox.sh install`
2. **Check logs after operations**: `tail logs/devbox_*.log`
3. **Run doctor periodically**: `sudo ./devbox.sh doctor`
4. **Keep system updated**: `sudo apt update && sudo apt upgrade`
5. **Review diagnostic reports**: `cat diagnostic_reports/report-*.log`
6. **Monitor disk space**: `df -h /`

---

**Last Updated**: 2026-02-14  
**DevBox Version**: 1.0.0  
**Author**: Pavara Mirihagalla