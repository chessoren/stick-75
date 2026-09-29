#!/bin/sh
# Generates Stick.xcodeproj from Project.json and creates the local secrets file.
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

if [ ! -f App/Resources/Secrets.local.plist ]; then
  cp docs/Secrets.example.plist App/Resources/Secrets.local.plist
  echo "Created App/Resources/Secrets.local.plist (all keys empty: the app runs in offline demo mode)."
fi

xcodegen generate --spec Project.json
echo "Done. Open Stick.xcodeproj, pick an iPhone simulator and run the Stick scheme."
