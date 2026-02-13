#!/bin/bash
set -euo pipefail
start_time=$(date +%s%3N)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Devbox V1.0
#------------------
#This script is designed to set up a development environment on a Debian-based Linux system. It checks for and installs essential packages, and can be extended to include additional tools and configurations as needed.

#Initial Variables
timestamp=$(date '+%Y-%m-%d')

#Checks if libraries are executable.
if [ ! -x "$SCRIPT_DIR/lib/logging.sh" ] || [ ! -x "$SCRIPT_DIR/lib/packages.sh" ] || [ ! -x "$SCRIPT_DIR/lib/docker.sh" ]; then
    chmod +x "$SCRIPT_DIR/lib/logging.sh" "$SCRIPT_DIR/lib/packages.sh" "$SCRIPT_DIR/lib/docker.sh"
fi

#Header
echo "DevBox v1.0"
echo "---------------------------"

# Load logging functions first to ensure all actions are logged
source "$SCRIPT_DIR/lib/logging.sh"
trap log_footer EXIT

#fuctions
wrong_arg() {
    echo "Invalid Input"
    log ERROR "Invalid Argument : \"$1\""
    exit 3
}
no_arg() {
    echo "No Input - Try Again.."
    log ERROR "Missing Argument."
    exit 2
}
pull_libraries() {  #function to load libraries and log the process
    log DEBUG "Loading libraries..."
    # The following libraries are essential for the script's functionality. Each library is sourced and checked for successful loading. If any library fails to load, an error is logged and the script exits with a specific code.
    if source "$SCRIPT_DIR/lib/packages.sh" &>> $logfile; then
        log INFO "\"lib/packages.sh\" loaded successfully."
    else
        log ERROR "Failed to load \"lib/packages.sh\""
        echo "Failed Loading libraries."
        exit 4
    fi

    if source "$SCRIPT_DIR/lib/docker.sh"; then
        log INFO "\"lib/docker.sh\" loaded successfully."
    else
        log ERROR "Failed to load \"lib/docker.sh\""
        exit 4
    fi
    
#    if source lib/packages.sh; then
#        log INFO "\"lib/packages.sh\" loaded successfully."
#    else
#        log ERROR "Failed to load \"lib/packages.sh\""
#        exit 4
#    fi
}
installscript() {
    pull_libraries      #loading libraries
#    apt_update          #updating the system
# commenting out apt update for now, because its a waste run this everytime we test. will uncomment it when the script is ready for production.
    main_essentials     #installing essential packages
}

if [ $# -eq 0 ]; then
    no_arg # if no arguments are provided, call the no_arg function to log the error and exit.
fi

case $1 in
    --help)
        echo "Usage: $0 [install|doctor|--help] [--plus-docker]"
        echo "  install       Set up the development environment by installing essential packages and tools."
        echo "  doctor        Run diagnostic checks to verify the health of the development environment (not implemented yet)."
        echo "  --help          Display this help message and exit."
        
        echo "  --plus-docker   Optionally install Docker and Docker Compose during the setup process."
        exit 0
esac

if [[ $EUID -ne 0 ]]; then #checks for root permision
    echo "This script must be run as root"
    log ERROR "No ROOT Permission."
    exit 1
fi
case $1 in #handling arguments
    install)
        # This case handles the installation process. When the user runs the script with the "--install" argument, it triggers the "installscript" function, which is responsible for setting up the development environment by calling various functions to load libraries, update the system, install essential packages, and set up Docker.
        installscript
    ;;
    doctor)
        # This case is a placeholder for a future implementation of a diagnostic tool. When the user runs the script with the "--doctor" argument, it currently does nothing, but it can be extended in the future to include checks for the health and configuration of the development environment, such as verifying that essential packages are installed and that Docker is running correctly.
    ;;
    *)
        # This case handles any invalid arguments passed to the script. If the user provides an argument that does not match the expected options (like "--install" or "--doctor"), the "wrong_arg" function is called, which logs an error message and exits the script with a specific code indicating an invalid argument.
        wrong_arg "$1"
    ;;
esac
shift # Shift the arguments to process any additional options like "--plus-docker"
for arg in "$@"; do
    case "$arg" in
        --plus-docker) docker_setup ;;
        *) wrong_arg "$arg" ;;
    esac
done

exit 0      # Exit with success code after completing the script without errors.

# Author: Pavara Mirihagalla
# Github:
# License: MIT License
# Version: 1.0
# Date: 2026-02-13

# Notes:
# The "--doctor" case is currently a placeholder and can be implemented in the future to include diagnostic checks for the development environment.
# The script is designed to be modular, allowing for easy addition of new features and tools as needed. Each function is responsible for a specific aspect of the setup process, making it easier to maintain and extend the script in the future.
# The logging functions ensure that all actions are recorded, providing a clear history of the setup process and any issues that may arise. This is crucial for troubleshooting and ensuring a smooth setup experience for users.
# Overall, this script serves as a foundation for automating the setup of a development environment, streamlining the process and reducing the time and effort required to get started with development on a new system.

# Exit codes:
# 0 - Success
# 1 - No root permission
# 2 - No argument provided
# 3 - Invalid argument
# 4 - Library loading failure
# 5 - apt installation failure
# 6 - Docker installation failure
# 7 - Docker service start failure
# 8 - Docker group setup failure
# 9 - Docker Compose installation failure
# 10 - Docker setup verification failure
# Additional exit codes can be defined as needed for other specific error conditions that may arise during the execution of the script.

