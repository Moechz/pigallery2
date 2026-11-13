#!/bin/sh
# ===========================================================================
# PiGallery2 entrypoint for a non-root container (TOS 7 requirement).
#
# The upstream image listens on port 80 (which an unprivileged container cannot
# bind) and its built-in defaults point Media/Database at /app/demo - a path
# that does not exist in the runtime image. This wrapper seeds a minimal config
# that keeps everything inside the mounted data folder and moves the server to
# port 3000, then starts the Node backend like the image's own entrypoint.
# ===========================================================================
set -e
set -u

DATA=/app/data
CONF="$DATA/config/config.json"

mkdir -p "$DATA/config" "$DATA/images" "$DATA/tmp" "$DATA/db" "$DATA/extensions" 2>/dev/null || true

if [ ! -s "$CONF" ]; then
  cat > "$CONF" <<'JSON'
{"Server":{"port":3000,"host":"0.0.0.0"},
 "Database":{"type":"sqlite","dbFolder":"/app/data/db"},
 "Media":{"folder":"/app/data/images","tempFolder":"/app/data/tmp"},
 "Extensions":{"folder":"/app/data/extensions"}}
JSON
  echo "pigallery2: seeded $CONF (port 3000, data in /app/data)"
fi

exec node --expose-gc ./src/backend/index --config-path="$CONF"
