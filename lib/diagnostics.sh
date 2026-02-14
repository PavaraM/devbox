# lib/diagnostics.sh
# Diagnostics library for devbox

# Placeholder for future diagnostic functions

osinfo() {
    log INFO "Collecting OS information"
    echo "Collecting OS information..."
    distro=$(lsb_release -d 2>/dev/null | cut -f2- || echo "Unknown")
    kernel=$(uname -r)
    architecture=$(uname -m)
    userpermissions=$(id -u)
    internet=$(ping -c 1 google.com &>/dev/null && echo "Online" || echo "Offline")
    
    echo "Distro: $distro"
    echo "Kernel: $kernel"
    echo "Architecture: $architecture"
    echo "User Permissions: $userpermissions"
    echo "Internet Connectivity: $internet"
    log INFO "Distro: $distro"
    log INFO "Kernel: $kernel"
    log INFO "Architecture: $architecture"
    log INFO "User Permissions: $userpermissions"
    log INFO "Internet Connectivity: $internet"

    return 0
}

pkg_mgr_health() {
    report INFO "Checking package manager health..."
    if command -v apt &>/dev/null; then
        if ! apt update -qq; then
            report ERROR "APT package manager is not healthy"
            return 1
        fi
        report INFO "APT package manager is healthy"
    else
        report ERROR "No supported package manager found"
        return 1
    fi
    return 0
}

toolchain_verification() {
    report INFO "Verifying essential development tools..."
    local tools=(git curl wget htop tmux vim unzip tree net-tools ca-certificates build-essential ufw iproute2 dnsutils nmap)
    local all_ok=true
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            report ERROR "Required tool \"$tool\" is missing"
            all_ok=false
        else
            version=$("$tool" --version 2>&1 | head -n1)
            report INFO "Tool \"$tool\" is present: $version"
        fi
    done
    $all_ok && return 0 || return 1
}
