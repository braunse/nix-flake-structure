# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

name:
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  locked = lock.nodes.${name}.locked;
in
if locked.type == "github" then
  fetchTarball
  {
    url = "https://github.com/edolstra/flake-compat/archive/${locked.rev}.tar.gz";
    sha256 = locked.narHash;
  }
else
  throw "Don't know how to load input type ${locked.type} of input ${name}"
