# ====================================================
# LOGGER - BASH UTILS
# logging library for bash scripts
# ----------------------------------------------------
# Authour: Pavara Mirihagalla
# ====================================================

# ====================================================
# PULL CONFIG
# ----------------------------------------------------
source "$SCRIPT_DIR/conf/logger.conf"
# ====================================================

# ====================================================
# Set ownership of logs to the invoking user if running with sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$SCRIPT_DIR/logs/"
fi
# =====================================================

# ====================================================
# ARCHIVE LOGS
# ----------------------------------------------------
log_archive() {   
if [[ "$AUTO_ARCHIVE" == "true" ]]; then
        find "$LOG_DIR" -type f -name "${softname}_*.log" \
            -mtime +"$LOG_RETENTION_DAYS" \
            -exec mv {} "$ARCHIVE_DIR/" \;
    fi
}
# ====================================================

# ====================================================
# INITIALIZE LOG FILE
# ----------------------------------------------------
logger_init() {
    #TIMESTAMP=$(date '+%Y-%m-%d')
    logfile="$LOG_DIR/${softname}_${environment}_${TIMESTAMP}.log"

    mkdir -p "$LOG_DIR"
    mkdir -p "$ARCHIVE_DIR"

    log_archive

    touch "$logfile"

    if [[ "$SHOW_FILE" == "true" ]]; then
        {
            echo ""
            echo "Script started at $(date)"
            echo "Environment: $environment"
            echo "User: $USER (SUDO_USER: ${SUDO_USER:-none})"
            echo "------------------------------"
            echo ""
        } >> "$logfile"
    fi
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$logfile"
    fi
    trap log_footer EXIT
}
# ====================================================

# ====================================================
# SET OWNERSHIP OF NEW LOG FILE TO INVOKING USER IF RUNNING WITH SUDO

# ====================================================

# ====================================================
# LOG LEVEL MAPPING FUNCTION
# ----------------------------------------------------
_log_level_to_number() {
    case "$1" in
        DEBUG) echo 1 ;;
        INFO)  echo 2 ;;
        WARN)  echo 3 ;;
        ERROR) echo 4 ;;
        *)     echo 0 ;;
    esac
}
# ====================================================


# ====================================================
# LOGGING FUNCTION
# ----------------------------------------------------
log() {
    local level=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    shift

    local level_num=$(_log_level_to_number "$level")
    local min_level_num=$(_log_level_to_number "$MIN_LOG_LEVEL")

    # Level filtering
    if (( level_num < min_level_num )); then
        return
    fi

    local timestamp=$(date +"$LOG_DATE_FORMAT")

    # Select color
    local color=""
    if [[ "$ENABLE_COLORS" == "true" ]]; then
        case "$level" in
            DEBUG) color="$COLOR_DEBUG" ;;
            INFO)  color="$COLOR_INFO" ;;
            WARN)  color="$COLOR_WARN" ;;
            ERROR) color="$COLOR_ERROR" ;;
        esac
    fi

    local console_line="$timestamp [${color}${level}${COLOR_RESET}] $*"
    local file_line="$timestamp [$level] $*"

    # Console output
    if [[ "$SHOW_CONSOLE" == "true" ]]; then
        if [[ "$ENABLE_COLORS" == "true" ]]; then
            printf "%b\n" "$console_line"
        else
            echo "$file_line"
        fi
    fi

    # File output
    if [[ "$SHOW_FILE" == "true" ]]; then
        echo "$file_line" >> "$logfile"
    fi
}
# ====================================================


# ====================================================
# LOG FOOTER FUNCTION TO LOG SCRIPT END TIME, DURATION, EXIT CODE, AND DEBUG
# ----------------------------------------------------
log_footer() {
    local exit_code=$?
    local END_TIME=$(date +%s%3N)
    local duration_ms=$((END_TIME - START_TIME))
    local duration_s=$(awk "BEGIN {printf \"%.3f\", $duration_ms/1000}")

    if [[ "$SHOW_FILE" == "true" ]]; then
        {
            echo ""
            echo "------------------------------"
            echo "Script ended at $(date)"
            echo "Exit code: $exit_code"
            echo "Duration: ${duration_s}s"
            echo "=============================="
            echo ""
        } >> "$logfile"
    fi

    # Fix ownership if sudo
    if [[ -n "${SUDO_USER:-}" && "$AUTO_CHOWN" == "true" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$LOG_DIR" 2>/dev/null
    fi
}
# ====================================================