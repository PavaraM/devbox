#!/bin/bash
# tests/test_hooks.sh — Tests for lib/hooks.sh hook lifecycle

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Override HOOKS_DIR after sourcing? No: hooks.sh sets HOOKS_DIR at source time.
# Instead source hooks.sh, then point HOOKS_DIR at a temp tree.
source "$SCRIPT_DIR/lib/hooks.sh"

TMP_HOOKS="$(mktemp -d /tmp/devbox-hooks-test.XXXXXX)"
trap 'rm -rf "$TMP_HOOKS"' EXIT
HOOKS_DIR="$TMP_HOOKS"

mkdir -p "$HOOKS_DIR/pre-install"
cat > "$HOOKS_DIR/pre-install/20-second.sh" <<'EOF'
#!/bin/bash
echo "second hook ran"
EOF
cat > "$HOOKS_DIR/pre-install/10-first.sh" <<'EOF'
#!/bin/bash
echo "first hook ran"
EOF
chmod +x "$HOOKS_DIR/pre-install"/*.sh

mkdir -p "$HOOKS_DIR/post-install"

begin_test "hooks_run runs hooks in lexicographic order"
out=$(hooks_run "pre-install" 2>&1)
first=$(echo "$out" | grep -o "first hook ran" | head -1)
second=$(echo "$out" | grep -o "second hook ran" | head -1)
assert_eq "$first" "first hook ran"
assert_eq "$second" "second hook ran"
order_ok=$(echo "$out" | grep -n "first hook ran" | head -1 | cut -d: -f1)
order_ok2=$(echo "$out" | grep -n "second hook ran" | head -1 | cut -d: -f1)
if [[ -n "$order_ok" && -n "$order_ok2" && $order_ok -lt $order_ok2 ]]; then pass; else fail "hooks not in lexicographic order"; fi

begin_test "hooks_run returns 0 for missing phase directory"
assert_true hooks_run "does-not-exist"

begin_test "hooks_run returns 0 for empty phase directory"
assert_true hooks_run "post-install"

begin_test "hooks_run honors DRY_RUN"
DRY_RUN=true
out=$(hooks_run "pre-install" 2>&1)
assert_contains "$out" "[DRY RUN] Would run hook: 10-first.sh"
DRY_RUN=false

begin_test "hooks_list lists hooks per phase"
out=$(hooks_list)
assert_contains "$out" "pre-install: 2 hook(s)"
assert_contains "$out" "10-first.sh"
assert_contains "$out" "post-install: 0 hook(s)"

begin_test "hooks_list handles missing dir"
HOOKS_DIR="$TMP_HOOKS/nonexistent"
out=$(hooks_list)
assert_contains "$out" "No hooks directory found"

summary
