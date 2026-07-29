#!/bin/bash
# Example post-install hook: log installed packages
set -euo pipefail

echo "Post-install report — $(date)"
echo "Package manager: $PKG_MGR"
echo "Distribution: $DISTRO_NAME $DISTRO_VERSION"

exit 0
