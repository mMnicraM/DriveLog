#!/bin/zsh
set -e
cd "$(dirname "$0")"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Brakuje XcodeGen. Zainstaluj go samodzielnie (brew install xcodegen), a następnie uruchom skrypt ponownie."
  exit 1
fi
xcodegen generate
open DriveLog.xcodeproj
echo "Projekt DriveLog został wygenerowany i otwarty."
