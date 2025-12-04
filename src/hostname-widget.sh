#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_hostname 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

# macOS compatible hostname detection
if command -v hostnamectl &>/dev/null; then
  hostname=$(hostnamectl hostname 2>/dev/null || hostname -s)
else
  hostname=$(hostname -s)
fi

ACCENT_COLOR="${THEME[black]}"

echo "#[nodim,fg=$ACCENT_COLOR]@${hostname}"
