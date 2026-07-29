#!/bin/bash
# lib/diagnostics.sh — Multi-distro diagnostics library

passed=0

osinfo() {
    report DEBUG "Collecting OS information..."
    report INFO "Distribution: $DISTRO_NAME"
    report INFO "Family: $DISTRO_FAMILY"
    report INFO "Version: $DISTRO_VERSION"
    report INFO "Package Manager: $PKG_MGR"
    report INFO "Service Manager: $SVC_MGR"
    report INFO "Firewall Tool: $FIREWALL_TOOL"
    kernel=$(uname -r)
    architecture=$(uname -m)
    userpermissions=$(id -u)
    internet=$(curl -fs -o /dev/null -w "%{http_code}" http://google.com &>/dev/null && echo "online" || echo "offline")

    report INFO "Kernel: $kernel"
    report INFO "Architecture: $architecture"
    report INFO "User Permissions: $userpermissions"
    report INFO "Internet Connectivity: $internet"

    if [[ "$internet" != "online" ]]; then
        report WARN "Internet is offline"
    fi

    passed=$((passed + 1))
    return 0
}

pkg_mgr_health() {
    report DEBUG "Checking package manager health..."

    if ! command -v "$PKG_MGR" &> /dev/null; then
        report ERROR "$PKG_MGR not found"
        return 1
    fi

    case "$PKG_MGR" in
        apt)
            if lsof /var/lib/dpkg/lock &>/dev/null 2>&1; then
                report ERROR "dpkg is locked"
                return 11
            fi
            if dpkg --audit 2>/dev/null | grep . &>/dev/null; then
                report ERROR "Broken packages detected"
                return 14
            fi
            ;;
        dnf|zypper)
            if lsof /var/lib/rpm/.rpm.lock &>/dev/null 2>&1; then
                report ERROR "RPM is locked"
                return 11
            fi
            ;;
        pacman)
            if [[ -f /var/lib/pacman/db.lck ]]; then
                report ERROR "pacman is locked"
                return 11
            fi
            ;;
        apk)
            if [[ -f /lib/apk/db/lock ]]; then
                report WARN "apk may be locked"
            fi
            ;;
    esac

    report INFO "$PKG_MGR package manager is healthy"
    passed=$((passed + 1))
    return 0
}

toolchain_verification() {
    report DEBUG "Verifying essential development tools..."
    local tools=("git" "curl" "wget" "htop" "tmux" "vim" "unzip" "tree" "net-tools" "ca-certificates" "build-essential")
    local all_ok=true

    for tool in "${tools[@]}"; do
        local pkg_name
        pkg_name=$(pkg_map "$tool")
        if ! pkg_installed "$pkg_name"; then
            report ERROR "Required tool \"$tool\" ($pkg_name) is missing"
            all_ok=false
        else
            report INFO "Tool \"$tool\" is present."
        fi
    done

    if [[ "$all_ok" == true ]]; then
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
    if [[ -f "$SCRIPT_DIR/conf/pkg.conf" ]]; then
        source "$SCRIPT_DIR/conf/pkg.conf"
    fi

    if [[ ${#CUSTOM_PACKAGES[@]} -eq 0 ]]; then
        report INFO "No custom packages defined in pkg.conf"
        passed=$((passed + 1))
        return 0
    fi

    local all_ok=true
    for pkg in "${CUSTOM_PACKAGES[@]}"; do
        if ! pkg_installed "$pkg"; then
            report ERROR "Custom package \"$pkg\" is missing"
            all_ok=false
        else
            report INFO "Custom package \"$pkg\" is present."
        fi
    done

    if [[ "$all_ok" == true ]]; then
        report INFO "All custom packages are present"
        passed=$((passed + 1))
        return 0
    else
        report ERROR "One or more custom packages are missing"
        return 14
    fi
}

ssh_harden_check() {
    report DEBUG "Checking SSH hardening..."
    local sshd_config
    sshd_config=$(ssh_config_path)

    if [[ ! -f "$sshd_config" ]]; then
        report WARN "SSH server is not installed"
    elif grep -q "^PermitRootLogin no" "$sshd_config" 2>/dev/null; then
        report INFO "SSH hardening is applied"
    else
        report WARN "SSH hardening is not applied"
    fi
    passed=$((passed + 1))
    return 0
}

firewall_check() {
    report DEBUG "Checking firewall status..."
    if ! command -v "$FIREWALL_TOOL" &>/dev/null; then
        report WARN "Firewall tool ($FIREWALL_TOOL) is not installed"
    elif firewall_is_active; then
        report INFO "Firewall is active"
    else
        report WARN "Firewall is not active"
    fi
    passed=$((passed + 1))
    return 0
}

deploy_user_check() {
    report DEBUG "Checking deploy user..."
    source "$SCRIPT_DIR/conf/security.conf"

    if id "$DEPLOY_USERNAME" &>/dev/null; then
        report INFO "Deploy user $DEPLOY_USERNAME exists"
    else
        report INFO "No deploy user configured"
    fi
    passed=$((passed + 1))
    return 0
}

report_summary() {
    local total_checks=7

    if [[ "$passed" -eq "$total_checks" && "$total_checks" -gt 0 ]]; then
        status="PASSED"
    else
        status="FAILED"
    fi

    echo "======================="
    echo "Diagnostic Summary"
    echo "status: $status"
    echo "checks_passed: $passed/$total_checks"
    echo "report generated at: $reportfile"
    echo "======================="
}
