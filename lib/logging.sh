# lib/logging.sh
# This file contains logging functions and setup for the devbox script.

mkdir -p "$SCRIPT_DIR/logs/"
mkdir -p "$SCRIPT_DIR/logs/archive/"
mkdir -p "$SCRIPT_DIR/logs/apt/"
mkdir -p "$SCRIPT_DIR/logs/archive/apt/"

logfile="$SCRIPT_DIR/logs/devbox_$TIMESTAMP.log"

#archive old logs (keep last 7 days)
find "$SCRIPT_DIR/logs/" -type f -name "devbox_*.log" -mtime +7 -exec mv {} "$SCRIPT_DIR/logs/archive/" \;
find "$SCRIPT_DIR/logs/apt/" -type f -name "apt_*.log" -mtime +7 -exec mv {} "$SCRIPT_DIR/logs/archive/apt/" \;

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