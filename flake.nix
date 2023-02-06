{
  description = "marijan's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    horizon-platform.url = "git+https://gitlab.homotopic.tech/horizon/horizon-platform?rev=046c7305362aa0b3445539f9d78e648dd65167b7";
    horizon-platform.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs@{ self, flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        treefmt-nix.flakeModule
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          haskellPackages =
            with pkgs.haskell.lib.compose; inputs'.horizon-platform.legacyPackages.extend
              (self: _: {
                website = self.callCabal2nix "epilentio" ./. { };
              });
        in
        {
          treefmt = {
            projectRootFile = ".git/config";
            programs.nixpkgs-fmt.enable = true;
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
          packages.default = haskellPackages.website;
          devShells.default = haskellPackages.shellFor {
            packages = p: [ p.website ];
            withHoogle = false;
            nativeBuildInputs = [ config.treefmt.build.wrapper ];
          };
        };
    };
}
