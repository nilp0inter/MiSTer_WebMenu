.PHONY: deploy deploy-with-log develop-all develop-web ssh

MISTER_SCRIPTS = /media/fat/Scripts
MISTER_USER = root
MISTER_HOST = 192.168.1.63

webmenu.sh: Makefile srv/MiSTer_WebMenu
	./packscript.sh > webmenu.sh

srv/MiSTer_WebMenu: Makefile srv/statik/statik.go srv/main.go srv/go.sum srv/go.mod
	cd srv && GOPATH="/tmp" GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -ldflags="-X main.Version=$$(git describe --tags --always --dirty)"

srv/statik/statik.go: Makefile web/build/index.html web/build/elm.js.min
	statik -f -src web/build/ -dest srv

web/build/elm.js: Makefile web/src/Main.elm
	cd web && elm make --optimize src/Main.elm --output build/elm.js

web/build/elm.js.min: Makefile web/build/elm.js
	cd web && uglifyjs build/elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output="build/elm.min.js"
	rm -f web/build/elm.js

deploy: webmenu.sh
	scp webmenu.sh ${MISTER_USER}@${MISTER_HOST}:${MISTER_SCRIPTS}
	ssh ${MISTER_USER}@${MISTER_HOST} '${MISTER_SCRIPTS}/webmenu.sh </dev/null >/dev/null 2>&1'

deploy-with-log: webmenu.sh
	scp webmenu.sh ${MISTER_USER}@${MISTER_HOST}:${MISTER_SCRIPTS}
	ssh ${MISTER_USER}@${MISTER_HOST} '${MISTER_SCRIPTS}/webmenu.sh'

develop-all:
	find . -type f -name '*.elm' -or -name '*.go' -or -name '*.html' -or -name '*.sh' | entr -cd make deploy-with-log

develop-web:
	cd web && elm-live src/Main.elm -h 0.0.0.0 --open -d build --start-page="index.html" -- --output="build/elm.min.js"

ssh:
	ssh ${MISTER_USER}@${MISTER_HOST}
