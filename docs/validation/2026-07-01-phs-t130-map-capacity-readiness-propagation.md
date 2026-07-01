# PHS-T130 Map Capacity Readiness Propagation

## Scope

`PHS-T130` propagates map event-capacity summaries through session, mutation-plan, and duplicate-map review surfaces while keeping over-capacity diagnostics warning-only.

## Review Remediation Addendum

- Targeted app proof was rerun during review remediation to ensure the warning-only capacity contract still holds after the app/store and project wiring changes.
- `MapEditorSessionTests/testEventCapacityWarningsTrackStagedEventsWithoutBlockingInsertion` continues to assert `MAP_EVENT_CAPACITY_OVER_LIMIT` is a warning and does not block insertion or apply planning.
- Adjacent app/store remediation for Resources hidden NDS drafts now includes cache-key and invalidation proof without changing map capacity gates.

## Proof

- Targeted Xcode proof passed under `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1` for `MapEditorSessionTests/testEventCapacityWarningsTrackStagedEventsWithoutBlockingInsertion`.
- Existing app/store coverage continues to exercise sidebar capacity summaries, mutation-plan capacity warnings, and duplicate-map source-capacity propagation while leaving those diagnostics warning-only.
- `MapEditorStoreTests/testHiddenNDSDraftFacetInvalidatesCachedResourceRowsWhenDraftChanges` passed in targeted Xcode proof for the Resources cache regression.
- `make validate` passed after remediation.

## Boundary

`MAP_EVENT_CAPACITY_OVER_LIMIT` remains warning-only. Add, Duplicate, Preview, Apply, source writers, ROM writers, build/export paths, and existing mutation-plan gates remain unchanged.
