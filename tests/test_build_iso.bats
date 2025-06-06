#!/usr/bin/env bats

@test "build_iso.sh exists" {
  [ -f scripts/build_iso.sh ]
}

@test "build_iso.sh is executable" {
  [ -x scripts/build_iso.sh ]
}

@test "docker_build_iso.sh exists" {
  [ -f scripts/docker_build_iso.sh ]
}

@test "docker_build_iso.sh is executable" {
  [ -x scripts/docker_build_iso.sh ]
}

