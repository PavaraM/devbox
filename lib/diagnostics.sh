# lib/diagnostics.sh
# Diagnostics library for devbox

# Placeholder for future diagnostic functions
passed=0

osinfo() {
    report DEBUG "Collecting OS information..."
    distro=$(lsb_release -d 2>/dev/null | cut -f2- || echo "Unknown")
    kernel=$(uname -r)
    architecture=$(uname -m)
    userpermissions=$(id -u)
    internet=$(ping -c 1 google.com &>/dev/null && echo "online" || echo "offline")
    
    report INFO "Distro: $distro"
    report INFO "Kernel: $kernel"
    report INFO "Architecture: $architecture"
    report INFO "User Permissions: $userpermissions"
    report INFO "Internet Connectivity: $internet"

    if [ ! "$internet" = "online" ]; then
        report WARN "Internet is offline"
    fi

    passed=$((passed + 1))
    return 0
}

pkg_mgr_health() {
    report DEBUG "Checking package manager health..."

    if ! command -v apt &> /dev/null; then
        report ERROR "APT not found"
        return 1
    fi

    # Check dpkg lock
    if lsof /var/lib/dpkg/lock &>/dev/null; then
        report ERROR "dpkg is locked"
        return 11
    fi

    # Check broken packages
    if dpkg --audit | grep . &>/dev/null; then
        report ERROR "Broken packages detected"
        return 15
    fi

    report INFO "APT package manager is healthy"
    passed=$((passed + 1))
    return 0
}


toolchain_verification() {
    report DEBUG "Verifying essential development tools..."
    local tools=(git curl wget htop tmux vim unzip tree net-tools ca-certificates build-essential ufw iproute2 dnsutils nmap)
    local all_ok=true
    for tool in "${tools[@]}"; do
        if ! dpkg -s "$tool" &>/dev/null; then
            report ERROR "Required tool \"$tool\" is missing"
            all_ok=false
        else
            report INFO "Tool \"$tool\" is present."
        fi
    done
    if [ "$all_ok" = true ]; then
        report INFO "All essential development tools are present"
        passed=$((passed + 1))
        return 0
    else
        report ERROR "One or more essential development tools are missing"
        return 13
    fi
}

custom_packages_check() {
    report DEBUG "Checking custom packages..."
    source "$SCRIPT_DIR/pkg.conf"
    if [ ${#CUSTOM_PACKAGES[@]} -eq 0 ]; then
        report INFO "No custom packages defined in pkg.conf"
        passed=$((passed + 1))
        return 0
    fi
    local all_ok=true
    for pkg in "${CUSTOM_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            report ERROR "Custom package \"$pkg\" is missing"
            all_ok=false
        else
            report INFO "Custom package \"$pkg\" is present."
        fi
    done
    if [ "$all_ok" = true ]; then
        report INFO "All custom packages are present"
        passed=$((passed + 1))
        return 0
    else
        report ERROR "One or more custom packages are missing"
        return 14
    fi
}

report_summary() {
    if [ $passed -eq 3 ]; then
        status="PASSED"
    else
        status="FAILED"
    fi

    echo "======================="
    echo "Diagnostic Summary"
    echo "status: $status"
    echo "checks_passed: $passed/3"
    echo "report generated at: $reportfile"
    echo "======================="
}