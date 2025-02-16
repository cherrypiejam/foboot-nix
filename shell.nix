{ pkgs ? import <nixpkgs> {} }:

let
  litexPkgs = import ./litex-pkgs.nix {
    inherit pkgs;
    skipLitexPkgChecks = true;
  };
  pinnedNixpkgs = import (builtins.fetchTarball {
    name = "nixos-unstable-24-11-2025-1-28";
    url = "https://github.com/nixos/nixpkgs/archive/852ff1d9e153d8875a83602e03fdef8a63f0ecf8.tar.gz";
    sha256 = "0f22vwxah4xhasfdi3lssk0kyng7xkjzygrz2d1wss3kpd523zb5";
  }) {};
in
pkgs.mkShell {

  name = "tomu-dev";

  buildInputs = with pkgs; [
    (python39.withPackages (p: with p; [
      # Deps are defined in submodules
    ]))

    nextpnr # Place and route tool for FPGAs
    icestorm
    yosys
    dfu-util
    git

  ] ++ (with pinnedNixpkgs; [
    pkgsCross.riscv64-embedded.buildPackages.gcc
  ]) ++ (with litexPkgs; [
    # litex
  ]);

}
