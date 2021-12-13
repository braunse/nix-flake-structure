# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, nixpkgs, part, ... }:

with builtins;
with nixpkgs.lib;
with import ./diff.nix { inherit (nixpkgs) lib; };

let
  pretty = generators.toPretty { multiline = true; };
in
{
  runUnitTests = { system, tests }:
    let
      inherit (self) lib;
      pkgs = nixpkgs.legacyPackages.${system};

      indent = s: "  " + replaceStrings [ "\n" ] [ "\n  " ] s;

      checkTests = tests:
        let
          results = concatMap runTests (toList tests);
          isFailed = results != [ ];

          outputResult = { name, expected, result }:
            ''
              Failed test ${name}:
              Expected:
              ${indent (pretty expected)}
              Actual:
              ${indent (pretty result)}
              Diff:
              ${indent (pretty (diff expected result))}

            '';

          summary =
            if length results == 0 then
              "All tests passed"
            else if length results == 1 then
              "One test failed"
            else
              "${toString (length results)} tests failed";

          output =
            concatMapStringsSep "\n" outputResult results
            + summary
          ;
        in
        pkgs.runCommand "test-results"
          {
            inherit output;
            passAsFile = [ "output" ];
            testNames = concatMap attrNames tests;
            passthru.tests = tests;
          } ''
          cat >&2 <$outputPath
          ${if isFailed then "exit 1" else "touch $out"}
        '';

      collectTests = attrs:
        listToAttrs (
          concatMap
            (name:
              let value = attrs.${name};
              in
              if match "test.*" name != null then
                if isList value then
                  imap (idx: test: { name = "${name}_${toString idx}"; value = test; }) value
                else
                  [{ inherit name value; }]
              else
                [ ]
            )
            (attrNames attrs)
        );
    in
    checkTests (map collectTests (toList tests));
}
