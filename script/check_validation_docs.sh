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

row_id_pattern = re.compile(r"PHS-T[0-9]+[A-Z]*(?:/[A-Z]+)*", re.IGNORECASE)
proof_row_pattern = re.compile(
    r"^\|\s*`(?P<row>PHS-T[^`]+)`\s*\|\s*\[(?P<label>[^\]]+)\]\((?P<link>[^)]+)\)\s*\|.*\|\s*$"
)
active_done_pattern = re.compile(r"^\|\s*(?P<row>PHS-T[^|\s]+)\s*\|\s*Done\s*\|\s*(?P<title>[^|]+)\|")

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

if errors:
    print("Validation docs check failed:", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    sys.exit(1)

print("Validation docs proof index check passed.")
PY
