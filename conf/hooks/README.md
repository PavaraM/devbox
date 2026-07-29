DevBox Hook System
===================

Hooks allow you to run custom scripts at specific lifecycle points during
devbox install. Each lifecycle phase is a subdirectory containing
executable `.sh` scripts run in lexicographic order.

Lifecycle Phases:
  pre-install   Before package installation
  post-install  After package installation
  pre-docker    Before Docker setup
  post-docker   After Docker setup
  pre-harden    Before SSH/firewall hardening
  post-harden   After SSH/firewall hardening
  pre-user      Before deploy user creation
  post-user     After deploy user creation

Naming convention: NN-name.sh (e.g., 10-preflight.sh, 20-notify.sh)

Scripts receive no arguments and inherit the following exported environment
variables:

  DISTRO_ID       Distribution ID (e.g., ubuntu, fedora, alpine)
  DISTRO_NAME     Pretty name (e.g., Ubuntu 24.04 LTS)
  DISTRO_VERSION  Version string (e.g., 24.04)
  DISTRO_CODENAME  Distribution codename (e.g., noble, may vary by distro)
  DISTRO_FAMILY   Normalized family: debian, rhel, arch, alpine, suse
  PKG_MGR         Detected package manager (apt, dnf, pacman, apk, zypper)
  SVC_MGR         Service manager (systemctl, rc-service)
  FIREWALL_TOOL   Firewall tool (ufw, firewalld-cmd, nft, iptables)
  SCRIPT_DIR      Absolute path to the DevBox installation directory
  DRY_RUN         Set to "true" if --dry-run was passed (empty otherwise)
