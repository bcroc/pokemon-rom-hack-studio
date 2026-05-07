#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/PokemonHackStudio"
POKEEMERALD_DIR="$ROOT_DIR/pokeemerald"
POKEFIRERED_DIR="$ROOT_DIR/pokefirered"
POKERUBY_REFERENCE_DIR="$ROOT_DIR/references/pokeruby"
PATCH_SMOKE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pokemonhack-patch-manifest.XXXXXX")"
trap 'rm -rf "$PATCH_SMOKE_DIR"' EXIT

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
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli resources --json
printf 'APS1' > "$PATCH_SMOKE_DIR/cleanroom.aps"
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli patch-manifest "$PATCH_SMOKE_DIR/cleanroom.aps" --json

if [[ -d "$POKEEMERALD_DIR" ]]; then
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli inspect "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli patch-manifest "$POKEEMERALD_DIR" "$PATCH_SMOKE_DIR/cleanroom.aps" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli asset-index "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli moves-graph "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli species-graph "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli maps "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli script-readiness "$POKEEMERALD_DIR" --map MAP_MAUVILLE_CITY --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli toolchain-health "$POKEEMERALD_DIR" --json
else
  printf '\n==> skipping pokeemerald CLI smoke; fixture not found at %s\n' "$POKEEMERALD_DIR"
fi

if [[ -d "$POKEFIRERED_DIR" ]]; then
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli asset-index "$POKEFIRERED_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli moves-graph "$POKEFIRERED_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli species-graph "$POKEFIRERED_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli script-readiness "$POKEFIRERED_DIR" --script PalletTown_EventScript_TryReadySignLady --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli toolchain-health "$POKEFIRERED_DIR" --json
else
  printf '\n==> skipping pokefirered toolchain-health smoke; fixture not found at %s\n' "$POKEFIRERED_DIR"
fi

if [[ -d "$POKERUBY_REFERENCE_DIR" ]]; then
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli index "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli source-index "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli asset-index "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli moves-graph "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli species-graph "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli toolchain-health "$POKERUBY_REFERENCE_DIR" --json
else
  printf '\n==> skipping pokeruby reference CLI smoke; fixture not found at %s\n' "$POKERUBY_REFERENCE_DIR"
fi

printf '\nValidation complete.\n'
