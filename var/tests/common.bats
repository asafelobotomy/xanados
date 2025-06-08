#!/usr/bin/env bats

@test "run_cmd executes" {
  run bash -c 'LOG_DIR=/tmp/xanados-test; DRY_RUN=false; source xanados-iso/airootfs/etc/xanados/scripts/common.sh; run_cmd echo hi'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "hi" ]
}

@test "run_cmd dry-run" {
  run bash -c 'LOG_DIR=/tmp/xanados-test; DRY_RUN=true; source xanados-iso/airootfs/etc/xanados/scripts/common.sh; run_cmd echo hi'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "DRY RUN: echo hi" ]
}
