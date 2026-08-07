#!/bin/bash
# tests/test_argparse.sh — Tests for devbox.sh CLI argument handling

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

DEVOX="$SCRIPT_DIR/devbox.sh"

begin_test "--help exits 0 and lists commands"
out=$("$DEVOX" --help 2>&1)
rc=$?
assert_eq "$rc" "0"
assert_contains "$out" "Usage:"
assert_contains "$out" "install"
assert_contains "$out" "doctor"
assert_contains "$out" "--dist-upgrade"
assert_contains "$out" "--resume"
assert_contains "$out" "--with-mise"
assert_contains "$out" "--json"

begin_test "--version exits 0 and reports version"
out=$("$DEVOX" --version 2>&1)
rc=$?
assert_eq "$rc" "0"
assert_contains "$out" "2.0.0"

begin_test "-V exits 0 and reports version"
out=$("$DEVOX" -V 2>&1)
rc=$?
assert_eq "$rc" "0"
assert_contains "$out" "2.0.0"

begin_test "no arguments exits 2"
"$DEVOX" >/dev/null 2>&1
assert_eq "$?" "2"

begin_test "shell bash exits 0 and emits completion script"
out=$("$DEVOX" shell bash 2>&1)
rc=$?
assert_eq "$rc" "0"
assert_contains "$out" "_devbox_completions"
assert_contains "$out" "complete -F _devbox_completions"

begin_test "shell zsh exits 0"
"$DEVOX" shell zsh >/dev/null 2>&1
assert_eq "$?" "0"

begin_test "shell with unsupported shell exits 1"
"$DEVOX" shell fish >/dev/null 2>&1
assert_eq "$?" "1"

begin_test "invalid argument handled (exit 3 as root, exit 1 as non-root)"
"$DEVOX" --bogus-flag >/dev/null 2>&1
rc=$?
if [[ $EUID -eq 0 ]]; then
    assert_eq "$rc" "3"
else
    assert_eq "$rc" "1"
fi

begin_test "install without root is rejected with exit 1"
if [[ $EUID -ne 0 ]]; then
    "$DEVOX" install >/dev/null 2>&1
    assert_eq "$?" "1"
else
    echo "  SKIP: running as root, install would execute"
fi

summary
