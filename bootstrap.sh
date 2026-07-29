#!/bin/sh
# DevBox v2 Bootstrap — zero-dependency POSIX sh installer
# Usage: curl -fsSL https://raw.githubusercontent.com/PavaraM/devbox/v2/bootstrap.sh | sh
#        curl -fsSL https://raw.githubusercontent.com/PavaraM/devbox/v2/bootstrap.sh | sh -s -- --profile python-dev
set -e

REPO_OWNER="PavaraM"
REPO_NAME="devbox"
REPO_BRANCH="v2"
INSTALL_DIR="${DEVBOX_DIR:-${HOME:-/root}/devbox}"

if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BOLD=''; NC=''
fi

info()   { printf "${GREEN}%s${NC}\n" "$*"; }
warn()   { printf "${YELLOW}Warning: %s${NC}\n" "$*"; }
error()  { printf "${RED}%s${NC}\n" "$*" >&2; }
header() { printf "\n${BOLD}%s${NC}\n" "$*"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        error "This script needs root access to install packages."
        error "Run as root, or install sudo."
        exit 1
    fi
fi

detect_pkg_mgr() {
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt"
        PKG_INSTALL="apt-get install -y"
        PKG_UPDATE="apt-get update -qq"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf check-update || true"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MGR="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum check-update || true"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MGR="apk"
        PKG_INSTALL="apk add"
        PKG_UPDATE="apk update"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MGR="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_UPDATE="zypper refresh"
    else
        error "Unsupported package manager."
        error "Install bash, curl, and git manually, then run: bash $INSTALL_DIR/devbox.sh"
        exit 1
    fi
}

run_root() {
    ${SUDO} sh -c "$*"
}

main() {
    header "DevBox v2 — Bootstrap Installer"
    echo ""

    detect_pkg_mgr
    info "Detected package manager: $PKG_MGR"

    header "Step 1/4: Updating package lists"
    run_root "$PKG_UPDATE" || warn "Package update skipped"

    header "Step 2/4: Installing prerequisites"
    for pkg in bash curl git; do
        if command -v "$pkg" >/dev/null 2>&1; then
            info "  $pkg already available"
        else
            info "  Installing $pkg..."
            run_root "$PKG_INSTALL $pkg" || {
                error "Failed to install $pkg. Install it manually."
                exit 1
            }
        fi
    done

    header "Step 3/4: Fetching DevBox"
    if [ -d "$INSTALL_DIR/.git" ]; then
        info "Updating existing installation at $INSTALL_DIR"
        git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || {
            warn "Update failed, re-cloning..."
            rm -rf "$INSTALL_DIR"
            git clone --branch "$REPO_BRANCH" "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$INSTALL_DIR"
        }
    else
        info "Cloning to $INSTALL_DIR"
        git clone --branch "$REPO_BRANCH" "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$INSTALL_DIR"
    fi

    for f in "$INSTALL_DIR/devbox.sh" "$INSTALL_DIR/lib"/*.sh; do
        chmod +x "$f" 2>/dev/null || true
    done

    header "Step 4/4: Launching DevBox"
    echo ""
    info "DevBox installed at: $INSTALL_DIR"
    echo ""

    exec bash "$INSTALL_DIR/devbox.sh" "$@"
}

main "$@"
