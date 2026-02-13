# lib/docker.sh
# Docker installation and setup functions

install_docker() {
    log DEBUG "Checking if Docker is installed..."
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
        log INFO "Docker already installed on this system."
        return 0
    fi
    echo "Docker is not installed, installing now..."
    log INFO "Docker not installed"
    log DEBUG "Running Docker installation commands"
    
    # Install Docker using the official convenience script
    if curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh >> "$logfile" 2>&1; then
        rm -f /tmp/get-docker.sh  # Cleanup
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
        return 0
    else
        echo "Docker installation failed"
        log ERROR "Docker installation failed"
        rm -f /tmp/get-docker.sh  # Cleanup even on failure
        return 6
    fi
}

docker_compose_setup() {
    log DEBUG "Checking if Docker Compose is available..."
    
    # Check for modern Docker Compose plugin first (preferred)
    if docker compose version &> /dev/null; then
        echo "Docker Compose (plugin) is already installed."
        log INFO "Docker Compose plugin already available."
        return 0
    fi
    
    # Check for legacy standalone docker-compose
    if command -v docker-compose &> /dev/null; then
        echo "Docker Compose (standalone) is already installed."
        log INFO "Docker Compose standalone already installed."
        return 0
    fi
    
    echo "Docker Compose is not installed, installing plugin..."
    log INFO "Installing Docker Compose plugin"
    
    # Install Docker Compose plugin (modern approach)
    local compose_version="v2.24.5"  # Pinned stable version
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    # Map architecture names
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        armv7l) arch="armv7" ;;
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
    
    if curl -fsSL "$download_url" -o "$plugin_dir/docker-compose"; then
        chmod +x "$plugin_dir/docker-compose"
        echo "Docker Compose plugin installed successfully."
        log INFO "Docker Compose plugin installation successful"
        return 0
    else
        echo "Docker Compose plugin installation failed"
        log ERROR "Docker Compose plugin installation failed"
        return 9
    fi
}

docker_setup() {
    log DEBUG "Setting up Docker environment..."
    
    # Install Docker
    if ! install_docker; then
        return $?
    fi
    
    # Start Docker daemon
    if ! systemctl is-active --quiet docker; then
        log DEBUG "Starting Docker service..."
        if ! systemctl start docker >> "$logfile" 2>&1; then
            log ERROR "Failed to start Docker service"
            echo "Failed to start Docker service"
            return 7
        fi
        log INFO "Docker service started successfully"
    fi
    
    # Enable Docker on boot
    if ! systemctl enable docker >> "$logfile" 2>&1; then
        log ERROR "Failed to enable Docker service on boot"
        return 7
    else
        log INFO "Docker service enabled on boot successfully"
    fi

    # Install Docker Compose
    if ! docker_compose_setup; then
        return $?
    fi

    # Add current user to docker group for non-root usage
    # Note: When run as root, SUDO_USER contains the original user
    local target_user="${SUDO_USER:-$USER}"
    
    if ! groups "$target_user" | grep -q '\bdocker\b'; then
        log DEBUG "Adding user $target_user to docker group..."
        echo "Adding user $target_user to docker group for non-root usage..."
        
        if ! usermod -aG docker "$target_user" >> "$logfile" 2>&1; then
            log ERROR "Failed to add user $target_user to docker group"
            echo "Failed to add user $target_user to docker group"
            return 8
        fi
        
        log INFO "User $target_user added to docker group successfully"
        echo "User $target_user added to docker group successfully."
        echo "Note: You may need to log out and back in for group changes to take effect."
    else
        log INFO "User $target_user already in docker group"
        echo "User $target_user is already in the docker group."
    fi

    # Verify installation
    log DEBUG "Verifying Docker installation..."
    
    local docker_ok=false
    local compose_ok=false
    
    if docker --version >> "$logfile" 2>&1; then
        docker_ok=true
        log INFO "Docker verification successful"
    else
        log ERROR "Docker verification failed"
    fi
    
    # Check both plugin and standalone versions
    if docker compose version >> "$logfile" 2>&1; then
        compose_ok=true
        log INFO "Docker Compose (plugin) verification successful"
    elif command -v docker-compose &> /dev/null && docker-compose --version >> "$logfile" 2>&1; then
        compose_ok=true
        log INFO "Docker Compose (standalone) verification successful"
    else
        log ERROR "Docker Compose verification failed"
    fi
    
    if [[ "$docker_ok" == true && "$compose_ok" == true ]]; then
        log INFO "Docker and Docker Compose are installed and working correctly."
        echo "Docker and Docker Compose installation verification successful."
        return 0
    else
        log ERROR "Docker or Docker Compose installation verification failed"
        echo "Docker or Docker Compose installation verification failed"
        [[ "$docker_ok" == false ]] && echo "  - Docker verification failed"
        [[ "$compose_ok" == false ]] && echo "  - Docker Compose verification failed"
        return 10
    fi
}