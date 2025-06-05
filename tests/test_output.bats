#!/usr/bin/env bats

@test "script outputs expected message" {
  run bash scripts/your_script.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Expected Output"* ]]
}