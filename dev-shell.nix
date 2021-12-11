# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ nixpkgs ? null
, system ? builtins.currentSystem
, pkgs ? nixpkgs.legacyPackages.${system}
, ...
}:

with pkgs.lib;

pkgs.mkShell {
  buildInputs = with pkgs; [
    pkgs.nixFlakes
    pkgs.nixpkgs-fmt
    pkgs.reuse
  ];
}
