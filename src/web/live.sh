#!/usr/bin/env bash
nix-shell --run 'elm-live src/Main.elm --open -d build --start-page=index.html -- --output=build/elm.min.js'
