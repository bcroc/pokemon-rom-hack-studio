#!/usr/bin/env bash
set -euo pipefail

if [[ "${POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS:-0}" == "1" ]]; then
  echo "PokemonHackStudio asset bundling skipped by POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1"
  exit 0
fi

ROOT_DIR="${POKEMONHACKSTUDIO_WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REFERENCE_REPOS_ROOT="${POKEMONHACKSTUDIO_REFERENCE_REPOS_ROOT:-/Users/bryan/projects/reference-repos}"
REFERENCE_REPOS_DIR="$REFERENCE_REPOS_ROOT/repos"
RESOURCES_DIR="${1:-${TARGET_BUILD_DIR:-}/${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}}"

if [[ -z "$RESOURCES_DIR" || "$RESOURCES_DIR" == "/" ]]; then
  echo "usage: $0 <app resources directory>" >&2
  exit 2
fi

DESTINATION_ROOT="$RESOURCES_DIR/PokemonHackStudioAssets"
PROJECTS_DESTINATION="$DESTINATION_ROOT/Projects"
MANIFEST_PATH="$DESTINATION_ROOT/manifest.json"
MANIFEST_SCHEMA_VERSION=2
MANIFEST_SOURCE_POLICY="Local noncommercial build artifact. Source-heavy decomp mirrors and companion metadata only; commercial ROMs, saves, generated ROMs, build products, Git data, caches, and local extracted/built artifacts are excluded."

DEFAULT_PROJECT_SPECS=(
  "pokeemerald|editableSource|pokeemerald|emerald|localEditable|Pokemon - Emerald Version (USA, Europe).gba|$ROOT_DIR/pokeemerald;$REFERENCE_REPOS_DIR/pret__pokeemerald"
  "pokefirered|editableSource|pokefirered|fireRedLeafGreen|localEditable|Pokemon - FireRed Version (USA, Europe) (Rev 1).gba;Pokemon - LeafGreen Version (USA, Europe) (Rev 1).gba|$ROOT_DIR/pokefirered;$REFERENCE_REPOS_DIR/pret__pokefirered"
  "pokeruby|referenceSource|pokeruby|rubySapphire|centralReference|Pokemon - Ruby Version (USA, Europe) (Rev 2).gba;Pokemon - Sapphire Version (USA, Europe) (Rev 2).gba|$REFERENCE_REPOS_DIR/pret__pokeruby;$ROOT_DIR/references/pokeruby"
  "pokeemerald-expansion|referenceSource|pokeemeraldExpansion|emeraldExpansion|centralReference|Pokemon Emerald Expansion|$REFERENCE_REPOS_DIR/rh-hideout__pokeemerald-expansion;$ROOT_DIR/references/pokeemerald-expansion"
  "pokediamond|referenceSource|pokediamond|diamondPearl|centralReference|Pokemon - Diamond Version (USA) (Rev 5).nds;Pokemon - Pearl Version (USA) (Rev 5).nds|$REFERENCE_REPOS_DIR/pret__pokediamond"
  "pokeplatinum|referenceSource|pokeplatinum|platinum|centralReference|Pokemon - Platinum Version (USA) (Rev 1).nds|$REFERENCE_REPOS_DIR/pret__pokeplatinum"
  "pokeheartgold|referenceSource|pokeheartgold|heartGoldSoulSilver|centralReference|Pokemon - HeartGold Version (USA).nds;Pokemon - SoulSilver Version (USA, Australia).nds|$REFERENCE_REPOS_DIR/pret__pokeheartgold"
  "pokeblack|referenceSource|pokeblack|blackWhite|centralReference|Pokemon - Black Version (USA, Europe) (NDSi Enhanced).nds|$REFERENCE_REPOS_DIR/pokemodding__pokeblack"
)

UNAVAILABLE_TITLE_SPECS=(
  "Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds|blackWhite|pokeblack|No materialized White source decomp is available in the current central corpus; the available pokeblack tree currently supports black.us only."
  "Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds|black2White2|none|No public/materialized Black 2 decomp source root was found in the configured central corpus."
  "Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds|black2White2|none|No public/materialized White 2 decomp source root was found in the configured central corpus."
)

RSYNC_EXCLUDES=(
  "--exclude=.build/"
  "--exclude=.cache/"
  "--exclude=.git/"
  "--exclude=.github/"
  "--exclude=.pokemonhackstudio/"
  "--exclude=.swiftpm/"
  "--exclude=DerivedData/"
  "--exclude=build/"
  "--exclude=builds/"
  "--exclude=*.3ds"
  "--exclude=*.a"
  "--exclude=*.aps"
  "--exclude=*.bps"
  "--exclude=*.cia"
  "--exclude=*.diff"
  "--exclude=*.dSYM/"
  "--exclude=*.dump"
  "--exclude=*.elf"
  "--exclude=*.exe"
  "--exclude=*.gba"
  "--exclude=*.gb"
  "--exclude=*.gbc"
  "--exclude=*.gcm"
  "--exclude=*.i"
  "--exclude=*.ips"
  "--exclude=*.iso"
  "--exclude=*.map"
  "--exclude=*.nds"
  "--exclude=*.o"
  "--exclude=*.patch"
  "--exclude=*.sa1"
  "--exclude=*.sav"
  "--exclude=*.sgm"
  "--exclude=*.ss[0-9]"
  "--exclude=*.sym"
  "--exclude=*.ups"
  "--exclude=*.xdelta"
  "--exclude=*.xMAP"
  "--exclude=*.xmap"
  "--exclude=__pycache__/"
  "--exclude=*.pyc"
)

json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

json_value() {
  printf '%s' "$1" | json_escape
}

bundle_changed=0
changed_item_count=0
pruned_path_count=0
updated_path_count=0
reused_path_count=0

mark_changed() {
  bundle_changed=1
}

count_file_lines() {
  local path="$1"
  if [[ -s "$path" ]]; then
    wc -l < "$path" | tr -d ' '
  else
    printf '0'
  fi
}

run_incremental_rsync() {
  local source_path="$1"
  local destination_path="$2"
  shift 2

  local rsync_log
  rsync_log="$(mktemp "${TMPDIR:-/tmp}/pokemonhack-rsync.XXXXXX")"
  if rsync -a --delete --delete-excluded --itemize-changes "$@" "$source_path" "$destination_path" > "$rsync_log"; then
    local line_count
    line_count="$(count_file_lines "$rsync_log")"
    if [[ "$line_count" != "0" ]]; then
      mark_changed
      changed_item_count=$((changed_item_count + line_count))
      updated_path_count=$((updated_path_count + 1))
    else
      reused_path_count=$((reused_path_count + 1))
    fi
  else
    local status=$?
    rm -f "$rsync_log"
    return "$status"
  fi
  rm -f "$rsync_log"
}

copy_project_mirror() {
  local source_root="$1"
  local destination_root="$2"

  mkdir -p "$destination_root"
  run_incremental_rsync "$source_root/" "$destination_root/" "${RSYNC_EXCLUDES[@]}"
}

split_semicolon_json_array() {
  local value="$1"
  local first=1
  local item

  printf '['
  IFS=';' read -r -a items <<< "$value"
  for item in "${items[@]}"; do
    [[ -n "$item" ]] || continue
    if [[ "$first" == "0" ]]; then
      printf ', '
    fi
    printf '"%s"' "$(json_value "$item")"
    first=0
  done
  printf ']'
}

project_is_bundled() {
  local project_name="$1"
  local bundled_project
  for bundled_project in "${bundled_projects[@]:-}"; do
    if [[ "$bundled_project" == "$project_name" ]]; then
      return 0
    fi
  done
  return 1
}

prune_stale_projects() {
  local project_entry
  local project_name

  [[ -d "$PROJECTS_DESTINATION" ]] || return 0

  for project_entry in "$PROJECTS_DESTINATION"/* "$PROJECTS_DESTINATION"/.[!.]* "$PROJECTS_DESTINATION"/..?*; do
    [[ -e "$project_entry" ]] || continue
    project_name="$(basename "$project_entry")"
    if ! project_is_bundled "$project_name"; then
      rm -rf "$project_entry"
      mark_changed
      pruned_path_count=$((pruned_path_count + 1))
    fi
  done
}

existing_manifest_generated_at() {
  [[ -f "$MANIFEST_PATH" ]] || return 0
  sed -n 's/^[[:space:]]*"generatedAt": "\(.*\)",[[:space:]]*$/\1/p' "$MANIFEST_PATH" | head -n 1
}

resolved_source_mode() {
  local configured_mode="$1"
  local path="$2"

  if [[ "$path" == "$REFERENCE_REPOS_DIR/"* ]]; then
    printf 'centralReference'
  elif [[ "$path" == "$ROOT_DIR/references/"* ]]; then
    printf 'compatibilityReference'
  else
    printf '%s' "$configured_mode"
  fi
}

resolved_role() {
  local configured_role="$1"
  local path="$2"

  if [[ "$path" == "$REFERENCE_REPOS_DIR/"* || "$path" == "$ROOT_DIR/references/"* ]]; then
    printf 'referenceSource'
  else
    printf '%s' "$configured_role"
  fi
}

find_source_root() {
  local candidates="$1"
  local candidate

  IFS=';' read -r -a paths <<< "$candidates"
  for candidate in "${paths[@]}"; do
    [[ -n "$candidate" ]] || continue
    if [[ -d "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

filters_project() {
  local project_name="$1"
  local filter

  if [[ ${#PROJECT_FILTERS[@]} -eq 0 ]]; then
    return 0
  fi

  for filter in "${PROJECT_FILTERS[@]}"; do
    if [[ "$filter" == "$project_name" ]]; then
      return 0
    fi
  done
  return 1
}

record_unavailable_titles() {
  local titles="$1"
  local family="$2"
  local source_name="$3"
  local reason="$4"
  local title

  IFS=';' read -r -a title_items <<< "$titles"
  for title in "${title_items[@]}"; do
    [[ -n "$title" ]] || continue
    unavailable_titles+=("$title")
    unavailable_families+=("$family")
    unavailable_sources+=("$source_name")
    unavailable_reasons+=("$reason")
  done
}

write_manifest() {
  local generated_at="$1"
  local output_path="$2"
  local index
  local comma

  {
    printf '{\n'
    printf '  "schemaVersion": %s,\n' "$MANIFEST_SCHEMA_VERSION"
    printf '  "generatedAt": "%s",\n' "$(json_value "$generated_at")"
    printf '  "sourcePolicy": "%s",\n' "$(json_value "$MANIFEST_SOURCE_POLICY")"
    printf '  "workspaceRoot": "%s",\n' "$(json_value "$ROOT_DIR")"
    printf '  "referenceReposRoot": "%s",\n' "$(json_value "$REFERENCE_REPOS_ROOT")"
    printf '  "projects": [\n'
    for index in "${!bundled_projects[@]}"; do
      comma=","
      if [[ "$index" == "$((${#bundled_projects[@]} - 1))" ]]; then
        comma=""
      fi
      printf '    {\n'
      printf '      "name": "%s",\n' "$(json_value "${bundled_projects[$index]}")"
      printf '      "sourcePath": "%s",\n' "$(json_value "${bundled_source_paths[$index]}")"
      printf '      "bundlePath": "%s",\n' "$(json_value "${bundled_bundle_paths[$index]}")"
      printf '      "profile": "%s",\n' "$(json_value "${bundled_profiles[$index]}")"
      printf '      "family": "%s",\n' "$(json_value "${bundled_families[$index]}")"
      printf '      "role": "%s",\n' "$(json_value "${bundled_roles[$index]}")"
      printf '      "sourceMode": "%s",\n' "$(json_value "${bundled_source_modes[$index]}")"
      printf '      "titleCoverage": '
      split_semicolon_json_array "${bundled_title_coverage[$index]}"
      printf ',\n'
      printf '      "unavailableReason": null\n'
      printf '    }%s\n' "$comma"
    done
    printf '  ],\n'
    printf '  "unavailableTitles": [\n'
    for index in "${!unavailable_titles[@]}"; do
      comma=","
      if [[ "$index" == "$((${#unavailable_titles[@]} - 1))" ]]; then
        comma=""
      fi
      printf '    { "title": "%s", "family": "%s", "sourceName": "%s", "unavailableReason": "%s" }%s\n' \
        "$(json_value "${unavailable_titles[$index]}")" \
        "$(json_value "${unavailable_families[$index]}")" \
        "$(json_value "${unavailable_sources[$index]}")" \
        "$(json_value "${unavailable_reasons[$index]}")" \
        "$comma"
    done
    printf '  ],\n'
    printf '  "excluded": ["Git data", "ROMs", "saves", "patch files", "generated ROMs", "build products", "compiler objects", "debug maps", "disc images", "Swift/Xcode caches"],\n'
    printf '  "rsyncExcludes": ['
    for index in "${!RSYNC_EXCLUDES[@]}"; do
      if [[ "$index" != "0" ]]; then
        printf ', '
      fi
      printf '"%s"' "$(json_value "${RSYNC_EXCLUDES[$index]}")"
    done
    printf ']\n'
    printf '}\n'
  } > "$output_path"
}

write_manifest_if_needed() {
  local generated_at
  local existing_generated_at
  local manifest_temp

  existing_generated_at="$(existing_manifest_generated_at)"
  if [[ "$bundle_changed" == "0" && -n "$existing_generated_at" ]]; then
    generated_at="$existing_generated_at"
  else
    generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  fi

  manifest_temp="$(mktemp "$DESTINATION_ROOT/manifest.XXXXXX")"
  write_manifest "$generated_at" "$manifest_temp"

  if [[ -f "$MANIFEST_PATH" ]] && cmp -s "$manifest_temp" "$MANIFEST_PATH"; then
    rm -f "$manifest_temp"
  else
    mv "$manifest_temp" "$MANIFEST_PATH"
  fi
}

mkdir -p "$DESTINATION_ROOT"
mkdir -p "$PROJECTS_DESTINATION"

PROJECT_FILTERS=()
if [[ -n "${POKEMONHACKSTUDIO_BUNDLE_PROJECTS:-}" ]]; then
  # Preserve the old environment variable as a project-name filter over the new spec list.
  # shellcheck disable=SC2206
  PROJECT_FILTERS=(${POKEMONHACKSTUDIO_BUNDLE_PROJECTS})
fi

PROJECT_SPECS=("${DEFAULT_PROJECT_SPECS[@]}")
if [[ -n "${POKEMONHACKSTUDIO_BUNDLE_SOURCE_SPECS:-}" ]]; then
  IFS=$'\n' read -r -d '' -a PROJECT_SPECS <<< "${POKEMONHACKSTUDIO_BUNDLE_SOURCE_SPECS}"$'\0'
fi

bundled_projects=()
bundled_source_paths=()
bundled_bundle_paths=()
bundled_profiles=()
bundled_families=()
bundled_roles=()
bundled_source_modes=()
bundled_title_coverage=()
unavailable_titles=()
unavailable_families=()
unavailable_sources=()
unavailable_reasons=()

for spec in "${PROJECT_SPECS[@]}"; do
  [[ -n "$spec" ]] || continue
  IFS='|' read -r project_name configured_role profile family configured_source_mode title_coverage source_candidates <<< "$spec"
  [[ -n "${project_name:-}" ]] || continue
  filters_project "$project_name" || continue

  if ! source_root="$(find_source_root "$source_candidates")"; then
    record_unavailable_titles "$title_coverage" "$family" "$project_name" "No source root found for configured candidates: $source_candidates"
    continue
  fi

  project_destination="$PROJECTS_DESTINATION/$project_name"
  if [[ ! -d "$project_destination" ]]; then
    mark_changed
  fi

  copy_project_mirror "$source_root" "$project_destination"

  bundled_projects+=("$project_name")
  bundled_source_paths+=("$source_root")
  bundled_bundle_paths+=("PokemonHackStudioAssets/Projects/$project_name")
  bundled_profiles+=("$profile")
  bundled_families+=("$family")
  bundled_roles+=("$(resolved_role "$configured_role" "$source_root")")
  bundled_source_modes+=("$(resolved_source_mode "$configured_source_mode" "$source_root")")
  bundled_title_coverage+=("$title_coverage")
done

for spec in "${UNAVAILABLE_TITLE_SPECS[@]}"; do
  IFS='|' read -r title family source_name reason <<< "$spec"
  record_unavailable_titles "$title" "$family" "$source_name" "$reason"
done

prune_stale_projects
write_manifest_if_needed

if [[ "$bundle_changed" == "0" ]]; then
  echo "Reused ${#bundled_projects[@]} PokemonHackStudio asset project(s) in $DESTINATION_ROOT (unchanged)"
else
  echo "Bundled ${#bundled_projects[@]} PokemonHackStudio asset project(s) into $DESTINATION_ROOT (${changed_item_count} updated item(s), ${pruned_path_count} pruned path(s), ${reused_path_count} reused path(s))"
fi
