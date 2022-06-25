{
  description = "epilentio website";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-2111";
  };

  outputs = { self, flake-utils, nixpkgs, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        overlays = [ haskellNix.overlay (final: prev: {
          epilentio = final.haskell-nix.cabalProject {
            src = ./.;
            compiler-nix-name = "ghc8107";
            shell.tools = {
              cabal = {};
              hlint = {};
              haskell-language-server = {};
            };
          };
        })];
        pkgs = import nixpkgs { inherit system overlays; };
        flake = pkgs.epilentio.flake { };
      in flake // {
        devShells.default = flake.devShell;
        defaultPackage = flake.packages."epilentio:exe:site";
      }
    );
}
