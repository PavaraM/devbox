#!/bin/bash
# tests/test_pkgmap.sh — Tests for lib/pkgmap.sh canonical → distro name mapping

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

source "$SCRIPT_DIR/lib/distro.sh"
source "$SCRIPT_DIR/lib/pkgmap.sh"

test_family() {
    local family="$1"
    local name="$2"
    local expected="$3"
    DISTRO_FAMILY="$family"
    begin_test "pkg_map $name ($family) → $expected"
    assert_eq "$(pkg_map "$name")" "$expected"
}

# vim mapping varies by family
test_family debian vim neovim
test_family rhel vim vim-enhanced
test_family arch vim neovim
test_family alpine vim neovim
test_family suse vim vim

# identity mapping for common tools
test_family debian git git
test_family rhel git git
test_family arch git git
test_family alpine git git
test_family suse git git

# family-specific firewall/net tools
test_family debian ufw ufw
test_family rhel ufw firewalld
test_family alpine ufw iptables
test_family debian dnsutils dnsutils
test_family rhel dnsutils bind-utils
test_family arch dnsutils bind
test_family alpine dnsutils bind-tools
test_family debian iproute2 iproute2
test_family rhel iproute2 iproute

# build-essential maps via build_base_pkg (sourced from distro.sh)
test_family debian build-essential build-essential
test_family rhel build-essential "@development-tools"
test_family alpine build-essential build-base

# bulk mapping
begin_test "pkg_map_bulk maps multiple canonical names"
DISTRO_FAMILY=debian
assert_eq "$(pkg_map_bulk git curl vim)" $'git\ncurl\nneovim'

# unknown canonical falls through to itself
begin_test "pkg_map unknown canonical passes through"
DISTRO_FAMILY=debian
assert_eq "$(pkg_map some-random-tool)" "some-random-tool"

summary
