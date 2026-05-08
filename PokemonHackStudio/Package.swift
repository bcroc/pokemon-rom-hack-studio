// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PokemonHackStudio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "PokemonHackCore", targets: ["PokemonHackCore"]),
        .executable(name: "pokemonhack-cli", targets: ["pokemonhack-cli"])
    ],
    targets: [
        .target(name: "PokemonHackCore"),
        .executableTarget(
            name: "pokemonhack-cli",
            dependencies: ["PokemonHackCore"]
        ),
        .testTarget(
            name: "PokemonHackCoreTests",
            dependencies: ["PokemonHackCore"]
        ),
        .testTarget(
            name: "PokemonHackCLITests",
            dependencies: ["pokemonhack-cli"]
        )
    ]
)
