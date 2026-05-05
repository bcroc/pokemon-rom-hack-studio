#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="PokemonHackStudio"
BUNDLE_ID="com.pokemonhack.PokemonHackStudio"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/PokemonHackStudio"
PROJECT_FILE="$PROJECT_DIR/PokemonHackStudio.xcodeproj"
BUILD_DIR="$ROOT_DIR/DerivedData/PokemonHackStudio"
CONFIGURATION="Debug"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$PROJECT_DIR"
xcodegen generate

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  build

APP_BUNDLE="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
