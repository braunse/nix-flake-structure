# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, nixpkgs, flake-utils, ... }:

with nixpkgs.lib;

let
  testModule = import ../tests {
    inherit self nixpkgs;
    part = "${self}/tests";
  };
in
genAttrs
  flake-utils.lib.defaultSystems
  (system:
    let pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      tests = self.lib.runUnitTests { inherit system; tests = testModule; };

      formatted = pkgs.runCommandNoCC "check-formatted" { buildInputs = [ pkgs.nixpkgs-fmt ]; } ''
        nixpkgs-fmt --check ${self}
        touch $out
      '';
    })
