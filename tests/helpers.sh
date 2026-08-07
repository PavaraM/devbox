#!/bin/bash
# tests/helpers.sh — Shared test helpers and assert utilities (no external deps)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPT_DIR

# Minimal log() stub so libraries can be sourced without the logging framework
if ! declare -F log >/dev/null 2>&1; then
    log() {
        local level="$1"
        shift
        case "$level" in
            ERROR) echo "  [ERROR] $*" >&2 ;;
            *)     echo "  [$level] $*" ;;
        esac
    }
fi

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST=""

begin_test() { CURRENT_TEST="$1"; }

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  PASS: $CURRENT_TEST"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL: $CURRENT_TEST: $*" >&2
}

assert_eq() {
    if [[ "$1" == "$2" ]]; then pass; else fail "expected '$1', got '$2'"; fi
}

assert_true() {
    if "$@"; then pass; else fail "expected success: $*"; fi
}

assert_false() {
    if "$@"; then fail "expected failure: $*"; else pass; fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" == *"$needle"* ]]; then pass; else fail "expected '$needle' in: $haystack"; fi
}

summary() {
    echo ""
    echo "Tests passed: $PASS_COUNT"
    echo "Tests failed: $FAIL_COUNT"
    [[ $FAIL_COUNT -eq 0 ]]
}
