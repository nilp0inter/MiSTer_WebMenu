MiSTer_WebMenu: srv/statik/statik.go srv/main.go srv/go.sum srv/go.mod
	cd srv && go build

srv/statik/statik.go: web/build/index.html
	nix-shell -p statik --run "statik -f -src web/build/ -dest srv"

web/build/index.html: web/src/Main.elm
	cd web && nix-shell -p elmPackages.elm --run "elm make --optimize src/Main.elm --output build/index.html"
