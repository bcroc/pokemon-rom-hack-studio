# PHS-T142 Reference Status Visibility

## Scope

`references --json` now keeps the existing top-level `repositories` array and adds read-only status for:

- `/Users/bryan/projects/reference-repos/docs/index.json` existence.
- Ignored `references/*` compatibility alias resolution.
- Validation tiers affected by existing `ValidationTierCommandRow.skippedReferenceCauses`.
- Git tracking under `references/`, including whether only `references/manifest.json` is tracked.
- Project Hub and Diagnostics app surfaces that render the same cached report as facts, warning diagnostics, and Copy JSON only.

The accepted plan named `PHS-T140`, but the live dirty board already had `PHS-T140` and `PHS-T141`, so this closeout is recorded as `PHS-T142`.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'ReferenceStatusReportTests|PokemonHackCLITests/testReferencesCommandEmitsVisibilityStatusJSON'`
  - Passed after SwiftPM waited on an existing `.build` lock.
  - 3 selected tests, 0 failures.
- `swift run --package-path PokemonHackStudio pokemonhack-cli references --json | python3 -c '...'`
  - Passed.
  - Reported 30 repositories, missing `/Users/bryan/projects/reference-repos/docs/index.json`, 41 dangling ignored aliases, Git tracking only `references/manifest.json`, and affected tiers `localGBAFixtures`, `ndsSyntheticAndOptionalReferences`, `centralNDSReferences`, and `releaseCandidate`.
- `xcodebuild test -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -destination 'platform=macOS' -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests/testReferenceStatusFeedsProjectHubFactsAndDiagnostics`
  - Passed after `xcodegen generate` refreshed the app project membership.
  - 1 selected app/store test, 0 failures.
  - Covered Project Hub fact labels, ignored alias counts, affected validation tier copy, Git tracking posture, and Diagnostics row contribution.
- `git check-ignore -v references/* references/manifest.json`
  - Passed.
  - Ignored aliases were reported from `.gitignore:43`; `references/manifest.json` was not reported as ignored.
- Symlink-resolution check over `references/*`
  - Passed.
  - `/Users/bryan/projects/reference-repos/docs/index.json` was missing.
  - Summary: `resolved=0`, `dangling=41`, `materialized=0`.
- `bash -n script/*.sh`
  - Passed.
- `./script/check_validation_docs.sh`
  - Passed.
- `make verify`
  - Passed after regenerating `PokemonHackStudio.xcodeproj`.
  - Existing ad-hoc signing, bundle-script, and skipped AppIntents metadata warnings only.
- `git diff --check`
  - Passed.

## Boundaries

No ignored reference repo, tracked `references/manifest.json`, `.gitignore` policy, validation-script behavior, source-write path, ROM-write path, build/export path, command execution authority, or app repair/sync surface was changed.
