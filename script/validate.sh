#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/PokemonHackStudio"
GBA_FIXTURE_ROOT="${GBA_FIXTURE_ROOT:-$ROOT_DIR}"
POKEEMERALD_DIR="${POKEEMERALD_FIXTURE_ROOT:-${POKEEMERALD_DIR:-$GBA_FIXTURE_ROOT/pokeemerald}}"
POKEFIRERED_DIR="${POKEFIRERED_FIXTURE_ROOT:-${POKEFIRERED_DIR:-$GBA_FIXTURE_ROOT/pokefirered}}"
POKERUBY_REFERENCE_DIR="${POKERUBY_REFERENCE_FIXTURE_ROOT:-${POKERUBY_REFERENCE_DIR:-$ROOT_DIR/references/pokeruby}}"
REQUIRE_GBA_FIXTURES="${REQUIRE_GBA_FIXTURES:-0}"
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

requires_gba_fixtures() {
  case "$REQUIRE_GBA_FIXTURES" in
    1|true|TRUE|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

fixture_available() {
  local label="$1"
  local path="$2"
  local env_prefix="$3"

  if [[ -d "$path" ]]; then
    return 0
  fi

  if requires_gba_fixtures; then
    printf '\n==> missing required %s fixture at %s\n' "$label" "$path" >&2
    printf '    Set %s_FIXTURE_ROOT or GBA_FIXTURE_ROOT, or unset REQUIRE_GBA_FIXTURES.\n' "$env_prefix" >&2
    exit 1
  fi

  printf '\n==> skipping %s CLI smoke; fixture not found at %s\n' "$label" "$path"
  return 1
}

if requires_gba_fixtures; then
  fixture_available "pokeemerald" "$POKEEMERALD_DIR" "POKEEMERALD"
  fixture_available "pokefirered" "$POKEFIRERED_DIR" "POKEFIRERED"
  fixture_available "pokeruby reference" "$POKERUBY_REFERENCE_DIR" "POKERUBY_REFERENCE"
fi

run swift test --package-path "$PACKAGE_DIR"
run swift build --package-path "$PACKAGE_DIR" --product pokemonhack-cli
CLI_BIN="$(swift build --package-path "$PACKAGE_DIR" --show-bin-path)/pokemonhack-cli"

run_quiet "$CLI_BIN" references --json
run_quiet "$CLI_BIN" resources --json
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
run_quiet "$CLI_BIN" patch "$PATCH_SMOKE_DIR/cleanroom.aps" --json
run_quiet "$CLI_BIN" patch-manifest "$PATCH_SMOKE_DIR/cleanroom.aps" --json
run_quiet "$CLI_BIN" playtest "$PATCH_SMOKE_DIR/blocked-playtest" --launch --json
run_quiet "$CLI_BIN" graphics-import-plan "$PATCH_SMOKE_DIR/blocked-playtest" "$PATCH_SMOKE_DIR/graphics-pack" --json
run_quiet "$CLI_BIN" rom-graph "$PATCH_SMOKE_DIR/test.gba" --json
run_quiet "$CLI_BIN" rom-inspect "$PATCH_SMOKE_DIR/test.gba" --json
run_quiet "$CLI_BIN" playtest-debug-plan "$PATCH_SMOKE_DIR/test.gba" --json
run_quiet "$CLI_BIN" migration-coverage "$PATCH_SMOKE_DIR/test.gba" --json

if fixture_available "pokeemerald" "$POKEEMERALD_DIR" "POKEEMERALD"; then
  run_quiet "$CLI_BIN" inspect "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" validate "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" patch-manifest "$POKEEMERALD_DIR" "$PATCH_SMOKE_DIR/cleanroom.aps" --json
  run_quiet "$CLI_BIN" resource-index "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" asset-index "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" pokemon-catalog "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" trainer-catalog "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" moves-graph "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" move-catalog "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" item-catalog "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" species-graph "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" maps "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" map-visual "$POKEEMERALD_DIR" MAP_MAUVILLE_CITY --json
  run_quiet "$CLI_BIN" graphics "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" graphics-import-plan "$POKEEMERALD_DIR" "$PATCH_SMOKE_DIR/graphics-pack" --json
  run_quiet "$CLI_BIN" build "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" playtest "$POKEEMERALD_DIR" --headless --json
  run_quiet "$CLI_BIN" playtest-debug-plan "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" script-outline "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" script-readiness "$POKEEMERALD_DIR" --map MAP_MAUVILLE_CITY --json
  run_quiet "$CLI_BIN" toolchain-health "$POKEEMERALD_DIR" --json
  run_quiet "$CLI_BIN" migration-coverage "$POKEEMERALD_DIR" --json
fi

if fixture_available "pokefirered" "$POKEFIRERED_DIR" "POKEFIRERED"; then
  run_quiet "$CLI_BIN" asset-index "$POKEFIRERED_DIR" --json
  run_quiet "$CLI_BIN" moves-graph "$POKEFIRERED_DIR" --json
  run_quiet "$CLI_BIN" move-catalog "$POKEFIRERED_DIR" --json
  run_quiet "$CLI_BIN" item-catalog "$POKEFIRERED_DIR" --json
  run_quiet "$CLI_BIN" species-graph "$POKEFIRERED_DIR" --json
  run_quiet "$CLI_BIN" script-readiness "$POKEFIRERED_DIR" --script PalletTown_EventScript_TryReadySignLady --json
  run_quiet "$CLI_BIN" toolchain-health "$POKEFIRERED_DIR" --json
  run_quiet "$CLI_BIN" migration-coverage "$POKEFIRERED_DIR" --json
fi

if fixture_available "pokeruby reference" "$POKERUBY_REFERENCE_DIR" "POKERUBY_REFERENCE"; then
  run_quiet "$CLI_BIN" index "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" source-index "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" asset-index "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" moves-graph "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" move-catalog "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" item-catalog "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" species-graph "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" toolchain-health "$POKERUBY_REFERENCE_DIR" --json
  run_quiet "$CLI_BIN" migration-coverage "$POKERUBY_REFERENCE_DIR" --json
fi

printf '\nValidation complete.\n'
