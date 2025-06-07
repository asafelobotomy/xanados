#!/usr/bin/env bats

@test "run_cmd executes" {
  run bash -c 'DRY_RUN=false; source xanados-iso/airootfs/etc/xanados/scripts/common.sh; run_cmd true'
  [ "$status" -eq 0 ]
}

@test "run_cmd dry-run" {
  run bash -c 'DRY_RUN=true; source xanados-iso/airootfs/etc/xanados/scripts/common.sh; run_cmd echo hi'
  [ "$status" -eq 0 ]
}
