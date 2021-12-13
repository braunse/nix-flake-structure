# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, nixpkgs, ... }:

with nixpkgs.lib;

let
  testModule = import ../tests {
    inherit self nixpkgs;
    part = "${self}/tests";
  };
in
self.lib.eachDefaultSystem
  (system:
    let pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      tests = self.lib.runUnitTests { inherit system; tests = testModule; };

      formatted = pkgs.runCommandNoCC "check-formatted" { buildInputs = [ pkgs.nixpkgs-fmt ]; } ''
        nixpkgs-fmt --check ${self}
        touch $out
      '';

      reuse = pkgs.runCommandNoCC "reuse-check" { buildInputs = [ pkgs.reuse ]; } ''
        cd ${self}
        reuse lint
        touch $out
      '';
    })
