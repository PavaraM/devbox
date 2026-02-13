#!/bin/bash
set -euo pipefail
start_time=$(date +%s%3N)
#Devbox V1.0
#------------------

#Initial Variables
timestamp=$(date '+%Y-%m-%d')
logfile="./logs/devbox_$timestamp.log"
mkdir -p logs/

#Header
echo "DevBox v1.0"
echo "---------------------------"

#logfile header
echo "script started at $(date)" >> "$logfile"
echo "command: devbox $@" >> "$logfile"
echo "------------------------------" >> "$logfile"

log_footer() {
    local exit_code=$?
    end_time=$(date +%s%3N)
    
    duration_ms=$((end_time - start_time))
    duration_s=$(awk "BEGIN {printf \"%.3f\", $duration_ms/1000}")
    echo "------------------------------" >> "$logfile"
    echo "Script ended at $(date) exit_code=$exit_code duration=${duration_s}s" >> "$logfile"
    echo "==============================" >> "$logfile"
}


trap log_footer EXIT
log() {
    local level=$1
    shift
    local line="$(date +%H:%M:%S) [$level] $*"
    
    #echo "$line"               # console
    echo "$line" >> "$logfile"  # file
}

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
    log DEBUG "Loading libraries"

    if source lib/essencials.sh &>> $logfile; then
        log INFO "\"lib/essencials.sh\" loaded successfully."
    else
        log ERROR "Failed to load \"lib/essencials.sh\""
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
    install_git
    install_curl
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