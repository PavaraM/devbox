#!/bin/bash
# lib/docker.sh — Multi-distro Docker installation and setup

install_docker() {
    log DEBUG "Checking if Docker is installed..."
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
        log INFO "Docker already installed on this system."
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would install Docker"
        log INFO "[DRY RUN] Would install Docker"
        return 0
    fi

    echo "Docker is not installed, installing now..."
    log INFO "Docker not installed"

    case "$DISTRO_FAMILY" in
        debian)
            _install_docker_debian
            ;;
        rhel)
            _install_docker_rhel
            ;;
        arch)
            _install_docker_arch
            ;;
        alpine)
            _install_docker_alpine
            ;;
        suse)
            _install_docker_suse
            ;;
        *)
            _install_docker_generic
            ;;
    esac
}

_install_docker_debian() {
    log DEBUG "Installing Docker via official convenience script (Debian family)"

    if curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && \
       sh /tmp/get-docker.sh >> "$logfile" 2>&1; then
        rm -f /tmp/get-docker.sh
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
        return 0
    else
        echo "Docker installation failed"
        log ERROR "Docker installation failed"
        rm -f /tmp/get-docker.sh
        return 6
    fi
}

_install_docker_rhel() {
    log DEBUG "Installing Docker via dnf (RHEL family)"

    dnf install -y dnf-plugins-core >> "$logfile" 2>&1
    dnf config-manager --add-repo \
        https://download.docker.com/linux/$DISTRO_ID/docker-ce.repo >> "$logfile" 2>&1
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
        docker-compose-plugin >> "$logfile" 2>&1

    if command -v docker &> /dev/null; then
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
        return 0
    fi

    echo "Docker installation failed"
    log ERROR "Docker installation failed"
    return 6
}

_install_docker_arch() {
    log DEBUG "Installing Docker via pacman (Arch family)"

    pacman -Sy --noconfirm docker docker-compose containerd >> "$logfile" 2>&1

    if command -v docker &> /dev/null; then
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
        return 0
    fi

    echo "Docker installation failed"
    log ERROR "Docker installation failed"
    return 6
}

_install_docker_alpine() {
    log DEBUG "Installing Docker via apk (Alpine)"

    apk add docker docker-compose >> "$logfile" 2>&1

    if command -v docker &> /dev/null; then
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
        return 0
    fi

    echo "Docker installation failed"
    log ERROR "Docker installation failed"
    return 6
}

_install_docker_suse() {
    log DEBUG "Installing Docker via zypper (SUSE family)"

    zypper addrepo \
        https://download.docker.com/linux/suse/docker-ce.repo >> "$logfile" 2>&1 || true
    zypper install -y docker-ce docker-ce-cli containerd.io \
        docker-compose >> "$logfile" 2>&1

    if command -v docker &> /dev/null; then
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
        return 0
    fi

    echo "Docker installation failed"
    log ERROR "Docker installation failed"
    return 6
}

_install_docker_generic() {
    log WARN "No distro-specific Docker install — trying get.docker.com"
    _install_docker_debian
}

docker_compose_setup() {
    log DEBUG "Checking if Docker Compose is available..."

    if docker compose version &> /dev/null; then
        echo "Docker Compose (plugin) is already installed."
        log INFO "Docker Compose plugin already available."
        return 0
    fi

    if command -v docker-compose &> /dev/null; then
        echo "Docker Compose (standalone) is already installed."
        log INFO "Docker Compose standalone already installed."
        return 0
    fi

    if [[ "$DISTRO_FAMILY" == "arch" || "$DISTRO_FAMILY" == "alpine" ]]; then
        echo "Docker Compose should have been installed with Docker."
        log WARN "Docker Compose not found after Docker install"
        return 9
    fi

    echo "Docker Compose is not installed, installing plugin..."
    log INFO "Installing Docker Compose plugin"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would install Docker Compose plugin"
        log INFO "[DRY RUN] Would install Docker Compose plugin"
        return 0
    fi

    local compose_version="v2.27.0"
    local arch
    arch=$(uname -m)
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        armv7l)  arch="armv7" ;;
        *)
            log ERROR "Unsupported architecture: $arch"
            echo "Error: Unsupported architecture: $arch"
            return 9
            ;;
    esac

    local plugin_dir="/usr/local/lib/docker/cli-plugins"
    mkdir -p "$plugin_dir"

    local download_url="https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-${os}-${arch}"

    log DEBUG "Downloading Docker Compose from: $download_url"

    local tmp_file
    tmp_file=$(mktemp)
    if curl -fsSL "$download_url" -o "$tmp_file"; then
        if [[ -s "$tmp_file" ]]; then
            mv "$tmp_file" "$plugin_dir/docker-compose"
            chmod +x "$plugin_dir/docker-compose"
            echo "Docker Compose plugin installed successfully."
            log INFO "Docker Compose plugin installation successful"
            return 0
        else
            rm -f "$tmp_file"
            echo "Docker Compose download produced empty file"
            log ERROR "Docker Compose download produced empty file"
            return 9
        fi
    else
        rm -f "$tmp_file"
        echo "Docker Compose installation failed"
        log ERROR "Docker Compose installation failed"
        return 9
    fi
}

docker_setup() {
    log DEBUG "Setting up Docker environment..."

    if ! install_docker; then
        return $?
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY RUN] Would configure Docker service and user groups"
        log INFO "[DRY RUN] Would configure Docker"
        return 0
    fi

    # Start Docker daemon
    if ! svc_is_active docker; then
        log DEBUG "Starting Docker service..."
        if ! svc_start docker >> "$logfile" 2>&1; then
            log ERROR "Failed to start Docker service"
            echo "Failed to start Docker service"
            return 7
        fi
        log INFO "Docker service started successfully"
    fi

    # Enable Docker on boot
    if ! svc_enable docker >> "$logfile" 2>&1; then
        log ERROR "Failed to enable Docker service on boot"
        return 7
    fi
    log INFO "Docker service enabled on boot"

    # Install Docker Compose
    if ! docker_compose_setup; then
        return $?
    fi

    # Add user to docker group
    local target_user="${SUDO_USER:-$USER}"

    if ! groups "$target_user" 2>/dev/null | grep -q '\bdocker\b'; then
        log DEBUG "Adding user $target_user to docker group..."
        echo "Adding user $target_user to docker group..."

        case "$DISTRO_FAMILY" in
            alpine)
                adduser "$target_user" docker
                ;;
            *)
                usermod -aG docker "$target_user" >> "$logfile" 2>&1
                ;;
        esac

        log INFO "User $target_user added to docker group"
        echo "Note: You may need to log out and back in for group changes to take effect."
    else
        log INFO "User $target_user already in docker group"
    fi

    # Verify
    log DEBUG "Verifying Docker installation..."
    local docker_ok=false
    local compose_ok=false

    docker --version >> "$logfile" 2>&1 && docker_ok=true || true
    docker compose version >> "$logfile" 2>&1 && compose_ok=true || \
        command -v docker-compose &>/dev/null && compose_ok=true || true

    if [[ "$docker_ok" == true && "$compose_ok" == true ]]; then
        log INFO "Docker and Docker Compose verified successfully"
        echo "Docker and Docker Compose installation verification successful"
        return 0
    else
        log ERROR "Docker or Docker Compose verification failed"
        echo "Docker or Docker Compose installation verification failed"
        [[ "$docker_ok" == false ]] && echo "  - Docker verification failed"
        [[ "$compose_ok" == false ]] && echo "  - Docker Compose verification failed"
        return 10
    fi
}
