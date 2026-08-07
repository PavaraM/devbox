#!/bin/bash
set -euo pipefail
# DevBox v2.0 - Development Environment Setup Script
# Author: Pavara Mirihagalla | License: MIT

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
# 11 - Diagnostic check failure
# 12 - No internet connection for diagnostics
# 13 - Essential tool missing in diagnostics
# 14 - Package manager is not healthy
# 15 - SSH hardening failure
# 16 - Firewall configuration failure
# 17 - Deploy user setup failure
# 18 - Version manager setup failure

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
readonly TIMESTAMP=$(date '+%Y-%m-%d')
readonly START_TIME=$(date +%s%3N)
# Load logging first (required for other operations)
if ! source "$SCRIPT_DIR/lib/logging.sh"; then
    echo "Error: Failed to load logging library" >&2
    exit 4
fi
logger_init

# Load distro detection early (no deps)
for lib in distro.sh; do
    lib_path="$SCRIPT_DIR/lib/$lib"
    if [[ -f "$lib_path" ]]; then
        source "$lib_path"
    fi
done

# Detect the OS distribution
if ! distro_init; then
    echo "Error: Unsupported Linux distribution" >&2
    exit 4
fi


# ============================================================================
# EARLY VALIDATION (fail fast)
# ============================================================================

# Check for arguments first
if [[ $# -eq 0 ]]; then
    echo "Error: No arguments provided. Use --help for usage information." >&2
    log ERROR "No arguments provided"
    exit 2
fi

# Allow --help and --version without root
if [[ "$1" == "--help" ]]; then
    cat << EOF
DevBox v2.0 - Multi-Distro Development Environment Setup

Detected: $DISTRO_NAME

Usage: $0 COMMAND [OPTIONS]

Commands:
  install (i)   Set up development environment with essential packages
  doctor (d)    Run diagnostic checks on the environment
  distro        Display detected operating system information
  profiles      List available installation profiles
  hooks         List installed lifecycle hooks
  shell         Generate shell completion script
  --config      Open custom package config in editor
  --help        Display this help message

Options:
  --plus-docker Install Docker and Docker Compose
  --harden      Harden SSH configuration and configure firewall
  --setup-user  Create a deploy user with SSH access and groups (requires username)
  --all, -a     Shorthand for --plus-docker --harden (can combine with --setup-user)
  --profile P   Use a profile from conf/profiles/ (repeatable: --profile python-dev --profile node-dev)
  --dist-upgrade Upgrade all packages (default: update package lists only)
  --resume      Skip steps already completed (from /var/lib/devbox state)
  --with-mise   Install mise and tools listed in conf/tools.conf
  --dry-run     Show what would be done without making changes
  --verbose, -v Increase log verbosity
  --quiet, -q   Suppress non-error output

Supported Distributions:
  Debian/Ubuntu, Fedora/RHEL, Arch Linux, Alpine Linux, openSUSE

Examples:
  $0 install
  $0 i --profile python-dev
  $0 install --plus-docker --harden --setup-user deploy
  $0 --all --setup-user deploy
  $0 doctor
  $0 distro

EOF
    exit 0
fi

# Allow --version without root
if [[ "$1" == "--version" || "$1" == "-V" ]]; then
    if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
        cat "$SCRIPT_DIR/VERSION"
    else
        echo "DevBox v2.0"
    fi
    exit 0
fi

# Check for root (after --help/--version check)
if [[ "$1" == "shell" ]]; then
    # shell completions don't need root — generate and exit
    SHELL_TYPE="${2:-bash}"
    case "$SHELL_TYPE" in
        bash)
            cat << 'BASH_EOF'
_devbox_completions() {
    local cur prev words cword
    _init_completion || return
    local commands="install doctor distro shell"
    local opts="--help --version -V --config --plus-docker --harden --setup-user --all --profile --dist-upgrade --resume --with-mise --dry-run --verbose --quiet"
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands $opts" -- "$cur"))
    elif [[ $cword -ge 2 ]]; then
        case "${words[1]}" in
            install|i) COMPREPLY=($(compgen -W "--plus-docker --harden --setup-user --all --profile --dist-upgrade --resume --with-mise --dry-run" -- "$cur")) ;;
            --profile) local profiles; profiles=$(ls "$SCRIPT_DIR/conf/profiles/"*.conf 2>/dev/null | sed 's|.*/||;s/\.conf$//'); COMPREPLY=($(compgen -W "$profiles" -- "$cur")) ;;
        esac
    fi
} && complete -F _devbox_completions devbox.sh
BASH_EOF
        ;;
        zsh)
            cat << 'ZSH_EOF'
#compdef devbox.sh
_devbox() {
    local -a commands
    commands=('install:Set up' 'i:Alias' 'doctor:Diagnose' 'd:Alias' 'distro:OS info' 'shell:Completions')
    _describe 'command' commands
}
ZSH_EOF
        ;;
        *) echo "Unsupported shell: $SHELL_TYPE (use bash or zsh)" >&2; exit 1 ;;
    esac
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root" >&2
    log ERROR "Not running as root"
    exit 1
fi

# ============================================================================
# LOAD LIBRARIES
# ============================================================================

# Ensure library scripts are executable
for lib in pkgmap.sh packages.sh docker.sh diagnostics.sh reporting.sh security.sh config.sh profiles.sh hooks.sh state.sh version-manager.sh; do
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
for lib in pkgmap.sh packages.sh docker.sh reporting.sh diagnostics.sh security.sh config.sh profiles.sh hooks.sh state.sh version-manager.sh; do
    if source "$SCRIPT_DIR/lib/$lib" &>> "${logfile:-/dev/null}"; then
        log INFO "\"lib/$lib\" loaded successfully"
    else
        log ERROR "Failed to load \"lib/$lib\""
        exit 4
    fi
done
# Load configuration hierarchy
config_load

# ============================================================================
# FUNCTIONS
# ============================================================================

run_install() {
    log INFO "Starting installation process on $DISTRO_NAME"
    hooks_run "pre-install"
    pkg_update_system

    if ! main_essentials; then
        log ERROR "Failed to install essential packages"
        exit 5
    fi

    if ! networkingtools; then
        log ERROR "Failed to install networking tools"
        exit 5
    fi

    if ! custom_packages; then
        log ERROR "Failed to install custom packages"
        exit 5
     fi

    hooks_run "post-install"
    log INFO "Installation completed successfully"
}

run_doctor() {
    init_reporting
    passed=0
    GENERAL_HEALTH_CHECKS=(
        osinfo
        pkg_mgr_health
        toolchain_verification
        custom_packages_check
        ssh_harden_check
        firewall_check
        deploy_user_check
    )
    echo "Running diagnostics..."
    log DEBUG "Running diagnostic checks..."
    for check in "${GENERAL_HEALTH_CHECKS[@]}"; do
        if ! $check; then
            log ERROR "Diagnostic check \"$check\" failed"
            exit 11
        fi
    done
    report INFO "Diagnostics completed successfully"
    log INFO "All diagnostic checks passed successfully"
    log INFO "Diagnostic report saved to $reportfile"
}

setup_docker() {
    log INFO "Starting Docker setup"
    hooks_run "pre-docker"
    
    if ! docker_setup; then
        log ERROR "Docker setup failed"
        exit 6
    fi
    
    hooks_run "post-docker"
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
OPEN_CONFIG=false
export DRY_RUN=false
HARDEN=false
SETUP_USER=""
DIST_UPGRADE=false
RESUME=false
WITH_MISE=false
declare -a CLI_PROFILES=()
VERBOSE=false
QUIET=false

# Parse all arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        install|i)
            [[ "$1" == "i" ]] && COMMAND="install" || COMMAND="$1"
        ;;
        doctor|d)
            [[ "$1" == "d" ]] && COMMAND="doctor" || COMMAND="$1"
        ;;
        distro|profiles|p|hooks|shell)
            if [[ -n "$COMMAND" ]]; then
                echo "Error: Multiple commands specified" >&2
                exit 3
            fi
            case "$1" in
                p) COMMAND="profiles" ;;
                *) COMMAND="$1" ;;
            esac
        ;;
        --all|-a)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="install"
            elif [[ "$COMMAND" != "install" ]]; then
                echo "Error: --all can only be used with install" >&2
                exit 3
            fi
            INSTALL_DOCKER=true
            HARDEN=true
        ;;
        --plus-docker)
            INSTALL_DOCKER=true
        ;;
        --harden)
            HARDEN=true
        ;;
        --setup-user)
            if [[ $# -lt 2 ]]; then
                echo "Error: --setup-user requires a username" >&2
                exit 3
            fi
            SETUP_USER="$2"
            shift
        ;;
        --dry-run)
            DRY_RUN=true
        ;;
        --dist-upgrade)
            DIST_UPGRADE=true
        ;;
        --resume)
            RESUME=true
        ;;
        --with-mise)
            WITH_MISE=true
        ;;
        --config)
            OPEN_CONFIG=true
        ;;
        --profile)
            if [[ $# -lt 2 ]]; then
                echo "Error: --profile requires a profile name" >&2
                exit 3
            fi
            CLI_PROFILES+=("$2")
            shift
        ;;
        --verbose|-v)
            VERBOSE=true
        ;;
        --quiet|-q)
            QUIET=true
        ;;
        *)
            invalid_argument "$1"
        ;;
    esac
    shift
done

# Open config and exit when no command is requested
if [[ "$OPEN_CONFIG" == true && -z "$COMMAND" ]]; then
    conf_target=""
    case "${DISTRO_FAMILY:-}" in
        debian) conf_target="$SCRIPT_DIR/conf/apt-packages.conf" ;;
        rhel)   conf_target="$SCRIPT_DIR/conf/dnf-packages.conf" ;;
        *)      conf_target="$SCRIPT_DIR/conf/pkg.conf" ;;
    esac
    [[ -f "$conf_target" ]] || conf_target="$SCRIPT_DIR/conf/pkg.conf"
    nano "$conf_target"
    log INFO "Opened $(basename "$conf_target") for editing"
    exit 0
fi

# Validate that a command was provided
if [[ -z "$COMMAND" ]]; then
    echo "Error: No command specified" >&2
    echo "Use --help for usage information" >&2
    exit 2
fi

# Load profiles (CLI profiles override config profiles)
for p in "${CLI_PROFILES[@]}"; do
    if ! profile_load "$p"; then
        echo "Error: Profile '$p' not found. Use 'profiles' command to list available profiles." >&2
        exit 3
    fi
done
if [[ ${#CLI_PROFILES[@]} -eq 0 ]]; then
    for p in $(config_get_profiles); do
        profile_load "$p" || true
    done
fi

# Validate install-specific flags
if [[ "$COMMAND" != "install" ]]; then
    if [[ "$INSTALL_DOCKER" == true ]]; then
        echo "Error: --plus-docker requires the install command" >&2
        exit 3
    fi
    if [[ "$HARDEN" == true ]]; then
        echo "Error: --harden requires the install command" >&2
        exit 3
    fi
    if [[ -n "$SETUP_USER" ]]; then
        echo "Error: --setup-user requires the install command" >&2
        exit 3
    fi
    if [[ "$DIST_UPGRADE" == true ]]; then
        echo "Error: --dist-upgrade requires the install command" >&2
        exit 3
    fi
    if [[ "$RESUME" == true ]]; then
        echo "Error: --resume requires the install command" >&2
        exit 3
    fi
    if [[ "$WITH_MISE" == true ]]; then
        echo "Error: --with-mise requires the install command" >&2
        exit 3
    fi
fi

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "DevBox v2.0 — $DISTRO_NAME"
echo "=============================="
if [[ "$DRY_RUN" == true ]]; then
    echo "*** DRY RUN MODE - No changes will be made ***"
    echo ""
fi
log INFO "Script started with command: $COMMAND"

case "$COMMAND" in
    distro)
        echo "DevBox v2 — Distribution Info"
        echo "============================="
        echo "Name:       $DISTRO_NAME"
        echo "Family:     $DISTRO_FAMILY"
        echo "Version:    $DISTRO_VERSION"
        echo "Code Name:  $DISTRO_CODENAME"
        echo "Arch:       $(uname -m)"
        echo "Kernel:     $(uname -r)"
        echo "Pkg Mgr:    $PKG_MGR"
        echo "Svc Mgr:    $SVC_MGR"
        echo "Firewall:   $FIREWALL_TOOL"
        exit 0
    ;;
    profiles)
        profile_list
    ;;
    hooks)
        hooks_list
    ;;
    install)
        if [[ "$RESUME" == true ]]; then
            state_init
        fi
        if [[ "$RESUME" == true ]] && state_done "packages"; then
            log INFO "Resume: packages already installed, skipping"
        else
            run_install
            profile_apply
            profile_apply_extra
            if [[ "$RESUME" == true ]]; then
                state_mark "packages"
            fi
        fi
        if [[ "$WITH_MISE" == true ]]; then
            if [[ "$RESUME" == true ]] && state_done "version-manager"; then
                log INFO "Resume: version manager already set up, skipping"
            else
                if ! setup_version_manager; then
                    log ERROR "Version manager setup failed"
                    exit 18
                fi
                if [[ "$RESUME" == true ]]; then
                    state_mark "version-manager"
                fi
            fi
        fi
        if [[ "$INSTALL_DOCKER" == true ]] || profile_wants_docker; then
            if [[ "$RESUME" == true ]] && state_done "docker"; then
                log INFO "Resume: Docker already installed, skipping"
            else
                setup_docker
                if [[ "$RESUME" == true ]]; then
                    state_mark "docker"
                fi
            fi
        fi
        if [[ "$HARDEN" == true ]] || profile_wants_harden; then
            if [[ "$RESUME" == true ]] && state_done "harden"; then
                log INFO "Resume: security hardening already applied, skipping"
            else
                hooks_run "pre-harden"
                if ! ssh_harden; then
                    log ERROR "SSH hardening failed"
                    exit 15
                fi
                if ! configure_firewall; then
                    log ERROR "Firewall configuration failed"
                    exit 16
                fi
                hooks_run "post-harden"
                if [[ "$RESUME" == true ]]; then
                    state_mark "harden"
                fi
            fi
        fi
        deploy_user="${SETUP_USER:-$(profile_deploy_user)}"
        if [[ -n "$deploy_user" ]]; then
            if [[ "$RESUME" == true ]] && state_done "user"; then
                log INFO "Resume: deploy user already setup, skipping"
            else
                hooks_run "pre-user"
                if ! setup_deploy_user "$deploy_user"; then
                    log ERROR "Deploy user setup failed"
                    exit 17
                fi
                hooks_run "post-user"
                if [[ "$RESUME" == true ]]; then
                    state_mark "user"
                fi
            fi
        fi
    ;;
    doctor)
        run_doctor
        report_summary >> "$reportfile"
        report_summary >> "$logfile"
    ;;
esac

log INFO "Script completed successfully"
exit 0