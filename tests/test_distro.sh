#!/bin/bash
# tests/test_distro.sh — Tests for lib/distro.sh detection on the host OS

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

source "$SCRIPT_DIR/lib/distro.sh"

begin_test "distro_init succeeds on host"
assert_true distro_init

begin_test "distro family is one of the supported families"
case "$DISTRO_FAMILY" in
    debian|rhel|arch|suse|alpine) pass ;;
    *) fail "unexpected DISTRO_FAMILY=$DISTRO_FAMILY" ;;
esac

begin_test "distro globals are populated"
assert_true test -n "$DISTRO_NAME"
assert_true test -n "$PKG_MGR"
assert_true test -n "$SVC_MGR"
assert_true test -n "$FIREWALL_TOOL"

begin_test "distro_supported reflects detected family"
if distro_supported; then
    pass
else
    fail "distro_supported returned non-zero for $DISTRO_FAMILY"
fi

begin_test "distro globals are exported"
env | grep -q "^DISTRO_FAMILY="
assert_eq "$?" "0"

summary
