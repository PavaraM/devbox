# DevBox API Reference

Developer documentation for extending and customizing DevBox v2.0

---

## Table of Contents

1. [Library Architecture](#library-architecture)
2. [Logging API](#logging-api)
3. [Distro API](#distro-api)
4. [Package Map API](#package-map-api)
5. [Package Management API](#package-management-api)
6. [Docker API](#docker-api)
7. [Security API](#security-api)
8. [Config API](#config-api)
9. [Profiles API](#profiles-api)
10. [Hooks API](#hooks-api)
11. [State API](#state-api)
12. [Version Manager API](#version-manager-api)
13. [Diagnostics API](#diagnostics-api)
14. [Reporting API](#reporting-api)
15. [Creating Custom Modules](#creating-custom-modules)
16. [Best Practices](#best-practices)
17. [Exit Code Conventions](#exit-code-conventions)
18. [Testing Your Module](#testing-your-module)

---

## Library Architecture

### Overview

DevBox uses a modular library system where each library is a separate bash script in the `lib/` directory:

```
lib/
├── logging.sh         # Core logging functionality
├── distro.sh          # Multi-distro detection + package/service/firewall primitives
├── pkgmap.sh          # Canonical package name → distro package mapping
├── packages.sh        # Package installation groups
├── docker.sh          # Docker setup
├── security.sh        # SSH hardening + firewall + deploy user
├── config.sh          # Configuration file hierarchy
├── profiles.sh        # Profile accumulation + application
├── hooks.sh           # Phase hook execution
├── state.sh           # Persistent install state (--resume)
├── version-manager.sh # mise + tools.conf (--with-mise)
├── diagnostics.sh     # System health checks
└── reporting.sh       # Diagnostic reporting (log + JSON)
```

### Loading Order

Libraries are loaded in `devbox.sh` in this order:

1. `logging.sh` - **Loaded first** (required by others) + `logger_init`
2. `distro.sh` + `distro_init` (fail → exit 4)
3. `pkgmap.sh`
4. `packages.sh`
5. `docker.sh`
6. `reporting.sh`
7. `diagnostics.sh`
8. `security.sh`
9. `config.sh`
10. `profiles.sh`
11. `hooks.sh`
12. `state.sh`
13. `version-manager.sh`

Then `config_load` is called to merge user config.

### Global Variables

Available to all libraries after `devbox.sh` initialization:

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `SCRIPT_DIR` | readonly | DevBox installation directory | `/home/user/devbox` |
| `TIMESTAMP` | readonly | Current date | `2026-02-14` |
| `START_TIME` | readonly | Execution start (milliseconds) | `1707873938000` |
| `logfile` | string | Path to main log file | `logs/devbox_dev_2026-02-14.log` |
| `reportfile` | string | Path to diagnostic report | `diagnostic_reports/report-*.log` |
| `DISTRO_ID` | string | OS identifier from `/etc/os-release` | `ubuntu` |
| `DISTRO_FAMILY` | string | Normalized family | `debian` |
| `PKG_MGR` | string | Package manager binary | `apt` |
| `SVC_MGR` | string | Service manager | `systemctl` |
| `FIREWALL_TOOL` | string | Firewall command | `ufw` |
| `DRY_RUN` | string | `true` when `--dry-run` passed | `true`/`false` |
| `SUDO_USER` | string | Original invoking user (when run via sudo) | `pavara` |

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

#### `logger_init()`

Initialize the logger: creates directories, archives old logs, opens the log file. Called from `devbox.sh` before any other library loads.

**Parameters:** None

**Returns:**

- `0` - Logger initialized
- Non-zero - Failed to create log file

#### `log_footer()`

Automatically called on script exit (EXIT trap). Logs execution summary and fixes ownership.

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

#### `log_archive()`

Move logs older than `LOG_RETENTION_DAYS` into `logs/archive/`. Called automatically by `logger_init`.

**Parameters:** None

**Returns:** None

### Log File Management

#### Automatic Features

**Log Creation:**

```bash
# Automatically creates (from conf/logger.conf):
logs/devbox_dev_$TIMESTAMP.log     # softname_environment_date.log
logs/pkg/                          # per-package install logs
logs/archive/                      # archived logs
```

Log naming is configured in `conf/logger.conf`:

```bash
softname="devbox"      # → devbox_dev_*.log
environment="dev"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_RETENTION_DAYS=7
```

**Log Archival:**

```bash
# Automatically archives logs older than LOG_RETENTION_DAYS
# via log_archive() on every logger_init()
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

## Distro API

### Source

`lib/distro.sh`

### Purpose

Multi-distro detection and system primitives. DevBox supports Debian, RHEL, Arch, SUSE, and Alpine families by abstracting package managers, service managers, and firewall tools.

### Family Mapping

`distro_init()` reads `/etc/os-release` and normalizes:

| Family | Distributions | PKG_MGR | SVC_MGR | FIREWALL_TOOL |
|--------|--------------|---------|---------|---------------|
| `debian` | ubuntu, debian, linuxmint, pop, kali, raspbian, zorin, elementary | `apt` | `systemctl` | `ufw` |
| `rhel` | fedora, rhel, centos, rocky, almalinux | `dnf` | `systemctl` | `firewalld-cmd` |
| `arch` | arch, manjaro, endeavouros, artix, garuda | `pacman` | `systemctl` | `nft` |
| `suse` | opensuse*, suse | `zypper` | `systemctl` | `firewalld-cmd` |
| `alpine` | alpine | `apk` | `rc-service` | `iptables` |

Unknown distributions fall back to `ID_LIKE`; unsupported distributions cause `distro_init` to return 1 (exit 4).

### Global Variables

Set by `distro_init()` and exported:

- `DISTRO_ID`, `DISTRO_VERSION`, `DISTRO_CODENAME`
- `DISTRO_FAMILY`, `DISTRO_NAME`
- `PKG_MGR`, `SVC_MGR`, `FIREWALL_TOOL`

### Functions

#### `distro_init()`

Detect the distribution and set all distro globals. Called from `devbox.sh`.

**Returns:**

- `0` - Detected
- `1` - Unsupported distribution

#### `distro_supported()`

**Returns:**

- `0` - Distribution is supported
- `1` - Not supported

#### Package primitives

Each takes a package name and dispatches to the correct backend (`apt`/`dnf`/`pacman`/`apk`/`zypper`):

- `pkg_install <pkg>` - Install a package
- `pkg_remove <pkg>` - Remove a package
- `pkg_update` - Refresh package lists (no upgrade)
- `pkg_upgrade` - Upgrade all packages
- `pkg_installed <pkg>` - Returns 0 if installed
- `pkg_cache_clean` - Clean package cache

#### Service primitives

- `svc_start <name>` / `svc_stop <name>` / `svc_restart <name>` / `svc_reload <name>`
- `svc_enable <name>` / `svc_disable <name>`
- `svc_status <name>` - Print status
- `svc_is_active <name>` - Returns 0 if active

#### Firewall primitives

- `firewall_allow_port <port>` - Open a port
- `firewall_limit_port <port>` - Rate-limit a port (e.g. SSH)
- `firewall_default_deny` - Deny by default
- `firewall_enable` - Turn the firewall on
- `firewall_status` - Print status
- `firewall_is_active` - Returns 0 if active

#### Misc

- `user_add <user> [groups]` - Create a user with supplementary groups
- `ssh_config_path` - Print the sshd_config path for this system
- `sudo_cmd_wrapper` - Wrap commands that need sudo
- `is_bash_available` - Returns 0 if bash is available (used by bootstrap)
- `docker_pkg_name` - Print the Docker package name for this family
- `build_base_pkg` - Print the build-essential equivalent (`build-essential`/`base-devel`/`build-base`)

---

## Package Map API

### Source

`lib/pkgmap.sh`

### Purpose

Maps canonical package names to the distro-specific package name, so higher layers only ever use one name.

### Functions

#### `pkg_map <canonical>`

Print the distro package name for a canonical name.

**Parameters:**

- `canonical` (string): Canonical name used across DevBox

**Returns:**

- `0` - Mapping found
- `1` - No mapping (name passed through unchanged)

**Examples:**

```bash
pkg_map vim
# debian → neovim
# rhel   → vim-enhanced
# arch   → neovim
# alpine → neovim
# suse   → vim

pkg_map git
# all families → git
```

#### `pkg_map_bulk <names...>`

Print each canonical name mapped, one per line.

**Parameters:**

- `names` (string...): Canonical names

**Returns:** None

---

## Package Management API

### Source

`lib/packages.sh`

### Functions

#### `pkg_update_system()`

Update package lists; upgrade only when `DIST_UPGRADE=true` (the `--dist-upgrade` flag).

**Parameters:** None

**Returns:**

- `0` - Success
- `1` - Update failed

**Example:**

```bash
pkg_update_system
# with --dist-upgrade:
#   pkg_update + pkg_upgrade
# without:
#   pkg_update only
```

#### `pkg_check_and_install(name, canonical)`

Generic helper to check and install a package by canonical name.

**Parameters:**

- `name` (string): Display name for logging
- `canonical` (string): Canonical package name (mapped via `pkg_map`)

**Returns:**

- `0` - Success (already installed or newly installed)
- `1` - Installation failed

**Features:**

- Idempotent (skips if already installed)
- Creates per-package log: `logs/pkg/pkg_$TIMESTAMP-$name.log`
- User-friendly console output
- Automatic ownership fixing (`chown` to `$SUDO_USER`)

**Example:**

```bash
# Install git
pkg_check_and_install git git

# vim maps to neovim/vim-enhanced per family
pkg_check_and_install vim vim

# Check return value
if ! pkg_check_and_install python3 python3; then
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
2026-02-14 01:45:38 [DEBUG] Running apt install git
2026-02-14 01:45:39 [INFO] git installation successful
```

#### `_install_group(group_name, pkgs...)`

Install a group of canonical packages, collecting failures.

**Parameters:**

- `group_name` (string): Label for logging
- `pkgs` (string...): Canonical package names

**Returns:**

- `0` - All installed
- `1` - One or more failed

**Example:**

```bash
if ! _install_group "custom tools" htop tree ripgrep; then
    log ERROR "Some custom tools failed"
fi
```

#### `main_essentials()`

Install core development packages.

**Parameters:** None

**Returns:**

- `0` - All packages installed successfully
- `1` - One or more packages failed

**Installs (canonical):**

- git, curl, wget, htop, tmux, vim, unzip, tree, net-tools, ca-certificates, build-essential

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
- `1` - One or more tools failed

**Installs:**

- ufw, iproute2, dnsutils, nmap

**Example:**

```bash
if ! networkingtools; then
    log ERROR "Failed to install networking tools"
    exit 5
fi
```

#### `custom_packages()`

Install packages from the distro-family package config.

**Config selection:**

- `debian` family → `conf/apt-packages.conf`
- `rhel` family → `conf/dnf-packages.conf`
- other families / missing file → `conf/pkg.conf` (backward compatible)

**Returns:**

- `0` - All installed or none configured
- `1` - One or more failed

**Example:**

```bash
if ! custom_packages; then
    log ERROR "Failed to install custom packages"
    exit 5
fi
```

#### `custom_packages_conf()`

Source the correct package config file for the current distro family (used by `custom_packages()` and `custom_packages_check()`).

**Returns:**

- `0` - Config sourced
- `1` - No config found

### Creating Custom Package Groups

```bash
# In lib/packages.sh or custom library

python_stack() {
    log INFO "Installing Python development stack..."
    local failed_packages=()

    _install_group python3 python3 || failed_packages+=("python3")
    _install_group pip python3-pip || failed_packages+=("pip")
    _install_group venv python3-venv || failed_packages+=("venv")

    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "Python stack installed successfully"
        return 0
    else
        log ERROR "Failed to install Python packages: ${failed_packages[*]}"
        return 1
    fi
}

nodejs_stack() {
    log INFO "Installing Node.js development stack..."
    local failed_packages=()

    _install_group nodejs nodejs || failed_packages+=("nodejs")
    _install_group npm npm || failed_packages+=("npm")

    if [ ${#failed_packages[@]} -eq 0 ]; then
        log INFO "Node.js stack installed successfully"
        return 0
    else
        log ERROR "Failed to install Node.js packages: ${failed_packages[*]}"
        return 1
    fi
}
```

Then call from your profile or hook:

```bash
_install_group "custom stacks" ...   # from a profile extra command
```

---

## Docker API

### Source

`lib/docker.sh`

### Functions

#### `install_docker()`

Install Docker Engine using the official bootstrap script.

**Parameters:** None

**Returns:**

- `0` - Docker installed (or already present)
- `1` - Installation failed

**Features:**

- Checks for existing installation (idempotent)
- Downloads official script from `https://get.docker.com`
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

Install the Docker Compose plugin.

**Parameters:** None

**Returns:**

- `0` - Docker Compose available (plugin or standalone)
- `1` - Installation failed

**Features:**

- Checks for plugin first (`docker compose`)
- Falls back to standalone check (`docker-compose`)
- Architecture detection (x86_64, aarch64, armv7)
- Downloads from official GitHub releases (pinned `v2.27.0` in `lib/docker.sh`)
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
- `1` - Any stage failed (caller maps to exit 6-10)

**Process:**

1. Install Docker Engine
2. Start Docker daemon (`svc_start`/`svc_enable`)
3. Install Docker Compose plugin
4. Add user to `docker` group
5. Verify installation

**Example:**

```bash
if ! docker_setup; then
    log ERROR "Docker setup failed"
    exit 6
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

Modify the Docker Compose version in `lib/docker.sh`:

```bash
# In docker_compose_setup()
local compose_version="v2.27.0"  # Change this

# Available versions: https://github.com/docker/compose/releases
```

---

## Security API

### Source

`lib/security.sh` — loaded by `devbox.sh` on v1.2.0+.

### Configuration

`conf/security.conf` is sourced at module load time. Edit values there, not in scripts.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `SSH_PORT` | integer | `22` | Port `sshd` listens on; must match `sshd_config` |
| `FIREWALL_OPEN_PORTS` | string | `"22 80 443"` | Space-separated ports to allow |
| `DEPLOY_USERNAME` | string | `"deploy"` | Username for `--setup-user` |
| `DEPLOY_SUDO_NOPASSWD` | boolean | `true` | If true, deploy user gets passwordless sudo |
| `DEPLOY_GROUPS` | string | `"docker,sudo"` | Comma-separated supplementary groups |

### Functions

#### `ssh_harden()`

Back up `/etc/ssh/sshd_config` to `sshd_config.devbox-backup.<timestamp>`, rewrite it with strong defaults, validate with `sshd -t`, then restart `sshd`. On any failure, restores the backup.

```bash
# Direct call (normally invoked via --harden)
ssh_harden [--dry-run]

# Exits 15 on failure (after rollback).
```

Writes: key-only auth, strong ciphers/MACs only, root login disabled, password auth disabled. Honors `SSH_PORT` from `conf/security.conf`.

#### `configure_firewall()`

Reset the firewall (UFW/firewalld/nft/iptables per distro) to defaults, then apply the allow-list from `conf/security.conf`. Rate-limits SSH via `firewall_limit_port`.

```bash
configure_firewall [--dry-run]
```

Exits 16 on failure.

#### `setup_deploy_user <username>`

Create the user (if missing), set up `~/.ssh/authorized_keys`, add supplementary groups, write `/etc/sudoers.d/<username>`. Idempotent — safe to re-run.

```bash
setup_deploy_user "$DEPLOY_USERNAME" [--dry-run]
```

Exits 17 on failure.

### Idempotency

All security functions check current state before modifying. Re-running `--harden` on an already-hardened host produces no diff. This is what makes DevBox safe to run on existing systems.

### Dry Run

Every security function accepts `--dry-run` and prints planned changes without applying them. Exit code still reflects what would have happened.

---

## Config API

### Source

`lib/config.sh`

### Purpose

Hierarchical configuration merge, applied after all libraries load.

### Hierarchy

`config_load()` sources each file if it exists, in order (later wins):

1. `/etc/devbox/config.conf`
2. `$HOME/.config/devbox/config.conf`
3. `$SCRIPT_DIR/devbox.conf` (repository-local)

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `CONFIG_LOADED` | boolean | `true` after `config_load()` |
| `CONFIG_PROFILES` | array | Profiles requested via config |

### Functions

#### `config_load()`

Load the configuration hierarchy.

**Parameters:** None

**Returns:**

- `0` - Always succeeds (missing files are fine)

#### `config_get_profiles()`

Print profiles requested via config (one per line), if any.

**Parameters:** None

**Returns:** None

---

## Profiles API

### Source

`lib/profiles.sh`

### Purpose

Named, composable provisioning profiles stored as `.conf` files in `conf/profiles/`. Selected via `--profile <name>` (repeatable).

### Configuration Format

Each profile file sets:

| Variable | Type | Description |
|----------|------|-------------|
| `PROFILE_DESC` | string | One-line description (shown by `profiles` command) |
| `PROFILE_PACKAGES` | array | Canonical packages to install |
| `PROFILE_EXTRA_CMDS` | array | Arbitrary commands to run after install |
| `PROFILE_INSTALL_DOCKER` | boolean | Install Docker |
| `PROFILE_HARDEN` | boolean | Apply SSH hardening + firewall |
| `PROFILE_SETUP_USER` | string | Deploy username to create |

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `ACTIVE_PROFILES` | array | Loaded profile names |
| `_ACCUM_PKGS` | array | Accumulated packages |
| `_ACCUM_CMDS` | array | Accumulated extra commands |
| `_ACCUM_DOCKER` | boolean | Docker requested by any profile |
| `_ACCUM_HARDEN` | boolean | Harden requested by any profile |
| `_ACCUM_DEPLOY` | string | Deploy username (first wins) |

### Functions

#### `profile_list()`

Print available profiles and their descriptions. Names must match `^[a-zA-Z0-9_-]+$`.

**Parameters:** None

**Returns:** None

#### `profile_load <name>`

Source a profile config and accumulate its settings.

**Parameters:**

- `name` (string): Profile basename (without `.conf`)

**Returns:**

- `0` - Loaded
- `1` - Not found

#### `profile_apply()`

Install accumulated `_ACCUM_PKGS` via `_install_group`.

**Parameters:** None

**Returns:** None

#### `profile_apply_extra()`

Run each accumulated `_ACCUM_CMDS` via `eval`. Non-fatal — failures log `WARN` (except with `--dry-run`, which prints the command).

**Parameters:** None

**Returns:** None

#### `profile_wants_docker()`

**Returns:**

- `0` - Docker requested
- `1` - Not requested

#### `profile_wants_harden()`

**Returns:**

- `0` - Harden requested
- `1` - Not requested

#### `profile_deploy_user()`

Print the deploy username requested by profiles (empty if none).

**Parameters:** None

**Returns:** None

---

## Hooks API

### Source

`lib/hooks.sh`

### Purpose

Extensible lifecycle hooks. Hook scripts live in `conf/hooks/<phase>/` and run at named points during install. Customize provisioning without editing libraries.

### Phases

Hook directories under `conf/hooks/`:

| Phase | When it runs |
|-------|--------------|
| `pre-install` | Before package installation |
| `post-install` | After package installation |
| `pre-docker` | Before Docker setup |
| `post-docker` | After Docker setup |
| `pre-harden` | Before SSH hardening |
| `post-harden` | After SSH hardening |
| `pre-user` | Before deploy user setup |
| `post-user` | After deploy user setup |

Any `*.sh` file in a phase directory runs in lexicographic order (e.g. `10-preflight.sh` runs before `20-dns.sh`).

### Functions

#### `hooks_run <phase>`

Run all hook scripts in a phase directory.

**Parameters:**

- `phase` (string): Phase name (e.g. `pre-install`)

**Returns:**

- `0` - All hooks ran (failures log `WARN`, not fatal)

**Example:**

```bash
hooks_run "pre-install"
hooks_run "post-install"
```

#### `hooks_list()`

Print hook counts and script names per phase.

**Parameters:** None

**Returns:** None

### Creating a Hook

```bash
# conf/hooks/post-install/10-report.sh
#!/bin/bash
# Runs after packages install
echo "Installation finished at $(date)" >> /tmp/devbox-hook.log
```

```bash
chmod +x conf/hooks/post-install/10-report.sh
```

---

## State API

### Source

`lib/state.sh`

### Purpose

Persistent install state backing the `--resume` flag. Records which phases have completed so a re-run can skip them.

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `STATE_DIR` | string | State directory (override with `DEVBOX_STATE_DIR`) |
| `STATE_FILE` | string | State file path (default `/var/lib/devbox/state`) |

### Functions

#### `state_init()`

Create the state directory if missing.

**Parameters:** None

**Returns:**

- `0` - Directory ready
- `1` - Failed

#### `state_mark <step>`

Mark a step complete. Reads the existing file, merges, and rewrites a sorted JSON object.

**Parameters:**

- `step` (string): Step name (`packages`, `docker`, `harden`, `user`, `version-manager`)

**Returns:**

- `0` - Written

**Example file:**

```json
{
  "docker": true,
  "packages": true
}
```

#### `state_done <step>`

**Parameters:**

- `step` (string): Step name

**Returns:**

- `0` - Step is marked complete
- `1` - Not complete, or state file missing

#### `state_clear()`

Remove the state file entirely.

**Parameters:** None

**Returns:** None

**Example:**

```bash
state_init
state_done "packages"        # → 1 on first run
state_mark "packages"
state_done "packages"        # → 0
state_clear                  # wipe all state
```

---

## Version Manager API

### Source

`lib/version-manager.sh`

### Purpose

Install `mise` and provision runtime tools pinned in `conf/tools.conf`, backing the `--with-mise` flag.

### Configuration

`conf/tools.conf` uses `tool=version` lines:

```bash
# conf/tools.conf
nodejs=20.0.0
golang=1.22.5
python=3.12.0
ruby=3.3.0
```

A value of `*` or `latest` maps to `tool@latest`. Comments (`#`) and blank lines are ignored.

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `TOOLS_CONF` | string | Path to `conf/tools.conf` |
| `TOOLS_TO_INSTALL` | array | Parsed `tool@version` specs |

### Functions

#### `mise_bin_path()`

Print the path to the `mise` binary.

**Returns:**

- `0` - Found (via `command -v mise` or `$HOME/.local/bin/mise`)
- `1` - Not found

#### `install_mise()`

Install mise from `https://mise.run`. Idempotent and `DRY_RUN`-aware. Output goes to `logs/mise-install.log`.

**Parameters:** None

**Returns:**

- `0` - Installed or already present
- `1` - Failed

#### `tools_load()`

Parse `conf/tools.conf` into `TOOLS_TO_INSTALL`.

**Parameters:** None

**Returns:**

- `0` - Parsed

#### `mise_install_tools()`

Install each spec in `TOOLS_TO_INSTALL` via `mise install`.

**Parameters:** None

**Returns:**

- `0` - All installed
- `1` - One or more failed

#### `setup_version_manager()`

Orchestrator: `install_mise` then `mise_install_tools`.

**Parameters:** None

**Returns:**

- `0` - Success
- `1` - Failure (caller exits 18)

**Example:**

```bash
if ! setup_version_manager; then
    log ERROR "Version manager setup failed"
    exit 18
fi
```

---

## Diagnostics API

### Source

`lib/diagnostics.sh`

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `passed` | integer | Count of passed diagnostic checks |
| `total_checks` | integer | Total check count (7) |

The seven checks, in order:

1. `osinfo`
2. `pkg_mgr_health`
3. `toolchain_verification`
4. `custom_packages_check`
5. `ssh_harden_check`
6. `firewall_check`
7. `deploy_user_check`

### Functions

#### `osinfo()`

Collect and report system information.

**Parameters:** None

**Returns:**

- `0` - Always succeeds; increments `passed`

**Collects:**

- Distribution name and version
- Kernel version
- System architecture
- User permissions (UID)
- Internet connectivity status

**Output:**

```
[INFO] Distro: Ubuntu 24.04 LTS
[INFO] Kernel: 6.17.0-14-generic
[INFO] Architecture: x86_64
[INFO] User Permissions: 0
[INFO] Internet Connectivity: online
```

#### `pkg_mgr_health()`

Verify the detected package manager health (apt/dnf/pacman/apk/zypper).

**Parameters:** None

**Returns:**

- `0` - Package manager healthy
- `1` - Binary not found
- `11` - Lock detected
- `14` - Broken packages (apt only)

**Checks:**

- Binary availability
- Lock status (dpkg/rpm/pacman/apk)
- Broken package detection (apt)

**Example:**

```bash
if ! pkg_mgr_health; then
    report ERROR "Package manager is unhealthy"
    exit 11
fi
```

#### `toolchain_verification()`

Verify essential development tools are installed, using `pkg_map` + `pkg_installed` for cross-distro correctness.

**Parameters:** None

**Returns:**

- `0` - All tools present
- `13` - One or more tools missing

**Checks For (canonical):**

- git, curl, wget, htop, tmux, vim, unzip, tree, net-tools, ca-certificates, build-essential

**Example:**

```bash
if ! toolchain_verification; then
    report ERROR "Missing essential tools"
    exit 13
fi
```

#### `custom_packages_check()`

Verify custom packages (from the family config) are installed.

**Parameters:** None

**Returns:**

- `0` - All present, or none configured
- `14` - One or more missing

#### `ssh_harden_check()`

Check whether SSH hardening is applied (looks for `PermitRootLogin no`).

**Parameters:** None

**Returns:**

- `0` - Always; increments `passed` (WARN if not applied)

#### `firewall_check()`

Check firewall status using `FIREWALL_TOOL`.

**Parameters:** None

**Returns:**

- `0` - Always; increments `passed`

#### `deploy_user_check()`

Check whether the deploy user exists.

**Parameters:** None

**Returns:**

- `0` - Always; increments `passed`

#### `report_summary()`

Generate diagnostic summary. `status` is `PASSED` when `passed == total_checks`.

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
checks_passed: 7/7
report generated at: diagnostic_reports/report-2026-02-14-01-45-38.log
=======================
```

### Creating Custom Diagnostic Checks

```bash
# In lib/diagnostics.sh, then add to GENERAL_HEALTH_CHECKS in devbox.sh

check_disk_space() {
    report DEBUG "Checking disk space..."

    local available=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "$available" -lt 5 ]; then
        report ERROR "Low disk space: ${available}GB available"
        return 1
    fi

    report INFO "Disk space: ${available}GB available"
    passed=$((passed + 1))
    return 0
}
```

Add to `devbox.sh` `run_doctor()`:

```bash
GENERAL_HEALTH_CHECKS=(
    osinfo
    pkg_mgr_health
    toolchain_verification
    custom_packages_check
    ssh_harden_check
    firewall_check
    deploy_user_check
    check_disk_space      # Custom check
)
```

Then update `total_checks` in `report_summary()` (currently 7) to match.

---

## Reporting API

### Source

`lib/reporting.sh`

### Global Variables

| Variable | Type | Description |
|----------|------|-------------|
| `reportfile` | string | Path to current diagnostic report |
| `JSON_ENTRIES` | array | JSON entries collected for `--json` output |

### Functions

#### `report(level, message...)`

Write to the diagnostic report, main log, and (when `JSON_REPORT=true`) collect a JSON entry.

**Parameters:**

- `level` (string): Report level - `INFO`, `DEBUG`, `ERROR`, `WARN`
- `message` (string...): Message to report

**Returns:** None

**Output:**

- Console (stdout)
- Diagnostic report file
- Main log file
- `JSON_ENTRIES` (when `--json` active)

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

**logs/devbox_dev_*.log:**

```
2026-02-14 01:45:38 [INFO] System check passed
2026-02-14 01:45:38 [DEBUG] Checking component X
2026-02-14 01:45:38 [ERROR] Component Y failed
2026-02-14 01:45:38 [WARN] Component Z deprecated
```

#### `write_json_report()`

Write `JSON_ENTRIES` to `<reportfile-basename>.json` with distro context and a PASSED/FAILED summary. Called by `devbox.sh` when `--json` is passed.

**Parameters:** None

**Returns:**

- `0` - Written
- `1` - Failed

**Example output (`diagnostic_reports/report-2026-02-14-01-45-38.json`):**

```json
{
  "report_type": "diagnostic",
  "generated_at": "2026-02-14 01:45:38",
  "distro": {
    "name": "Ubuntu 24.04 LTS",
    "family": "debian",
    "version": "24.04",
    "pkg_mgr": "apt",
    "svc_mgr": "systemctl",
    "firewall_tool": "ufw"
  },
  "summary": { "status": "PASSED", "passed": 7, "total": 7 },
  "checks": [
    {"level": "INFO", "message": "Distro: Ubuntu 24.04 LTS"},
    {"level": "INFO", "message": "Package manager is healthy"}
  ]
}
```

#### `report_header()`

Initialize diagnostic report file. Called by `init_reporting()`.

**Parameters:** None

**Returns:** None

**Output:**

```
Diagnostic Report - 2026-02-14
Generated by devbox diagnostics
======================================
```

#### `init_reporting()`

Set up the report file, archive old reports, write the header. Called before checks run.

**Parameters:** None

**Returns:** None

#### `archive_old_reports()`

Move old diagnostic reports to `diagnostic_reports/archive/`.

**Parameters:** None

**Returns:** None

### Report File Structure

```
diagnostic_reports/
├── report-2026-02-14-01-45-38.log   # Current report
├── report-2026-02-14-01-45-38.json  # Current JSON report (--json)
├── report-2026-02-13-15-30-22.log
└── archive/                          # Archived reports
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

**2. Load in `devbox.sh`** — add `mymodule.sh` to BOTH the executable-check loop and the source loop:

```bash
# Executable check loop (around line 166)
for lib in pkgmap.sh packages.sh docker.sh diagnostics.sh reporting.sh security.sh \
           config.sh profiles.sh hooks.sh state.sh version-manager.sh mymodule.sh; do
    lib_path="$SCRIPT_DIR/lib/$lib"
    if [[ ! -f "$lib_path" ]]; then
        log ERROR "Missing required library: $lib_path"
        exit 4
    fi
    chmod +x "$lib_path"
done

# Source loop (around line 179)
for lib in pkgmap.sh packages.sh docker.sh reporting.sh diagnostics.sh security.sh \
           config.sh profiles.sh hooks.sh state.sh version-manager.sh mymodule.sh; do
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
readonly SCRIPT_VERSION="2.0"

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

### DRY-RUN Awareness

```bash
# Honor --dry-run in custom functions
if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would run: my_command --flag"
    return 0
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

The full exit code map is documented in `devbox.sh` and `docs/QUICKREF.md`. For custom functions:

| Range | Purpose | Example |
|-------|---------|---------|
| 0 | Success | Operation completed |
| 1-10 | Core errors | See devbox.sh |
| 11-19 | Diagnostic + security + v2 errors | See devbox.sh |
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
grep ERROR logs/devbox_dev_$(date +%Y-%m-%d).log

# Verify results
if [ $? -eq 0 ]; then
    echo "✅ Integration test passed"
else
    echo "❌ Integration test failed"
fi
```

---

**Last Updated**: 2026-08-07  
**DevBox Version**: 2.0.0  
**Author**: Pavara Mirihagalla
