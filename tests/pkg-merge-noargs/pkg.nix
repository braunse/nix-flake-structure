# SPDX-FileCopyrightText: 2021 2021 Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ runCommand }:

runCommand "command" { } ''
  touch $out
''
