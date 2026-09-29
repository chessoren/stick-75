#!/bin/sh
# Generates Stick.xcodeproj from Project.json. No keys needed: purchases use the RevenueCat Test Store in Debug,
# and voice and AI calls go through Stick's server relay.
set -e
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing XcodeGen with Homebrew…"
    brew install xcodegen
  else
    echo "XcodeGen is required: https://github.com/yonaskolb/XcodeGen#installing" >&2
    exit 1
  fi
fi

xcodegen generate --spec Project.json
echo "Done. Open Stick.xcodeproj, pick an iPhone simulator and run the Stick scheme."
