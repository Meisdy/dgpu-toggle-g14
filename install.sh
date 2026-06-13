#!/usr/bin/env bash
# Installs the dgpu command to /usr/local/bin. Run from the repo root.
set -euo pipefail

src="$(dirname "$(readlink -f "$0")")/dgpu"

if [[ ! -f "$src" ]]; then
    echo "install.sh: dgpu not found next to this script" >&2
    exit 1
fi

sudo install -m 755 "$src" /usr/local/bin/dgpu
echo "Installed: $(command -v dgpu)"
