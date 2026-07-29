#!/bin/bash
# lib/hooks.sh — Hook lifecycle engine
# Runs executable scripts from conf/hooks/ at lifecycle points.
# Hook naming: NN-name.sh (lexicographic order, e.g. 10-preflight.sh)

HOOKS_DIR="$SCRIPT_DIR/conf/hooks"

hooks_run() {
    local phase="$1"
    local hook_dir="$HOOKS_DIR/$phase"

    if [[ ! -d "$hook_dir" ]]; then
        log DEBUG "No hooks directory for phase '$phase'"
        return 0
    fi

    log INFO "Running $phase hooks..."

    local hook
    for hook in "$hook_dir"/*.sh; do
        [[ -f "$hook" ]] || continue
        if [[ ! -x "$hook" ]]; then
            chmod +x "$hook"
        fi

        local name
        name=$(basename "$hook")
        log DEBUG "Running hook: $name"

        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "[DRY RUN] Would run hook: $name"
            continue
        fi

        if "$hook"; then
            log INFO "Hook '$name' completed"
        else
            log WARN "Hook '$name' failed (exit code $?)"
        fi
    done

    log INFO "$phase hooks finished"
}

hooks_list() {
    if [[ ! -d "$HOOKS_DIR" ]]; then
        echo "No hooks directory found at $HOOKS_DIR"
        return 0
    fi

    echo "Installed hooks:"
    echo "================"
    local phase
    for phase in "$HOOKS_DIR"/*/; do
        [[ -d "$phase" ]] || continue
        local phase_name
        phase_name=$(basename "$phase")
        local count
        count=$(find "$phase" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l)
        echo "  $phase_name: $count hook(s)"
        for hook in "$phase"*.sh; do
            [[ -f "$hook" ]] || continue
            echo "    - $(basename "$hook")"
        done
    done
}
