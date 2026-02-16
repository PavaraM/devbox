# lib/dockerbuild.sh
# Docker build script for devbox

#exit codes:
# 0  - Success
# 1  - No root permission
# 2  - No argument provided
# 3  - Invalid argument
# 4  - Library loading failure
# 5  - Package installation failure
# 6  - Docker installation failure
# 7  - Docker service failure
# 8  - Docker group setup failure
# 9  - Docker Compose installation failure
# 10 - Docker verification failure
# 11 - Diagnostic check failure
# 12 - No internet connection for diagnostics
# 13 - Essential tool missing in diagnostics
# 14 - apt package manager is not healthy
# 15 - Docker image build failure
# 16 - Docker container run failure
# 17 - Docker cleanup failure

build_docker_image() {
    report DEBUG "Building Docker image..."
    if ! docker build -t devbox:latest -f dockerfile .; then
        report ERROR "Failed to build Docker image"
        return 15
    fi
    report INFO "Docker image built successfully"
    passed=$((passed + 1))
    return 0
}

docker_run_container() {
    report DEBUG "Running Docker container..."
    if ! docker run -it --rm --name devbox_container devbox:latest; then
        report ERROR "Failed to run Docker container"
        return 16
    fi
    report INFO "Docker container ran successfully"
    passed=$((passed + 1))
    return 0
}

docker_cleanup() {
    report DEBUG "Cleaning up Docker resources..."
    if ! docker system prune -f; then
        report ERROR "Failed to clean up Docker resources"
        return 17
    fi
    report INFO "Docker resources cleaned up successfully"
    passed=$((passed + 1))
    return 0
}