#!/bin/bash
# tests/run_tests.sh — Run the DevBox unit test suite (plain bash, no deps)
# Usage: bash tests/run_tests.sh

set -uo pipefail
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

total_pass=0
total_fail=0

for test in "$TESTS_DIR"/test_*.sh; do
    [[ -f "$test" ]] || continue
    echo ""
    echo "=== $(basename "$test") ==="
    output=$(bash "$test" 2>&1)
    rc=$?
    echo "$output"
    if [[ $rc -ne 0 ]]; then
        echo ">>> FAILED: $(basename "$test")"
        total_fail=$((total_fail + 1))
    else
        echo ">>> OK: $(basename "$test")"
        total_pass=$((total_pass + 1))
    fi
done

echo ""
echo "Suites passed: $total_pass / $((total_pass + total_fail))"
if [[ $total_fail -ne 0 ]]; then
    echo "Some test suites failed"
    exit 1
fi
echo "All test suites passed"
exit 0
