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

Scripts receive no arguments and run with the same environment as devbox.sh
(SCRIPT_DIR, DISTRO_NAME, etc. are available).
