# PHS-T57G Cry/Audio Compatibility Reporting

## Scope

- Extend the existing GBA cry/audio preview-only compatibility plan with candidate source path patterns, future replacement constraints, and missing-source blocked reasons.
- Surface missing-source blocked reasons on the top-level `cries` compatibility entry.
- Keep existing source files limited to local project-relative paths with size and SHA1 facts.
- Keep audio conversion, generated audio output writes, playback, ROM export, binary mutation, and source mutation apply disabled.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'PokemonDataCompatibilityTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON'` (passed; 9 selected tests)
- `swift test --package-path PokemonHackStudio --filter PokemonHackCLITests/testPokemonCompatibilityCommandEmitsCryAudioBlockedJSON` (passed; 1 selected CLI test)
- `make validate-synthetic` (passed; `scripts-check` plus 387 SwiftPM tests)
- `git check-ignore -v pokeemerald/example.gba pokefirered/example.gba references/example-clone .pokemonhackstudio/generated.wav build/example.gba DerivedData/example dist/example.gba artifacts/example.wav .build/debug/example.o` (passed; local fixture, reference, generated-output, cache, and build-output rules remain active)
- `git diff --check` (passed)

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/2026-06-29-phs-t57g-cry-audio-compatibility.md`

## Posture

No conversion, generated audio output, playback, ROM export, binary mutation, source mutation apply, source mutation writer, local fixture mutation, generated-output tracking, or ignore-rule change was added.
