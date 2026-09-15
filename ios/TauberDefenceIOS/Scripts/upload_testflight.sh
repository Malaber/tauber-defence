#!/usr/bin/env bash
set -euo pipefail

package_dir=$(cd "$(dirname "$0")/.." && pwd)
repo_dir=$(git -C "$package_dir" rev-parse --show-toplevel)
marketing_version=${1:-}
build_number=${2:-}

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
if [[ -n "$(git -C "$repo_dir" status --porcelain --untracked-files=all)" ]]; then
  echo "Refusing TestFlight upload from a dirty working tree." >&2
  exit 2
fi

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

require_current_origin_main

temp_base=${TMPDIR:-/tmp}
release_dir=$(mktemp -d "${temp_base%/}/tauber-defence-testflight.XXXXXX")
archive_path="$release_dir/TauberDefence-$marketing_version-$build_number.xcarchive"
export_path="$release_dir/export"
derived_data="$release_dir/DerivedData"
echo "Release evidence: $release_dir"

cd "$package_dir"
xcodegen generate

env PATH=/usr/bin:/bin:/usr/sbin:/sbin /usr/bin/xcodebuild \
  -project TauberDefenceApp.xcodeproj \
  -scheme TauberDefence \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  -derivedDataPath "$derived_data" \
  DEVELOPMENT_TEAM=VWKG94374J \
  PRODUCT_BUNDLE_IDENTIFIER=de.malaber.tauberdefence \
  MARKETING_VERSION="$marketing_version" \
  CURRENT_PROJECT_VERSION="$build_number" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive \
  2>&1 | tee "$release_dir/archive.log"

require_current_origin_main

env PATH=/usr/bin:/bin:/usr/sbin:/sbin /usr/bin/xcodebuild \
  -exportArchive \
  -archivePath "$archive_path" \
  -exportPath "$export_path" \
  -exportOptionsPlist "$package_dir/ExportOptions.TestFlight.plist" \
  -allowProvisioningUpdates \
  2>&1 | tee "$release_dir/export.log"

echo "TestFlight upload accepted. Archive: $archive_path"
