#!/usr/bin/env bash
set -euo pipefail

# Resolve this script's directory (your userpatches repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CONF="$SCRIPT_DIR/global-config.conf"

if [[ ! -f "$GLOBAL_CONF" ]]; then
  echo "Missing global config at: $GLOBAL_CONF" >&2
  exit 1
fi

# Find compile.sh (works if called from build root or from userpatches dir)
if [[ -x "./compile.sh" ]]; then
  COMPILE="./compile.sh"
elif [[ -x "$SCRIPT_DIR/../compile.sh" ]]; then
  COMPILE="$SCRIPT_DIR/../compile.sh"
else
  echo "Could not find compile.sh. Run from Armbian build dir or keep this script in userpatches." >&2
  exit 1
fi

# Export all vars from global config so compile sees them
set -a
source "$GLOBAL_CONF"
set +a

# Optional: ensure build uses this userpatches directory
export USERPATCHES_PATH="$SCRIPT_DIR"

# Default to non-interactive kernel config unless explicitly overridden.
export KERNEL_CONFIGURE="${KERNEL_CONFIGURE:-no}"

# If first arg is a board shorthand and no matching config-<board>.conf exists,
# fall back to global-config.conf + BOARD=<board> so one global config can drive builds.
args=("$@")
if [[ ${#args[@]} -ge 2 ]]; then
  first_arg="${args[0]}"
  config_for_first="$SCRIPT_DIR/config-${first_arg}.conf"

  if [[ "$first_arg" != *=* && "$first_arg" != "build" && ! -f "$config_for_first" ]]; then
    board="$first_arg"
    args=("${args[@]:1}")

    has_board_arg="no"
    for a in "${args[@]}"; do
      if [[ "$a" == BOARD=* ]]; then
        has_board_arg="yes"
        break
      fi
    done

    if [[ "$has_board_arg" == "no" ]]; then
      args+=("BOARD=$board")
    fi

    echo "No config-$board.conf found; using global-config.conf with BOARD=$board" >&2
  fi
fi

# Pass through all args (interactive board picker still works)
exec "$COMPILE" "${args[@]}"