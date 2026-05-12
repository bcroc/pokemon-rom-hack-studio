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
mkdir -p "$PATCH_SMOKE_DIR/blocked-playtest/data/maps" "$PATCH_SMOKE_DIR/blocked-playtest/data/layouts" "$PATCH_SMOKE_DIR/blocked-playtest/include" "$PATCH_SMOKE_DIR/blocked-playtest/src" "$PATCH_SMOKE_DIR/blocked-playtest/graphics/pokenav"
printf 'TITLE := POKEMON EMER\nGAME_CODE := BPEE\n' > "$PATCH_SMOKE_DIR/blocked-playtest/Makefile"
printf '{"group_order":[]}\n' > "$PATCH_SMOKE_DIR/blocked-playtest/data/maps/map_groups.json"
printf '{"layouts_table_label":"gMapLayouts","layouts":[]}\n' > "$PATCH_SMOKE_DIR/blocked-playtest/data/layouts/layouts.json"
mkdir -p "$PATCH_SMOKE_DIR/graphics-pack/anim"
printf 'Credit: local validation fixture\n' > "$PATCH_SMOKE_DIR/graphics-pack/credits.txt"
printf 'id,behavior,layer\n' > "$PATCH_SMOKE_DIR/graphics-pack/attributes.csv"
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03PLTE\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00IEND\x00\x00\x00\x00' > "$PATCH_SMOKE_DIR/graphics-pack/top.png"
printf '// anim\n' > "$PATCH_SMOKE_DIR/graphics-pack/anim/water.c"
printf '\xff%.0s' {1..512} > "$PATCH_SMOKE_DIR/test.gba"
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli patch "$PATCH_SMOKE_DIR/cleanroom.aps" --json
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli patch-manifest "$PATCH_SMOKE_DIR/cleanroom.aps" --json
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli playtest "$PATCH_SMOKE_DIR/blocked-playtest" --launch --json
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli graphics-import-plan "$PATCH_SMOKE_DIR/blocked-playtest" "$PATCH_SMOKE_DIR/graphics-pack" --json
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli rom-graph "$PATCH_SMOKE_DIR/test.gba" --json
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli rom-inspect "$PATCH_SMOKE_DIR/test.gba" --json
run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli playtest-debug-plan "$PATCH_SMOKE_DIR/test.gba" --json

if [[ -d "$POKEEMERALD_DIR" ]]; then
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli inspect "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli validate "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli patch-manifest "$POKEEMERALD_DIR" "$PATCH_SMOKE_DIR/cleanroom.aps" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli resource-index "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli asset-index "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli pokemon-catalog "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli trainer-catalog "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli moves-graph "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli move-catalog "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli item-catalog "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli species-graph "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli maps "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli map-visual "$POKEEMERALD_DIR" MAP_MAUVILLE_CITY --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli graphics "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli graphics-import-plan "$POKEEMERALD_DIR" "$PATCH_SMOKE_DIR/graphics-pack" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli build "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli playtest "$POKEEMERALD_DIR" --headless --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli playtest-debug-plan "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli script-outline "$POKEEMERALD_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli script-readiness "$POKEEMERALD_DIR" --map MAP_MAUVILLE_CITY --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli toolchain-health "$POKEEMERALD_DIR" --json
else
  printf '\n==> skipping pokeemerald CLI smoke; fixture not found at %s\n' "$POKEEMERALD_DIR"
fi

if [[ -d "$POKEFIRERED_DIR" ]]; then
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli asset-index "$POKEFIRERED_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli moves-graph "$POKEFIRERED_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli move-catalog "$POKEFIRERED_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli item-catalog "$POKEFIRERED_DIR" --json
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
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli move-catalog "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli item-catalog "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli species-graph "$POKERUBY_REFERENCE_DIR" --json
  run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli toolchain-health "$POKERUBY_REFERENCE_DIR" --json
else
  printf '\n==> skipping pokeruby reference CLI smoke; fixture not found at %s\n' "$POKERUBY_REFERENCE_DIR"
fi

printf '\nValidation complete.\n'
