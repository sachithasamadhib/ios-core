#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

SIGNER="$HOME/.local/bin/rcodesign"

if [[ ! -x "$SIGNER" ]]; then
    echo "rcodesign is missing. Install it before building."
    exit 1
fi

# Compile the app for an ARM64 iOS simulator.
xtool dev build --triple arm64-apple-ios-simulator

# Apply the local signature required to run it.
"$SIGNER" sign xtool/TapFrenzy.app

# Package the signed app for Appetize.
cd xtool
rm -f TapFrenzy-simulator.zip
zip -r TapFrenzy-simulator.zip TapFrenzy.app

echo "Ready: xtool/TapFrenzy-simulator.zip"