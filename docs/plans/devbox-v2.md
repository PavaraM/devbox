---
plan name: devbox-v2
plan description: Multi-distro + version managers
plan status: completed
---

## Idea
DevBox v2.0: evolve from Ubuntu/APT-only to multi-distro (Fedora/RHEL) with version manager integration (mise/asdf), a state file for resume after failure, and safer defaults (remove apt upgrade). Keep pure Bash — zero dependencies is a feature, not a limitation. The plan touches every lib but changes are additive (new branches, new config files, new functions), not rewrites.

## Implementation
- Create `lib/distro.sh` — auto-detect distro/family (Debian vs RedHat), set vars for pkg manager (apt/dnf), service manager, firewall (ufw/firewalld), and known quirks. Source it early in devbox.sh before other libs.
- Abstract `lib/packages.sh` — add `check_and_install()` that dispatches to distro-specific backends. Remove `apt upgrade -y` from `apt_update()`, gate it behind `--dist-upgrade`. Add `conf/versions.conf` for version pinning.
- Add Fedora/RHEL package backend — `dnf` equivalents of all essential/networking packages. Branch on distro family in the new package dispatch.
- Abstract `lib/security.sh` — add firewalld support alongside UFW. Auto-detect which firewall is available. Keep SSH hardening (same config, distro-agnostic).
- Abstract `lib/docker.sh` — Docker install script is distro-agnostic (official script). Docker Compose download is also arch-aware only. Minimal changes needed — verify curl URL works on Fedora.
- Add `lib/state.sh` — simple JSON state file at `/var/lib/devbox/state` tracking completed steps (packages, docker, harden, user). Add `--resume` flag to devbox.sh that skips already-completed steps.
- Add `lib/version-manager.sh` — install mise (single Rust binary) on `--with-mise` flag. Read tool versions from `conf/tools.conf` (e.g. `nodejs=20.0.0`, `golang=1.22.5`). Install them via `mise install`. Add `conf/tools.conf` config file.
- Update `conf/pkg.conf` → rename to `conf/apt-packages.conf` and add `conf/dnf-packages.conf` for distro-specific custom packages. Keep backward compat with old name.
- Add `--json` flag to `doctor` — output diagnostic report as JSON for CI consumption. Gate behind `--json` flag, default stays human-readable.
- Add `lib/hooks.sh` — source `conf/hooks/pre-*.sh` and `conf/hooks/post-*.sh` at appropriate lifecycle points. Empty by default, extensible without forking.

## Required Specs
<!-- SPECS_START -->
- Multi-distro detection via `lib/distro.sh` (Debian/RHEL/Arch/Alpine/SUSE families) setting `DISTRO_FAMILY`, `PKG_MGR`, `SVC_MGR`, `FIREWALL_TOOL`. Sourced early in `devbox.sh` before other libs.
- Unified package backends: `pkg_install`, `pkg_update`, `pkg_upgrade`, `pkg_installed` dispatched by distro family. `pkg_update_system()` runs only `pkg_update` by default; full `pkg_upgrade` gated behind `--dist-upgrade`.
- Canonical package mapping via `lib/pkgmap.sh` (`pkg_map`, `pkg_map_bulk`) so scripts specify distro-agnostic names.
- Firewalld support in `lib/security.sh` alongside UFW; firewall tool auto-detected from `FIREWALL_TOOL`.
- Docker install uses the distro-agnostic official script with distro-specific backends in `lib/docker.sh`; Compose v2 is arch-aware.
- `lib/state.sh` — JSON state file at `/var/lib/devbox/state` tracking completed steps (packages, docker, harden, user). `--resume` flag skips already-completed steps.
- `lib/version-manager.sh` — installs mise on `--with-mise`; reads `conf/tools.conf` (`nodejs=20.0.0`) and installs via `mise install`.
- Custom package config split: `conf/apt-packages.conf` (debian) + `conf/dnf-packages.conf` (rhel), with legacy `conf/pkg.conf` kept as backward-compatible fallback.
- `--json` flag on `doctor` emits a JSON diagnostic report (`report-<timestamp>.json`) alongside the human-readable log.
- `lib/hooks.sh` — sources executable `conf/hooks/<phase>/*.sh` at 8 lifecycle points (pre/post-install, docker, harden, user). Empty by default, extensible without forking.
- Exit codes extended: 18 = version manager setup failure, 19 = JSON report generation failure.
<!-- SPECS_END -->