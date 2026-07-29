#!/bin/bash
# lib/pkgmap.sh — Canonical to distro-specific package name mapping
# Sources: lib/distro.sh (must be loaded first)

# Usage: pkg_map "git" → returns distro-specific name
#        pkg_map "git" "vim" "curl" → returns all mapped names

pkg_map() {
    local canonical
    local result=()

    for canonical in "$@"; do
        case "$DISTRO_FAMILY:$canonical" in
            # Core tools
            debian:git)              result+=("git") ;;
            rhel:git)                result+=("git") ;;
            arch:git)                result+=("git") ;;
            alpine:git)              result+=("git") ;;
            suse:git)                result+=("git") ;;

            debian:curl)             result+=("curl") ;;
            rhel:curl)               result+=("curl") ;;
            arch:curl)               result+=("curl") ;;
            alpine:curl)             result+=("curl") ;;
            suse:curl)               result+=("curl") ;;

            debian:wget)             result+=("wget") ;;
            rhel:wget)               result+=("wget") ;;
            arch:wget)               result+=("wget") ;;
            alpine:wget)             result+=("wget") ;;
            suse:wget)               result+=("wget") ;;

            # Text editors
            debian:vim)              result+=("neovim") ;;
            rhel:vim)                result+=("vim-enhanced") ;;
            arch:vim)                result+=("neovim") ;;
            alpine:vim)              result+=("neovim") ;;
            suse:vim)                result+=("vim") ;;

            # System tools
            debian:htop)             result+=("htop") ;;
            rhel:htop)               result+=("htop") ;;
            arch:htop)               result+=("htop") ;;
            alpine:htop)             result+=("htop") ;;
            suse:htop)               result+=("htop") ;;

            debian:tmux)             result+=("tmux") ;;
            rhel:tmux)               result+=("tmux") ;;
            arch:tmux)               result+=("tmux") ;;
            alpine:tmux)             result+=("tmux") ;;
            suse:tmux)               result+=("tmux") ;;

            debian:unzip)            result+=("unzip") ;;
            rhel:unzip)              result+=("unzip") ;;
            arch:unzip)              result+=("unzip") ;;
            alpine:unzip)            result+=("unzip") ;;
            suse:unzip)              result+=("unzip") ;;

            debian:tree)             result+=("tree") ;;
            rhel:tree)               result+=("tree") ;;
            arch:tree)               result+=("tree") ;;
            alpine:tree)             result+=("tree") ;;
            suse:tree)               result+=("tree") ;;

            # Network
            debian:net-tools)        result+=("net-tools") ;;
            rhel:net-tools)          result+=("net-tools") ;;
            arch:net-tools)          result+=("net-tools") ;;
            alpine:net-tools)        result+=("net-tools") ;;
            suse:net-tools)          result+=("net-tools") ;;

            debian:ca-certificates)  result+=("ca-certificates") ;;
            rhel:ca-certificates)    result+=("ca-certificates") ;;
            arch:ca-certificates)    result+=("ca-certificates") ;;
            alpine:ca-certificates)  result+=("ca-certificates") ;;
            suse:ca-certificates)    result+=("ca-certificates") ;;

            # Build
            debian:build-essential)  result+=("$(build_base_pkg)") ;;
            rhel:build-essential)    result+=("$(build_base_pkg)") ;;
            arch:build-essential)    result+=("$(build_base_pkg)") ;;
            alpine:build-essential)  result+=("$(build_base_pkg)") ;;
            suse:build-essential)    result+=("$(build_base_pkg)") ;;

            # Firewall
            debian:ufw)              result+=("ufw") ;;
            rhel:ufw)                result+=("firewalld") ;;
            arch:ufw)                result+=("ufw") ;;
            alpine:ufw)              result+=("iptables") ;;
            suse:ufw)                result+=("firewalld") ;;

            # Network tools
            debian:iproute2)         result+=("iproute2") ;;
            rhel:iproute2)           result+=("iproute") ;;
            arch:iproute2)           result+=("iproute2") ;;
            alpine:iproute2)         result+=("iproute2") ;;
            suse:iproute2)           result+=("iproute2") ;;

            debian:dnsutils)         result+=("dnsutils") ;;
            rhel:dnsutils)           result+=("bind-utils") ;;
            arch:dnsutils)           result+=("bind") ;;
            alpine:dnsutils)         result+=("bind-tools") ;;
            suse:dnsutils)           result+=("bind-utils") ;;

            debian:nmap)             result+=("nmap") ;;
            rhel:nmap)               result+=("nmap") ;;
            arch:nmap)               result+=("nmap") ;;
            alpine:nmap)             result+=("nmap") ;;
            suse:nmap)               result+=("nmap") ;;

            # Languages
            debian:python3)          result+=("python3") ;;
            rhel:python3)            result+=("python3") ;;
            arch:python3)            result+=("python") ;;
            alpine:python3)          result+=("python3") ;;
            suse:python3)            result+=("python3") ;;

            debian:python3-pip)      result+=("python3-pip") ;;
            rhel:python3-pip)        result+=("python3-pip") ;;
            arch:python3-pip)        result+=("python-pip") ;;
            alpine:python3-pip)      result+=("py3-pip") ;;
            suse:python3-pip)        result+=("python3-pip") ;;

            # Docker
            debian:docker)           result+=("docker.io") ;;
            rhel:docker)             result+=("docker-ce") ;;
            arch:docker)             result+=("docker") ;;
            alpine:docker)           result+=("docker") ;;
            suse:docker)             result+=("docker") ;;

            # Default: use the canonical name as-is
            *)
                result+=("$canonical")
                ;;
        esac
    done

    printf '%s\n' "${result[@]}"
}

# Bulk map: read canonical names from stdin, output distro-specific names
pkg_map_bulk() {
    local names=()
    if [[ $# -gt 0 ]]; then
        names=("$@")
    else
        while IFS= read -r line; do
            [[ -n "$line" ]] && names+=("$line")
        done
    fi
    pkg_map "${names[@]}"
}
