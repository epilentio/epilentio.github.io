{ runCommand
, soupault
, tailwindcss_4
, pandoc
, nodejs
, npmlock2nix
, lib
,
}:
let
  NODE_PATH = "${
    npmlock2nix.v2.node_modules {
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./package.json
          ./package-lock.json
        ];
      };
      inherit nodejs;
    }
  }/node_modules";
in
runCommand "dist"
{
  LANG = "en_US.UTF-8";
  nativeBuildInputs = [
    soupault
    tailwindcss_4
    pandoc
  ];
  env = {
    inherit NODE_PATH;
  };
  passthru = {
    inherit NODE_PATH;
  };
  src =
    let fs = lib.fileset;
    in fs.toSource {
      root = ./.;
      fileset = fs.unions [
        ./site
        ./templates
        ./plugins
        ./soupault.toml
        ./Makefile
      ];
    };
}
  ''
    set -euo pipefail
    cp -r $src/* .

    make all

    mkdir -p $out
    cp -r build/* $out/
  ''
