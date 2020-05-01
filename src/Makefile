srv/MiSTer_WebMenu: Makefile srv/statik/statik.go srv/main.go srv/go.sum srv/go.mod
	cd srv && nix-shell -p go --run "GOPATH=/tmp GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build"

srv/statik/statik.go: Makefile web/build/index.html
	nix-shell -p statik --run "statik -f -src web/build/ -dest srv"

web/build/index.html: Makefile web/src/Main.elm
	cd web && nix-shell -p elmPackages.elm --run "elm make --optimize src/Main.elm --output build/index.html"
