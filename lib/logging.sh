# lib/logging.sh
# This file contains logging functions and setup for the devbox script.

logfile="$SCRIPT_DIR/logs/devbox_$TIMESTAMP.log"
mkdir -p logs/

#logfile header
echo "script started at $(date)" >> "$logfile"
echo "command: devbox $@" >> "$logfile"
echo "------------------------------" >> "$logfile"

log_footer() {
    local exit_code=$?
    END_TIME=$(date +%s%3N)
    
    duration_ms=$((END_TIME - START_TIME))
    duration_s=$(awk "BEGIN {printf \"%.3f\", $duration_ms/1000}")
    echo "------------------------------" >> "$logfile"
    echo "Script ended at $(date) exit_code=$exit_code duration=${duration_s}s" >> "$logfile"
    echo "==============================" >> "$logfile"
    echo " " >> $logfile
}

log() {
    local level=$1
    shift
    local line="$(date +%H:%M:%S) [$level] $*"
    
    #echo "$line"               # console
    echo "$line" >> "$logfile"  # file
}