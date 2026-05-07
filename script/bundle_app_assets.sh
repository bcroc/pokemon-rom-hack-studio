#!/usr/bin/env bash
set -euo pipefail

if [[ "${POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS:-0}" == "1" ]]; then
  echo "PokemonHackStudio asset bundling skipped by POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1"
  exit 0
fi

ROOT_DIR="${POKEMONHACKSTUDIO_WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RESOURCES_DIR="${1:-${TARGET_BUILD_DIR:-}/${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}}"

if [[ -z "$RESOURCES_DIR" || "$RESOURCES_DIR" == "/" ]]; then
  echo "usage: $0 <app resources directory>" >&2
  exit 2
fi

DESTINATION_ROOT="$RESOURCES_DIR/PokemonHackStudioAssets"
PROJECTS_DESTINATION="$DESTINATION_ROOT/Projects"
MANIFEST_PATH="$DESTINATION_ROOT/manifest.json"

IFS=" " read -r -a PROJECT_NAMES <<< "${POKEMONHACKSTUDIO_BUNDLE_PROJECTS:-pokeemerald pokefirered pokeruby pokesapphire pokeemerald-expansion}"

INCLUDED_DIRECTORIES=(
  "constants"
  "data"
  "graphics"
  "include"
  "sound"
  "songs"
  "src/data"
)

ROOT_FILES=(
  "config.mk"
  "firered.sha1"
  "leafgreen.sha1"
  "Makefile"
  "rom.sha1"
)

RSYNC_EXCLUDES=(
  "--exclude=.build/"
  "--exclude=.git/"
  "--exclude=.swiftpm/"
  "--exclude=DerivedData/"
  "--exclude=build/"
  "--exclude=builds/"
  "--exclude=xcuserdata/"
  "--exclude=*.a"
  "--exclude=*.bps"
  "--exclude=*.diff"
  "--exclude=*.dump"
  "--exclude=*.elf"
  "--exclude=*.gba"
  "--exclude=*.gbc"
  "--exclude=*.gcm"
  "--exclude=*.i"
  "--exclude=*.ips"
  "--exclude=*.iso"
  "--exclude=*.map"
  "--exclude=*.o"
  "--exclude=*.sa1"
  "--exclude=*.sav"
  "--exclude=*.sgm"
  "--exclude=*.ss[0-9]"
  "--exclude=*.sym"
  "--exclude=*.ups"
)

json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

copy_directory() {
  local source_root="$1"
  local destination_root="$2"
  local relative_path="$3"
  local source_path="$source_root/$relative_path"
  local destination_path="$destination_root/$relative_path"

  [[ -d "$source_path" ]] || return 0

  mkdir -p "$destination_path"
  rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$source_path/" "$destination_path/"
}

copy_root_file() {
  local source_root="$1"
  local destination_root="$2"
  local file_name="$3"
  local source_path="$source_root/$file_name"

  [[ -f "$source_path" ]] || return 0

  mkdir -p "$destination_root"
  rsync -a "${RSYNC_EXCLUDES[@]}" "$source_path" "$destination_root/"
}

mkdir -p "$DESTINATION_ROOT"
rm -rf "$PROJECTS_DESTINATION"
mkdir -p "$PROJECTS_DESTINATION"

bundled_projects=()
for project_name in "${PROJECT_NAMES[@]}"; do
  [[ -n "$project_name" ]] || continue

  source_root="$ROOT_DIR/$project_name"
  [[ -d "$source_root" ]] || continue

  project_destination="$PROJECTS_DESTINATION/$project_name"
  mkdir -p "$project_destination"

  for relative_path in "${INCLUDED_DIRECTORIES[@]}"; do
    copy_directory "$source_root" "$project_destination" "$relative_path"
  done

  for file_name in "${ROOT_FILES[@]}"; do
    copy_root_file "$source_root" "$project_destination" "$file_name"
  done

  bundled_projects+=("$project_name")
done

{
  printf '{\n'
  printf '  "schemaVersion": 1,\n'
  printf '  "generatedAt": "%s",\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '  "sourcePolicy": "Local build artifact. Safe source asset trees only; ROMs, saves, generated outputs, build products, toolchains, and reference clones are excluded.",\n'
  printf '  "workspaceRoot": "%s",\n' "$(printf '%s' "$ROOT_DIR" | json_escape)"
  printf '  "projects": [\n'
  for index in "${!bundled_projects[@]}"; do
    project_name="${bundled_projects[$index]}"
    comma=","
    if [[ "$index" == "$((${#bundled_projects[@]} - 1))" ]]; then
      comma=""
    fi
    printf '    { "name": "%s", "sourcePath": "%s", "bundlePath": "PokemonHackStudioAssets/Projects/%s" }%s\n' \
      "$(printf '%s' "$project_name" | json_escape)" \
      "$(printf '%s' "$ROOT_DIR/$project_name" | json_escape)" \
      "$(printf '%s' "$project_name" | json_escape)" \
      "$comma"
  done
  printf '  ],\n'
  printf '  "includedDirectories": ['
  for index in "${!INCLUDED_DIRECTORIES[@]}"; do
    if [[ "$index" != "0" ]]; then
      printf ', '
    fi
    printf '"%s"' "$(printf '%s' "${INCLUDED_DIRECTORIES[$index]}" | json_escape)"
  done
  printf '],\n'
  printf '  "excluded": ["ROMs", "saves", "generated ROMs", "build outputs", "toolchains", "reference clones"]\n'
  printf '}\n'
} > "$MANIFEST_PATH"

echo "Bundled ${#bundled_projects[@]} PokemonHackStudio asset project(s) into $DESTINATION_ROOT"
