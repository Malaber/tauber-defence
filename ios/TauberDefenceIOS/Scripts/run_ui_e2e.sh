#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd "$(dirname "$0")/.." && pwd)
repo_dir=$(cd "$package_dir/../.." && pwd)
device_name=${1:-"iPhone 17 Pro"}
artifact_dir=${2:-"e2e-artifacts/ios-iphone"}
only_testing=${3:-"TauberDefenceUITests"}
attempts=${TAUBERDEFENCE_E2E_ATTEMPTS:-2}

if [[ "$artifact_dir" = /* ]]; then
  artifact_candidate="$artifact_dir"
else
  artifact_candidate="$repo_dir/$artifact_dir"
fi
artifact_path=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' \
  "$artifact_candidate")
case "$artifact_path" in
  "$repo_dir/e2e-artifacts/"*) ;;
  *)
    echo "Artifact directory must be a child of $repo_dir/e2e-artifacts" >&2
    exit 2
    ;;
esac

safe_device=$(printf '%s' "$device_name" | tr -cs '[:alnum:]' '-')
result_bundle="$artifact_path/TestResults.xcresult"
summary_path="$artifact_path/summary.md"
marketing_manifest="$artifact_path/marketing-screenshots.md"
simulator_inventory="$artifact_path/simulators.json"
device_lock="/tmp/tauber-defence-e2e.lock"
derived_data=""
lock_acquired=false

cleanup() {
  if [[ -n "${device_udid:-}" ]]; then
    xcrun simctl status_bar "$device_udid" clear >/dev/null 2>&1 || true
    xcrun simctl shutdown "$device_udid" >/dev/null 2>&1 || true
  fi
  if [[ -n "$derived_data" ]]; then
    rm -rf "$derived_data"
  fi
  if [[ "$lock_acquired" == "true" ]]; then
    rm -f "$device_lock"
  fi
}
trap cleanup EXIT

if ! shlock -p "$$" -f "$device_lock"; then
  echo "Another Tauber Defence E2E run is already active." >&2
  exit 2
fi
lock_acquired=true

rm -rf "$artifact_path"
mkdir -p "$artifact_path" "$package_dir/.clang-module-cache"
derived_data=$(mktemp -d "$package_dir/.derived-e2e-$safe_device.XXXXXX")

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$package_dir/.clang-module-cache}"
export TAUBERDEFENCE_UI_TEST_ARTIFACT_DIR="$artifact_path"
export TAUBERDEFENCE_UI_TEST_DEVICE_NAME="$device_name"

xcrun simctl list devices available -j > "$simulator_inventory"
device_udid=$(python3 "$package_dir/Scripts/resolve_simulator.py" \
  "$simulator_inventory" \
  "$device_name")

cd "$package_dir"
xcodegen generate

build_for_testing() {
  local log_path=$1
  set +e
  xcodebuild \
    -project TauberDefenceApp.xcodeproj \
    -scheme TauberDefence \
    -derivedDataPath "$derived_data" \
    -destination "platform=iOS Simulator,id=$device_udid" \
    -destination-timeout 120 \
    -parallel-testing-enabled NO \
    -maximum-parallel-testing-workers 1 \
    -only-testing:"$only_testing" \
    CODE_SIGNING_ALLOWED=NO \
    build-for-testing \
    2>&1 | tee "$log_path"
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

build_log="$artifact_path/build-for-testing.log"
build_status=0
build_for_testing "$build_log" || build_status=$?
if [[ "$build_status" -ne 0 ]]; then
  {
    echo "# Tauber Defence UI e2e"
    echo
    echo "- Device: \`$device_name\`"
    echo "- Result: build failed"
  } > "$summary_path"
  exit "$build_status"
fi

test_status=1
used_attempts=0
test_selections=("$only_testing")
for ((attempt = 1; attempt <= attempts; attempt++)); do
  used_attempts=$attempt
  rm -rf "$result_bundle"
  xcrun simctl shutdown "$device_udid" >/dev/null 2>&1 || true
  if [[ "${CI:-}" == "true" ]]; then
    xcrun simctl erase "$device_udid"
  fi
  xcrun simctl boot "$device_udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device_udid" -b
  xcrun simctl ui "$device_udid" appearance light
  xcrun simctl status_bar "$device_udid" override \
    --time 09:41 \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4 \
    >/dev/null 2>&1 || true
  xcrun simctl uninstall "$device_udid" de.malaber.tauberdefence >/dev/null 2>&1 || true

  test_log="$artifact_path/test-attempt-$attempt.log"
  only_testing_args=()
  for selection in "${test_selections[@]}"; do
    only_testing_args+=("-only-testing:$selection")
  done
  set +e
  xcodebuild \
    -project TauberDefenceApp.xcodeproj \
    -scheme TauberDefence \
    -derivedDataPath "$derived_data" \
    -destination "platform=iOS Simulator,id=$device_udid" \
    -destination-timeout 120 \
    -resultBundlePath "$result_bundle" \
    -parallel-testing-enabled NO \
    -maximum-parallel-testing-workers 1 \
    "${only_testing_args[@]}" \
    CODE_SIGNING_ALLOWED=NO \
    test-without-building \
    2>&1 | tee "$test_log"
  test_status=${PIPESTATUS[0]}
  set -e

  if [[ "$test_status" -eq 0 ]]; then
    break
  fi
  if [[ "$attempt" -lt "$attempts" ]]; then
    attempt_bundle="$artifact_path/TestResults-attempt-$attempt.xcresult"
    if [[ -d "$result_bundle" ]]; then
      mv "$result_bundle" "$attempt_bundle"
    fi
    failed_tests=()
    failure_summary="$artifact_path/test-attempt-$attempt-summary.json"
    if [[ -d "$attempt_bundle" ]] && \
      xcrun xcresulttool get test-results summary \
        --path "$attempt_bundle" > "$failure_summary" 2>/dev/null; then
      while IFS= read -r failed_test; do
        if [[ -n "$failed_test" ]]; then
          failed_tests+=("$failed_test")
        fi
      done < <(
        python3 - "$failure_summary" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    summary = json.load(source)

selections = set()
for failure in summary.get("testFailures", []):
    identifier = failure.get("testIdentifierString", "").removesuffix("()")
    target = failure.get("targetName", "")
    if target and "/" in identifier:
        selections.add(f"{target}/{identifier}")

for selection in sorted(selections):
    print(selection)
PY
      )
    fi
    if [[ ${#failed_tests[@]} -eq 0 ]]; then
      while IFS= read -r failed_test; do
        if [[ -n "$failed_test" ]]; then
          failed_tests+=("$failed_test")
        fi
      done < <(
        sed -nE \
          "s/^Test Case '-\[([^.]*)\.([^ ]+) ([^]]+)\]' failed.*/\1\/\2\/\3/p" \
          "$test_log"
      )
    fi
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
      test_selections=("${failed_tests[@]}")
      echo "Retrying failed UI tests ($attempt/$attempts): ${test_selections[*]}"
    else
      test_selections=("$only_testing")
      echo "Retrying full isolated UI test run ($attempt/$attempts)..."
    fi
    app_bundle="$derived_data/Build/Products/Debug-iphonesimulator/Tauber Defence.app"
    if [[ ! -d "$app_bundle" ]]; then
      echo "Built app disappeared; rebuilding before retry $((attempt + 1))."
      rebuild_status=0
      build_for_testing "$artifact_path/rebuild-for-testing-attempt-$((attempt + 1)).log" \
        || rebuild_status=$?
      if [[ "$rebuild_status" -ne 0 ]]; then
        test_status=$rebuild_status
        break
      fi
    fi
  fi
done

result="passed"
if [[ "$test_status" -ne 0 ]]; then
  result="failed"
fi

extract_marketing_screenshots() {
  local bundle=$1
  local attachment_dir
  attachment_dir=$(mktemp -d "$artifact_path/.xcresult-attachments.XXXXXX")
  if xcrun xcresulttool export attachments \
    --path "$bundle" \
    --output-path "$attachment_dir" \
    > "$attachment_dir/export.log" 2>&1; then
    python3 - "$attachment_dir" "$artifact_path" <<'PY'
import json
import re
import shutil
import sys
from pathlib import Path

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
for test in manifest:
    for attachment in test.get("attachments", []):
        suggested = attachment.get("suggestedHumanReadableName", "")
        match = re.match(r"(marketing-[0-9]{2}-[a-z0-9-]+)", suggested)
        exported = source / attachment.get("exportedFileName", "")
        if match and exported.suffix.lower() == ".png" and exported.is_file():
            shutil.copy2(exported, destination / f"{match.group(1)}.png")
PY
  else
    echo "Warning: could not export attachments from $(basename "$bundle")." >&2
  fi
  rm -rf "$attachment_dir"
}

for bundle in "$artifact_path"/TestResults*.xcresult; do
  if [[ -d "$bundle" ]]; then
    extract_marketing_screenshots "$bundle"
  fi
done

screenshot_count=$(find "$artifact_path" -maxdepth 1 -type f -name '*.png' -print | wc -l | tr -d ' ')
{
  echo "# App Store marketing screenshots"
  echo
  echo "Generated by deterministic XCUITest on \`$device_name\`."
  echo
  for screenshot in "$artifact_path"/marketing-*.png; do
    if [[ ! -f "$screenshot" ]]; then
      continue
    fi
    dimensions=$(sips -g pixelWidth -g pixelHeight "$screenshot" 2>/dev/null \
      | awk '/pixelWidth:/{width=$2} /pixelHeight:/{height=$2} END{print width "x" height}')
    echo "- \`$(basename "$screenshot")\` — $dimensions"
  done
} > "$marketing_manifest"
{
  echo "# Tauber Defence UI e2e"
  echo
  echo "- Device: \`$device_name\`"
  echo "- Simulator UDID: \`$device_udid\`"
  echo "- Selection: \`$only_testing\`"
  echo "- Result: $result"
  echo "- Attempts: $used_attempts"
  echo "- Screenshots: $screenshot_count"
  echo "- Marketing manifest: \`marketing-screenshots.md\`"
  echo "- Result bundle: \`TestResults.xcresult\`"
} > "$summary_path"

exit "$test_status"
