# ====================================================
# LOGGER - BASH UTILS
# logging library for bash scripts
# ----------------------------------------------------
# Authour: Pavara Mirihagalla
# ====================================================

# ====================================================
# PULL CONFIG
# ----------------------------------------------------
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
source "$SCRIPT_DIR/conf/logger.conf"
# ====================================================

# ----------------------------------------------------
# Convert \033 escape sequences in color vars to actual ESC bytes
# so printf '%s' works safely (no unwanted %b interpretation)
for _logger_var in COLOR_INFO COLOR_WARN COLOR_ERROR COLOR_DEBUG COLOR_RESET; do
    eval "$_logger_var=\"\$(printf '%b' \"\${$_logger_var:-}\")\""
done
unset _logger_var
# =====================================================

# ----------------------------------------------------
# Validate configuration
if [[ ! "$MIN_LOG_LEVEL" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
    echo "logger.sh: invalid MIN_LOG_LEVEL='$MIN_LOG_LEVEL' — must be DEBUG, INFO, WARN, or ERROR" >&2
    MIN_LOG_LEVEL="INFO"
fi
# =====================================================

# ====================================================
# ARCHIVE LOGS
# ----------------------------------------------------
log_archive() {
    if [[ "$AUTO_ARCHIVE" == "true" ]]; then
        mkdir -p "$ARCHIVE_DIR"
        find "$LOG_DIR" -type f -name "${softname}_*.log" \
            -not -path "$ARCHIVE_DIR/*" \
            -mtime +"$LOG_RETENTION_DAYS" \
            -exec mv {} "$ARCHIVE_DIR/" \;
    fi
}
# ====================================================

# ====================================================
# INITIALIZE LOG FILE
# ----------------------------------------------------
logger_init() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d')
    logfile="$LOG_DIR/${softname}_${environment}_${timestamp}.log"

    mkdir -p "$LOG_DIR"
    mkdir -p "$ARCHIVE_DIR"

    log_archive

    touch "$logfile"

    if [[ "$SHOW_FILE" == "true" ]]; then
        {
            echo ""
            echo "Script started at $(date +"$LOG_DATE_FORMAT")"
            echo "Environment: $environment"
            echo "User: ${USER:-unknown} (SUDO_USER: ${SUDO_USER:-none})"
            echo "------------------------------"
            echo ""
        } >> "$logfile"
    fi

    # SET OWNERSHIP OF NEW LOG FILE TO INVOKING USER IF RUNNING WITH SUDO
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$logfile"
    fi

    trap log_footer EXIT
}
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
            printf '%s\n' "$console_line"
        else
            printf '%s\n' "$file_line"
        fi
    fi

    # File output
    if [[ "$SHOW_FILE" == "true" ]]; then
        printf '%s\n' "$file_line" >> "$logfile"
    fi
}
# ====================================================


# ====================================================
# LOG FOOTER FUNCTION TO LOG SCRIPT END TIME, DURATION, EXIT CODE, AND DEBUG
# ----------------------------------------------------
log_footer() {
    local exit_code=$?
    if [[ -n "${START_TIME:-}" ]]; then
        local end_time
        end_time=$(date +%s%3N)
        local duration_ms=$((end_time - START_TIME))
        local duration_s
        duration_s=$(awk "BEGIN {printf \"%.3f\", $duration_ms/1000}")
    else
        local duration_s="N/A"
    fi

    if [[ "$SHOW_FILE" == "true" ]]; then
        {
            echo ""
            echo "------------------------------"
            echo "Script ended at $(date +"$LOG_DATE_FORMAT")"
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


# MIT License

# Copyright (c) 2026 Pavara Mirihagalla

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
