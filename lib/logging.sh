# lib/logging.sh
# This file contains logging functions and setup for the devbox script.

mkdir -p "$SCRIPT_DIR/logs/"
mkdir -p "$SCRIPT_DIR/logs/archive/"
mkdir -p "$SCRIPT_DIR/logs/apt/"
mkdir -p "$SCRIPT_DIR/logs/archive/apt/"

logfile="$SCRIPT_DIR/logs/devbox_$TIMESTAMP.log"

# Set ownership of logs to the invoking user if running with sudo
if [[ -n "$SUDO_USER" ]]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$SCRIPT_DIR/logs/"
fi

#archive old logs (keep last 7 days)
find "$SCRIPT_DIR/logs/" -type f -name "devbox_*.log" -mtime +7 -exec mv {} "$SCRIPT_DIR/logs/archive/" \;
find "$SCRIPT_DIR/logs/apt/" -type f -name "apt_*.log" -mtime +7 -exec mv {} "$SCRIPT_DIR/logs/archive/apt/" \;

# Initialize log file
echo "script started at $(date)" >> "$logfile"
echo "command: devbox $@" >> "$logfile"
echo "system: $(uname -a)" >> "$logfile"
echo "shell: $SHELL" >> "$logfile"
echo "SCRIPT_DIR: $SCRIPT_DIR" >> "$logfile"
echo "user: $USER (SUDO_USER: ${SUDO_USER:-none})" >> "$logfile"
echo "------------------------------" >> "$logfile"
echo " " >> "$logfile" 

# Set ownership of the new log file
if [[ -n "$SUDO_USER" ]]; then
    chown "$SUDO_USER:$SUDO_USER" "$logfile"
fi

log_footer() {
    local exit_code=$?
    END_TIME=$(date +%s%3N)
    DEBUGGING_GUIDE="$SCRIPT_DIR/docs/DEBUGGING.md"
    duration_ms=$((END_TIME - START_TIME))
    duration_s=$(awk "BEGIN {printf \"%.3f\", $duration_ms/1000}")
    echo "------------------------------" >> "$logfile"
    echo "Script ended at $(date) exit_code=$exit_code duration=${duration_s}s" >> "$logfile"
    echo "Check debugging guide: $DEBUGGING_GUIDE" >> "$logfile"
    echo "==============================" >> "$logfile"
    echo " " >> "$logfile"
    # Fix ownership one final time (in case any logs were created as root)
    if [[ -n "$SUDO_USER" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$SCRIPT_DIR/logs/"
    fi
}

log() {
    local level=$1
    shift
    local line="$(date +%Y-%m-%d' '%H:%M:%S) [$level] $*"
    
    # Uncomment next line for console output
    #echo "$line"
    echo "$line" >> "$logfile"
}
