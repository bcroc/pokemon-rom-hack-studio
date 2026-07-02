# PHS-T140 Resources Detail Packet Copy Affordance

Date: 2026-07-02

## Scope

Resources detail panes now show a visible `Copy Packet JSON` action for selected packet/NDS readiness rows when the existing selected Resources packet copy gate is enabled. The action calls `copySelectedResourceReadinessPacketJSONToPasteboard()` and reuses the same asset plus NDS readiness JSON payload used by command-palette copy.

No new packet builder, readiness computation, parser behavior, hidden-draft gate, NDS editability, generated/reference/container row write, ROM/export/build/playtest path, binary write, Core schema, CLI command, or persisted workspace schema was added.

## Proof

- Focused app-hosted Resources/store proof:
  ```bash
  POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T140-ResourcesPacketCopy -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVVariantReadinessPacketStaysPreviewOnlyInResourcesSelection -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVGeneratedOutputFreshnessPacketStaysPreviewOnlyInResourcesSelection -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVBlockedActionAuditPacketStaysPreviewOnlyInResourcesSelection -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVNitroFSRootInventoryStaysPreviewOnlyInResourcesSelection -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSSourceResourceRecordEditsPreviewApplyAndBlockBinaryRows test
  ```
  Result: passed. Covers Gen V variant, generated-output freshness, blocked-action packet, NitroFS readiness row, and NDS edit/apply gate regression selections. Existing Xcode warnings only.
- `make verify`
  Result: passed after a type-only Swift 6 compile unblocker adding `Sendable` to `NDSDataSemanticFieldValueKind`; no behavior change.
- `git diff --check`
  Result: passed.

## Notes

Concurrent unrelated dirty work was preserved outside this row, including existing IDE command routing, validation promotion, NDS semantic coverage, patch/library, CLI, and proof-doc changes.
