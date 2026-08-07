# DevBox v2.0 - File Structure

## Project Structure

```
devbox/
├── devbox.sh                            # Main CLI entrypoint
├── bootstrap.sh                         # Zero-dependency POSIX installer
├── VERSION
├── LICENSE
├── .github/
│   └── workflows/
│       └── ci.yml                       # CI: shellcheck lint + distro test matrix
│
├── lib/
│   ├── logging.sh                       # Structured logging
│   ├── distro.sh                        # Multi-distro detection & abstraction
│   ├── pkgmap.sh                        # Canonical → distro package mapping
│   ├── config.sh                        # Hierarchical config loader
│   ├── packages.sh                      # Multi-distro package management
│   ├── docker.sh                        # Docker Engine + Compose setup
│   ├── security.sh                      # SSH hardening, firewall, deploy user
│   ├── diagnostics.sh                   # System health checks
│   ├── reporting.sh                     # Diagnostic report generation
│   ├── profiles.sh                      # Profile engine
│   ├── hooks.sh                         # Lifecycle hook runner
│   ├── state.sh                         # Install state tracking (--resume)
│   └── version-manager.sh               # mise + versioned tool install (--with-mise)
│
├── conf/
│   ├── pkg.conf                         # Custom packages (fallback, legacy name)
│   ├── apt-packages.conf                # Custom packages (Debian family)
│   ├── dnf-packages.conf                # Custom packages (RHEL family)
│   ├── logger.conf                      # Logger configuration
│   ├── security.conf                    # SSH, firewall, deploy user settings
│   ├── tools.conf                       # Versioned tools for mise (tool=version)
│   ├── profiles/                        # Profile definitions
│   │   ├── minimal.conf
│   │   ├── base.conf
│   │   ├── standard.conf
│   │   ├── full.conf
│   │   ├── secure.conf
│   │   ├── python-dev.conf
│   │   ├── node-dev.conf
│   │   ├── go-dev.conf
│   │   ├── rust-dev.conf
│   │   └── cloud-dev.conf
│   └── hooks/                           # Lifecycle hook scripts
│       ├── pre-install/
│       ├── post-install/
│       ├── pre-docker/
│       ├── post-docker/
│       ├── pre-harden/
│       ├── post-harden/
│       ├── pre-user/
│       └── post-user/
│
├── README.md                            # Main project documentation
├── docs/
│   ├── API.md
│   ├── CONTRIBUTING.md
│   ├── DEBUGGING.md
│   ├── FILE_STRUCTURE.md
│   ├── QUICKREF.md
│   └── plans/
│       └── devbox-v2.md
│
├── logs/                                (auto-generated)
│   ├── devbox_YYYY-MM-DD.log
│   ├── pkg/
│   │   └── pkg_YYYY-MM-DD-<name>.log
│   └── archive/
│
└── diagnostic_reports/                  (auto-generated)
    ├── report-YYYY-MM-DD-HH-MM-SS.log
    ├── report-YYYY-MM-DD-HH-MM-SS.json (with --json)
    └── archive/
```

---

## File Descriptions

### Root Directory

**devbox.sh**
- Main executable script
- Entry point for all commands
- Loads library modules and orchestrates operations

**bootstrap.sh**
- Zero-dependency POSIX installer
- Fetches `devbox.sh`, all `lib/*.sh`, and `conf/` from the repository
- Works on any POSIX system with curl or wget

**VERSION**
- Version number and build information
- Format: version, build date, tested platform

**LICENSE**
- MIT License text

---

### lib/ Directory

**logging.sh**
- Structured logging infrastructure
- Creates and manages log files
- Auto-archives logs older than 7 days
- Manages file ownership
- Functions: `logger_init`, `log`, `log_footer`, `log_archive`, `_log_level_to_number`

**distro.sh**
- Multi-distro detection (Debian, RHEL/Fedora, Arch, Alpine, openSUSE)
- Sets `DISTRO_FAMILY`, `PKG_MGR`, `SVC_MGR`, `FIREWALL_TOOL`
- Unified package/service/firewall abstraction layer
- Functions: `distro_init`, `distro_supported`, `pkg_install`, `pkg_remove`, `pkg_update`, `pkg_upgrade`, `pkg_installed`, `pkg_cache_clean`, `svc_*`, `firewall_*`, `user_add`, `ssh_config_path`, `sudo_cmd_wrapper`, `build_base_pkg`

**pkgmap.sh**
- Canonical → distro-specific package name mapping
- Functions: `pkg_map`, `pkg_map_bulk`

**config.sh**
- Hierarchical configuration loader
- Load order: `/etc/devbox/config.conf` > `~/.config/devbox/config.conf` > `./devbox.conf`
- Functions: `config_load`, `config_get_profiles`

**packages.sh**
- Multi-distro package installation
- Functions: `pkg_update_system`, `pkg_check_and_install`, `_install_group`, `main_essentials`, `networkingtools`, `custom_packages_conf`, `custom_packages`, `pkg_install_wrapper`, `pkg_verbose_install`

**docker.sh**
- Docker Engine + Compose v2 installation
- Distro-specific backends (Debian, RHEL, Arch, Alpine, SUSE)
- Functions: `install_docker`, `docker_compose_setup`, `docker_setup`, `_install_docker_*`

**security.sh**
- SSH hardening, firewall configuration, deploy user creation
- Functions: `ssh_harden`, `configure_firewall`, `setup_deploy_user`, `_setup_deploy_user_ssh`, `_setup_deploy_user_groups`

**diagnostics.sh**
- System health checks (doctor command)
- Functions: `osinfo`, `pkg_mgr_health`, `toolchain_verification`, `custom_packages_check`, `ssh_harden_check`, `firewall_check`, `deploy_user_check`, `report_summary`

**reporting.sh**
- Diagnostic report generation (log + optional JSON)
- Functions: `init_reporting`, `report_header`, `report`, `write_json_report`, `archive_old_reports`

**profiles.sh**
- Profile-based customization engine
- Functions: `profile_list`, `profile_load`, `profile_apply`, `profile_apply_extra`, `profile_wants_docker`, `profile_wants_harden`, `profile_deploy_user`

**hooks.sh**
- Lifecycle hook runner (8 phases)
- Functions: `hooks_run`, `hooks_list`

**state.sh**
- Install state tracking for `--resume`
- JSON state at `/var/lib/devbox/state`
- Functions: `state_init`, `state_mark`, `state_done`, `state_clear`

**version-manager.sh**
- mise installation + versioned tool installs
- Functions: `setup_version_manager`, `install_mise`, `mise_bin_path`, `tools_load`, `mise_install_tools`

---

### conf/ Directory

**pkg.conf**
- Legacy fallback custom package configuration
- Defines `CUSTOM_PACKAGES` array
- Used when no distro-specific conf exists

**apt-packages.conf**
- Custom packages for the Debian family (apt)
- Same `CUSTOM_PACKAGES` array format as `pkg.conf`

**dnf-packages.conf**
- Custom packages for the RHEL family (dnf)
- Same `CUSTOM_PACKAGES` array format as `pkg.conf`

**logger.conf**
- Logger settings: log levels, colors, archive retention, date format

**security.conf**
- SSH port, firewall open ports, deploy user settings

**tools.conf**
- Versioned tools for mise: `nodejs=20.0.0`, `golang=1.22.5`, etc.

**profiles/ (10 profiles)**
- `minimal`, `base`, `standard`, `full`, `secure`
- `python-dev`, `node-dev`, `go-dev`, `rust-dev`, `cloud-dev`

**hooks/ (8 phases)**
- `pre-install`, `post-install`, `pre-docker`, `post-docker`
- `pre-harden`, `post-harden`, `pre-user`, `post-user`

---

## Installed Packages

Packages are specified by canonical name and mapped per-distro via `lib/pkgmap.sh`:

### Core Development Tools
- git
- curl
- wget
- htop
- tmux
- vim (mapped: neovim on Debian/Arch/Alpine, vim-enhanced on RHEL)
- unzip
- tree
- net-tools
- ca-certificates
- build-essential

### Networking Tools
- ufw
- iproute2
- dnsutils
- nmap

### Custom Packages
- Defined in `conf/<family>-packages.conf` (or legacy `pkg.conf`)
- User-configurable

### Profile Packages
- Defined per profile in `conf/profiles/*.conf`

---

## Commands

**install**
- Install essential development packages
- Usage: `sudo ./devbox.sh install`
- Flags: `--plus-docker`, `--harden`, `--setup-user <name>`, `--all`, `--profile <name>`, `--dist-upgrade`, `--resume`, `--with-mise`

**doctor**
- Run system diagnostics
- Usage: `sudo ./devbox.sh doctor`
- Flags: `--json`

**distro**
- Display detected operating system information
- Usage: `./devbox.sh distro`

**profiles**
- List available installation profiles
- Usage: `./devbox.sh profiles`

**hooks**
- List installed lifecycle hooks
- Usage: `./devbox.sh hooks`

**shell**
- Generate shell completion script (bash/zsh)
- Usage: `./devbox.sh shell bash`

**--config**
- Open the family-specific custom package config in an editor
- Usage: `./devbox.sh --config`

**--help**
- Display help information
- Usage: `./devbox.sh --help`

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | No root permission |
| 2 | No argument provided |
| 3 | Invalid argument |
| 4 | Library loading failure |
| 5 | Package installation failure |
| 6 | Docker installation failure |
| 7 | Docker service failure |
| 8 | Docker group setup failure |
| 9 | Docker Compose installation failure |
| 10 | Docker verification failure |
| 11 | Diagnostic check failure |
| 12 | No internet connection for diagnostics |
| 13 | Essential tool missing in diagnostics |
| 14 | Package manager is not healthy |
| 15 | SSH hardening failure |
| 16 | Firewall configuration failure |
| 17 | Deploy user setup failure |
| 18 | Version manager setup failure |
| 19 | JSON report generation failure |

---

## File Permissions

```bash
# Executable files
chmod +x devbox.sh
chmod +x lib/*.sh
chmod +x bootstrap.sh

# Hook scripts (auto-made executable on first run)
chmod +x conf/hooks/*/*.sh

# Configuration and documentation
chmod 644 conf/*.conf
chmod 644 VERSION
chmod 644 LICENSE
chmod 644 docs/*.md
```

---

## Log Format

### Main Log (logs/devbox_YYYY-MM-DD.log)
```
script started at [date]
command: devbox [command]
system: [uname output]
user: [username]
------------------------------

YYYY-MM-DD HH:MM:SS [LEVEL] message

------------------------------
Script ended at [date] exit_code=N duration=X.XXXs
==============================
```

### Per-Package Logs (logs/pkg/pkg_YYYY-MM-DD-<name>.log)
```
Detailed output of the package manager install for one package.
```

### Diagnostic Report (diagnostic_reports/report-*.log)
```
Diagnostic Report - YYYY-MM-DD
Generated by devbox diagnostics
======================================

[LEVEL] message
[LEVEL] message

=======================
Diagnostic Summary
status: PASSED/FAILED
checks_passed: N/M
=======================
```

### JSON Diagnostic Report (diagnostic_reports/report-*.json)
```
{
  "report_type": "diagnostic",
  "generated_at": "YYYY-MM-DD HH:MM:SS",
  "distro": { ... },
  "summary": { "status": "PASSED/FAILED", "checks_passed": N, "total_checks": M },
  "checks": [ ... ]
}
```
Emitted only when running `doctor --json`.

---

DevBox v2.0
