#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "missing required tool: python3" >&2
  exit 1
fi

python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root_dir = Path(sys.argv[1])
validation_dir = root_dir / "docs" / "validation"
readme_path = validation_dir / "README.md"
planning_path = root_dir / "docs" / "planning-and-progress.md"
makefile_path = root_dir / "Makefile"
validate_nds_path = root_dir / "script" / "validate_nds.sh"
cli_tests_path = root_dir / "PokemonHackStudio" / "Tests" / "PokemonHackCLITests" / "PokemonHackCLITests.swift"
cli_source_path = root_dir / "PokemonHackStudio" / "Sources" / "pokemonhack-cli" / "PokemonHackCLI.swift"

row_id_pattern = re.compile(r"PHS-T[0-9]+[A-Z]*(?:/[A-Z]+)*", re.IGNORECASE)
proof_row_pattern = re.compile(
    r"^\|\s*`(?P<row>PHS-T[^`]+)`\s*\|\s*\[(?P<label>[^\]]+)\]\((?P<link>[^)]+)\)\s*\|.*\|\s*$"
)
active_done_pattern = re.compile(r"^\|\s*(?P<row>PHS-T[^|\s]+)\s*\|\s*Done\s*\|\s*(?P<title>[^|]+)\|")
coverage_skip_row_pattern = re.compile(
    r"^\|\s*`(?P<skip_id>(?:pokemonhack-cli|PokemonHackCLITests)/[^`]+)`\s*\|"
)
tier_command_row_pattern = re.compile(
    r"^\|\s*(?P<tier>[^|]+?)\s*\|\s*`(?P<command>make\s+[^`]+)`\s*\|"
)
make_target_pattern = re.compile(r"^(?P<targets>[A-Za-z0-9_.-]+(?:\s+[A-Za-z0-9_.-]+)*)\s*:(?!=)")
nds_repo_ids_pattern = re.compile(r"^NDS reference repo IDs:\s*(?P<body>.+)$", re.MULTILINE)
validate_nds_repo_loop_pattern = re.compile(r"for\s+repo_id\s+in\s+(?P<body>[^;\n]+);\s+do")
cli_command_metadata_pattern = re.compile(r'CLICommandMetadata\(\s*name:\s*"(?P<name>[^"]+)"')
swift_test_pattern = re.compile(r"(?m)^\s*func\s+(?P<name>test\w+)\s*\(")

errors = []


def read_text(path):
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing required file: {path.relative_to(root_dir)}")
        return ""


def section(text, heading, stop_heading=None):
    lines = text.splitlines()
    start = None
    for index, line in enumerate(lines):
        if line.strip() == heading:
            start = index + 1
            break
    if start is None:
        errors.append(f"missing heading {heading!r}")
        return ""

    end = len(lines)
    for index in range(start, len(lines)):
        stripped = lines[index].strip()
        if stop_heading is not None and stripped == stop_heading:
            end = index
            break
        if stop_heading is None and stripped.startswith("## "):
            end = index
            break
    return "\n".join(lines[start:end])


def normalize_row_id(row_id):
    return row_id.upper()


def extract_row_ids(text):
    seen = set()
    row_ids = []
    for match in row_id_pattern.finditer(text):
        row_id = normalize_row_id(match.group(0))
        if row_id not in seen:
            seen.add(row_id)
            row_ids.append(row_id)
    return row_ids


def doc_row_ids(path):
    filename_ids = extract_row_ids(path.stem)
    if filename_ids:
        return filename_ids
    return extract_row_ids(read_text(path))


def resolve_validation_link(link):
    link_without_fragment = link.split("#", 1)[0]
    if not link_without_fragment:
        return None
    if "://" in link_without_fragment or link_without_fragment.startswith("/"):
        return None
    return (validation_dir / link_without_fragment).resolve(strict=False)


def extract_validate_nds_filters(text):
    match = re.search(r"nds_test_filters=\(\s*(?P<body>.*?)\n\)", text, re.DOTALL)
    if match is None:
        errors.append("missing nds_test_filters array in script/validate_nds.sh")
        return []
    return re.findall(r'"([^"]+)"', match.group("body"))


def extract_makefile_targets(text):
    targets = set()
    for line in text.splitlines():
        match = make_target_pattern.match(line)
        if match is None:
            continue
        for target in match.group("targets").split():
            if target.startswith("."):
                continue
            targets.add(target)
    return targets


def extract_validation_tier_commands(readme_text):
    tier_section = section(readme_text, "## Tiers", "## NDS Validate Coverage Skips")
    commands = []
    for line in tier_section.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        if stripped in {"| Tier | Command | Purpose | Skips And Blockers |", "| --- | --- | --- | --- |"}:
            continue
        match = tier_command_row_pattern.match(stripped)
        if match is None:
            errors.append(f"malformed validation tier row: {stripped}")
            continue
        commands.append((match.group("tier").strip(), match.group("command").strip()))
    return commands


def extract_documented_nds_repo_ids(readme_text):
    match = nds_repo_ids_pattern.search(readme_text)
    if match is None:
        errors.append("missing NDS reference repo IDs line in docs/validation/README.md")
        return []
    return re.findall(r"`([^`]+)`", match.group("body"))


def extract_validate_nds_repo_ids(text):
    match = validate_nds_repo_loop_pattern.search(text)
    if match is None:
        errors.append("missing NDS reference repo loop in script/validate_nds.sh")
        return []
    return match.group("body").split()


def extract_cli_reference_smoke_commands(text):
    return set(re.findall(r"pokemonhack-cli\s+([a-z0-9-]+)", text))


def extract_cli_commands(text):
    return [match.group("name") for match in cli_command_metadata_pattern.finditer(text)]


def extract_swift_tests(text):
    matches = list(swift_test_pattern.finditer(text))
    tests = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        tests.append((match.group("name"), text[match.start():end]))
    return tests


def filter_covers_test(filters, test_class, test_name):
    return test_class in filters or f"{test_class}/{test_name}" in filters


def is_semantic_or_row_operation_cli_test(test_name):
    if test_name.startswith("testNDSDataSemantic"):
        return True
    return (
        "RowOperation" in test_name
        or "TextLineOperation" in test_name
        or "ItemCSVRowOperation" in test_name
        or "EncounterJSONRowOperation" in test_name
    )


def extract_nds_coverage_skips(readme_text):
    skip_section = section(readme_text, "## NDS Validate Coverage Skips")
    skip_ids = set()
    for line in skip_section.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        if stripped in {"| Skip ID | Reason |", "| --- | --- |"}:
            continue
        match = coverage_skip_row_pattern.match(stripped)
        if match is None:
            errors.append(f"malformed NDS validate coverage skip row: {stripped}")
            continue
        skip_id = match.group("skip_id")
        if skip_id in skip_ids:
            errors.append(f"duplicate NDS validate coverage skip row: {skip_id}")
        skip_ids.add(skip_id)
    return skip_ids


def check_validation_tier_make_targets(readme_text):
    makefile_text = read_text(makefile_path)
    if not makefile_text:
        return

    targets = extract_makefile_targets(makefile_text)
    for tier, command in extract_validation_tier_commands(readme_text):
        parts = command.split()
        if len(parts) != 2 or parts[0] != "make":
            errors.append(f"validation tier {tier} command is not a simple make target: {command}")
            continue
        target = parts[1]
        if target not in targets:
            errors.append(f"validation tier {tier} documents missing Makefile target: {command}")


def check_nds_reference_repo_ids(readme_text):
    validate_nds_text = read_text(validate_nds_path)
    if not validate_nds_text:
        return

    documented_repo_ids = extract_documented_nds_repo_ids(readme_text)
    validate_nds_repo_ids = extract_validate_nds_repo_ids(validate_nds_text)
    if not documented_repo_ids or not validate_nds_repo_ids:
        return
    if documented_repo_ids != validate_nds_repo_ids:
        errors.append(
            "documented NDS reference repo IDs do not match script/validate_nds.sh repo loop: "
            f"docs={', '.join(documented_repo_ids)}; script={', '.join(validate_nds_repo_ids)}"
        )


def check_nds_validate_coverage(readme_text):
    validate_nds_text = read_text(validate_nds_path)
    cli_tests_text = read_text(cli_tests_path)
    cli_source_text = read_text(cli_source_path)
    if not validate_nds_text or not cli_tests_text or not cli_source_text:
        return

    filters = set(extract_validate_nds_filters(validate_nds_text))
    reference_smoke_commands = extract_cli_reference_smoke_commands(validate_nds_text)
    cli_tests = extract_swift_tests(cli_tests_text)
    covered_cli_test_bodies = [
        body
        for test_name, body in cli_tests
        if filter_covers_test(filters, "PokemonHackCLITests", test_name)
    ]
    guarded_tests = {
        f"PokemonHackCLITests/{test_name}"
        for test_name, _ in cli_tests
        if is_semantic_or_row_operation_cli_test(test_name)
    }
    skip_ids = extract_nds_coverage_skips(readme_text)

    guarded_commands = {
        command
        for command in extract_cli_commands(cli_source_text)
        if command.startswith("nds-") or command == "narc-inspect"
    }
    guarded_command_ids = {f"pokemonhack-cli/{command}" for command in guarded_commands}
    known_skip_ids = guarded_command_ids | guarded_tests
    for skip_id in sorted(skip_ids - known_skip_ids):
        errors.append(f"NDS validate coverage skip {skip_id} does not match a guarded command or test")

    for command in sorted(guarded_commands):
        command_id = f"pokemonhack-cli/{command}"
        if command_id in skip_ids:
            continue
        if command in reference_smoke_commands:
            continue
        command_literal = f'"{command}"'
        if any(command_literal in body for body in covered_cli_test_bodies):
            continue
        errors.append(
            f"NDS CLI command {command_id} is not covered by script/validate_nds.sh "
            "and is missing from NDS Validate Coverage Skips"
        )

    for test_name, _ in cli_tests:
        if not is_semantic_or_row_operation_cli_test(test_name):
            continue
        test_id = f"PokemonHackCLITests/{test_name}"
        if filter_covers_test(filters, "PokemonHackCLITests", test_name):
            continue
        if test_id in skip_ids:
            continue
        errors.append(
            f"{test_id} is not listed in script/validate_nds.sh and is missing from "
            "NDS Validate Coverage Skips"
        )


readme_text = read_text(readme_path)
planning_text = read_text(planning_path)
validation_root = validation_dir.resolve()

docs_by_row = {}
doc_ids_by_path = {}
for doc_path in sorted(validation_dir.glob("*.md")):
    if doc_path.name == "README.md":
        continue
    ids = doc_row_ids(doc_path)
    doc_ids_by_path[doc_path.resolve(strict=False)] = ids
    for row_id in ids:
        docs_by_row.setdefault(row_id, []).append(doc_path.relative_to(validation_dir).as_posix())

proof_rows = {}
proof_section = section(readme_text, "## Focused Closeout Proof")
for line in proof_section.splitlines():
    stripped = line.strip()
    if not stripped.startswith("|"):
        continue
    if stripped in {"| Row | Proof | Outcome |", "| --- | --- | --- |"}:
        continue
    match = proof_row_pattern.match(stripped)
    if match is None:
        errors.append(f"malformed proof index row: {stripped}")
        continue

    row_id = normalize_row_id(match.group("row"))
    link = match.group("link")
    if row_id in proof_rows:
        errors.append(f"duplicate proof index row: {row_id}")
    proof_rows[row_id] = link

    resolved_link = resolve_validation_link(link)
    if resolved_link is None:
        errors.append(f"proof link for {row_id} is not a relative docs/validation link: {link}")
        continue

    try:
        resolved_link.relative_to(validation_root)
    except ValueError:
        errors.append(f"proof link for {row_id} escapes docs/validation: {link}")
        continue

    if not resolved_link.is_file():
        errors.append(f"proof link for {row_id} does not resolve to a file: {link}")
        continue

    target_ids = doc_ids_by_path.get(resolved_link, doc_row_ids(resolved_link))
    if row_id not in target_ids:
        mapped_ids = ", ".join(target_ids) if target_ids else "no row IDs"
        errors.append(f"proof link for {row_id} points to {link}, which maps to {mapped_ids}")

active_board_section = section(planning_text, "## Active Board", "## Recent Progress")
done_rows = {}
for line in active_board_section.splitlines():
    match = active_done_pattern.match(line.strip())
    if match is None:
        continue
    row_id = normalize_row_id(match.group("row"))
    done_rows[row_id] = match.group("title").strip()

for row_id in sorted(done_rows):
    if row_id not in docs_by_row:
        continue
    if row_id not in proof_rows:
        docs = ", ".join(docs_by_row[row_id])
        errors.append(f"completed board row {row_id} has validation doc(s) but is missing from proof index: {docs}")

check_validation_tier_make_targets(readme_text)
check_nds_reference_repo_ids(readme_text)
check_nds_validate_coverage(readme_text)

if errors:
    print("Validation docs check failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    sys.exit(1)

print("Validation docs proof index, tier drift, and NDS coverage checks passed.")
PY
