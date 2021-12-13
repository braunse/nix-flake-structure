# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

inputs@{ self
, nixpkgs
, part
, ...
}:

with builtins;
with nixpkgs.lib;

let
  inherit (nixpkgs) lib;
  testlib = import ./testlib.nix inputs;
  prettify = generators.toPretty { };
in
rec {
  allAttrs = predicate: attrset:
    foldl' (sofar: name: sofar && predicate name attrset.${name}) true (attrNames attrset);

  anyAttrs = predicate: attrset:
    foldl' (sofar: name: sofar || predicate name attrset.${name}) false (attrNames attrset);

  filters = {
    all = { system, name, value }: true;
    compatible = { system, name, value }: !(value ? meta && value.meta ? platforms) or elem system value.meta.platforms;
  };

  transforms = rec {
    value = { system, name, value }:
      if system != null then
        { "${system}" = value; }
      else value;
    valueNoSystem = { value, ... }: value;
    attrsNamed = changeName: { system, name, value }:
      if system != null then
        { "${system}" = { "${changeName name}" = value; }; }
      else
        { "${changeName name}" = value; };
    attrsByFile = attrsNamed stripNixExtension;
    callPkgs = nixpkgs: { system, name, value }:
      assert system != null;
      { "${system}" = nixpkgs.legacyPackages.${system}.callPackage value { }; };
    callPkgsNames = changeName: nixpkgs: { system, name, value }:
      { "${system}"."${changeName name}" = nixpkgs.legacyPackages.${system}.callPackage value { }; };
    callPkgsByFile = callPkgsNames stripNixExtension;
  };

  maybeCall = fnorf: arg: if arg != null && lib.isFunction fnorf then fnorf arg else fnorf;

  mergeAttrs' = merge: ll: rr:
    let
      recurse = l: r: isAttrs l && isAttrs r && !(isDerivation l) && !(isDerivation r);

      go = path: l: r:
        if l == null then
          r
        else if r == null then
          l
        else if recurse l r then
          foldl'
            (set: name:
              let
                lhas = hasAttr name l;
                rhas = hasAttr name r;
                lval = l.${name};
                rval = r.${name};
              in
              if lhas && rhas then
                set // { ${name} = go (path ++ [ name ]) lval rval; }
              else if lhas then
                set // { ${name} = lval; }
              else if rhas then
                set // { ${name} = rval; }
              else
                set)
            { }
            (attrNames (l // r))
        else
          merge path l r;
    in
    go [ ] ll rr;

  mergeAttrs = mergeAttrs'
    (path: l: r: throw "Could not merge values in ${concatStringsSep "." path}: ${prettify l} and ${prettify r}");

  stripNixExtension = path:
    if hasSuffix ".nix" path
    then substring 0 (stringLength path - 4) path
    else path;

  callFile =
    { filepath
    , name ? builtins.baseNameOf filepath
    , args ? null
    , systems ? null
    , transform ? transforms.value
    , filter ? filters.all
    }:
    addErrorContext "calling file ${filepath}" (
      let
        fileContent = import filepath;
        systemArg = maybeCall args;
        filteredCall = system: args':
          let
            value = maybeCall fileContent args';
            include = filter { inherit system name value; };
          in
          if include then
            [ (transform { inherit system name value; }) ]
          else [ ];
      in
      if systems == null then
        filteredCall null args
      else
        concatMap (sys: filteredCall sys (systemArg sys)) systems
    );

  foldDirectory =
    { path
    , initial
    , combine
    , filter ? filters.all
    , transform ? transforms.value
    , args ? null
    , systems ? null
    }:
    let
      names = attrNames (readDir path);
      doFile = name: callFile {
        filepath = "${path}/${name}";
        inherit name args systems transform filter;
      };
    in
    foldl' combine initial
      (concatMap doFile names);

  callDirectory =
    { path
    , transform
    , filter ? filters.all
    , args ? null
    , systems ? null
    }:
    foldDirectory
      {
        inherit path args transform systems filter;
        initial = { };
        combine = mergeAttrs;
      };

  mergeDirectory =
    { path
    , filter ? filters.all
    , args ? null
    , systems ? null
    }:
    callDirectory
      {
        inherit path args systems filter;
        transform = transforms.value;
      };

  importDirectory =
    { path
    , filter ? filters.all
    , args ? null
    , systems ? null
    }:
    callDirectory {
      inherit path filter args systems;
      transform = transforms.attrsByFile;
    };

  mergeDirectoryPackages =
    { path
    , filter ? filters.compatible
    , args ? null
    , systems
    , nixpkgs ? <nixpkgs>
    }:
    callDirectory {
      inherit path args filter systems;
      transform = transforms.callPkgs;
    };

  importDirectoryPackages =
    { path
    , filter ? filters.compatible
    , args ? null
    , systems
    , nixpkgs ? <nixpkgs>
    }:
    callDirectory {
      inherit path args filter systems;
      transform = transforms.callPkgsByFile;
    };

  inherit (testlib) runUnitTests;

  # It feels silly to import flake-utils just for defaultSystems...
  defaultSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "i686-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  defaultLinuxSystems = [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
  ];

  eachSystem = genAttrs;

  eachDefaultSystem = eachSystem defaultSystems;

  eachDefaultLinuxSystem = eachSystem defaultLinuxSystems;
}
