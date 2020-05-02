webmenu.sh: Makefile srv/MiSTer_WebMenu
	nix-shell -p sharutils --run ./packscript.sh > webmenu.sh

srv/MiSTer_WebMenu: Makefile srv/statik/statik.go srv/main.go srv/go.sum srv/go.mod
	cd srv && nix-shell -p go git --run "GOPATH=/tmp GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build"

srv/statik/statik.go: Makefile web/build/index.html web/build/elm.js.min
	nix-shell -p statik --run "statik -f -src web/build/ -dest srv"

web/build/elm.js: Makefile web/src/Main.elm
	cd web && nix-shell -p elmPackages.elm --run "elm make --optimize src/Main.elm --output build/elm.js"

web/build/elm.js.min: Makefile web/build/elm.js
	cd web && nix-shell -p nodePackages.uglify-js --run "uglifyjs build/elm.js --compress 'pure_funcs=\"F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9\",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=build/elm.min.js"
	rm -f web/build/elm.js
