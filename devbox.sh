#!/bin/bash
set -euo pipefail

#Devbox V1.0
#------------------

#Initial Variables
timestamp=$(date '+%Y-%m-%d')
logfile="./logs/devbox_$timestamp.log"
mkdir -p logs/

#checks for root permision
 if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    echo "[DEBUG] No Permision (EXIT 1)"
    exit 1
  fi

#fuctions
wrong-arg() {
    echo "Invalid Input"
    echo "[DEBUG] Invalid Input (EXIT 3)" >> "$logfile"
    exit 3
}
no-arg() {
    echo "No Input - Try Again.."
    echo "[DEBUG] No Input (EXIT 2)" >> "$logfile"
    exit 2
}
installscript() {
    echo "[INFO] Installing packages..." >> "$logfile"
    source ./lib/packages.sh
    #source ./lib/something.sh
    #source ./lib/something.sh
    #source ./lib/something.sh
}

#Header
echo "DevBox v1.0"
echo "---------------------------"

#logfile header
echo "script started at $(date)" >> "$logfile"
echo "command: devbox $@" >> "$logfile"
echo "------------------------------" >> "$logfile"

if [ $# -eq 0 ];
then
    no-arg
fi

case $1 in
    install)
        installscript >> $logfile 2>&1 | tee -a "$logfile"
        ;;
    doctor)

        ;;
    *)
        wrong-arg
        ;;
esac


#log footer
echo "------------------------------" >> "$logfile"
echo "Script ended at $(date)" >> "$logfile"
echo "==============================" >> "$logfile"
exit 0