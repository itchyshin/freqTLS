#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SRC="$ROOT/docs/dev-log/dashboard"
DEST="${PROFILETLS_DASHBOARD_DIR:-/tmp/profiletls-dashboard}"
PORT="${PROFILETLS_DASHBOARD_PORT:-8767}"
HOST="${PROFILETLS_DASHBOARD_HOST:-127.0.0.1}"

mkdir -p "$DEST"
cp "$SRC/index.html" "$SRC/status.json" "$SRC/sweep.json" "$SRC/version.txt" "$SRC/README.md" "$DEST/"

if command -v lsof >/dev/null 2>&1; then
  if lsof -iTCP:"$PORT" -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    echo "dashboard already listening at http://$HOST:$PORT/"
    exit 0
  fi
fi

if [ "${1:-}" = "--background" ]; then
  nohup python3 -m http.server "$PORT" --bind "$HOST" --directory "$DEST" > "$DEST/server.log" 2>&1 &
  echo "$!" > "$DEST/server.pid"
  echo "dashboard started at http://$HOST:$PORT/"
  echo "log: $DEST/server.log"
  exit 0
fi

exec python3 -m http.server "$PORT" --bind "$HOST" --directory "$DEST"
