#!/usr/bin/env bats

@test "basic arithmetic" {
  run expr 1 + 1
  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
}

@test "string test" {
  str="xanados"
  [[ "${str^^}" == "XANADOS" ]]
}