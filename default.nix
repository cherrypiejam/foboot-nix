{ pkgs ? import <nixpkgs> {}, seed ? null }:

let
  pinnedNixpkgs = import (builtins.fetchTarball {
    name = "nixos-unstable-24-11-2025-1-28";
    url = "https://github.com/nixos/nixpkgs/archive/852ff1d9e153d8875a83602e03fdef8a63f0ecf8.tar.gz";
    sha256 = "0f22vwxah4xhasfdi3lssk0kyng7xkjzygrz2d1wss3kpd523zb5";
  }) {};
in
pkgs.stdenv.mkDerivation {
  name = "foboot";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "im-tomu";
    repo = "foboot";
    rev = "dfa09fc84b0acb4d9a2d409f3a381274a1551e9f";
    hash = "sha256-VDpt38op7Jq8ZoEXmYoZjh3zez7J6ELKM0Z9W4qFLeU=";
    fetchSubmodules = true;
  };

  buildInputs = with pkgs; [
    python39
    nextpnr # Place and route tool for FPGAs
    icestorm
    yosys
    dfu-util
    git

    pinnedNixpkgs.pkgsCross.riscv64-embedded.buildPackages.gcc
  ];

  patchPhase = ''
    patch -p1 < ${./patches/foboot-0001-fix-builds.patch}

    pushd hw/deps/litex/
    patch -p1 < ${./patches/litex-0001-soc-cores-spi-fix-index-error.patch}
    popd
  '';

  buildPhase = ''
    pushd hw
  '' + (if seed != null then ''
    python3 ./foboot-bitstream.py --revision hacker --seed ${builtins.toString seed}
  '' else ''
    for seed in $(seq 4 100)
    do
      echo "Attempting Seed $seed"
      python3 ./foboot-bitstream.py --revision hacker --seed $seed 2>&1 |
         tee >(grep 'FAIL at 48.00 MHz') && continue
      echo "Working Seed is $seed"
      break
    done
  '') + ''
    popd
  '';

  installPhase = ''
    cp -r hw/build $out
  '';

}
