# SPDX-FileCopyrightText: 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

import
  (import ./flake-input.nix "flake-compat")
{
  src = ./.;
}
