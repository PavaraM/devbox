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
│   ├── docker.sh
│   ├── essentials.sh
│   └── logging.sh
└── logs/              # Script execution logs
```

## Documentation
- [Debugging Guide](./DEBUGING.md) - Troubleshooting and exit codes

## Requirements
- Root/sudo access
- Debian-based Linux system
- Internet connection

## Author
Pavara Mirihagalla  
License: MIT License  
Version: 1.0