#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/PokemonHackStudio"
POKEEMERALD_DIR="$ROOT_DIR/pokeemerald"

run() {
  printf '\n==> %s\n' "$*"
  "$@"
}

run_quiet() {
  printf '\n==> %s\n' "$*"
  "$@" >/dev/null
}

run swift test --package-path "$PACKAGE_DIR"
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli references --json

if [[ -d "$POKEEMERALD_DIR" ]]; then
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli inspect "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli maps "$POKEEMERALD_DIR" --json
else
  printf '\n==> skipping pokeemerald CLI smoke; fixture not found at %s\n' "$POKEEMERALD_DIR"
fi

printf '\nValidation complete.\n'
