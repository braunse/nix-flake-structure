{ runCommand }:

runCommand "command" { } ''
  touch $out
''
