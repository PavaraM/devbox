#!/bin/bash
# tests/test_profiles.sh — Tests for lib/profiles.sh profile loading/accumulation

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

source "$SCRIPT_DIR/lib/profiles.sh"

# Stub _install_group (normally from lib/packages.sh) to capture args
INSTALLED_GROUP=""
_install_group() {
    INSTALLED_GROUP="$1: ${*:2}"
    return 0
}

begin_test "profile_list prints available profiles"
out=$(profile_list)
assert_contains "$out" "Available profiles:"
assert_contains "$out" "python-dev"
assert_contains "$out" "base"
assert_contains "$out" "cloud-dev"

begin_test "profile_list returns 1 when directory missing"
PROFILE_DIR="/tmp/nonexistent-profiles"
if profile_list 2>/dev/null; then fail "expected failure"; else pass; fi
PROFILE_DIR="$SCRIPT_DIR/conf/profiles"

begin_test "profile_load rejects invalid names"
if profile_load "bad name!" 2>/dev/null; then fail "expected failure"; else pass; fi

begin_test "profile_load rejects nonexistent profile"
if profile_load "does-not-exist" 2>/dev/null; then fail "expected failure"; else pass; fi

begin_test "profile_load python-dev accumulates packages"
profile_load "python-dev"
if [[ ${#_ACCUM_PKGS[@]} -gt 0 ]]; then pass; else fail "no packages accumulated"; fi
assert_contains "${_ACCUM_PKGS[*]}" "python3"

begin_test "profile_load adds to ACTIVE_PROFILES"
assert_contains "${ACTIVE_PROFILES[*]}" "python-dev"

begin_test "profile_wants_docker false by default"
if profile_wants_docker; then fail "expected docker=false"; else pass; fi

begin_test "cloud-dev profile wants docker"
profile_load "cloud-dev"
assert_true profile_wants_docker

begin_test "profile_apply installs accumulated packages"
profile_apply
assert_contains "$INSTALLED_GROUP" "profile packages"

begin_test "profile_apply with no active profiles is a no-op"
ACTIVE_PROFILES=()
_ACCUM_PKGS=()
out=$(profile_apply)
assert_contains "$out" "No profiles selected"

begin_test "profile_apply_extra respects DRY_RUN"
_ACCUM_CMDS=("echo hi")
DRY_RUN=true
out=$(profile_apply_extra)
assert_contains "$out" "[DRY RUN] Would run: echo hi"
DRY_RUN=false

begin_test "profile_deploy_user prints accumulated user"
_ACCUM_DEPLOY="deploy"
assert_eq "$(profile_deploy_user)" "deploy"

summary
