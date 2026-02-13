#!/bin/bash
set -euo pipefail
start_time=$(date +%s%3N)
#Devbox V1.0
#------------------

#Initial Variables
timestamp=$(date '+%Y-%m-%d')

#Header
echo "DevBox v1.0"
echo "---------------------------"

source ./lib/logging.sh
trap log_footer EXIT

if [[ $EUID -ne 0 ]]; then #checks for root permision
    echo "This script must be run as root"
    log ERROR "No ROOT Permission."
    exit 1
fi

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
pull_libraries() {
    log DEBUG "Loading libraries..."

    if source lib/essentials.sh &>> $logfile; then
        log INFO "\"lib/essentials.sh\" loaded successfully."
    else
        log ERROR "Failed to load \"lib/essentials.sh\""
        echo "Failed Loading libraries."
        exit 4
    fi

#    if source lib/packages.sh; then
#        log INFO "\"lib/packages.sh\" loaded successfully."
#    else
#        log ERROR "Failed to load \"lib/packages.sh\""
#        exit 4
#    fi
    
#    if source lib/packages.sh; then
#        log INFO "\"lib/packages.sh\" loaded successfully."
#    else
#        log ERROR "Failed to load \"lib/packages.sh\""
#        exit 4
#    fi
}
installscript() {
    pull_libraries
#    apt_update
    main_essentials
}

if [ $# -eq 0 ]; then
    no_arg
fi

case $1 in
    --install)
        installscript
    ;;
    --doctor)
        
    ;;
    *)
        wrong_arg "$1"
    ;;
esac


exit 0