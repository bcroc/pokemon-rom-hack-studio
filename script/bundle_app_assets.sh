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
MANIFEST_SCHEMA_VERSION=1
MANIFEST_SOURCE_POLICY="Local build artifact. Safe source asset trees only; ROMs, saves, generated outputs, build products, toolchains, and reference clones are excluded."

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
  if rsync -a --delete --itemize-changes "$@" "$source_path" "$destination_path" > "$rsync_log"; then
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

copy_directory() {
  local source_root="$1"
  local destination_root="$2"
  local relative_path="$3"
  local source_path="$source_root/$relative_path"
  local destination_path="$destination_root/$relative_path"

  if [[ ! -d "$source_path" ]]; then
    if [[ -e "$destination_path" ]]; then
      rm -rf "$destination_path"
      mark_changed
      pruned_path_count=$((pruned_path_count + 1))
    fi
    return 0
  fi

  mkdir -p "$(dirname "$destination_path")"
  run_incremental_rsync "$source_path/" "$destination_path/" "${RSYNC_EXCLUDES[@]}"
}

copy_root_file() {
  local source_root="$1"
  local destination_root="$2"
  local file_name="$3"
  local source_path="$source_root/$file_name"
  local destination_path="$destination_root/$file_name"

  if [[ ! -f "$source_path" ]]; then
    if [[ -e "$destination_path" ]]; then
      rm -f "$destination_path"
      mark_changed
      pruned_path_count=$((pruned_path_count + 1))
    fi
    return 0
  fi

  mkdir -p "$destination_root"
  run_incremental_rsync "$source_path" "$destination_root/" "${RSYNC_EXCLUDES[@]}"
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

top_level_is_allowed() {
  local entry_name="$1"
  local relative_path
  local file_name

  for relative_path in "${INCLUDED_DIRECTORIES[@]}"; do
    if [[ "${relative_path%%/*}" == "$entry_name" ]]; then
      return 0
    fi
  done

  for file_name in "${ROOT_FILES[@]}"; do
    if [[ "$file_name" == "$entry_name" ]]; then
      return 0
    fi
  done

  return 1
}

nested_child_is_allowed() {
  local parent_path="$1"
  local child_name="$2"
  local relative_path
  local suffix

  for relative_path in "${INCLUDED_DIRECTORIES[@]}"; do
    [[ "$relative_path" == "$parent_path/"* ]] || continue
    suffix="${relative_path#"$parent_path/"}"
    if [[ "${suffix%%/*}" == "$child_name" ]]; then
      return 0
    fi
  done

  return 1
}

prune_project_top_level() {
  local project_destination="$1"
  local entry
  local entry_name

  [[ -d "$project_destination" ]] || return 0

  for entry in "$project_destination"/* "$project_destination"/.[!.]* "$project_destination"/..?*; do
    [[ -e "$entry" ]] || continue
    entry_name="$(basename "$entry")"
    if ! top_level_is_allowed "$entry_name"; then
      rm -rf "$entry"
      mark_changed
      pruned_path_count=$((pruned_path_count + 1))
    fi
  done
}

prune_nested_allowed_paths() {
  local project_destination="$1"
  local relative_path
  local parent_path
  local seen_parents=()
  local seen_parent
  local parent_destination
  local entry
  local entry_name
  local should_skip

  for relative_path in "${INCLUDED_DIRECTORIES[@]}"; do
    [[ "$relative_path" == */* ]] || continue
    parent_path="${relative_path%/*}"
    should_skip=0
    for seen_parent in "${seen_parents[@]:-}"; do
      if [[ "$seen_parent" == "$parent_path" ]]; then
        should_skip=1
        break
      fi
    done
    [[ "$should_skip" == "0" ]] || continue
    seen_parents+=("$parent_path")

    parent_destination="$project_destination/$parent_path"
    [[ -d "$parent_destination" ]] || continue

    for entry in "$parent_destination"/* "$parent_destination"/.[!.]* "$parent_destination"/..?*; do
      [[ -e "$entry" ]] || continue
      entry_name="$(basename "$entry")"
      if ! nested_child_is_allowed "$parent_path" "$entry_name"; then
        rm -rf "$entry"
        mark_changed
        pruned_path_count=$((pruned_path_count + 1))
      fi
    done

    if rmdir "$parent_destination" >/dev/null 2>&1; then
      mark_changed
      pruned_path_count=$((pruned_path_count + 1))
    fi
  done
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

write_manifest() {
  local generated_at="$1"
  local output_path="$2"

  {
    printf '{\n'
    printf '  "schemaVersion": %s,\n' "$MANIFEST_SCHEMA_VERSION"
    printf '  "generatedAt": "%s",\n' "$(printf '%s' "$generated_at" | json_escape)"
    printf '  "sourcePolicy": "%s",\n' "$(printf '%s' "$MANIFEST_SOURCE_POLICY" | json_escape)"
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

bundled_projects=()
for project_name in "${PROJECT_NAMES[@]}"; do
  [[ -n "$project_name" ]] || continue

  source_root="$ROOT_DIR/$project_name"
  [[ -d "$source_root" ]] || continue

  project_destination="$PROJECTS_DESTINATION/$project_name"
  if [[ ! -d "$project_destination" ]]; then
    mark_changed
  fi
  mkdir -p "$project_destination"

  for relative_path in "${INCLUDED_DIRECTORIES[@]}"; do
    copy_directory "$source_root" "$project_destination" "$relative_path"
  done

  for file_name in "${ROOT_FILES[@]}"; do
    copy_root_file "$source_root" "$project_destination" "$file_name"
  done

  prune_project_top_level "$project_destination"
  prune_nested_allowed_paths "$project_destination"

  bundled_projects+=("$project_name")
done

prune_stale_projects
write_manifest_if_needed

if [[ "$bundle_changed" == "0" ]]; then
  echo "Reused ${#bundled_projects[@]} PokemonHackStudio asset project(s) in $DESTINATION_ROOT (unchanged)"
else
  echo "Bundled ${#bundled_projects[@]} PokemonHackStudio asset project(s) into $DESTINATION_ROOT (${changed_item_count} updated item(s), ${pruned_path_count} pruned path(s), ${reused_path_count} reused path(s))"
fi
