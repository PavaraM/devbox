#!/bin/bash
set -euo pipefail

# DevBox V1.0 - Development Environment Setup Script
# Author: Pavara Mirihagalla | License: MIT | Date: 2026-02-13

#exit codes:
# 0  - Success
# 1  - No root permission
# 2  - No argument provided
# 3  - Invalid argument
# 4  - Library loading failure
# 5  - Package installation failure
# 6  - Docker installation failure
# 7  - Docker service failure
# 8  - Docker group setup failure
# 9  - Docker Compose installation failure
# 10 - Docker verification failure

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP=$(date '+%Y-%m-%d')
readonly START_TIME=$(date +%s%3N)
# Load logging first (required for other operations)
if ! source "$SCRIPT_DIR/lib/logging.sh"; then
    echo "Error: Failed to load logging library" >&2
    exit 4
fi
trap log_footer EXIT

# ============================================================================
# EARLY VALIDATION (fail fast)
# ============================================================================

# Check for arguments first
if [[ $# -eq 0 ]]; then
    echo "Error: No arguments provided. Use --help for usage information." >&2
    log ERROR "No arguments provided"
    exit 2
fi

# Allow --help without root
if [[ "$1" == "--help" ]]; then
    cat << EOF
DevBox v1.0 - Development Environment Setup

Usage: $0 COMMAND [OPTIONS]

Commands:
  install       Set up development environment with essential packages
  doctor        Run diagnostic checks on the environment
  --help        Display this help message

Options:
  --plus-docker Install Docker and Docker Compose

Examples:
  $0 install
  $0 install --plus-docker
  $0 doctor

Exit Codes:
  0  - Success
  1  - No root permission
  2  - No argument provided
  3  - Invalid argument
  4  - Library loading failure
  5  - Package installation failure
  6  - Docker installation failure
  7  - Docker service failure
  8  - Docker group setup failure
  9  - Docker Compose installation failure
  10 - Docker verification failure

EOF
    exit 0
fi

# Check for root (after --help check)
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root" >&2
    log ERROR "Not running as root"
    exit 1
fi

# ============================================================================
# LOAD LIBRARIES
# ============================================================================

# Ensure library scripts are executable
for lib in packages.sh docker.sh; do
    lib_path="$SCRIPT_DIR/lib/$lib"
    log DEBUG "Checking library: $lib_path"
    if [[ ! -f "$lib_path" ]]; then
        echo "Error: Required library not found: $lib_path" >&2
        log ERROR "Required library not found: $lib_path"
        exit 4
    fi
    [[ ! -x "$lib_path" ]] && chmod +x "$lib_path"
    log INFO "Library \"$lib\" is present and executable"
done

# Load remaining libraries
for lib in packages.sh docker.sh; do
    if source "$SCRIPT_DIR/lib/$lib" &>> "${logfile:-/dev/null}"; then
        log INFO "\"lib/$lib\" loaded successfully"
    else
        log ERROR "Failed to load \"lib/$lib\""
        exit 4
    fi
done

# ============================================================================
# FUNCTIONS
# ============================================================================

run_install() {
    log INFO "Starting installation process"
    # apt_update  # Uncomment for production
    
    if ! main_essentials; then
        log ERROR "Failed to install essential packages"
        exit 5
    fi

    if ! networkingtools; then
        log ERROR "Failed to install networking tools"
        exit 5
    fi
    
    log INFO "Installation completed successfully"
}

run_doctor() {
    log INFO "Running diagnostic checks"
    
    # TODO: Implement comprehensive checks
    # - Verify essential packages are installed
    # - Check system requirements
    # - Validate configurations
    # - Test Docker if installed
    
    echo "Diagnostic checks not yet implemented"
    log WARN "Doctor command not yet implemented"
}

setup_docker() {
    log INFO "Starting Docker setup"
    
    if ! docker_setup; then
        log ERROR "Docker setup failed"
        exit 6
    fi
    
    log INFO "Docker setup completed successfully"
}

invalid_argument() {
    echo "Error: Invalid argument '$1'" >&2
    echo "Use --help for usage information" >&2
    log ERROR "Invalid argument: '$1'"
    exit 3
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

COMMAND=""
INSTALL_DOCKER=false

# Parse all arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        install|doctor)
            if [[ -n "$COMMAND" ]]; then
                echo "Error: Multiple commands specified" >&2
                exit 3
            fi
            COMMAND="$1"
            ;;
        --plus-docker)
            INSTALL_DOCKER=true
            ;;
        *)
            invalid_argument "$1"
            ;;
    esac
    shift
done

# Validate that a command was provided
if [[ -z "$COMMAND" ]]; then
    echo "Error: No command specified" >&2
    echo "Use --help for usage information" >&2
    exit 2
fi

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "DevBox v1.0"
echo "===================="
log INFO "Script started with command: $COMMAND"

case "$COMMAND" in
    install)
        run_install
        if [[ "$INSTALL_DOCKER" == true ]]; then
            setup_docker
        fi
        ;;
    doctor)
        run_doctor
        ;;
esac

log INFO "Script completed successfully"
exit 0