#!/usr/bin/env bash

SRC="srv/MiSTer_WebMenu"
HASH=$(sha256sum -b < "$SRC")
# BIN="/media/fat/WebMenu"
BIN="/tmp/WebMenu"

cat <<-EOF
	#!/usr/bin/env bash
	[ -x "$BIN" ] && sha256sum -c <(echo "$HASH") < "$BIN" > /dev/null 2>&1 && exec "$BIN"
	uudecode -o - "\$0" | xzcat -d -c > "$BIN" && chmod a+x "$BIN" && exec "$BIN"
	echo "Something went wrong, run with 'bash -x' and report the error" >&2 && exit 1
EOF
uuencode - < <(xzcat -z < "$SRC")
