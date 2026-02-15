# DevBox

**A lightweight, modular development environment setup tool for Ubuntu systems.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/PavaraM/devbox)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)

DevBox automates the tedious setup of development environments by installing essential tools, configuring Docker, and providing diagnostic capabilities—all through a clean, modular bash script architecture.

---

## Features

✨ **Modular Architecture** - Clean separation of concerns with library-based design  
🔧 **Essential Dev Tools** - Git, curl, wget, htop, tmux, neovim, and more  
🐳 **Docker Integration** - Optional Docker and Docker Compose installation  
📊 **Comprehensive Logging** - Detailed logs with timestamps and duration tracking  
🩺 **System Diagnostics** - Built-in health checks and environment verification  
🛡️ **Robust Error Handling** - Granular exit codes for easy debugging  
⚡ **Idempotent Operations** - Safe to run multiple times  
📝 **User-Accessible Logs** - Logs owned by your user, not root  
🎯 **Custom Package Support** - Easy configuration for additional packages via `pkg.conf`

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/PavaraM/devbox.git
cd devbox

# Make the script executable
chmod +x devbox.sh

# Install essential packages
sudo ./devbox.sh install

# Install with Docker support
sudo ./devbox.sh install --plus-docker

# Run diagnostics
sudo ./devbox.sh doctor
```

---

## Installation

### Prerequisites

- Ubuntu 20.04+ (or Debian-based distributions)
- Root/sudo access
- Internet connection

### Project Structure

```
devbox/
├── devbox.sh              # Main script
├── lib/                   # Library modules
│   ├── diagnostics.sh     # System diagnostics & health checks
│   ├── docker.sh          # Docker installation & setup
│   ├── logging.sh         # Logging utilities
│   ├── packages.sh        # Package management
│   └── reporting.sh       # Diagnostic report generation
├── logs/                  # Execution logs (auto-created)
│   ├── devbox_*.log       # Main script logs
│   ├── apt/               # Per-package installation logs
│   │   └── apt_*.log   
│   └── archive/           # Archived logs (7+ days old)
│       ├── devbox_*.log
│       └── apt/
├── diagnostic_reports/    # System diagnostic reports
│   ├── report-*.log       # Timestamped diagnostic reports
│   └── archive/           # Archived reports
├── docs/
│   ├── README.md          # This file
│   ├── API.md             # API documentation for developers
│   ├── DEBUGGING.md       # Debugging guide
│   └── QUICKREF.md        # Quick reference guide
├── pkg.conf               # Custom package configuration
├── LICENSE                # MIT License
└── VERSION                # Version information
```

---

## Usage

### Commands

#### `install`
Set up your development environment with essential packages.

```bash
sudo ./devbox.sh install
```

**Installs:**

**Core Development Tools:**
- **Version Control**: git-all
- **Network Tools**: curl, wget, net-tools, ca-certificates
- **System Utilities**: htop, tmux, tree, unzip
- **Development**: neovim, build-essential

**Networking Tools:**
- **Firewall**: ufw (Uncomplicated Firewall)
- **Network Utilities**: iproute2, dnsutils, nmap

**Custom Packages:**
- Any packages defined in `pkg.conf`

#### `install --plus-docker`
Install everything plus Docker and Docker Compose.

```bash
sudo ./devbox.sh install --plus-docker
```

**Additionally configures:**
- Docker Engine (latest stable via official script)
- Docker Compose plugin (v2.24.5)
- Docker service auto-start on boot
- User permissions for non-root Docker access
- Architecture detection (x86_64, aarch64, armv7)

> **Note:** You'll need to log out and back in for Docker group permissions to take effect.

#### `doctor`
Run comprehensive diagnostic checks on your environment.

```bash
sudo ./devbox.sh doctor
```

**Diagnostic Checks:**
1. **OS Information**
   - Distribution and version
   - Kernel version
   - System architecture
   - User permissions
   - Internet connectivity

2. **Package Manager Health**
   - APT availability
   - dpkg lock status
   - Broken package detection

3. **Toolchain Verification**
   - Checks for all essential development tools
   - Validates networking utilities
   - Reports missing packages

4. **Custom Package Verification**
   - Validates packages defined in `pkg.conf`
   - Reports any missing custom packages

**Output:**
- Generates timestamped diagnostic report in `diagnostic_reports/`
- Displays summary with pass/fail status
- Logs detailed results for troubleshooting

Example output:
```
Running diagnostics...
[INFO] Distro: Ubuntu 24.04 LTS
[INFO] Kernel: 6.17.0-14-generic
[INFO] Architecture: x86_64
[INFO] Internet Connectivity: online
[INFO] APT package manager is healthy
[INFO] All essential development tools are present
[INFO] All custom packages are present
=======================
Diagnostic Summary
status: PASSED
checks_passed: 4/4
report generated at: diagnostic_reports/report-2026-02-14-01-45-38.log
=======================
```

#### `--help`
Display usage information and exit codes.

```bash
./devbox.sh --help
```

---

## Exit Codes

DevBox uses granular exit codes for precise error identification:

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Missing root permissions |
| `2` | No argument provided |
| `3` | Invalid argument |
| `4` | Library loading failure |
| `5` | Package installation failure |
| `6` | Docker installation failure |
| `7` | Docker service failure |
| `8` | Docker group setup failure |
| `9` | Docker Compose installation failure |
| `10` | Docker verification failure |
| `11` | Diagnostic check failure |
| `12` | No internet connection for diagnostics |
| `13` | Essential tool missing in diagnostics |
| `14` | APT package manager is not healthy |

---

## Logging System

Every execution creates detailed, timestamped log files:

### Log Types

**Main Execution Logs:**
```
logs/devbox_2026-02-14.log
```

**Per-Package APT Logs:**
```
logs/apt/apt_2026-02-14-git.log
logs/apt/apt_2026-02-14-curl.log
logs/apt/apt_2026-02-14-docker.log
```

**Diagnostic Reports:**
```
diagnostic_reports/report-2026-02-14-01-45-38.log
```

### Log Features

📝 **Main log** - Overall script execution with all operations  
📦 **Per-package APT logs** - Individual installation details and errors  
🩺 **Diagnostic reports** - System health check results  
🗄️ **Auto-archival** - Logs older than 7 days moved to `archive/`  
👤 **User ownership** - All logs owned by your user, not root  
⏱️ **Duration tracking** - Precise execution time in milliseconds  

### Log Format

```
script started at Sat Feb 14 01:45:38 +0530 2026
command: devbox install --plus-docker
system: Linux OBSIDIAN 6.17.0-14-generic x86_64
user: root (SUDO_USER: pavara)
------------------------------
 
2026-02-14 01:45:38 [INFO] Script started with command: install
2026-02-14 01:45:38 [DEBUG] Checking library: /path/to/lib/packages.sh
2026-02-14 01:45:38 [INFO] Library "packages.sh" is present and executable
2026-02-14 01:45:38 [INFO] "lib/packages.sh" loaded successfully
2026-02-14 01:45:38 [INFO] Starting installation process
2026-02-14 01:45:38 [DEBUG] Checking if git is installed...
2026-02-14 01:45:39 [INFO] git installation successful
...
------------------------------
Script ended at Sat Feb 14 01:45:40 +0530 2026 exit_code=0 duration=2.192s
==============================
```

### Log Levels

- **INFO** - Successful operations and milestones
- **DEBUG** - Detailed operation information
- **ERROR** - Failed operations with context
- **WARN** - Non-critical issues (e.g., offline status)

---

## Advanced Usage

### Custom Package Installation

DevBox supports custom package installation via the `pkg.conf` file:

**Edit `pkg.conf`:**
```bash
CUSTOM_PACKAGES=(
    "python3-pip"
    "nodejs"
    "npm"
    "golang-go"
)
```

Then run:
```bash
sudo ./devbox.sh install
```

Custom packages are automatically:
- Checked during installation
- Validated during `doctor` diagnostics
- Logged separately for easy troubleshooting

### Modifying Core Packages

Edit `lib/packages.sh` to add your own package groups:

```bash
main_essentials() {
    log INFO "Installing essential development packages..."
    local failed_packages=()
    
    # Existing packages
    check_and_install_apt git git-all || failed_packages+=("git")
    check_and_install_apt curl curl || failed_packages+=("curl")
    
    # Add your custom packages here
    check_and_install_apt python3 python3-pip || failed_packages+=("python3")
    check_and_install_apt nodejs npm || failed_packages+=("nodejs")
    check_and_install_apt golang golang-go || failed_packages+=("golang")
    
    # Report results
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "All essential packages installed successfully"
        return 0
    else
        log ERROR "Failed to install ${#failed_packages[@]} package(s): ${failed_packages[*]}"
        return 5
    fi
}
```

### Disable Networking Tools

The `networkingtools()` function is enabled by default. To disable it, modify `devbox.sh`:

```bash
run_install() {
    log INFO "Starting installation process"
    main_essentials
    # networkingtools  # Comment this out to disable
    custom_packages
    log INFO "Installation completed successfully"
}
```

---

## Troubleshooting

### Common Issues

**Package Installation Failed:**
```bash
# Check which package failed
grep "installation failed" logs/devbox_*.log

# View package-specific log
cat logs/apt/apt_*-git.log

# Fix broken packages
sudo dpkg --configure -a
sudo apt --fix-broken install

# Retry
sudo ./devbox.sh install
```

**Docker Permission Denied:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (choose one):
newgrp docker    # Current session
logout           # Then login again
```

**APT Locked:**
```bash
[ERROR] dpkg is locked

Solution:
# Wait for other package operations to complete, or:
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/lib/dpkg/lock
sudo dpkg --configure -a
```

### Debug Mode

Enable console logging by editing `lib/logging.sh`:

```bash
log() {
    local level=$1
    shift
    local line="$(date +%Y-%m-%d' '%H:%M:%S) [$level] $*"
    
    # Uncomment for console output:
    echo "$line"
    
    echo "$line" >> "$logfile"
}
```

### Viewing Logs

```bash
# Latest main log
tail -f logs/devbox_$(date +%Y-%m-%d).log

# Specific package installation
cat logs/apt/apt_*-git.log

# Latest diagnostic report
cat diagnostic_reports/report-*.log | tail -1

# All errors from today
grep ERROR logs/devbox_$(date +%Y-%m-%d).log
```

---

## Examples

### Fresh Ubuntu Server Setup

```bash
# Initial system setup
sudo apt update && sudo apt upgrade -y

# Install DevBox
git clone https://github.com/PavaraM/devbox.git
cd devbox
chmod +x devbox.sh

# Full installation with Docker
sudo ./devbox.sh install --plus-docker

# Verify installation
sudo ./devbox.sh doctor

# Start using Docker (after re-login)
docker run hello-world
```

### Continuous Integration Server

```bash
# Install only essential tools (no Docker)
sudo ./devbox.sh install

# Verify environment
sudo ./devbox.sh doctor

# Check report
cat diagnostic_reports/report-*.log
```

### Development Workstation

```bash
# Add custom packages first
nano pkg.conf
# Add: python3-pip, nodejs, npm, etc.

# Full setup with Docker
sudo ./devbox.sh install --plus-docker

# Periodic health checks
sudo ./devbox.sh doctor
```

---

## Best Practices

### Installation
- Always run `doctor` after `install` to verify setup
- Review logs if any package fails to install
- Run `install` again if network issues interrupted first attempt
- Use `pkg.conf` for custom packages instead of modifying core code

### Logging
- Check the main log for overview: `logs/devbox_$(date +%Y-%m-%d).log`
- Check package-specific logs for detailed errors: `logs/apt/`
- Archive old logs manually if disk space is limited

### Docker
- After Docker installation, log out and back in for group changes
- Test with `docker run hello-world` before production use
- Use `docker compose` (not `docker-compose`) for modern plugin

### Diagnostics
- Run `doctor` periodically to catch configuration drift
- Save diagnostic reports for troubleshooting history
- Use diagnostic reports when seeking support

### Custom Packages
- Use `pkg.conf` for project-specific or environment-specific packages
- Keep core packages in `lib/packages.sh` for universal needs
- Document your custom packages for team members

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/devbox.git
cd devbox

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
vim lib/packages.sh

# Test your changes
sudo ./devbox.sh install
sudo ./devbox.sh doctor

# Check logs for issues
tail -f logs/devbox_*.log

# Commit and push
git add .
git commit -m "Add: your feature description"
git push origin feature/your-feature-name
```

### Coding Standards

**Shell Scripting:**
- Use `set -euo pipefail` for error handling
- Quote all variables: `"$variable"`
- Use `readonly` for constants
- Use `local` for function variables
- Prefer `[[` over `[` for conditionals

**Logging:**
- Add descriptive log messages for all operations
- Use appropriate log levels (INFO, DEBUG, ERROR, WARN)
- Include context in error messages

**Error Handling:**
- Return specific exit codes (see Exit Codes section)
- Fail fast with early validation
- Clean up temporary files on failure

**Ownership:**
- Fix ownership of created files with `chown "$SUDO_USER:$SUDO_USER"`
- Ensure all logs are user-accessible

**Documentation:**
- Update README for user-facing changes
- Add inline comments for complex logic
- Update exit codes table if adding new codes

### Testing Checklist

Before submitting a PR:
- [ ] Test on fresh Ubuntu 22.04 LTS
- [ ] Test on fresh Ubuntu 24.04 LTS
- [ ] Test `install` command
- [ ] Test `install --plus-docker` command
- [ ] Test `doctor` command
- [ ] Test with and without internet
- [ ] Verify log file creation and ownership
- [ ] Verify diagnostic report generation
- [ ] Check for shellcheck warnings
- [ ] Update documentation

---

## Security

### Reporting Vulnerabilities

If you discover a security vulnerability, please email:
**pavaramirihagalla@icloud.com**

Please do not open public issues for security vulnerabilities.

### Security Considerations

- DevBox requires root access for system-level operations
- Docker installation uses official Docker scripts
- All downloads use HTTPS
- Logs may contain sensitive system information
- User credentials are never logged

---

## License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2026 Pavara Mirihagalla

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Acknowledgments

- Inspired by the need for consistent development environments
- Built with best practices from the bash scripting community
- Docker installation uses official Docker convenience scripts
- Thanks to all contributors and users for feedback and improvements

---

## Support

- **Issues**: [GitHub Issues](https://github.com/PavaraM/devbox/issues)
- **Discussions**: [GitHub Discussions](https://github.com/PavaraM/devbox/discussions)
- **Email**: pavaramirihagalla@icloud.com
- **Documentation**: [docs/](docs/)

---

## Changelog

### v1.0.0 (2026-02-14)
- Initial release
- Essential package installation
- Docker and Docker Compose support
- Comprehensive logging system
- Diagnostic capabilities with `doctor` command
- Modular library architecture
- User-accessible logs
- Automatic log archival
- Custom package support via `pkg.conf`

---

**Made with ❤️ by [Pavara Mirihagalla](https://github.com/PavaraM)**