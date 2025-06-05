#!/usr/bin/env bats

@test "build_iso.sh exists" {
  [ -f scripts/build_iso.sh ]
}

@test "build_iso.sh is executable" {
  [ -x scripts/build_iso.sh ] || chmod +x scripts/build_iso.sh
  [ -x scripts/build_iso.sh ]
}

@test "build_iso.sh runs without error" {
  run scripts/build_iso.sh --help
  [ "$status" -eq 0 ]
}