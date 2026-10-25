#!/bin/bash
# Builds PreviewTranslate.app from the Swift package.
#
# The bundle is signed with a real Developer ID / Apple Development identity when one
# is available, because macOS ties the Accessibility grant to the signature. An
# ad-hoc signature gets a new fingerprint on every rebuild, which would make the
# permission prompt reappear each time.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PreviewTranslate"
BUILD_DIR="$ROOT/.build/out"
APP="$BUILD_DIR/$APP_NAME.app"
BUNDLE_ID="dev.nixos.previewtranslate"

cd "$ROOT"
swift build -c release --product "$APP_NAME"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$(swift build -c release --product "$APP_NAME" --show-bin-path)/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

# `security` exits 0 with "0 valid identities found", and `grep` then exits 1, so the
# pipeline must tolerate failure or `set -o pipefail` aborts the build before packaging.
SIGNING_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -E 'Developer ID Application|Apple Development' | sed -E 's/.*"(.*)"/\1/' || true)"

if [ -n "$SIGNING_IDENTITY" ]; then
  codesign --force --sign "$SIGNING_IDENTITY" --identifier "$BUNDLE_ID" "$APP"
  echo "Signed with: $SIGNING_IDENTITY"
else
  codesign --force --sign - --identifier "$BUNDLE_ID" "$APP"
  echo "Signed ad-hoc (Accessibility permission must be re-granted after each rebuild)"
fi

echo "Built $APP"
