# lib/docker.sh
# Placeholder for Docker related functions and checks

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
    if curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh >> "$logfile" 2>&1; then
        echo "Docker installed successfully."
        log INFO "Docker installation successful"
    else
        echo "Docker installation failed"
        log ERROR "Docker installation failed"
        return 6
    fi
}

docker_compose_setup() {
    log DEBUG "Checking if Docker Compose is installed..."
    if command -v docker-compose &> /dev/null; then
        echo "Docker Compose is already installed."
        log INFO "Docker Compose already installed on this system."
        return 0
    fi
    echo "Docker Compose is not installed, installing now..."
    log INFO "Docker Compose not installed"
    log DEBUG "Running Docker Compose installation commands"
    
    # Install Docker Compose using the official convenience script
    if curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
        chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
        log INFO "Docker Compose installation successful"
    else
        echo "Docker Compose installation failed"
        log ERROR "Docker Compose installation failed"
        return 9
    fi
}
docker_setup() {
    log DEBUG "Setting up Docker environment..."
    install_docker
    # Start Docker daemon
    if ! systemctl is-active --quiet docker; then
        log DEBUG "Starting Docker service..."
        sudo systemctl start docker &> /dev/null
        if [ $? -ne 0 ]; then
            log ERROR "Failed to start Docker service"
            return 7
        fi
    fi
    
    # Enable Docker on boot
    sudo systemctl enable docker >> "$logfile" 2>&1
    if [ $? -ne 0 ]; then
            log ERROR "Failed to enable Docker service on boot"
            return 7
    else
        log INFO "Docker service enabled on boot successfully"
    fi

    #docker_compose_setup

    # adding current user to docker group for non-root usage
    if ! groups $USER | grep -q "\bdocker\b"; then
        log DEBUG "Adding user $USER to docker group..."
        sudo usermod -aG docker $USER >> "$logfile" 2>&1
    fi

    if [ $? -ne 0 ]; then
            log ERROR "Failed to add user $USER to docker group"
            return 8
    else
        log INFO "user $USER added to docker group successfully"
    fi



    # Verify installation
    if docker --version &> /dev/null && docker-compose --version &> /dev/null; then
        log INFO "Docker and Docker Compose are installed and working correctly."
        return 0
    else
        log ERROR "Docker or Docker Compose installation verification failed"
        return 10
    fi
    }