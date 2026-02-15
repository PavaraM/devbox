# lib/packages.sh
# This file contains functions to check and install essential packages for development.

apt_update() {
    log INFO "Updating APT package lists..."
    if apt update -y &> /dev/null; then
        log INFO "APT update successful"
    else
        log ERROR "APT update failed"
        return 5
    fi
    
    log INFO "Upgrading installed packages..."
    if apt upgrade -y &> /dev/null; then
        log INFO "APT upgrade successful"
    else
        log ERROR "APT upgrade failed"
        return 5
    fi
}


# A generic helper for standard packages
check_and_install_apt() {
    local name=$1
    local pkg_name=$2
    local aptlog="$SCRIPT_DIR/logs/apt/apt_$TIMESTAMP-$name.log"

    log DEBUG "Checking if $name is installed on this system..."
    if dpkg -s $name &> /dev/null; then
        echo "$name is already available."
        log INFO "$name already installed on this system."
        return 0
    fi
    echo "$name is not installed, installing now..."
    log INFO "$name not installed"
    log DEBUG "Running apt install $pkg_name"
    if sudo apt install "$pkg_name" -y >> "$aptlog" 2>&1; then
        # Fix ownership of the apt log file
        if [[ -n "$SUDO_USER" ]]; then
            chown "$SUDO_USER:$SUDO_USER" "$aptlog"
        fi
        echo "$name installed successfully."
        log INFO "$name installation successful"
    else
        # Fix ownership of the apt log file
        if [[ -n "$SUDO_USER" ]]; then
            chown "$SUDO_USER:$SUDO_USER" "$aptlog"
        fi
        echo "$name installation failed (check $aptlog for details)"
        log ERROR "$name installation failed (see apt log: apt_$TIMESTAMP-$name.log)"
        return 5
    fi
}

main_essentials() {
    log INFO "Installing essential development packages..."
    local failed_packages=()
    
    # Check and install each package, tracking failures
#   check_and_install_apt [name] [pkg-name]
    check_and_install_apt git git-all || failed_packages+=("git")
    check_and_install_apt curl curl || failed_packages+=("curl")
    check_and_install_apt wget wget || failed_packages+=("wget")
    check_and_install_apt htop htop || failed_packages+=("htop")
    check_and_install_apt tmux tmux || failed_packages+=("tmux")
    check_and_install_apt vim neovim || failed_packages+=("vim/neovim")
    check_and_install_apt unzip unzip || failed_packages+=("unzip")
    check_and_install_apt tree tree || failed_packages+=("tree")
    check_and_install_apt net-tools net-tools || failed_packages+=("net-tools")
    check_and_install_apt ca-certificates ca-certificates || failed_packages+=("ca-certificates")
    check_and_install_apt build-essential build-essential || failed_packages+=("build-essential")

    # Report results
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "All essential packages installed successfully"
        return 0
    else
        log ERROR "Failed to install ${#failed_packages[@]} package(s): ${failed_packages[*]}"
        echo "Warning: Some packages failed to install: ${failed_packages[*]}"
        return 5
    fi
}

networkingtools() {
    log INFO "Installing networking tools..."
    local failed_packages=()
    
    check_and_install_apt ufw ufw || failed_packages+=("ufw")
    check_and_install_apt iproute2 iproute2 || failed_packages+=("iproute2")
    check_and_install_apt dnsutils dnsutils || failed_packages+=("dnsutils")
    check_and_install_apt nmap nmap || failed_packages+=("nmap")
    # ufw, iproute2, dnsutils, nmap
    # Report results
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "All networking tools installed successfully"
        return 0
    else
        log ERROR "Failed to install ${#failed_packages[@]} networking tool(s): ${failed_packages[*]}"
        echo "Warning: Some networking tools failed to install: ${failed_packages[*]}"
        return 5
    fi
}

custom_packages() {
    log DEBUG "Checking for custom packages to install from \"$SCRIPT_DIR/pkg.conf\"..."
    source "$SCRIPT_DIR/pkg.conf"
    local failed_packages=()
    if [ ${#CUSTOM_PACKAGES[@]} -eq 0 ]; then
        log INFO "No custom packages to install"
        return 0
    fi
    echo "Custom packages to install: ${CUSTOM_PACKAGES[*]}"
    log INFO "Installing custom packages: ${CUSTOM_PACKAGES[*]}"
    for pkg in "${CUSTOM_PACKAGES[@]}"; do
        if ! check_and_install_apt "$pkg" "$pkg"; then
            log ERROR "Failed to install custom package: $pkg"
            failed_packages+=("$pkg")
        else
            log INFO "Custom package $pkg installed successfully"
        fi
    done

    if [ ${#failed_packages[@]} -eq 0 ]; then
        return 0
    fi

    log ERROR "Failed to install ${#failed_packages[@]} custom package(s): ${failed_packages[*]}"
    return 5
}
