{
  description = "Collection of FORMOSA GPGPU cores";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    bluespec-cmake.url = "github:yuyuranium/bluespec-cmake";
  };

  outputs = { self, nixpkgs, flake-utils, bluespec-cmake }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        devTools = with pkgs; [
          pre-commit
          clang-tools
          reviewdog # needed in CI env
        ];

        nativeBuildInputs = with pkgs; [
          git
          cmake
          ninja
          bluespec
          verilator
        ] ++ [
          bluespec-cmake.packages.${system}.default
        ];

        buildInputs = with pkgs; [
          systemc
        ];
      in
      rec {
        devShells.default = pkgs.mkShell {
          name = "fauna";
          packages = devTools ++ nativeBuildInputs ++ buildInputs;
        };

        packages.fauna-docker-env = pkgs.dockerTools.buildNixShellImage {
          name = "fauna-docker-env";
          drv = devShells.default;
          uid = 0;
        };
      });
}
