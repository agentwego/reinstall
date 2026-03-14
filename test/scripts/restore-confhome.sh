#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEST_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
ROOT_DIR=$(cd "$TEST_DIR/.." && pwd)
STATE_DIR="$TEST_DIR/state/confhome"

restore_one() {
    local backup=$1
    local target=$2
    if [ -f "$backup" ]; then
        cp "$backup" "$target"
    fi
}

restore_one "$STATE_DIR/reinstall.sh.orig" "$ROOT_DIR/reinstall.sh"
restore_one "$STATE_DIR/trans.sh.orig" "$ROOT_DIR/trans.sh"

echo "Restored confhome constants from $STATE_DIR"
