{
  description = "The website of Epilentio d.o.o.";

  nixConfig = {
    extra-substituters = [
      "https://horizon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "horizon.cachix.org-1:MeEEDRhRZTgv/FFGCv3479/dmJDfJ82G6kfUDxMSAw0="
    ];
    allow-import-from-derivation = true;
  };

  inputs = {
    website-builder.url = "git+https://git.sr.ht/~marijan/website-builder";
    nixpkgs.follows = "website-builder/nixpkgs";
    flake-parts.follows = "website-builder/flake-parts";
    treefmt-nix.follows = "website-builder/treefmt-nix";
    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;
  };

  outputs = inputs@{ self, flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        treefmt-nix.flakeModule
      ];
      perSystem = { config, self', inputs', pkgs, system, lib, ... }:
        {
          treefmt = {
            projectRootFile = ".git/config";
            programs.nixpkgs-fmt.enable = true;
            #settings.formatter = {
            #  "htmlq" = {
            #    command = pkgs.htmlq;
            #    options = [
            #      "--pretty"
            #    ];
            #    includes = [ "*.html" ];
            #  };
            #};
          };
          packages = {
            dist =
              let
                npmlock2nix = import inputs.npmlock2nix { inherit pkgs; };
              in
              pkgs.runCommand "dist" { LANG = "en_US.UTF-8"; nativeBuildInputs = [ pkgs.nodePackages.tailwindcss ]; } ''
                mkdir -p $out
                cp -r ${./src}/* .
                ${lib.getExe inputs'.website-builder.packages.default} build
                cp -r docs/* $out/
                export NODE_PATH=${npmlock2nix.v2.node_modules { src = ./.; nodejs = pkgs.nodejs; }}/node_modules
                tailwindcss -c ${./tailwind.config.js} -i $out/css/style.css -o $out/css/style.css
              '';
          };
        };
    };
}
