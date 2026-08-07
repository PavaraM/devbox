#!/bin/bash
# lib/version-manager.sh — mise-based runtime/tool version management

TOOLS_CONF="$SCRIPT_DIR/conf/tools.conf"

mise_bin_path() {
    if command -v mise &> /dev/null; then
        command -v mise
        return 0
    fi
    if [[ -x "$HOME/.local/bin/mise" ]]; then
        echo "$HOME/.local/bin/mise"
        return 0
    fi
    return 1
}

install_mise() {
    log DEBUG "Checking if mise is installed..."
    if mise_bin_path &> /dev/null; then
        echo "mise is already installed."
        log INFO "mise already installed on this system."
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would install mise (mise.run installer)"
        log INFO "[DRY RUN] Would install mise"
        return 0
    fi

    echo "mise is not installed, installing now..."
    log INFO "mise not installed"

    local install_log="$SCRIPT_DIR/logs/mise-install.log"
    mkdir -p "$SCRIPT_DIR/logs"

    if curl -fsSL https://mise.run | sh >> "$install_log" 2>&1; then
        if mise_bin_path &> /dev/null; then
            echo "mise installed successfully."
            log INFO "mise installation successful"
            return 0
        fi
    fi

    echo "mise installation failed (check $install_log for details)"
    log ERROR "mise installation failed"
    return 1
}

tools_load() {
    TOOLS_TO_INSTALL=()
    if [[ ! -f "$TOOLS_CONF" ]]; then
        log DEBUG "No tools.conf found, nothing to install via mise"
        return 0
    fi
    local line tool version
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        tool="${line%%=*}"
        version="${line#*=}"
        tool="${tool// /}"
        version="${version// /}"
        [[ -z "$tool" || -z "$version" ]] && continue
        if [[ "$version" == "*" || "$version" == "latest" ]]; then
            TOOLS_TO_INSTALL+=("$tool@latest")
        else
            TOOLS_TO_INSTALL+=("$tool@$version")
        fi
    done < "$TOOLS_CONF"
    return 0
}

mise_install_tools() {
    local mise_bin
    if ! mise_bin=$(mise_bin_path); then
        log ERROR "mise is not available — cannot install tools"
        echo "Error: mise is not available on PATH" >&2
        return 1
    fi

    tools_load
    if [[ ${#TOOLS_TO_INSTALL[@]} -eq 0 ]]; then
        log INFO "No tools configured in conf/tools.conf"
        return 0
    fi

    echo "Tools to install via mise: ${TOOLS_TO_INSTALL[*]}"
    log INFO "Installing ${#TOOLS_TO_INSTALL[@]} tool(s) via mise"

    local failed=0
    local spec
    for spec in "${TOOLS_TO_INSTALL[@]}"; do
        echo "Installing $spec via mise..."
        log DEBUG "Running mise install $spec"
        if "$mise_bin" install "$spec" >> "$logfile" 2>&1; then
            echo "$spec installed successfully."
            log INFO "$spec installation successful"
        else
            echo "$spec installation failed"
            log ERROR "$spec installation failed via mise"
            failed=1
        fi
    done

    if [[ $failed -eq 0 ]]; then
        return 0
    fi
    return 1
}

setup_version_manager() {
    log DEBUG "Setting up version manager (mise)..."
    if ! install_mise; then
        return $?
    fi
    if ! mise_install_tools; then
        return $?
    fi
    return 0
}
