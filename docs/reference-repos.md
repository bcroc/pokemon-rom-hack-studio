# Reference Repositories

The `references/` directory is a research bench for Pokemon GBA hacking tools, emulation, patching, and decompilation workflows. Reference repos should inform architecture and compatibility, but they are not owned product code.

## Strategy

- Keep reference repos read-only during product work unless a task explicitly asks to update or inspect them.
- Use references to understand file formats, editor ergonomics, patch formats, build expectations, and user workflows.
- Summarize learned patterns in docs or issues before adopting them.
- Prefer clean-room implementation in `PokemonHackCore` when the needed behavior is small or domain-specific.
- Require license review before copying code, assets, schemas, tests, or UI text.

The project should learn from existing tools while keeping PokemonHackStudio's implementation and distribution story clean.

Detailed feature synthesis, adoption decisions, and the current implementation lanes are tracked in `docs/reference-synthesis.md`.

## Current References

| Path | Primary Use | Notes |
| --- | --- | --- |
| `references/mgba` | Emulator behavior, launch/debug workflows, patch loading expectations | MPL 2.0; useful for integration boundaries and smoke-test behavior. |
| `references/porymap` | Source-tree map editing UX for Gen 3 decomp projects | LGPL 3.0; study project loading, map relationships, and editor workflows carefully before borrowing implementation details. |
| `references/poryscript` | Script language conventions for decomp-based event scripting | MIT; useful for script workflow compatibility and CLI ergonomics. |
| `references/porytiles` | Tileset and tile workflow reference | MIT; useful for asset pipeline terminology and validation ideas. |
| `references/hex-maniac-advance` | Binary ROM inspection and all-in-one editor UX | MIT; useful for safety affordances, data navigation, and binary-only fallback workflows. |
| `references/rompatcher-js` | Patch format support and user-facing patching flow | MIT with third-party components noted by upstream; useful for supported patch formats and verification UX. |
| `references/pokeemerald-expansion` | Expanded decomp content and compatibility pressure | Check upstream terms before borrowing; use as a target for schema flexibility. |
| `references/pokeruby` | Additional pret decomp project shape | Use to avoid overfitting core models to only Emerald and FireRed. |
| `references/pokemon-game-editor` | Legacy binary editor behavior | Custom restrictive license; treat as observational only unless reviewed. |

## Licensing Boundaries

Reference code is not automatically available to the product. Use this rule of thumb:

- MIT references can be candidates for direct borrowing only after attribution and dependency/reuse review.
- MPL and LGPL references require stronger care around file boundaries, modifications, linking, and distribution.
- Custom or restrictive licenses are observational references unless legal review says otherwise.
- Commercial ROM content, original game assets, and generated ROM files are out of scope for redistribution.

If a feature depends on a reference implementation, document whether the adoption is:

- Conceptual: behavior or UX pattern reimplemented independently.
- Compatible: file format or workflow support implemented from public behavior.
- Vendored: code copied or included with license and attribution review.
- External tool: invoked as a separate user-installed dependency.

## Working Notes

- Start with source-tree tools such as Porymap and Poryscript when designing editable decomp workflows.
- Use Hex Maniac Advance to understand binary fallbacks, safety messaging, and data discovery for ROM-only scenarios.
- Use Rom Patcher JS as a reference for patch UX, checksum display, and patch-format vocabulary.
- Use mGBA as the emulator integration reference, especially around launch, debug, and patch-loading expectations.
- Use pret decomp repos as the truth for source layout, build outputs, and project detection.

Any durable decision learned from references should move into `docs/product-architecture.md`, a future design note, or a tracked implementation issue.
