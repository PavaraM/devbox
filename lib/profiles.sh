#!/bin/bash
# lib/profiles.sh — Profile-based customization system

PROFILE_DIR="$SCRIPT_DIR/conf/profiles"
declare -a ACTIVE_PROFILES=()
declare -a _ACCUM_PKGS=()
declare -a _ACCUM_CMDS=()
_ACCUM_DOCKER=false
_ACCUM_HARDEN=false
_ACCUM_DEPLOY=""

profile_list() {
    if [[ ! -d "$PROFILE_DIR" ]]; then
        log WARN "Profile directory not found: $PROFILE_DIR"
        return 1
    fi

    echo "Available profiles:"
    echo "==================="
    for conf in "$PROFILE_DIR"/*.conf; do
        local name
        name=$(basename "$conf" .conf)
        local desc=""
        if [[ -f "$conf" ]]; then
            desc=$(grep "^PROFILE_DESC=" "$conf" | head -1 | cut -d'"' -f2)
        fi
        printf "  %-15s %s\n" "$name" "${desc:-No description}"
    done
}

profile_load() {
    local name="$1"
    local conf="$PROFILE_DIR/$name.conf"

    if [[ ! -f "$conf" ]]; then
        log ERROR "Profile not found: $name"
        return 1
    fi

    log INFO "Loading profile: $name"

    # Source profile — sets PROFILE_PACKAGES, PROFILE_EXTRA_CMDS, etc.
    source "$conf"

    # Accumulate
    _ACCUM_PKGS+=("${PROFILE_PACKAGES[@]}")
    _ACCUM_CMDS+=("${PROFILE_EXTRA_CMDS[@]}")
    [[ "$PROFILE_INSTALL_DOCKER" == true ]] && _ACCUM_DOCKER=true
    [[ "$PROFILE_HARDEN" == true ]] && _ACCUM_HARDEN=true
    [[ -n "$PROFILE_SETUP_USER" && -z "$_ACCUM_DEPLOY" ]] && _ACCUM_DEPLOY="$PROFILE_SETUP_USER"

    ACTIVE_PROFILES+=("$name")
    log INFO "Profile '$name' loaded"
}

profile_apply() {
    if [[ ${#ACTIVE_PROFILES[@]} -eq 0 ]]; then
        log INFO "No profiles selected, using default packages"
        return 0
    fi

    log INFO "Applying ${#ACTIVE_PROFILES[@]} profile(s): ${ACTIVE_PROFILES[*]}"

    [[ ${#_ACCUM_PKGS[@]} -eq 0 ]] && return 0

    _install_group "profile packages" "${_ACCUM_PKGS[@]}"
}

profile_apply_extra() {
    local cmd
    for cmd in "${_ACCUM_CMDS[@]}"; do
        log INFO "Running profile extra command: $cmd"
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "[DRY RUN] Would run: $cmd"
        else
            eval "$cmd" || log WARN "Profile extra command failed (non-fatal): $cmd"
        fi
    done
}

profile_wants_docker()   { [[ "$_ACCUM_DOCKER" == true ]]; }
profile_wants_harden()   { [[ "$_ACCUM_HARDEN" == true ]]; }
profile_deploy_user()    { echo "$_ACCUM_DEPLOY"; }
