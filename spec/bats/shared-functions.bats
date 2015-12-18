#!/usr/bin/env bats

@test "Check that total is listed" {
  run ls -l
  [[ ${lines[0]} =~ "total" ]]
}
