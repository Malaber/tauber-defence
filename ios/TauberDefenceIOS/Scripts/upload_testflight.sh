#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd "$(dirname "$0")/.." && pwd)
repo_dir=$(git -C "$package_dir" rev-parse --show-toplevel)
marketing_version=${1:-}
build_number=${2:-}
readonly expected_team_id=VWKG94374J
readonly expected_bundle_id=de.malaber.tauber-defence
readonly expected_app_store_id=6812439777

if [[ ! "$marketing_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 <marketing-version> <build-number>" >&2
  echo "Example: $0 0.0.1 1" >&2
  exit 2
fi
if [[ ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "Build number must be a positive integer." >&2
  exit 2
fi
if [[ "$(git -C "$repo_dir" branch --show-current)" != "main" ]]; then
  echo "Refusing TestFlight upload outside main." >&2
  exit 2
fi
require_clean_worktree() {
  if [[ -n "$(git -C "$repo_dir" status --porcelain --untracked-files=all)" ]]; then
    echo "Refusing TestFlight upload from a dirty working tree." >&2
    exit 2
  fi
}

require_current_origin_main() {
  git -C "$repo_dir" fetch --no-tags origin main
  local local_commit
  local remote_commit
  local_commit=$(git -C "$repo_dir" rev-parse HEAD)
  remote_commit=$(git -C "$repo_dir" rev-parse origin/main)
  if [[ "$local_commit" != "$remote_commit" ]]; then
    echo "Refusing unpushed or stale TestFlight build: $local_commit != $remote_commit" >&2
    exit 2
  fi
}

assert_plist_value() {
  local plist_path=$1
  local key_path=$2
  local expected_value=$3
  local label=$4
  local actual_value

  if [[ ! -f "$plist_path" ]]; then
    echo "Missing $label plist: $plist_path" >&2
    exit 2
  fi
  if ! actual_value=$(/usr/libexec/PlistBuddy -c "Print $key_path" "$plist_path" 2>/dev/null); then
    echo "Missing $label value $key_path in $plist_path" >&2
    exit 2
  fi
  if [[ "$actual_value" != "$expected_value" ]]; then
    echo "Refusing TestFlight upload: $label is '$actual_value', expected '$expected_value'." >&2
    exit 2
  fi
}

validate_archive_identity() {
  local archive_info="$archive_path/Info.plist"
  local application_path
  local app_info

  assert_plist_value "$archive_info" :ApplicationProperties:CFBundleIdentifier \
    "$expected_bundle_id" "archive bundle identifier"
  assert_plist_value "$archive_info" :ApplicationProperties:CFBundleShortVersionString \
    "$marketing_version" "archive marketing version"
  assert_plist_value "$archive_info" :ApplicationProperties:CFBundleVersion \
    "$build_number" "archive build number"
  assert_plist_value "$archive_info" :ApplicationProperties:Team \
    "$expected_team_id" "archive signing team"

  application_path=$(/usr/libexec/PlistBuddy \
    -c 'Print :ApplicationProperties:ApplicationPath' "$archive_info")
  if [[ "$application_path" != Applications/*.app ]]; then
    echo "Unexpected archived application path: $application_path" >&2
    exit 2
  fi
  app_info="$archive_path/Products/$application_path/Info.plist"
  assert_plist_value "$app_info" :CFBundleIdentifier \
    "$expected_bundle_id" "application bundle identifier"
  assert_plist_value "$app_info" :CFBundleShortVersionString \
    "$marketing_version" "application marketing version"
  assert_plist_value "$app_info" :CFBundleVersion \
    "$build_number" "application build number"
}

require_clean_worktree
require_current_origin_main

temp_base=${TMPDIR:-/tmp}
release_dir=$(mktemp -d "${temp_base%/}/tauber-defence-testflight.XXXXXX")
archive_path="$release_dir/TauberDefence-$marketing_version-$build_number.xcarchive"
export_path="$release_dir/export"
derived_data="$release_dir/DerivedData"
echo "Release evidence: $release_dir"
echo "App Store target: $expected_app_store_id ($expected_bundle_id)"

cd "$package_dir"
xcodegen generate

env PATH=/usr/bin:/bin:/usr/sbin:/sbin /usr/bin/xcodebuild \
  -project TauberDefenceApp.xcodeproj \
  -scheme TauberDefence \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  -derivedDataPath "$derived_data" \
  DEVELOPMENT_TEAM="$expected_team_id" \
  PRODUCT_BUNDLE_IDENTIFIER="$expected_bundle_id" \
  MARKETING_VERSION="$marketing_version" \
  CURRENT_PROJECT_VERSION="$build_number" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive \
  2>&1 | tee "$release_dir/archive.log"

validate_archive_identity
require_clean_worktree
require_current_origin_main

env PATH=/usr/bin:/bin:/usr/sbin:/sbin /usr/bin/xcodebuild \
  -exportArchive \
  -archivePath "$archive_path" \
  -exportPath "$export_path" \
  -exportOptionsPlist "$package_dir/ExportOptions.TestFlight.plist" \
  -allowProvisioningUpdates \
  2>&1 | tee "$release_dir/export.log"

echo "TestFlight upload accepted. Archive: $archive_path"
