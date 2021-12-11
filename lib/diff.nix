# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ lib ? (import <nixpkgs> { }).lib
, ...
}:

with builtins;
with lib;

rec {
  diff = l: r:
    let
      lnames = genAttrs (attrNames l) (_n: true);
      rnames = genAttrs (attrNames r) (_n: true);
      names = attrNames (lnames // rnames);
      attrDiff = genAttrs names (n:
        if hasAttr n l && hasAttr n r then
          diff l.${n} r.${n}
        else if hasAttr n l then
          { missing = "right"; }
        else if hasAttr n r then
          { missing = "left"; }
        else
          { missing = "both"; }
      );
      pruned = filterAttrs (_n: value: value != null) attrDiff;
    in
    if l == r then
      null
    else if isAttrs l && isAttrs r then
      pruned
    else {
      left = l;
      right = r;
    };

  x1 = diff { a = 1; } { a = 2; };
  x2 = diff { a = { b = 1; d = 4; }; } { a = { b = 2; c = 3; d = 4; }; };
}
