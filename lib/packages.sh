#!/bin/bash
# lib/packages.sh — Multi-distro package management

pkg_update_system() {
    pkg_update
    log INFO "Package lists updated successfully"
    if [[ "${DIST_UPGRADE:-false}" == true ]]; then
        pkg_upgrade
        log INFO "Distribution upgrade completed"
    fi
}

pkg_install_wrapper() {
    local pkg_log="$SCRIPT_DIR/logs/pkg/$TIMESTAMP-$1.log"
    mkdir -p "$(dirname "$pkg_log")"

    log DEBUG "Installing $2..."
    if pkg_verbose_install "$2" >> "$pkg_log" 2>&1; then
        echo "$1 installed successfully."
        log INFO "$1 installation successful"
        return 0
    else
        echo "$1 installation failed (check $pkg_log for details)"
        log ERROR "$1 installation failed (see log: $1.log)"
        return 1
    fi
}

pkg_check_and_install() {
    local name=$1
    local pkg_name
    pkg_name=$(pkg_map "$2")

    log DEBUG "Checking if $pkg_name is installed..."

    if pkg_installed "$pkg_name"; then
        echo "$name is already available."
        log INFO "$name already installed on this system."
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would install $name ($pkg_name)"
        log INFO "[DRY RUN] Would install $name ($pkg_name)"
        return 0
    fi

    echo "$name is not installed, installing now..."
    log INFO "$name not installed"

    local log_dir="$SCRIPT_DIR/logs/pkg"
    mkdir -p "$log_dir"
    local pkg_log="$log_dir/pkg_$TIMESTAMP-$name.log"

    log DEBUG "Running $PKG_MGR install $pkg_name"

    if pkg_install "$pkg_name" >> "$pkg_log" 2>&1; then
        echo "$name installed successfully."
        log INFO "$name installation successful"
    else
        echo "$name installation failed (check $pkg_log for details)"
        log ERROR "$name installation failed (see log: pkg_$TIMESTAMP-$name.log)"
        return 1
    fi

    if [[ -n "${SUDO_USER:-}" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$pkg_log" 2>/dev/null || true
    fi
}

_install_group() {
    local group_name=$1
    shift
    local packages=("$@")
    local failed=()

    log INFO "Installing $group_name..."
    for pkg in "${packages[@]}"; do
        if ! pkg_check_and_install "$pkg" "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if [[ ${#failed[@]} -eq 0 ]]; then
        log INFO "All $group_name installed successfully"
        return 0
    else
        log ERROR "Failed to install ${#failed[@]} package(s): ${failed[*]}"
        echo "Warning: Some $group_name failed to install: ${failed[*]}"
        return 1
    fi
}

main_essentials() {
    local packages=(
        "git" "curl" "wget" "htop" "tmux"
        "vim" "unzip" "tree" "net-tools"
        "ca-certificates" "build-essential"
    )
    _install_group "essential packages" "${packages[@]}"
}

networkingtools() {
    local packages=(
        "ufw" "iproute2" "dnsutils" "nmap"
    )
    _install_group "networking tools" "${packages[@]}"
}

custom_packages() {
    log DEBUG "Checking for custom packages from \"$SCRIPT_DIR/conf/pkg.conf\"..."
    if [[ -f "$SCRIPT_DIR/conf/pkg.conf" ]]; then
        source "$SCRIPT_DIR/conf/pkg.conf"
    fi

    if [[ ${#CUSTOM_PACKAGES[@]} -eq 0 ]]; then
        log INFO "No custom packages to install"
        return 0
    fi

    echo "Custom packages to install: ${CUSTOM_PACKAGES[*]}"
    log INFO "Installing custom packages: ${CUSTOM_PACKAGES[*]}"

    local failed=()
    for pkg in "${CUSTOM_PACKAGES[@]}"; do
        if ! pkg_check_and_install "$pkg" "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if [[ ${#failed[@]} -eq 0 ]]; then
        return 0
    fi

    log ERROR "Failed to install custom package(s): ${failed[*]}"
    return 1
}

pkg_verbose_install() {
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pacman -S --noconfirm "$@"
    elif [[ "$PKG_MGR" == "apk" ]]; then
        apk add "$@"
    else
        pkg_install --verbose "$@"
    fi
}
