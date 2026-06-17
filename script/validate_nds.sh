#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/PokemonHackStudio"
REFERENCE_ROOT="${REFERENCE_REPOS_ROOT:-/Users/bryan/projects/reference-repos/repos}"
REQUIRE_REFERENCES="${REQUIRE_NDS_REFERENCES:-0}"

run() {
  printf '\n==> %s\n' "$*"
  "$@"
}

run_quiet() {
  printf '\n==> %s\n' "$*"
  "$@" >/dev/null
}

run swift test --package-path "$PACKAGE_DIR" --filter 'NDSDataCatalogTests|NDSDecompSourceTreeIndexTests|NDSROMInspectorTests|ToolchainHealthMatrixTests|PokemonHackCLITests/testNDSDataCatalogCommandEmitsReadOnlyJSON|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackReadinessJSON|PokemonHackCLITests/testNDSDataCatalogCommandEmitsBlack2White2InventoryReadinessJSON|PokemonHackCLITests/testToolchainHealthCommandSurfacesNDSPreviewRows|PokemonHackCLITests/testMigrationCoverageCommandEmitsSourceFirstAndBlockedJSON|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyPlatinumMoveJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyPlatinumFieldEventJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyPlatinumEncounterJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverEncounterJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverZoneEventJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlEncounterJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlFieldEventJSONFields|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlItemJSONFields'

missing_references=0
for repo_id in pret__pokeplatinum pret__pokediamond pret__pokeheartgold pret__pmd-sky; do
  repo_path="$REFERENCE_ROOT/$repo_id"
  if [[ -d "$repo_path" ]]; then
    run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli index "$repo_path" --json
    run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli resource-index "$repo_path" --json
    run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli nds-data-catalog "$repo_path" --json
    run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli toolchain-health "$repo_path" --json
    run_quiet swift run --package-path "$PACKAGE_DIR" pokemonhack-cli migration-coverage "$repo_path" --json
  else
    missing_references=$((missing_references + 1))
    printf '\n==> skipping %s; central reference root not found at %s\n' "$repo_id" "$repo_path"
  fi
done

if [[ "$REQUIRE_REFERENCES" == "1" && "$missing_references" -gt 0 ]]; then
  printf '\nMissing %s required NDS reference root(s). Set REFERENCE_REPOS_ROOT or unset REQUIRE_NDS_REFERENCES to allow skips.\n' "$missing_references" >&2
  exit 1
fi

printf '\nNDS validation complete.\n'
