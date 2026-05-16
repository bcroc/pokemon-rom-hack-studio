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
DESTINATION="platform=macOS,arch=$(uname -m)"

usage() {
  echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|test|--check-tools]" >&2
}

check_tool() {
  local tool="$1"

  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "missing required tool: $tool" >&2
    return 1
  fi
}

check_tools() {
  local missing=0

  check_tool xcodegen || missing=1
  check_tool xcodebuild || missing=1
  check_tool /usr/bin/open || missing=1

  if [[ "$MODE" == "--debug" || "$MODE" == "debug" ]]; then
    check_tool lldb || missing=1
  fi

  return "$missing"
}

case "$MODE" in
  run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|test|--check-tools)
    ;;
  *)
    usage
    exit 2
    ;;
esac

check_tools

if [[ "$MODE" == "--check-tools" ]]; then
  echo "build tools available."
  exit 0
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$PROJECT_DIR"
xcodegen generate

build_action="build"
if [[ "$MODE" == "test" ]]; then
  build_action="test"
fi

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  -destination "$DESTINATION" \
  "$build_action"

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
  test)
    ;;
  *)
    usage
    exit 2
    ;;
esac
