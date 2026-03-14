#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEST_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
ROOT_DIR=$(cd "$TEST_DIR/.." && pwd)
STATE_DIR="$TEST_DIR/state/confhome"

host_ip=${HOST_IP:-10.0.2.2}
port=${PORT:-8000}
confhome_url=${CONFHOME_URL:-http://$host_ip:$port}
confhome_cn_url=${CONFHOME_CN_URL:-$confhome_url}

mkdir -p "$STATE_DIR"

backup_once() {
    local src=$1
    local dst=$2
    if [ ! -f "$dst" ]; then
        cp "$src" "$dst"
    fi
}

backup_once "$ROOT_DIR/reinstall.sh" "$STATE_DIR/reinstall.sh.orig"
backup_once "$ROOT_DIR/trans.sh" "$STATE_DIR/trans.sh.orig"

sed -i \
    -e "s#^confhome=.*#confhome=$confhome_url#" \
    -e "s#^confhome_cn=.*#confhome_cn=$confhome_cn_url#" \
    "$ROOT_DIR/reinstall.sh"

sed -i \
    -e "s#^DEFAULT_CONFHOME=.*#DEFAULT_CONFHOME=$confhome_url#" \
    -e "s#^DEFAULT_CONFHOME_CN=.*#DEFAULT_CONFHOME_CN=$confhome_cn_url#" \
    "$ROOT_DIR/trans.sh"

echo "Patched confhome to $confhome_url"
echo "Patched confhome_cn to $confhome_cn_url"
