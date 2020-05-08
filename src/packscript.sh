#!/usr/bin/env bash

SRC="srv/MiSTer_WebMenu"
HASH=$(sha256sum -b < "$SRC")
BIN="/media/fat/WebMenu"

cat <<-EOF
	#!/usr/bin/env bash
	killall WebMenu 2> /dev/null
	[ -x "$BIN" ] && sha256sum -c <(echo "$HASH") < "$BIN" > /dev/null 2>&1 && ("$BIN" &) && sleep 1 && exit 0
	uudecode -o - "\$0" | xzcat -d -c > "$BIN" && chmod a+x "$BIN" && ("$BIN" &) && sleep 1 && exit 0
	echo "Something went wrong, run with 'bash -x' and report the error" >&2 && exit 1
EOF
uuencode - < <(xzcat -z < "$SRC")
