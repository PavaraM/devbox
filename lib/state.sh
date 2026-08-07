#!/bin/bash
# lib/state.sh — Persistent install state tracking (JSON)

STATE_DIR="${DEVBOX_STATE_DIR:-/var/lib/devbox}"
STATE_FILE="$STATE_DIR/state"

state_init() {
    mkdir -p "$STATE_DIR"
}

state_mark() {
    local step="$1"
    state_init
    local -A seen=()
    local line key first=1
    if [[ -f "$STATE_FILE" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ \"([^\"]+)\"[[:space:]]*:[[:space:]]*true ]]; then
                seen["${BASH_REMATCH[1]}"]=1
            fi
        done < "$STATE_FILE"
    fi
    seen["$step"]=1
    {
        echo "{"
        for key in $(printf '%s\n' "${!seen[@]}" | sort); do
            if [[ $first -eq 0 ]]; then echo ","; fi
            printf '  "%s": true' "$key"
            first=0
        done
        echo ""
        echo "}"
    } > "$STATE_FILE"
}

state_done() {
    local step="$1"
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi
    grep -q "\"$step\"[[:space:]]*:[[:space:]]*true" "$STATE_FILE"
}

state_clear() {
    rm -f "$STATE_FILE"
}
