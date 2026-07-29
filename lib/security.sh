#!/bin/bash
# lib/security.sh — Multi-distro security hardening

source "$SCRIPT_DIR/conf/security.conf"

SSH_SERVICE_NAME=""
_ssh_svc() {
    if [[ -z "$SSH_SERVICE_NAME" ]]; then
        if command -v sshd &>/dev/null; then
            SSH_SERVICE_NAME="sshd"
        elif command -v ssh &>/dev/null; then
            SSH_SERVICE_NAME="ssh"
        elif command -v dropbear &>/dev/null; then
            SSH_SERVICE_NAME="dropbear"
        else
            SSH_SERVICE_NAME="sshd"
        fi
    fi
    echo "$SSH_SERVICE_NAME"
}

ssh_harden() {
    local sshd_config
    sshd_config=$(ssh_config_path)
    log INFO "Starting SSH hardening..."

    if [[ ! -f "$sshd_config" ]]; then
        log WARN "sshd_config not found at $sshd_config — SSH may not be installed"
        echo "OpenSSH server is not installed. Skipping SSH hardening."
        return 0
    fi

    local backup="${sshd_config}.devbox.bak"
    if [[ -f "$backup" ]]; then
        log INFO "SSH already hardened (backup at $backup)"
        echo "SSH is already hardened."
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would harden SSH configuration"
        log INFO "[DRY RUN] Would harden SSH configuration"
        return 0
    fi

    cp "$sshd_config" "$backup"
    log DEBUG "Original sshd_config backed up to $backup"

    {
        echo "# Hardened by DevBox v2 — $(date)"
        echo "Include /etc/ssh/sshd_config.d/*.conf"
        echo "Port $SSH_PORT"
        echo "Protocol 2"
        echo "PermitRootLogin no"
        echo "PubkeyAuthentication yes"
        echo "PasswordAuthentication no"
        echo "PermitEmptyPasswords no"
        echo "X11Forwarding no"
        echo "MaxAuthTries 3"
        echo "ClientAliveInterval 300"
        echo "ClientAliveCountMax 2"
        echo "UseDNS no"
        echo "AllowAgentForwarding no"
        echo "AllowTcpForwarding no"
        echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com"
        echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"
        echo "KexAlgorithms curve25519-sha256,diffie-hellman-group-exchange-sha256"
    } > "$sshd_config"

    local svc
    svc=$(_ssh_svc)

    if sshd -t &>> "$logfile"; then
        if svc_is_active "$svc" &>/dev/null; then
            svc_reload "$svc" >> "$logfile" 2>&1
        fi
        echo "SSH configuration hardened successfully."
        log INFO "SSH hardening completed"
        return 0
    else
        cp "$backup" "$sshd_config"
        log ERROR "SSH configuration test failed — restored original config"
        echo "SSH configuration test failed. Changes reverted."
        return 15
    fi
}

configure_firewall() {
    log INFO "Configuring firewall..."

    if [[ "$FIREWALL_TOOL" == "ufw" ]] && ! command -v ufw &>/dev/null; then
        log WARN "UFW is not installed"
        echo "UFW is not installed. Run 'install' first or install ufw manually."
        return 0
    fi

    if firewall_is_active; then
        log INFO "Firewall is already active"
        echo "Firewall is already configured and active."
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would configure firewall rules"
        log INFO "[DRY RUN] Would configure firewall"
        return 0
    fi

    firewall_default_deny

    for port in $FIREWALL_OPEN_PORTS; do
        if [[ "$port" == "22" ]]; then
            firewall_limit_port "$port" "tcp"
            log DEBUG "Firewall: rate-limited SSH on port $port"
        else
            firewall_allow_port "$port" "tcp"
            log DEBUG "Firewall: allowed port $port"
        fi
    done

    firewall_enable

    log INFO "Firewall configured successfully"
    echo "Firewall configured with rules: $(echo "$FIREWALL_OPEN_PORTS" | tr ' ' ',')"
    echo "  - Default: deny incoming, allow outgoing"
    if echo "$FIREWALL_OPEN_PORTS" | grep -q "22"; then
        echo "  - SSH (22): rate-limited"
    fi
    for port in $FIREWALL_OPEN_PORTS; do
        [[ "$port" != "22" ]] && echo "  - Port $port: allowed"
    done
    return 0
}

setup_deploy_user() {
    local username="${1:-$DEPLOY_USERNAME}"
    log INFO "Setting up deploy user: $username"

    if id "$username" &>/dev/null; then
        log INFO "User $username already exists"
        echo "User $username already exists."

        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "[DRY RUN] Would configure SSH access for $username"
            log INFO "[DRY RUN] Would configure SSH for $username"
            return 0
        fi

        _setup_deploy_user_ssh "$username"
        _setup_deploy_user_groups "$username"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would create user $username with SSH access and groups"
        log INFO "[DRY RUN] Would create user $username"
        return 0
    fi

    user_add "$username"
    log INFO "User $username created"

    _setup_deploy_user_ssh "$username"
    _setup_deploy_user_groups "$username"

    echo "Deploy user $username created successfully."
    log INFO "Deploy user $username setup completed"
    return 0
}

_setup_deploy_user_ssh() {
    local username=$1
    local home_dir
    home_dir=$(eval echo "~$username")

    local ssh_dir="$home_dir/.ssh"
    mkdir -p "$ssh_dir"

    local key_source=""

    if [[ -n "${DEPLOY_SSH_PUBLIC_KEY:-}" ]]; then
        key_source="conf/security.conf"
        echo "$DEPLOY_SSH_PUBLIC_KEY" > "$ssh_dir/authorized_keys"
    elif [[ -f "$SCRIPT_DIR/conf/deploy_key.pub" ]]; then
        key_source="$SCRIPT_DIR/conf/deploy_key.pub"
        cat "$SCRIPT_DIR/conf/deploy_key.pub" > "$ssh_dir/authorized_keys"
    else
        log INFO "No SSH public key provided — generating ED25519 key pair"
        ssh-keygen -t ed25519 -f "$ssh_dir/id_ed25519" -N "" -C "$username@devbox" >> "$logfile" 2>&1
        cp "$ssh_dir/id_ed25519.pub" "$ssh_dir/authorized_keys"
        key_source="ed25519 key (private: $ssh_dir/id_ed25519)"
        echo "Generated SSH key pair for $username."
        echo "  Private key: $ssh_dir/id_ed25519"
        echo "  Public key:  $ssh_dir/id_ed25519.pub"
    fi

    chmod 700 "$ssh_dir"
    chmod 600 "$ssh_dir/authorized_keys"

    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$ssh_dir" 2>/dev/null || true
    fi
    chown -R "$username:$username" "$ssh_dir"

    log INFO "SSH access configured for $username"
    echo "SSH authorized_keys configured for $username."
}

_setup_deploy_user_groups() {
    local username=$1

    IFS=',' read -ra groups <<< "$DEPLOY_GROUPS"
    for group in "${groups[@]}"; do
        group=$(echo "$group" | xargs)
        if getent group "$group" &>/dev/null; then
            case "$DISTRO_FAMILY" in
                alpine)
                    adduser "$username" "$group"
                    ;;
                *)
                    usermod -aG "$group" "$username" >> "$logfile" 2>&1
                    ;;
            esac
            log INFO "Added $username to group $group"
        else
            log WARN "Group $group does not exist — skipping"
        fi
    done

    if [[ "$DEPLOY_SUDO_NOPASSWD" == "true" ]]; then
        local sudoer_file="/etc/sudoers.d/$username"
        echo "$username ALL=(ALL) NOPASSWD:ALL" > "$sudoer_file"
        chmod 440 "$sudoer_file"
        log INFO "Passwordless sudo configured for $username"
    fi
}
