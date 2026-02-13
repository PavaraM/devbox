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
🛡️ **Robust Error Handling** - Granular exit codes for easy debugging  
⚡ **Idempotent Operations** - Safe to run multiple times  
📁 **User-Accessible Logs** - Logs owned by your user, not root  

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
```

---

## Installation

### Prerequisites

- Ubuntu 20.04+ (or Debian-based distributions)
- Root/sudo access
- Internet connection

### Structure

```
devbox/
├── devbox.sh           # Main script
├── lib/                # Library modules
│   ├── docker.sh       # Docker installation & setup
│   ├── logging.sh      # Logging utilities
│   └── packages.sh     # Package management
├── logs/               # Execution logs (auto-created)
│   ├── devbox_*.log    # Main script logs
│   ├── apt/            # Per-package installation logs
│   │   └── apt_*.log   
│   └── archive/        # Archived logs (7+ days old)
│       ├── devbox_*.log
│       └── apt/
└── docs/
    ├── README.md       # This file
    └── DEBUGGING.md    # Debugging guide
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
- **Version Control**: git
- **Network Tools**: curl, wget, net-tools, ca-certificates, ufw, iproute2, dnsutils, nmap
- **System Utilities**: htop, tmux, tree, unzip
- **Development**: neovim, build-essential

#### `install --plus-docker`
Install everything plus Docker and Docker Compose.

```bash
sudo ./devbox.sh install --plus-docker
```

**Additionally configures:**
- Docker Engine (latest stable)
- Docker Compose plugin (v2.24.5)
- Docker service auto-start
- User permissions for non-root Docker access

> **Note:** You'll need to log out and back in for Docker group permissions to take effect.

#### `doctor`
Run diagnostic checks on your environment *(coming soon)*.

```bash
sudo ./devbox.sh doctor
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

---

## Logging

Every execution creates a timestamped log file in the `logs/` directory:

```
logs/devbox_2026-02-14.log
logs/apt/apt_2026-02-14-git.log
logs/apt/apt_2026-02-14-curl.log
```

**Features:**
- 📝 **Main log** - Overall script execution
- 📦 **Per-package APT logs** - Individual installation details
- 🗄️ **Auto-archival** - Logs older than 7 days moved to `archive/`
- 👤 **User ownership** - All logs owned by your user, not root

**Log Format:**
```
script started at Sat Feb 14 01:45:38 +0530 2026
command: devbox install --plus-docker
system: Linux OBSIDIAN 6.17.0-14-generic ...
user: root (SUDO_USER: pavara)
------------------------------
2026-02-14 01:45:38 [INFO] Script started with command: install
2026-02-14 01:45:38 [DEBUG] Checking if git is installed...
2026-02-14 01:45:39 [INFO] git installation successful
...
------------------------------
Script ended at Sat Feb 14 01:45:40 +0530 2026 exit_code=0 duration=2.192s
==============================
```

---

## Advanced Usage

### Custom Package Installation

Edit `lib/packages.sh` to add your own packages:

```bash
main_essentials() {
    check_and_install_apt git git-all
    check_and_install_apt curl curl
    # Add your packages here
    check_and_install_apt python3 python3-pip
    check_and_install_apt nodejs npm
}
```

### Disable Networking Tools

The `networkingtools()` function is enabled by default. To disable it, modify `devbox.sh`:

```bash
run_install() {
    log INFO "Starting installation process"
    main_essentials
    # networkingtools  # Comment this line to skip
    log INFO "Installation completed successfully"
}
```

### Fix Log Ownership

If logs were created as root, use the included utility:

```bash
# Check ownership
./fix-logs-ownership.sh

# Fix it
sudo ./fix-logs-ownership.sh
```

---

## Architecture

### Design Principles

1. **Fail Fast** - Early validation prevents wasted execution
2. **Modular Libraries** - Each concern isolated in its own file
3. **Defensive Programming** - Extensive error checking and logging
4. **Idempotency** - Safe to re-run without side effects
5. **Transparency** - Detailed logging of all operations
6. **User-Friendly** - Logs accessible without sudo

### Library Overview

#### `lib/logging.sh`
- Timestamp-based log file creation
- Execution duration tracking
- Structured logging with levels (INFO, DEBUG, ERROR, WARN)
- Automatic log archival (7+ days)
- User ownership management

#### `lib/packages.sh`
- Generic `check_and_install_apt()` helper
- Pre-configured package collections
- Per-package APT logging
- Failed package tracking and reporting
- Silent installation with logged output

#### `lib/docker.sh`
- Modern Docker Compose plugin installation
- Architecture detection (x86_64, aarch64, armv7)
- Service configuration and verification
- User group management
- Comprehensive error handling

---

## Troubleshooting

See [DEBUGGING.md](docs/DEBUGGING.md) for comprehensive troubleshooting guide.

### Quick Fixes

**Script must be run as root:**
```bash
sudo ./devbox.sh install
```

**Library loading failure:**
```bash
chmod +x lib/*.sh
```

**Docker group not taking effect:**
```bash
newgrp docker
# Or log out and back in
```

**Logs are root-owned:**
```bash
sudo ./fix-logs-ownership.sh
```

---

## Roadmap

### v1.1 (Planned)
- [ ] Implement `doctor` command with health checks
- [ ] Add `--dry-run` flag for safe testing
- [ ] Support for additional Linux distributions
- [ ] Configuration file support
- [ ] Rollback functionality
- [ ] Color-coded console output
- [ ] `--quiet` and `--verbose` modes

### v2.0 (Future)
- [ ] Web dashboard for remote management
- [ ] Plugin system for extensibility
- [ ] Multi-language runtime support (Python, Node, Go, Rust)
- [ ] Container orchestration templates
- [ ] Package update checking

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/PavaraM/devbox.git
cd devbox

# Make your changes
vim lib/packages.sh

# Test your changes
sudo ./devbox.sh install

# Check logs for issues
tail -f logs/devbox_*.log
```

### Coding Standards

- Use `set -euo pipefail` for error handling
- Add descriptive log messages for all operations
- Quote all variables: `"$variable"`
- Use `readonly` for constants
- Return specific exit codes (see Exit Codes section)
- Fix ownership of created files with `chown "$SUDO_USER:$SUDO_USER"`

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

---

## Support

- **Issues**: [GitHub Issues](https://github.com/PavaraM/devbox/issues)
- **Discussions**: [GitHub Discussions](https://github.com/PavaraM/devbox/discussions)
- **Email**: pavaramirihagalla@icloud.com

---

**Made with ❤️ by [Pavara Mirihagalla](https://github.com/PavaraM)**