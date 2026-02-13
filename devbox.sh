#!/bin/bash
set -euo pipefail
start_time=$(date +%s%3N)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# DevBox V1.0 - Development Environment Setup Script
# Author: Pavara Mirihagalla | License: MIT | Date: 2026-02-13

timestamp=$(date '+%Y-%m-%d')

# Ensure library scripts are executable
if [ ! -x "$SCRIPT_DIR/lib/logging.sh" ] || [ ! -x "$SCRIPT_DIR/lib/packages.sh" ] || [ ! -x "$SCRIPT_DIR/lib/docker.sh" ]; then
    chmod +x "$SCRIPT_DIR/lib/logging.sh" "$SCRIPT_DIR/lib/packages.sh" "$SCRIPT_DIR/lib/docker.sh"
fi

echo "DevBox v1.0"
echo "---------------------------"

source "$SCRIPT_DIR/lib/logging.sh"
trap log_footer EXIT

# Error handlers
wrong_arg() {
    echo "Invalid Input"
    log ERROR "Invalid Argument: \"$1\""
    exit 3
}

no_arg() {
    echo "No Input - Try Again.."
    log ERROR "Missing Argument."
    exit 2
}

# Load required libraries
pull_libraries() {
    log DEBUG "Loading libraries..."
    
    if source "$SCRIPT_DIR/lib/packages.sh" &>> $logfile; then
        log INFO "\"lib/packages.sh\" loaded successfully."
    else
        log ERROR "Failed to load \"lib/packages.sh\""
        echo "Failed Loading libraries."
        exit 4
    fi

    if source "$SCRIPT_DIR/lib/docker.sh"; then
        log INFO "\"lib/docker.sh\" loaded successfully."
    else
        log ERROR "Failed to load \"lib/docker.sh\""
        exit 4
    fi
}

# Main installation workflow
installscript() {
    pull_libraries
    # apt_update  # Commented for testing - uncomment for production
    main_essentials
}

# Validate arguments
if [ $# -eq 0 ]; then
    no_arg
fi

# Help message
case $1 in
    --help)
        echo "Usage: $0 [install|doctor|--help] [--plus-docker]"
        echo "  install         Set up development environment"
        echo "  doctor          Run diagnostic checks (not implemented)"
        echo "  --help          Display this help message"
        echo "  --plus-docker   Install Docker and Docker Compose"
        exit 0
esac

# Require root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    log ERROR "No ROOT Permission."
    exit 1
fi

# Process main command
case $1 in
    install)
        installscript
        ;;
    doctor)
        # TODO: Implement diagnostic checks
        ;;
    *)
        wrong_arg "$1"
        ;;
esac

# Process additional flags
shift
for arg in "$@"; do
    case "$arg" in
        --plus-docker) docker_setup ;;
        *) wrong_arg "$arg" ;;
    esac
done

exit 0

# Exit codes:
# 0  - Success
# 1  - No root permission
# 2  - No argument provided
# 3  - Invalid argument
# 4  - Library loading failure
# 5  - apt installation failure
# 6  - Docker installation failure
# 7  - Docker service start failure
# 8  - Docker group setup failure
# 9  - Docker Compose installation failure
# 10 - Docker setup verification failure