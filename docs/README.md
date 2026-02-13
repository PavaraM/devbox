# Project Devbox - Personal Machine Bootstrapper
## Overview
DevBox v1.0 is an automated setup script designed to bootstrap a development environment on Debian-based Linux systems. It handles package management, essential tool installation, and Docker configuration.

## Quick Start
```bash
sudo ./devbox.sh --install
```

## Usage
- `--install` - Set up development environment with essentials and Docker
- `--doctor` - Run diagnostic checks (coming soon)

## Directory Structure
```
devbox/
├── devbox.sh          # Main setup script
├── lib/               # Function libraries
│   ├── docker.sh      # Docker installation and 
│   ├── packages.sh    # Essential packages and tools 
│   └── logging.sh     # Logging utilities and functions
├── docs/              # Documentation
│   ├── README.md      # Project documentation
│   └── DEBUGING.md    # Debugging guide and exit codes
└── logs/              # Script execution logs 
```

## Documentation
- [Debugging Guide](./DEBUGING.md) - Troubleshooting and exit codes

## Logs
All script execution logs are stored in the `logs/` directory with timestamps. Each run generates a log file named `devbox_<timestamp>.log` containing:
- Script start/end times
- Commands executed
- Exit codes and duration
- Timestamped log entries for each operation

### Sample Log Output

```log
script started at Fri Feb 13 23:26:28 +0530 2026
command: devbox --install
------------------------------
23:26:28 [DEBUG] Loading libraries...
23:26:28 [INFO] "lib/packages.sh" loaded successfully.
23:26:28 [INFO] "lib/docker.sh" loaded successfully.
23:26:28 [DEBUG] Checking if git is installed on this system...
23:26:28 [INFO] git already installed on this system.
23:26:28 [DEBUG] Checking if curl is installed on this system...
23:26:28 [INFO] curl already installed on this system.
23:26:30 [INFO] Docker service enabled on boot successfully
23:26:30 [DEBUG] Checking if Docker Compose is installed...
23:26:30 [INFO] Docker Compose already installed on this system.
23:26:30 [INFO] user root added to docker group successfully
Docker version 29.2.1, build a5c7197
23:26:30 [INFO] Docker and Docker Compose are installed and working correctly.
------------------------------
Script ended at Fri Feb 13 23:26:30 +0530 2026 exit_code=0 duration=2.049s
==============================
```

## Requirements
- Root/sudo access
- Debian-based Linux system
- Internet connection

## Author
Pavara Mirihagalla  
License: MIT License  
Version: 1.0