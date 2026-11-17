#!/usr/bin/env bash
# FORK: fork-only file (see FORK.md). Builds the Hive iOS app and uploads it to
# App Store Connect (app 6835712117), from which TestFlight distributes it.
#
#   fork/release/testflight.sh            # archive, sign and upload
#   fork/release/testflight.sh --no-upload # archive and export an .ipa only
#
# Version: HIVE_VERSION (default below). Build number: HIVE_BUILD_NUMBER, else
# the commit count of HEAD, which only grows on main because upstream is merged,
# never rebased. App Store Connect refuses a build number it has already seen.
#
# Signing: the archive uses the shared Apple Development identity through the
# personal Xcode template's signing helper; the export re-signs with the
# cloud-managed Apple Distribution certificate of the Apple account signed in
# to Xcode on this Mac, and uploads with that account. No App Store Connect API
# key is needed.
set -euo pipefail

HIVE_VERSION="${HIVE_VERSION:-0.1.0}"
SIGN="${XCODE_SIGN:-$HOME/.settings/templates/template-xcode-personal/scripts/xcode-sign}"
TEAM_ID="CNPCA4RAWZ"

destination="upload"
if [[ "${1:-}" == "--no-upload" ]]; then destination="export"; fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is dirty; commit first so the build matches a commit." >&2
  exit 1
fi
build_number="${HIVE_BUILD_NUMBER:-$(git rev-list --count HEAD)}"
out="$repo_root/mobile/build/hive-testflight/${HIVE_VERSION}-${build_number}"
rm -rf "$out"
mkdir -p "$out"

echo "Hive ${HIVE_VERSION} (${build_number}) from $(git rev-parse --short HEAD) -> ${destination}"

# shellcheck disable=SC1091
. bin/activate-hermit >/dev/null
(cd mobile && flutter build ios --config-only --release \
  --build-name "$HIVE_VERSION" --build-number "$build_number")

(cd mobile/ios && "$SIGN" run -- xcodebuild archive \
  -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$out/Hive.xcarchive" -allowProvisioningUpdates) > "$out/archive.log" 2>&1 \
  || { tail -40 "$out/archive.log"; exit 1; }

cat > "$out/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>${destination}</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF

"$SIGN" run -- xcodebuild -exportArchive -archivePath "$out/Hive.xcarchive" \
  -exportPath "$out/export" -exportOptionsPlist "$out/ExportOptions.plist" \
  -allowProvisioningUpdates > "$out/export.log" 2>&1 \
  || { tail -40 "$out/export.log"; exit 1; }

if [[ "$destination" == "upload" ]]; then
  grep -q 'Uploading .* is complete' "$out/export.log" \
    || { echo "Export succeeded but no upload completion was logged; see $out/export.log" >&2; exit 1; }
  echo "Uploaded Hive ${HIVE_VERSION} (${build_number}). App Store Connect processes it before TestFlight offers it."
else
  echo "Exported $(ls "$out"/export/*.ipa)"
fi
