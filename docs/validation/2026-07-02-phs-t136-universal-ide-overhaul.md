# PHS-T136 Universal IDE Overhaul

## Scope

`PHS-T136` turns the macOS app shell into a universal PokemonHackStudio IDE frame: a grouped Project Navigator, tabbed editor stack, right Inspector, bottom Activity Console, and Command Palette now surround the existing module editors.

The accepted plan assumed the next row would be `PHS-T135`, but the live planning board already used `PHS-T135` for Patch Distribution Readiness. This closeout is recorded as `PHS-T136` to preserve row IDs.

## Proof

- `cd PokemonHackStudio && xcodegen generate`
  Passed; regenerated `PokemonHackStudio.xcodeproj` after adding app-target source files.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T135-IDE-build -destination 'platform=macOS,arch=arm64' -quiet build`
  Passed; app shell compiled after the new IDE frame was wired.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T135-IDE-tests -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests -quiet test`
  Passed the focused app-hosted store tests.
- `make test`
  Passed with 548 SwiftPM tests and 0 failures.
- `make verify`
  Passed; regenerated the Xcode project and built/signed the macOS app with existing local signing/AppIntents/script-phase notes.
- `git diff --check`
  Passed.

## Guarded Execution Boundary

The command palette routes only to existing `WorkbenchStore` navigation, refresh, pasteboard copy, mutation preview/apply/discard, build, playtest/capture, patch, and binary review-token paths. Availability and disabled reasons are derived from the same gates that already drive toolbar and Build/Patch/Playtest actions.

Validation remains copy-only and terminal-guided. NDS build/playtest, NARC/container writes, generated/reference writes, broad ROM export, unsupported binary edits, and binary apply flows stay disabled unless an existing explicit gate already permits that exact action. No `PokemonHackCore` parser, planner, applier, CLI public behavior, source writer, ROM writer, export writer, or reference policy was widened for this row.
