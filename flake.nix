{
  description = "The website of Epilentio d.o.o.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    horizon-platform.url = "git+https://gitlab.horizon-haskell.net/package-sets/horizon-platform";
    horizon-platform.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
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
        let
          haskellPackages =
            inputs'.horizon-platform.legacyPackages.extend
              (self: _: {
                hakyll = self.callHackage "hakyll" "4.16.0.0" { };
                website-builder = self.callCabal2nix "website-builder" ./website-builder { };
              });
        in
        {
          treefmt = {
            projectRootFile = ".git/config";
            programs.nixpkgs-fmt.enable = true;
            programs.prettier.enable = true;
            programs.cabal-fmt.enable = true;
            settings.formatter = {
              "fourmolu" = {
                command = pkgs.haskellPackages.fourmolu;
                options = [
                  "--ghc-opt"
                  "-XImportQualifiedPost"
                  "--ghc-opt"
                  "-XTypeApplications"
                  "--mode"
                  "inplace"
                  "--check-idempotence"
                ];
                includes = [ "*.hs" ];
              };
            };
          };

          apps.gh-deploy = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "gh-deploy";
              runtimeInputs = [ ];
              text = ''
                cp -r -C ${self'.packages.dist}/* ./docs
              '';
            }}/bin/gh-deploy";
          };
          packages = {
            inherit (haskellPackages) website-builder;
            dist =
              let
                npmlock2nix = import inputs.npmlock2nix { inherit pkgs; };
              in
              pkgs.runCommand "dist" { LANG = "en_US.UTF-8"; nativeBuildInputs = [ pkgs.nodePackages.tailwindcss ]; } ''
                mkdir -p $out
                cp -r ${./src}/* .
                ${lib.getExe self'.packages.website-builder} build
                cp -r docs/* $out/
                export NODE_PATH=${npmlock2nix.v2.node_modules { src = ./.; nodejs = pkgs.nodejs; }}/node_modules
                tailwindcss -c ${./tailwind.config.js} -i $out/css/style.css -o $out/css/style.css
              '';
          };
          devShells.default = haskellPackages.shellFor {
            packages = p: [ p.website-builder ];
            withHoogle = false;
            nativeBuildInputs = [ ];
          };
        };
    };
}
