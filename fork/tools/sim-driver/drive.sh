#!/usr/bin/env bash
# FORK: fork-only tool. Usage: fork/tools/sim-driver/drive.sh <steps.json> [simulator-udid]
# Runs the steps against the installed Hive Dev app; output in /tmp/sim-driver/out.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
steps="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
udid="${2:-${SIM_DRIVER_UDID:?pass a simulator udid or set SIM_DRIVER_UDID}}"
out="${SIM_DRIVER_OUT:-/tmp/sim-driver/out}"
rm -rf "$out"; mkdir -p "$out"
cd "$here"
[[ -d SimDriver.xcodeproj ]] || xcodegen generate --quiet
TEST_RUNNER_SIM_DRIVER_STEPS="$steps" TEST_RUNNER_SIM_DRIVER_OUT="$out" \
TEST_RUNNER_SIM_DRIVER_BUNDLE="${SIM_DRIVER_BUNDLE:-com.belesky.buzz.dev}" \
  xcodebuild test -project SimDriver.xcodeproj -scheme SimDriver \
  -destination "id=$udid" -derivedDataPath /tmp/sim-driver/dd \
  CODE_SIGNING_ALLOWED=NO -quiet > "$out/xcodebuild.log" 2>&1 || true
cat "$out/log.txt" 2>/dev/null || tail -20 "$out/xcodebuild.log"
