#!/bin/bash
# lib/distro.sh — Multi-distro detection and abstraction layer
# Provides unified interfaces for package management, services, and firewall

DISTRO_ID=""
DISTRO_VERSION=""
DISTRO_CODENAME=""
DISTRO_FAMILY=""
DISTRO_NAME=""

PKG_MGR=""
SVC_MGR=""
FIREWALL_TOOL=""

distro_init() {
    if [[ ! -r /etc/os-release ]]; then
        log ERROR "Cannot detect OS: /etc/os-release not found"
        return 1
    fi

    source /etc/os-release

    DISTRO_ID="${ID:-unknown}"
    DISTRO_VERSION="${VERSION_ID:-unknown}"
    DISTRO_CODENAME="${VERSION_CODENAME:-}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID $DISTRO_VERSION}"

    case "$ID" in
        ubuntu|debian|linuxmint|pop|kali|raspbian|zorin|elementary)
            DISTRO_FAMILY="debian"
            PKG_MGR="apt"
            SVC_MGR="systemctl"
            FIREWALL_TOOL="ufw"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            DISTRO_FAMILY="rhel"
            PKG_MGR="dnf"
            SVC_MGR="systemctl"
            FIREWALL_TOOL="firewalld-cmd"
            ;;
        arch|manjaro|endeavouros|artix|garuda)
            DISTRO_FAMILY="arch"
            PKG_MGR="pacman"
            SVC_MGR="systemctl"
            FIREWALL_TOOL="nft"
            ;;
        opensuse*|suse)
            DISTRO_FAMILY="suse"
            PKG_MGR="zypper"
            SVC_MGR="systemctl"
            FIREWALL_TOOL="firewalld-cmd"
            ;;
        alpine)
            DISTRO_FAMILY="alpine"
            PKG_MGR="apk"
            SVC_MGR="rc-service"
            FIREWALL_TOOL="iptables"
            ;;
        *)
            # Try ID_LIKE fallback
            case " $ID_LIKE " in
                *debian*)
                    DISTRO_FAMILY="debian"
                    PKG_MGR="apt"
                    SVC_MGR="systemctl"
                    FIREWALL_TOOL="ufw"
                    ;;
                *fedora*|*rhel*)
                    DISTRO_FAMILY="rhel"
                    PKG_MGR="dnf"
                    SVC_MGR="systemctl"
                    FIREWALL_TOOL="firewalld-cmd"
                    ;;
                *arch*)
                    DISTRO_FAMILY="arch"
                    PKG_MGR="pacman"
                    SVC_MGR="systemctl"
                    FIREWALL_TOOL="nft"
                    ;;
                *alpine*)
                    DISTRO_FAMILY="alpine"
                    PKG_MGR="apk"
                    SVC_MGR="rc-service"
                    FIREWALL_TOOL="iptables"
                    ;;
                *)
                    log ERROR "Unsupported distribution: $ID (ID_LIKE: $ID_LIKE)"
                    return 1
                    ;;
            esac
            ;;
    esac

    log DEBUG "Detected: $DISTRO_NAME (family=$DISTRO_FAMILY, pkg=$PKG_MGR, svc=$SVC_MGR, fw=$FIREWALL_TOOL)"
    return 0
}

distro_supported() {
    [[ -n "$DISTRO_FAMILY" ]] && return 0
    return 1
}

# === PACKAGE MANAGER ===

pkg_install() {
    local verbose=false
    local quiet_flags=""
    [[ "$1" == "--verbose" ]] && { verbose=true; shift; }

    case "$PKG_MGR" in
        apt)
            [[ "$verbose" == false ]] && quiet_flags="-qq"
            apt install $quiet_flags -y "$@"
            ;;
        dnf)
            [[ "$verbose" == false ]] && quiet_flags="-q"
            dnf install $quiet_flags -y "$@"
            ;;
        pacman)
            [[ "$verbose" == false ]] && quiet_flags="--noconfirm"
            pacman -S $quiet_flags "$@"
            ;;
        zypper)
            [[ "$verbose" == false ]] && quiet_flags="-q"
            zypper install $quiet_flags -y "$@"
            ;;
        apk)
            [[ "$verbose" == false ]] && quiet_flags="-q"
            apk add $quiet_flags "$@"
            ;;
        *)
            log ERROR "Unknown package manager: $PKG_MGR"
            return 1
            ;;
    esac
}

pkg_remove() {
    case "$PKG_MGR" in
        apt)      apt remove -y "$@" ;;
        dnf)      dnf remove -y "$@" ;;
        pacman)   pacman -R --noconfirm "$@" ;;
        zypper)   zypper remove -y "$@" ;;
        apk)      apk del "$@" ;;
        *)        log ERROR "Unknown package manager: $PKG_MGR" ; return 1 ;;
    esac
}

pkg_update() {
    case "$PKG_MGR" in
        apt)      apt update -y ;;
        dnf)      dnf check-update -q || true ;;
        pacman)   pacman -Sy ;;
        zypper)   zypper refresh ;;
        apk)      apk update -q ;;
        *)        log ERROR "Unknown package manager: $PKG_MGR" ; return 1 ;;
    esac
}

pkg_upgrade() {
    log INFO "Upgrading installed packages..."
    case "$PKG_MGR" in
        apt)
            apt upgrade -y
            ;;
        dnf)
            dnf upgrade -y
            ;;
        pacman)
            pacman -Syu --noconfirm
            ;;
        zypper)
            zypper update -y
            ;;
        apk)
            apk upgrade -q
            ;;
        *)
            log ERROR "Unknown package manager: $PKG_MGR"
            return 1
            ;;
    esac
    log INFO "Package upgrade completed"
}

pkg_installed() {
    case "$PKG_MGR" in
        apt)      dpkg -s "$1" &>/dev/null ;;
        dnf)      rpm -q "$1" &>/dev/null ;;
        pacman)   pacman -Qi "$1" &>/dev/null ;;
        zypper)   rpm -q "$1" &>/dev/null ;;
        apk)      apk info -e "$1" &>/dev/null ;;
        *)        log ERROR "Unknown package manager: $PKG_MGR" ; return 1 ;;
    esac
}

pkg_cache_clean() {
    case "$PKG_MGR" in
        apt)      apt clean ;;
        dnf)      dnf clean all ;;
        pacman)   pacman -Scc --noconfirm ;;
        zypper)   zypper clean ;;
        apk)      apk cache clean ;;
    esac
}

# === SERVICE MANAGER ===

_svc_cmd() {
    local action=$1
    shift
    local services=("$@")

    case "$SVC_MGR" in
        systemctl)
            systemctl "$action" "${services[@]}"
            ;;
        rc-service)
            for svc in "${services[@]}"; do
                case "$action" in
                    start)   rc-service "$svc" start ;;
                    stop)    rc-service "$svc" stop ;;
                    restart) rc-service "$svc" restart ;;
                    reload)  rc-service "$svc" reload ;;
                    status)  rc-service "$svc" status ;;
                    enable)  rc-update add "$svc" ;;
                    disable) rc-update del "$svc" ;;
                    is-active) rc-service "$svc" status &>/dev/null ;;
                esac
            done
            ;;
        *)
            log ERROR "Unknown service manager: $SVC_MGR"
            return 1
            ;;
    esac
}

svc_start()    { _svc_cmd start "$@"; }
svc_stop()     { _svc_cmd stop "$@"; }
svc_restart()  { _svc_cmd restart "$@"; }
svc_reload()   { _svc_cmd reload "$@"; }
svc_enable()   { _svc_cmd enable "$@"; }
svc_disable()  { _svc_cmd disable "$@"; }
svc_status()   { _svc_cmd status "$@"; }
svc_is_active(){ _svc_cmd is-active "$@"; }

# === FIREWALL ===

firewall_allow_port() {
    local port=$1
    local proto="${2:-tcp}"

    case "$FIREWALL_TOOL" in
        ufw)
            ufw allow "$port/$proto"
            ;;
        firewalld-cmd)
            firewall-cmd --permanent --add-port="$port/$proto"
            firewall-cmd --reload
            ;;
        nft)
            nft add rule inet filter input tcp dport "$port" accept 2>/dev/null || \
            nft add rule ip filter INPUT tcp dport "$port" accept 2>/dev/null || \
            log WARN "nftables rule addition failed (may need manual setup)"
            ;;
        iptables)
            iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
            ;;
        *)
            log WARN "Firewall tool $FIREWALL_TOOL not yet supported"
            return 1
            ;;
    esac
}

firewall_limit_port() {
    local port=$1
    local proto="${2:-tcp}"

    case "$FIREWALL_TOOL" in
        ufw)
            ufw limit "$port/$proto"
            ;;
        firewalld-cmd)
            firewall_allow_port "$port" "$proto"
            log WARN "Rate limiting not supported on firewalld via DevBox"
            ;;
        nft|iptables)
            firewall_allow_port "$port" "$proto"
            log WARN "Rate limiting requires manual nftables/iptables rules"
            ;;
        *)
            log WARN "Firewall tool $FIREWALL_TOOL not yet supported"
            return 1
            ;;
    esac
}

firewall_default_deny() {
    case "$FIREWALL_TOOL" in
        ufw)
            ufw default deny incoming
            ufw default allow outgoing
            ;;
        firewalld-cmd)
            firewall-cmd --permanent --set-default-zone=drop
            firewall-cmd --reload
            ;;
        nft|iptables)
            log WARN "Set default policy manually in nftables/iptables"
            ;;
    esac
}

firewall_enable() {
    case "$FIREWALL_TOOL" in
        ufw)
            ufw --force enable
            ;;
        firewalld-cmd)
            svc_enable firewalld
            svc_start firewalld
            ;;
        nft)
            svc_enable nftables
            svc_start nftables
            ;;
        iptables)
            svc_enable iptables
            svc_start iptables
            ;;
    esac
}

firewall_status() {
    case "$FIREWALL_TOOL" in
        ufw)           ufw status ;;
        firewalld-cmd) firewall-cmd --state ;;
        nft)           nft list ruleset ;;
        iptables)      iptables -L -n ;;
    esac
}

firewall_is_active() {
    case "$FIREWALL_TOOL" in
        ufw)           ufw status | grep -q "Status: active" ;;
        firewalld-cmd) firewall-cmd --state &>/dev/null ;;
        nft)           svc_is_active nftables ;;
        iptables)      svc_is_active iptables ;;
        *)             return 1 ;;
    esac
}

# === USER MANAGEMENT ===

user_add() {
    local username=$1
    case "$DISTRO_FAMILY" in
        debian)   adduser --disabled-password --gecos "" "$username" ;;
        alpine)   adduser -D "$username" ;;
        rhel|arch|suse)
            useradd -m -s /bin/bash "$username"
            ;;
    esac
}

# === SYSTEM INFO ===

ssh_config_path() {
    echo "/etc/ssh/sshd_config"
}

sudo_cmd_wrapper() {
    if [[ "$DISTRO_FAMILY" == "alpine" ]]; then
        echo "doas"
    else
        echo "sudo"
    fi
}

is_bash_available() {
    command -v bash &>/dev/null
}

docker_pkg_name() {
    case "$DISTRO_FAMILY" in
        debian) echo "docker.io" ;;
        rhel)   echo "docker-ce" ;;
        arch|alpine) echo "docker" ;;
        suse)   echo "docker" ;;
        *)      echo "docker" ;;
    esac
}

# === DISTRO-SPECIAL BUILD GROUP ===

build_base_pkg() {
    case "$DISTRO_FAMILY" in
        debian) echo "build-essential" ;;
        rhel)   echo "@development-tools" ;;
        arch)   echo "base-devel" ;;
        alpine) echo "build-base" ;;
        suse)   echo "devel_basis"  ;;
    esac
}
