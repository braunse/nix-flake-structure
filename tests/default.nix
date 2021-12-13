# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, nixpkgs, part, ... }:

with builtins;
with nixpkgs.lib;
with self.lib;

let
  inherit (nixpkgs) lib;

  mustBeDerivation = it:
    if isDerivation it then true
    else { not-a-derivation = it; };
in
{

  test-maybeCall = [
    {
      expr = maybeCall 2 1;
      expected = 2;
    }
    {
      expr = maybeCall (it: it + 1) 1;
      expected = 2;
    }
  ];

  testMergeAttrs = [
    {
      expr = mergeAttrs { a = 1; } { b = 2; };
      expected = { a = 1; b = 2; };
    }
    {
      expr = mergeAttrs
        { a = { b = 1; }; }
        { a = { c = 2; }; d = 1; };
      expected = { a = { b = 1; c = 2; }; d = 1; };
    }
    {
      expr =
        mergeAttrs'
          (_path: l: r: { __conflict = { inherit l r; }; })
          { a = { b = 1; }; }
          { a = { b = 2; }; };
      expected = { a = { b = { __conflict = { l = 1; r = 2; }; }; }; };
    }
  ];

  testMaybeCall = [
    {
      expr = maybeCall (i: i + 1) 1;
      expected = 2;
    }
    { expr = maybeCall 1 1; expected = 1; }
    {
      expr = maybeCall (import ./fn-file.nix) 1;
      expected = { arg = 1; plusOne = 2; };
    }
    {
      expr = maybeCall (import ./val-file.nix) 1;
      expected = { two = 2; };
    }
  ];

  testCallFile = [
    {
      # simplest possible callFile should basically be import
      expr = map isFunction (callFile { filepath = ./fn-file.nix; });
      expected = [ true ];
    }
    {
      expr = callFile { filepath = ./fn-file.nix; args = 1; };
      expected = [{ arg = 1; plusOne = 2; }];
    }
    {
      expr = callFile { filepath = ./val-file.nix; args = 1; };
      expected = [{ two = 2; }];
    }
    {
      expr = callFile { filepath = ./val-file.nix; };
      expected = [{ two = 2; }];
    }
    {
      expr = callFile { filepath = ./val-file.nix; systems = [ "a" "b" ]; transform = transforms.valueNoSystem; };
      expected = [{ two = 2; } { two = 2; }];
    }
    {
      expr = callFile { filepath = ./fn-file.nix; args = stringLength; systems = [ "a" "aa" ]; };
      expected = [{ a = { arg = 1; plusOne = 2; }; } { aa = { arg = 2; plusOne = 3; }; }];
    }
  ];

  testMergeDirectory = [
    {
      expr = mergeDirectory { path = "${part}/trivial-merge"; };
      expected = { a = 1; b = 2; };
    }
    {
      expr = mergeDirectory {
        path = "${part}/args-merge";
        args = "arg";
      };
      expected = {
        it = "arg";
        one = 1;
      };
    }
    {
      expr = mergeDirectory {
        path = "${part}/args-merge";
        args = sys: "args4${sys}";
        systems = [ "sys1" "sys2" ];
      };
      expected = {
        sys1 = {
          it = "args4sys1";
          one = 1;
        };
        sys2 = {
          it = "args4sys2";
          one = 1;
        };
      };
    }
  ];

  testImportDirectory = [
    {
      expr = importDirectory { path = "${part}/trivial-merge"; };
      expected = { a = { a = 1; }; b = { b = 2; }; };
    }
    {
      expr = importDirectory {
        path = "${part}/args-merge";
        args = "arg";
      };
      expected = { a = { it = "arg"; }; b = { one = 1; }; };
    }
    {
      expr = importDirectory {
        path = "${part}/args-merge";
        args = sys: "args4${sys}";
        systems = [ "sys1" "sys2" ];
      };
      expected = {
        sys1 = {
          a = { it = "args4sys1"; };
          b = { one = 1; };
        };
        sys2 = {
          a = { it = "args4sys2"; };
          b = { one = 1; };
        };
      };
    }
  ];

  testImportDirectoryPackages = [
    {
      expr = mustBeDerivation (
        (
          (importDirectoryPackages {
            path = ./pkg-merge-noargs;
            systems = [ "x86_64-linux" ];
            inherit nixpkgs;
          }
          ).x86_64-linux or { problem = "No x86_64-linux!"; }
        ).pkg or { problem = "No pkg!"; }
      );
      expected = true;
    }
  ];
}
