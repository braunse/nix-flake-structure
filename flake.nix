# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , ...
    }@inputs:
    {
      lib = import ./lib (inputs // { part = "${self}/lib"; });
      checks = import ./checks (inputs // { part = "${self}/checks"; });
      devShell = self.lib.eachDefaultSystem (system: import ./dev-shell.nix { inherit nixpkgs system; });
    };
}
