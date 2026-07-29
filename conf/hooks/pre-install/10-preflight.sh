#!/bin/bash
# Example pre-install hook: check disk space
set -euo pipefail

MIN_SPACE_MB=512
available=$(df / | awk 'NR==2 {print $4}')
available_mb=$((available / 1024))

if [[ $available_mb -lt $MIN_SPACE_MB ]]; then
    echo "Warning: Low disk space (${available_mb}MB available, ${MIN_SPACE_MB}MB minimum)"
fi

exit 0
