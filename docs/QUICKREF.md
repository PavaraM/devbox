# DevBox Quick Reference

Quick reference guide for common DevBox operations and commands.

---

## Installation

```bash
# Clone repository
git clone https://github.com/PavaraM/devbox.git
cd devbox

# Make executable
chmod +x devbox.sh

# Basic installation
sudo ./devbox.sh install

# Installation with Docker
sudo ./devbox.sh install --plus-docker

# Run diagnostics
sudo ./devbox.sh doctor

# Show help
./devbox.sh --help
```

---

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `install` | Install development tools | `sudo ./devbox.sh install` |
| `install --plus-docker` | Install tools + Docker | `sudo ./devbox.sh install --plus-docker` |
| `doctor` | Run system diagnostics | `sudo ./devbox.sh doctor` |
| `--help` | Display help message | `./devbox.sh --help` |

---

## Installed Packages

### Core Tools (install)
- **Version Control**: git-all
- **Network**: curl, wget, net-tools, ca-certificates
- **Utilities**: htop, tmux, tree, unzip
- **Development**: neovim, build-essential
- **Networking**: ufw, iproute2, dnsutils, nmap

### Docker (install --plus-docker)
- Docker Engine (latest)
- Docker Compose plugin (v2.24.5)
- Docker service (auto-start)
- User group permissions

---

## Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | None needed |
| 1 | No root permission | Use `sudo` |
| 2 | No argument | Provide command |
| 3 | Invalid argument | Check `--help` |
| 4 | Library loading failure | Check `lib/` files |
| 5 | Package install failure | Check logs |
| 6 | Docker install failure | Check internet |
| 7 | Docker service failure | Check systemd |
| 8 | Docker group failure | Manual usermod |
| 9 | Docker Compose failure | Check architecture |
| 10 | Docker verification failure | Check installation |
| 11 | Diagnostic failure | Run `doctor` |
| 12 | No internet | Check connection |
| 13 | Tool missing | Run `install` |
| 14 | APT unhealthy | Fix package manager |

**Check exit code:**
```bash
sudo ./devbox.sh install
echo $?  # Shows exit code
```

---

## Log Files

### Main Log
```bash
# View latest log
cat logs/devbox_$(date +%Y-%m-%d).log

# Follow live
tail -f logs/devbox_$(date +%Y-%m-%d).log

# Find errors
grep ERROR logs/devbox_*.log
```

### Package Logs
```bash
# View specific package
cat logs/apt/apt_*-git.log
cat logs/apt/apt_*-docker.log

# All package logs
ls -la logs/apt/
```

### Diagnostic Reports
```bash
# Latest report
cat diagnostic_reports/report-*.log | tail -1

# View specific report
cat diagnostic_reports/report-2026-02-14-01-45-38.log

# All reports
ls -la diagnostic_reports/
```

### Archived Logs
```bash
# View archives
ls -la logs/archive/
ls -la logs/archive/apt/

# Access archived log
cat logs/archive/devbox_2026-02-13.log
```

---

## Common Tasks

### Check System Health
```bash
sudo ./devbox.sh doctor
```

### View Installation Status
```bash
# Check if package is installed
dpkg -l | grep git
dpkg -s git

# Check Docker
docker --version
systemctl status docker

# Check all installed tools
dpkg -l | grep -E '(git|curl|wget|htop|tmux|vim|unzip|tree|net-tools|build-essential|ufw|iproute2|dnsutils|nmap)'
```

### Fix Docker Permissions
```bash
# Check groups
groups | grep docker

# Add user to docker group
sudo usermod -aG docker $USER

# Apply (choose one):
newgrp docker        # Current session
logout               # Then login again
```

### View Logs
```bash
# Latest log
tail -50 logs/devbox_$(date +%Y-%m-%d).log

# All errors
grep -r ERROR logs/

# Errors with context
grep -B 5 -A 5 ERROR logs/devbox_*.log

# Execution time
grep "duration=" logs/devbox_*.log
```

### Clean Up Logs
```bash
# Manual archive (7+ days old)
find logs/ -name "*.log" -mtime +7 -exec mv {} logs/archive/ \;

# Delete old archives (30+ days)
find logs/archive/ -name "*.log" -mtime +30 -delete

# View disk usage
du -sh logs/
du -sh logs/archive/
```

---

## Troubleshooting

### Script Won't Run
```bash
# Check permissions
ls -l devbox.sh

# Fix
chmod +x devbox.sh

# Check libraries
ls -l lib/
chmod +x lib/*.sh
```

### Permission Denied Errors
```bash
# Use sudo for installation
sudo ./devbox.sh install

# Use sudo for diagnostics
sudo ./devbox.sh doctor
```

### Package Installation Failed
```bash
# Check specific package log
cat logs/apt/apt_*-packagename.log

# Update package lists
sudo apt update

# Fix broken packages
sudo dpkg --configure -a
sudo apt --fix-broken install

# Retry
sudo ./devbox.sh install
```

### Docker Issues
```bash
# Check Docker status
systemctl status docker
docker ps

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Check user groups
groups | grep docker

# Add to docker group
sudo usermod -aG docker $USER
newgrp docker

# Test
docker run hello-world
```

### Internet Issues
```bash
# Test connectivity
ping -c 3 google.com
ping -c 3 8.8.8.8

# Check DNS
cat /etc/resolv.conf

# Set DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### Logs Unreadable
```bash
# Fix ownership (automatic, but manual if needed)
sudo chown -R $USER:$USER logs/
sudo chown -R $USER:$USER diagnostic_reports/

# Verify
ls -la logs/
```

---

## Docker Commands

### Basic Docker
```bash
# Version
docker --version
docker info

# Run container
docker run hello-world
docker run -it ubuntu bash

# List containers
docker ps           # Running
docker ps -a        # All

# Images
docker images
docker pull ubuntu
docker rmi image_name

# Stop/remove
docker stop container_id
docker rm container_id
```

### Docker Compose
```bash
# Version (plugin)
docker compose version

# Version (standalone)
docker-compose --version

# Basic usage
docker compose up
docker compose down
docker compose ps
docker compose logs
```

### Docker Service
```bash
# Status
systemctl status docker

# Start/stop
sudo systemctl start docker
sudo systemctl stop docker

# Enable/disable auto-start
sudo systemctl enable docker
sudo systemctl disable docker

# Restart
sudo systemctl restart docker
```

---

## File Structure

```
devbox/
├── devbox.sh                           # Main script
├── lib/                                # Libraries
│   ├── diagnostics.sh                  # System diagnostics
│   ├── docker.sh                       # Docker setup
│   ├── logging.sh                      # Logging system
│   ├── packages.sh                     # Package management
│   └── reporting.sh                    # Report generation
├── logs/                               # Execution logs
│   ├── devbox_2026-02-14.log          # Main logs
│   ├── apt/                            # Package logs
│   │   ├── apt_2026-02-14-git.log
│   │   └── apt_2026-02-14-docker.log
│   └── archive/                        # Old logs (7+ days)
│       ├── devbox_*.log
│       └── apt/
├── diagnostic_reports/                 # Diagnostic reports
│   ├── report-2026-02-14-01-45-38.log
│   └── archive/                        # Old reports
├── docs/                               # Documentation
│   ├── README.md
│   ├── DEBUGGING.md
│   ├── API.md
│   └── QUICKREF.md
├── LICENSE                             # MIT License
└── VERSION                             # Version info
```

---

## Customization

### Add Custom Packages

Edit `lib/packages.sh`:
```bash
main_essentials() {
    # Existing packages...
    check_and_install_apt git git-all
    
    # Add yours here:
    check_and_install_apt python3 python3-pip
    check_and_install_apt nodejs npm
}
```

### Disable Networking Tools

Edit `devbox.sh`:
```bash
run_install() {
    main_essentials
    # networkingtools  # Comment this out
}
```

### Add Custom Diagnostic Check

Edit `lib/diagnostics.sh`:
```bash
check_custom() {
    report DEBUG "Running custom check..."
    
    # Your check logic
    if condition; then
        report INFO "Custom check passed"
        passed=$((passed + 1))
        return 0
    else
        report ERROR "Custom check failed"
        return 1
    fi
}
```

Then update `devbox.sh`:
```bash
GENERAL_HEALTH_CHECKS=(
    osinfo
    pkg_mgr_health
    toolchain_verification
    check_custom  # Add here
)
```

---

## Debugging

### Enable Console Logging

Edit `lib/logging.sh`:
```bash
log() {
    local level=$1
    shift
    local line="$(date +%Y-%m-%d' '%H:%M:%S) [$level] $*"
    
    echo "$line"  # Uncomment this
    echo "$line" >> "$logfile"
}
```

### Verbose Mode

```bash
# Run with bash -x
sudo bash -x ./devbox.sh install
```

### Check Library Loading

```bash
# Test each library
bash -n lib/logging.sh && echo "✅ logging.sh"
bash -n lib/packages.sh && echo "✅ packages.sh"
bash -n lib/docker.sh && echo "✅ docker.sh"
bash -n lib/diagnostics.sh && echo "✅ diagnostics.sh"
bash -n lib/reporting.sh && echo "✅ reporting.sh"
```

---

## System Information

### OS Information
```bash
# Distribution
lsb_release -a
cat /etc/os-release

# Kernel
uname -r
uname -a

# Architecture
uname -m
dpkg --print-architecture
```

### Package Manager
```bash
# APT version
apt --version

# Check locks
sudo lsof /var/lib/dpkg/lock
sudo lsof /var/lib/apt/lists/lock

# Broken packages
sudo dpkg --audit
```

### Disk Space
```bash
# Overall usage
df -h

# Directory sizes
du -sh logs/
du -sh diagnostic_reports/

# Available space
df -h / | awk 'NR==2 {print $4}'
```

### Memory
```bash
# Total and available
free -h

# Detailed
cat /proc/meminfo
```

### Network
```bash
# Interfaces
ip addr show
ifconfig

# Routes
ip route show

# DNS
cat /etc/resolv.conf

# Connectivity
ping -c 3 google.com
curl -I https://google.com
```

---

## Environment Variables

```bash
# Available during execution
$SCRIPT_DIR      # DevBox directory
$TIMESTAMP       # Current date (YYYY-MM-DD)
$START_TIME      # Start time (milliseconds)
$logfile         # Path to main log
$reportfile      # Path to diagnostic report
$SUDO_USER       # Original user (when using sudo)
$USER            # Current user
```

---

## Useful Commands

### Git
```bash
git clone <repo>
git status
git add .
git commit -m "message"
git push
git pull
```

### Curl
```bash
curl -I https://example.com
curl -o file.txt https://example.com/file.txt
curl -fsSL https://example.com/script.sh | sh
```

### Wget
```bash
wget https://example.com/file.txt
wget -O custom-name.txt https://example.com/file.txt
```

### Tmux
```bash
tmux new -s session_name
tmux attach -t session_name
tmux ls
# Ctrl+B then D to detach
```

### Htop
```bash
htop
# F9 to kill process
# F10 to quit
```

### UFW (Firewall)
```bash
sudo ufw status
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Network Tools
```bash
# IP addresses
ip addr

# DNS lookup
nslookup google.com
dig google.com

# Port scan
nmap localhost
nmap 192.168.1.1

# Network statistics
netstat -tulpn
ss -tulpn
```

---

## Support

- **GitHub**: https://github.com/PavaraM/devbox
- **Issues**: https://github.com/PavaraM/devbox/issues
- **Email**: pavaramirihagalla@icloud.com
- **Documentation**: https://github.com/PavaraM/devbox/tree/main/docs

---

## Quick Fixes

| Problem | Solution |
|---------|----------|
| Script won't run | `chmod +x devbox.sh` |
| Not root | `sudo ./devbox.sh install` |
| Library not found | `chmod +x lib/*.sh` |
| Docker permission denied | `newgrp docker` or logout/login |
| Package install failed | Check `logs/apt/apt_*.log` |
| Logs unreadable | Already fixed automatically |
| Docker won't start | `sudo systemctl start docker` |
| Internet offline | Check network connection |
| APT locked | Wait or remove `/var/lib/dpkg/lock` |
| Disk full | Clean with `sudo apt clean` |

---

## Version Info

**DevBox Version**: 1.0.0  
**Release Date**: 2026-02-14  
**License**: MIT  
**Author**: Pavara Mirihagalla

---

**Quick Start**: `git clone https://github.com/PavaraM/devbox.git && cd devbox && chmod +x devbox.sh && sudo ./devbox.sh install --plus-docker`