with import (builtins.fetchTarball {
  name = "nixos-unstable-2018-09-12";
  url = "https://github.com/nixos/nixpkgs/archive/5272327b81ed355bbed5659b8d303cf2979b6953.tar.gz";
  sha256 = "0182ys095dfx02vl2a20j1hz92dx3mfgz2a6fhn31bqlp1wa8hlq";
}) {}; {
  webmenuEnv = stdenv.mkDerivation {
    name = "WebMenu-Env";
    buildInputs = [ sharutils
                    go
                    git
                    statik
                    elmPackages.elm
		    entr
                    nodePackages.uglify-js
                    nodePackages.elm-oracle
                    elmPackages.elm-format
                    elmPackages.elm-live
                  ];
  };
}
