# Agent Guide

This repo is a local development workspace for PokemonHackStudio. Keep the first move grounded in the live files, then make narrow, verifiable changes.

## Start Here

- Read `docs/planning-and-progress.md` before choosing implementation work.
- Use `docs/planning.md` and `docs/product-architecture.md` for product direction.
- Use `docs/reference-repos.md` and `docs/reference-synthesis.md` before adopting behavior from reference projects.
- Prefer root tooling: `make validate`, `make test`, `make build`, `make run`, and `make verify`.

## Boundaries

- Keep `pokeemerald/`, `pokefirered/`, `agbcc/`, local ROMs, saves, generated ROMs, `DerivedData/`, SwiftPM caches, and Xcode output untracked.
- Keep `references/*` ignored; track only `references/manifest.json` unless a task explicitly changes the reference policy.
- Treat reference repositories as read-only research material. Do not copy code or assets without a license review.
- Keep source-tree edits reviewable and preserve unknown fields/order when parsing source formats.
- Model product writes as mutation plans before any apply/export workflow.

## Validation

- Run `make validate` for bootstrap and core changes.
- For narrow Swift package changes, `make test` is the minimum proof.
- For app shell changes, use `make verify` or `make run` after SwiftPM checks.
- Record completed work and proof in `docs/planning-and-progress.md` when closing a tracked row.

## Current Focus

`PHS-T1` is active: implement the read-only map/layout viewer backed by `ProjectIndex`, map groups, map JSON, layouts, and blockdata previews.
