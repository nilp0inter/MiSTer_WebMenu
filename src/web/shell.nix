{
  pkgs ? import <nixpkgs> {}
}:

with pkgs;
stdenv.mkDerivation {
  name = "WebMenu";
  buildInputs = [ elmPackages.elm elmPackages.elm-live ];
}
