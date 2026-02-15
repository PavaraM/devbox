# DevBox API Reference

Developer documentation for extending and customizing DevBox v1.0

---

## Table of Contents

1. [Library Architecture](#library-architecture)
2. [Logging API](#logging-api)
3. [Package Management API](#package-management-api)
4. [Docker API](#docker-api)
5. [Diagnostics API](#diagnostics-api)
6. [Reporting API](#reporting-api)
7. [Creating Custom Modules](#creating-custom-modules)
8. [Best Practices](#best-practices)

---

## Library Architecture

### Overview

DevBox uses a modular library system where each library is a separate bash script in the `lib/` directory:

```
lib/
├── logging.sh      # Core logging functionality
├── packages.sh     # Package installation
├── docker.sh       # Docker setup
├── diagnostics.sh  # System health checks
└── reporting.sh    # Diagnostic reporting
```

### Loading Order

Libraries are loaded in `devbox.sh` in this order:

1. `logging.sh` - **Loaded first** (required by others)
2. `packages.sh`
3. `docker.sh`
4. `reporting.sh`
5. `diagnostics.sh`

### Global Variables

Available to all libraries after `devbox.sh` initialization:

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `SCRIPT_DIR` | readonly | DevBox installation directory | `/home/user/devbox` |
| `TIMESTAMP` | readonly | Current date | `2026-02-14` |
| `START_TIME` | readonly | Execution start (milliseconds) | `1707873938000` |
| `logfile` | string | Path to main log file | `logs/devbox_2026-02-14.log` |
| `reportfile` | string | Path to diagnostic report | `diagnostic_reports/report-*.log` |

---

## Logging API

### Source

`lib/logging.sh`

### Functions

#### `log(level, message...)`

Write a log entry to the main log file.

**Parameters:**

- `level` (string): Log level - `INFO`, `DEBUG`, `ERROR`, `WARN`
- `message` (string...): Message to log (multiple arguments joined)

**Returns:** None

**Example:**

```bash
log INFO "Starting installation"
log DEBUG "Checking package: $package_name"
log ERROR "Failed to install $package_name"
log WARN "Internet connectivity unavailable"
```

**Output Format:**

```
2026-02-14 01:45:38 [INFO] Starting installation
2026-02-14 01:45:38 [DEBUG] Checking package: git
2026-02-14 01:45:38 [ERROR] Failed to install git
2026-02-14 01:45:39 [WARN] Internet connectivity unavailable
```

#### `log_footer()`

Automatically called on script exit. Logs execution summary and fixes ownership.

**Parameters:** None (uses `$?` exit code)

**Returns:** None

**Example:**

```bash
# Set as trap in devbox.sh
trap log_footer EXIT

# Automatically generates:
# ------------------------------
# Script ended at Sat Feb 14 01:45:40 +0530 2026 exit_code=0 duration=2.192s
# ==============================
```

### Log File Management

#### Automatic Features

**Log Creation:**

```bash
# Automatically creates:
logs/devbox_$TIMESTAMP.log
logs/apt/
logs/archive/
logs/archive/apt/
```

**Log Archival:**

```bash
# Automatically archives logs older than 7 days
find "$SCRIPT_DIR/logs/" -name "devbox_*.log" -mtime +7 -exec mv {} "logs/archive/" \;
```

**Ownership Management:**

```bash
# All logs automatically owned by invoking user (not root)
if [[ -n "$SUDO_USER" ]]; then
    chown "$SUDO_USER:$SUDO_USER" "$logfile"
fi
```

### Custom Log Destinations

To add additional log outputs:

```bash
# In your library
my_function() {
    local custom_log="$SCRIPT_DIR/logs/custom_$(date +%Y-%m-%d).log"
    
    echo "Custom log entry" >> "$custom_log"
    log INFO "Wrote to custom log"
    
    # Fix ownership
    if [[ -n "$SUDO_USER" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$custom_log"
    fi
}
```

---

## Package Management API

### Source

`lib/packages.sh`

### Functions

#### `check_and_install_apt(name, pkg_name)`

Generic helper to check and install APT packages.

**Parameters:**

- `name` (string): Display name for logging
- `pkg_name` (string): Actual APT package name

**Returns:**

- `0` - Success (already installed or newly installed)
- `5` - Installation failed

**Features:**

- Idempotent (skips if already installed)
- Creates per-package log: `logs/apt/apt_$TIMESTAMP-$name.log`
- User-friendly console output
- Automatic ownership fixing

**Example:**

```bash
# Install git
check_and_install_apt git git-all

# Install with different display name
check_and_install_apt vim neovim

# Check return value
if ! check_and_install_apt python3 python3-pip; then
    log ERROR "Python installation failed"
    return 5
fi
```

**Console Output:**

```
git is not installed, installing now...
git installed successfully.
```

**Log Output:**

```
2026-02-14 01:45:38 [DEBUG] Checking if git is installed on this system...
2026-02-14 01:45:38 [INFO] git not installed
2026-02-14 01:45:38 [DEBUG] Running apt install git-all
2026-02-14 01:45:39 [INFO] git installation successful
```

#### `main_essentials()`

Install core development packages.

**Parameters:** None

**Returns:**

- `0` - All packages installed successfully
- `5` - One or more packages failed

**Installs:**

- git-all
- curl
- wget
- htop
- tmux
- neovim
- unzip
- tree
- net-tools
- ca-certificates
- build-essential

**Example:**

```bash
if ! main_essentials; then
    log ERROR "Failed to install essential packages"
    exit 5
fi
```

#### `networkingtools()`

Install networking utilities.

**Parameters:** None

**Returns:**

- `0` - All tools installed successfully
- `5` - One or more tools failed

**Installs:**

- ufw
- iproute2
- dnsutils
- nmap

**Example:**

```bash
if ! networkingtools; then
    log ERROR "Failed to install networking tools"
    exit 5
fi
```

#### `apt_update()`

Update and upgrade system packages (currently commented out in main script).

**Parameters:** None

**Returns:**

- `0` - Success
- `5` - Failed

**Example:**

```bash
# Uncomment in devbox.sh run_install() to enable
apt_update
```

### Creating Custom Package Groups

```bash
# In lib/packages.sh or custom library

python_stack() {
    log INFO "Installing Python development stack..."
    local failed_packages=()
    
    check_and_install_apt python3 python3 || failed_packages+=("python3")
    check_and_install_apt pip python3-pip || failed_packages+=("pip")
    check_and_install_apt venv python3-venv || failed_packages+=("venv")
    check_and_install_apt virtualenv virtualenv || failed_packages+=("virtualenv")
    
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "Python stack installed successfully"
        return 0
    else
        log ERROR "Failed to install Python packages: ${failed_packages[*]}"
        return 5
    fi
}

nodejs_stack() {
    log INFO "Installing Node.js development stack..."
    local failed_packages=()
    
    check_and_install_apt nodejs nodejs || failed_packages+=("nodejs")
    check_and_install_apt npm npm || failed_packages+=("npm")
    
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "Node.js stack installed successfully"
        return 0
    else
        log ERROR "Failed to install Node.js packages: ${failed_packages[*]}"
        return 5
    fi
}
```

Then in `devbox.sh`:

```bash
run_install() {
    log INFO "Starting installation process"
    main_essentials
    networkingtools
    python_stack      # Add custom function
    nodejs_stack      # Add custom function
    log INFO "Installation completed successfully"
}
```

---

## Docker API

### Source

`lib/docker.sh`

### Functions

#### `install_docker()`

Install Docker Engine using official convenience script.

**Parameters:** None

**Returns:**

- `0` - Docker installed (or already present)
- `6` - Installation failed

**Features:**

- Checks for existing installation
- Downloads official script to `/tmp/get-docker.sh`
- Cleans up script after installation
- Logs all output

**Example:**

```bash
if ! install_docker; then
    log ERROR "Docker installation failed"
    exit 6
fi
```

#### `docker_compose_setup()`

Install Docker Compose plugin.

**Parameters:** None

**Returns:**

- `0` - Docker Compose available (plugin or standalone)
- `9` - Installation failed

**Features:**

- Checks for plugin first (`docker compose`)
- Falls back to standalone check (`docker-compose`)
- Architecture detection (x86_64, aarch64, armv7)
- Downloads from official GitHub releases
- Installs to `/usr/local/lib/docker/cli-plugins/docker-compose`

**Supported Architectures:**

- x86_64
- aarch64
- armv7

**Example:**

```bash
if ! docker_compose_setup; then
    log ERROR "Docker Compose installation failed"
    exit 9
fi
```

#### `docker_setup()`

Complete Docker environment setup.

**Parameters:** None

**Returns:**

- `0` - Full Docker environment ready
- `6` - Docker installation failed
- `7` - Service start/enable failed
- `8` - User group addition failed
- `9` - Docker Compose installation failed
- `10` - Verification failed

**Process:**

1. Install Docker Engine
2. Start Docker daemon
3. Enable Docker on boot
4. Install Docker Compose plugin
5. Add user to docker group
6. Verify installation

**Example:**

```bash
if ! docker_setup; then
    log ERROR "Docker setup failed"
    exit $?  # Preserves specific exit code
fi
```

### User Group Management

Docker adds the invoking user to the `docker` group:

```bash
# Automatic detection of user
local target_user="${SUDO_USER:-$USER}"

# Check existing membership
if ! groups "$target_user" | grep -q '\bdocker\b'; then
    usermod -aG docker "$target_user"
    echo "Note: You may need to log out and back in for group changes to take effect."
fi
```

### Version Configuration

Modify Docker Compose version in `lib/docker.sh`:

```bash
# In docker_compose_setup()
local compose_version="v2.24.5"  # Change this

# Available versions: https://github.com/docker/compose/releases
```

---

## Diagnostics API

### Source

`lib/diagnostics.sh`

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `passed` | integer | Count of passed diagnostic checks |

### Functions

#### `osinfo()`

Collect and report system information.

**Parameters:** None

**Returns:**

- `0` - Always succeeds

**Collects:**

- Distribution name and version
- Kernel version
- System architecture
- User permissions (UID)
- Internet connectivity status

**Example:**

```bash
osinfo
# Increments $passed counter
# Outputs to diagnostic report
```

**Output:**

```
[INFO] Distro: Ubuntu 24.04 LTS
[INFO] Kernel: 6.17.0-14-generic
[INFO] Architecture: x86_64
[INFO] User Permissions: 0
[INFO] Internet Connectivity: online
```

#### `pkg_mgr_health()`

Verify APT package manager health.

**Parameters:** None

**Returns:**

- `0` - APT is healthy
- `1` - APT not found
- `11` - dpkg is locked
- `15` - Broken packages detected

**Checks:**

- APT availability
- dpkg lock status
- Broken package detection

**Example:**

```bash
if ! pkg_mgr_health; then
    report ERROR "Package manager is unhealthy"
    exit 11
fi
```

#### `toolchain_verification()`

Verify essential development tools are installed.

**Parameters:** None

**Returns:**

- `0` - All tools present
- `13` - One or more tools missing

**Checks For:**

- git
- curl
- wget
- htop
- tmux
- vim
- unzip
- tree
- net-tools
- ca-certificates
- build-essential
- ufw
- iproute2
- dnsutils
- nmap

**Example:**

```bash
if ! toolchain_verification; then
    report ERROR "Missing essential tools"
    exit 13
fi
```

#### `report_summary()`

Generate diagnostic summary.

**Parameters:** None

**Returns:** None (outputs to stdout and files)

**Example:**

```bash
report_summary >> "$reportfile"
report_summary >> "$logfile"
```

**Output:**

```
=======================
Diagnostic Summary
status: PASSED
checks_passed: 3/3
report generated at: diagnostic_reports/report-2026-02-14-01-45-38.log
=======================
```

### Creating Custom Diagnostic Checks

```bash
# In lib/diagnostics.sh

check_disk_space() {
    report DEBUG "Checking disk space..."
    
    local available=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    local threshold=5
    
    if [ "$available" -lt "$threshold" ]; then
        report ERROR "Low disk space: ${available}GB available (minimum: ${threshold}GB)"
        return 1
    fi
    
    report INFO "Disk space: ${available}GB available"
    passed=$((passed + 1))
    return 0
}

check_memory() {
    report DEBUG "Checking system memory..."
    
    local total_mem=$(free -g | awk '/^Mem:/ {print $2}')
    local available_mem=$(free -g | awk '/^Mem:/ {print $7}')
    
    report INFO "Total memory: ${total_mem}GB"
    report INFO "Available memory: ${available_mem}GB"
    
    if [ "$available_mem" -lt 1 ]; then
        report WARN "Low available memory: ${available_mem}GB"
    fi
    
    passed=$((passed + 1))
    return 0
}

check_docker_status() {
    report DEBUG "Checking Docker status..."
    
    if ! command -v docker &> /dev/null; then
        report WARN "Docker is not installed"
        return 0  # Not an error if Docker is optional
    fi
    
    if ! systemctl is-active --quiet docker; then
        report ERROR "Docker is installed but not running"
        return 7
    fi
    
    report INFO "Docker is installed and running"
    passed=$((passed + 1))
    return 0
}
```

Add to `devbox.sh`:

```bash
run_doctor() {
    GENERAL_HEALTH_CHECKS=(
        osinfo
        pkg_mgr_health
        toolchain_verification
        check_disk_space      # Custom check
        check_memory          # Custom check
        check_docker_status   # Custom check
    )
    
    # Update total count in report_summary()
    # if [ $passed -eq 6 ]; then  # Update from 3 to 6
    #     status="PASSED"
    # ...
}
```

---

## Reporting API

### Source

`lib/reporting.sh`

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `reportfile` | string | Path to current diagnostic report |

### Functions

#### `report(level, message...)`

Write to both diagnostic report and main log.

**Parameters:**

- `level` (string): Report level - `INFO`, `DEBUG`, `ERROR`, `WARN`
- `message` (string...): Message to report

**Returns:** None

**Output:**

- Console (stdout)
- Diagnostic report file
- Main log file

**Example:**

```bash
report INFO "System check passed"
report DEBUG "Checking component X"
report ERROR "Component Y failed"
report WARN "Component Z deprecated"
```

**Output Files:**

**diagnostic_reports/report-*.log:**

```
[INFO] System check passed
[DEBUG] Checking component X
[ERROR] Component Y failed
[WARN] Component Z deprecated
```

**logs/devbox_*.log:**

```
2026-02-14 01:45:38 [INFO] System check passed
2026-02-14 01:45:38 [DEBUG] Checking component X
2026-02-14 01:45:38 [ERROR] Component Y failed
2026-02-14 01:45:38 [WARN] Component Z deprecated
```

**Console:**

```
System check passed
Checking component X
Component Y failed
Component Z deprecated
```

#### `report_header()`

Initialize diagnostic report file.

**Parameters:** None

**Returns:** None

**Automatically called** when `reporting.sh` is loaded.

**Output:**

```
Diagnostic Report - 2026-02-14
Generated by devbox diagnostics
======================================
```

#### `archive_old_reports()`

Move old diagnostic reports to archive.

**Parameters:** None

**Returns:** None

**Automatically called** when `reporting.sh` is loaded.

**Example:**

```bash
# Manual archival if needed
archive_old_reports
```

### Report File Structure

```
diagnostic_reports/
├── report-2026-02-14-01-45-38.log  # Current report
├── report-2026-02-13-15-30-22.log
└── archive/                         # Archived reports
    ├── report-2026-02-12-09-15-10.log
    └── report-2026-02-11-14-22-33.log
```

---

## Creating Custom Modules

### Template

```bash
# lib/mymodule.sh
# Custom module for DevBox

# Module-specific variables
readonly MY_MODULE_VERSION="1.0"
local_var=""

# Module initialization (if needed)
init_mymodule() {
    log INFO "Initializing mymodule..."
    local_var="initialized"
    return 0
}

# Public function 1
my_function() {
    log DEBUG "Running my_function..."
    
    # Your logic here
    if some_check; then
        log INFO "Function succeeded"
        return 0
    else
        log ERROR "Function failed"
        return 1
    fi
}

# Public function 2
another_function() {
    local param1=$1
    local param2=$2
    
    log DEBUG "Running another_function with params: $param1, $param2"
    
    # Your logic here
    echo "Result"
    return 0
}

# Private helper (prefix with _)
_helper_function() {
    # Internal use only
    return 0
}
```

### Integration with DevBox

**1. Add library to `lib/` directory:**

```bash
touch lib/mymodule.sh
chmod +x lib/mymodule.sh
```

**2. Load in `devbox.sh`:**

```bash
# In LOAD LIBRARIES section
for lib in packages.sh docker.sh reporting.sh diagnostics.sh mymodule.sh; do
    if source "$SCRIPT_DIR/lib/$lib" &>> "${logfile:-/dev/null}"; then
        log INFO "\"lib/$lib\" loaded successfully"
    else
        log ERROR "Failed to load \"lib/$lib\""
        exit 4
    fi
done
```

**3. Use in commands:**

```bash
# Create new command
run_mycommand() {
    log INFO "Running custom command"
    
    if ! my_function; then
        log ERROR "Custom command failed"
        exit 20  # Custom exit code
    fi
    
    log INFO "Custom command completed"
}

# Add to argument parsing
case "$COMMAND" in
    install)
        run_install
        ;;
    doctor)
        run_doctor
        ;;
    mycommand)       # New command
        run_mycommand
        ;;
esac
```

**4. Update help text:**

```bash
Commands:
  install       Set up development environment
  doctor        Run diagnostic checks
  mycommand     Run custom command          # Add this
```

---

## Best Practices

### Error Handling

```bash
# Always check return values
if ! my_function; then
    log ERROR "Operation failed"
    return 1
fi

# Use set flags
set -euo pipefail  # In script header

# Provide context in errors
log ERROR "Failed to install $package_name: disk space insufficient"
```

### Variable Naming

```bash
# Constants (readonly)
readonly MY_CONSTANT="value"
readonly SCRIPT_VERSION="1.0"

# Global variables
global_var="value"

# Local variables
local local_var="value"

# Function parameters
my_function() {
    local param1=$1
    local param2=$2
}
```

### Logging Guidelines

```bash
# Use appropriate levels
log INFO "User-facing milestone"
log DEBUG "Technical detail"
log ERROR "Operation failed"
log WARN "Non-critical issue"

# Include context
log INFO "Installing package: $pkg_name"
log ERROR "Failed to install $pkg_name: $error_message"

# Don't over-log
# Good:
log DEBUG "Starting installation"
log INFO "Installation complete"

# Bad:
log DEBUG "Step 1"
log DEBUG "Step 2"
log DEBUG "Step 3"
# ... (too verbose)
```

### Idempotency

```bash
# Always check before acting
if ! command -v tool &> /dev/null; then
    install_tool
else
    log INFO "Tool already installed"
fi

# Make operations repeatable
if ! check_state; then
    perform_action
fi
```

### User Experience

```bash
# Provide console feedback
echo "Installing packages..."
echo "Docker installed successfully."

# Show progress
for pkg in "${packages[@]}"; do
    echo "Installing $pkg..."
    install_package "$pkg"
done

# Handle sudo user context
if [[ -n "$SUDO_USER" ]]; then
    chown "$SUDO_USER:$SUDO_USER" "$file"
fi
```

### Documentation

```bash
# Function documentation
# my_function - Brief description
#
# Parameters:
#   $1 - param1 description
#   $2 - param2 description
#
# Returns:
#   0 - Success
#   1 - Failure
#
# Example:
#   my_function "value1" "value2"
my_function() {
    local param1=$1
    local param2=$2
    # Implementation
}
```

---

## Exit Code Conventions

When creating custom functions, use these exit code ranges:

| Range | Purpose | Example |
|-------|---------|---------|
| 0 | Success | Operation completed |
| 1-10 | Core errors | See devbox.sh |
| 11-19 | Diagnostic errors | pkg_mgr_health, toolchain_verification |
| 20-29 | Custom module errors | Your module |
| 30-39 | Reserved | Future use |

Example:

```bash
# In your custom module
readonly ERR_MY_MODULE_INIT=20
readonly ERR_MY_MODULE_CONFIG=21
readonly ERR_MY_MODULE_EXECUTE=22

my_function() {
    if ! init; then
        return $ERR_MY_MODULE_INIT
    fi
    
    if ! configure; then
        return $ERR_MY_MODULE_CONFIG
    fi
    
    if ! execute; then
        return $ERR_MY_MODULE_EXECUTE
    fi
    
    return 0
}
```

---

## Testing Your Module

### Unit Testing Template

```bash
#!/bin/bash
# test_mymodule.sh

# Setup
source lib/logging.sh
source lib/mymodule.sh

# Test 1
test_my_function() {
    echo "Testing my_function..."
    if my_function; then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL"
        return 1
    fi
}

# Test 2
test_another_function() {
    echo "Testing another_function..."
    result=$(another_function "param1" "param2")
    if [[ "$result" == "expected" ]]; then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL: got '$result'"
        return 1
    fi
}

# Run tests
failed=0
test_my_function || failed=$((failed + 1))
test_another_function || failed=$((failed + 1))

if [ $failed -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "$failed test(s) failed"
    exit 1
fi
```

### Integration Testing

```bash
# Test with DevBox
sudo ./devbox.sh mycommand

# Check logs
grep ERROR logs/devbox_$(date +%Y-%m-%d).log

# Verify results
if [ $? -eq 0 ]; then
    echo "✅ Integration test passed"
else
    echo "❌ Integration test failed"
fi
```

---

**Last Updated**: 2026-02-14  
**DevBox Version**: 1.0.0  
**Author**: Pavara Mirihagalla
