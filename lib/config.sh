#!/bin/bash
# lib/config.sh — Configuration hierarchy loader
# Load order: CLI flags > ./devbox.conf > ~/.config/devbox/config.conf > /etc/devbox/config.conf

CONFIG_LOADED=false
declare -a CONFIG_PROFILES=()

config_load() {
    local config_paths=(
        "/etc/devbox/config.conf"
        "$HOME/.config/devbox/config.conf"
        "$SCRIPT_DIR/devbox.conf"
    )

    for path in "${config_paths[@]}"; do
        if [[ -f "$path" ]]; then
            log DEBUG "Loading config: $path"
            source "$path"
        fi
    done

    CONFIG_LOADED=true
    log DEBUG "Config loaded successfully"
}

config_get_profiles() {
    if [[ ${#CONFIG_PROFILES[@]} -gt 0 ]]; then
        printf '%s\n' "${CONFIG_PROFILES[@]}"
    fi
}
