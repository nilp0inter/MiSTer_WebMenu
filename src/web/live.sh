#!/usr/bin/env bash
nix-shell --run 'elm-live src/Main.elm -h 0.0.0.0 --open -d build --start-page=index.html -- --output=build/elm.min.js'
