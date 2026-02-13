# lib/essentials.sh
# This file contains functions to check and install essential packages for development.

apt_update() {
    apt update -y
    apt upgrade -y
}


# A generic helper for standard packages
check_and_install_apt() {
    local name=$1
    local pkg_name=$2
    log DEBUG "Checking if $name is installed on this system..."
    if dpkg -s $name &> /dev/null; then
        echo "$name is already available."
        log INFO "$name already installed on this system."
        return 0
    fi
    echo "$name is not installed, installing now..."
    log INFO "$name not installed"
    log DEBUG "Running apt install $pkg_name"
    if sudo apt install "$pkg_name" -y >> "$logfile" 2>&1; then
        echo "$name installed successfully."
        log INFO "$name installation successful"
    else
        echo "$name installation failed"
        log ERROR "$name installation failed"
        return 5
    fi
}

main_essentials() {
#   check_and_install_apt [name] [pkg-name]
    check_and_install_apt git git-all
    check_and_install_apt curl curl
    check_and_install_apt wget wget
    check_and_install_apt htop htop
    check_and_install_apt tmux tmux
    check_and_install_apt vim neovim
    check_and_install_apt unzip unzip
    check_and_install_apt tree tree
    check_and_install_apt net-tools net-tools
    check_and_install_apt ca-certificates ca-certificates
    check_and_install_apt build-essential build-essential
}

Networkingtools() {
    check_and_install_apt ufw ufw
    check_and_install_apt iproute2 iproute2
    check_and_install_apt dnsutils dnsutils
    check_and_install_apt nmap nmap
}
