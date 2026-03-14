#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEST_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
ROOT_DIR=$(cd "$TEST_DIR/.." && pwd)

host=${HOST:-0.0.0.0}
port=${PORT:-8000}

cd "$ROOT_DIR"
exec python3 -m http.server "$port" --bind "$host"
