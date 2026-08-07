#!/bin/bash
# tests/test_state.sh — Tests for lib/state.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

export DEVBOX_STATE_DIR="$(mktemp -d /tmp/devbox-state-test.XXXXXX)"
trap 'rm -rf "$DEVBOX_STATE_DIR"' EXIT

source "$SCRIPT_DIR/lib/state.sh"

begin_test "state_done returns 1 when state file missing"
assert_false state_done "packages"

begin_test "state_init creates state directory"
state_init
assert_true test -d "$DEVBOX_STATE_DIR"

begin_test "state_mark packages writes JSON"
state_mark "packages"
content=$(cat "$STATE_FILE")
assert_eq "$content" $'{\n  "packages": true\n}'

begin_test "state_done packages returns 0 after mark"
assert_true state_done "packages"

begin_test "state_done unknown step returns 1"
assert_false state_done "docker"

begin_test "state_mark adds new step and keeps existing"
state_mark "docker"
assert_true state_done "packages"
assert_true state_done "docker"

begin_test "state file remains valid JSON"
python3 -m json.tool "$STATE_FILE" >/dev/null 2>&1
assert_eq "$?" "0"

begin_test "state_clear removes state file"
state_clear
assert_false test -f "$STATE_FILE"

summary
