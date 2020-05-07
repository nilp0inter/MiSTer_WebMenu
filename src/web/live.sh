#!/usr/bin/env bash
elm-live src/Main.elm -h 0.0.0.0 --open -d build --start-page=index.html -- --output=build/elm.min.js
