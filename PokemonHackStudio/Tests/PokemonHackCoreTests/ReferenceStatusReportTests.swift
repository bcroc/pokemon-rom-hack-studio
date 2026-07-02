import XCTest
@testable import PokemonHackCore

final class ReferenceStatusReportTests: XCTestCase {
    private var temporaryDirectories: [ReferenceStatusTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testReferenceStatusReportsCentralIndexAliasesValidationAndTracking() throws {
        let workspace = try makeWorkspace()
        let centralIndex = workspace.appendingPathComponent("central/docs/index.json")
        try write("{}", to: centralIndex)

        let resolvedTarget = workspace.appendingPathComponent("central/repos/huderlem__porymap")
        try makeDirectory(resolvedTarget)
        try FileManager.default.createSymbolicLink(
            at: workspace.appendingPathComponent("references/porymap"),
            withDestinationURL: resolvedTarget
        )
        try FileManager.default.createSymbolicLink(
            at: workspace.appendingPathComponent("references/missing-reference"),
            withDestinationURL: workspace.appendingPathComponent("central/repos/missing-reference")
        )
        try makeDirectory(workspace.appendingPathComponent("references/materialized-reference"))

        let report = try ReferenceStatusReportBuilder.build(
            from: workspace.path,
            centralReferenceIndexPath: centralIndex.path,
            gitProbe: ReferenceGitTrackingProbe(
                isAvailable: true,
                trackedPaths: ["references/manifest.json"]
            )
        )

        XCTAssertEqual(report.repositories.map(\.name), ["porymap"])
        XCTAssertEqual(report.centralReferenceIndex.status, .available)
        XCTAssertEqual(report.referenceAliases.totalCount, 3)
        XCTAssertEqual(report.referenceAliases.resolvedCount, 1)
        XCTAssertEqual(report.referenceAliases.danglingCount, 1)
        XCTAssertEqual(report.referenceAliases.materializedCount, 1)
        XCTAssertTrue(report.referenceAliases.ignoredByPolicy)
        XCTAssertTrue(report.referenceAliases.aliases.allSatisfy(\.ignoredByPolicy))
        XCTAssertEqual(report.referenceAliases.aliases.map(\.name), [
            "materialized-reference",
            "missing-reference",
            "porymap"
        ])
        XCTAssertEqual(report.referenceAliases.aliases.first { $0.name == "porymap" }?.status, .resolved)
        XCTAssertEqual(report.referenceAliases.aliases.first { $0.name == "missing-reference" }?.status, .dangling)
        XCTAssertEqual(report.referenceAliases.aliases.first { $0.name == "materialized-reference" }?.status, .materialized)

        XCTAssertEqual(
            report.validationTiersAffected.map(\.tier),
            [.localGBAFixtures, .ndsSyntheticAndOptionalReferences, .centralNDSReferences, .releaseCandidate]
        )
        let optionalNDS = try XCTUnwrap(report.validationTiersAffected.first { $0.tier == .ndsSyntheticAndOptionalReferences })
        XCTAssertEqual(optionalNDS.command, "make validate-nds")
        XCTAssertTrue(optionalNDS.affectedReferenceCauses.allSatisfy { $0.behavior == .skippedWhenMissing })

        XCTAssertEqual(report.tracking.source, .git)
        XCTAssertTrue(report.tracking.gitTrackedPathsAvailable)
        XCTAssertEqual(report.tracking.trackedPaths, ["references/manifest.json"])
        XCTAssertTrue(report.tracking.onlyReferencesManifestTracked)
        XCTAssertEqual(report.tracking.status, .manifestOnly)
    }

    func testReferenceStatusReportsMissingCentralIndexAndPolicyFallbackTracking() throws {
        let workspace = try makeWorkspace()
        let missingIndex = workspace.appendingPathComponent("central/docs/index.json")

        let report = try ReferenceStatusReportBuilder.build(
            from: workspace.path,
            centralReferenceIndexPath: missingIndex.path,
            gitProbe: ReferenceGitTrackingProbe(
                isAvailable: false,
                trackedPaths: [],
                errorMessage: "not a git checkout"
            )
        )

        XCTAssertEqual(report.centralReferenceIndex.path, missingIndex.path)
        XCTAssertFalse(report.centralReferenceIndex.exists)
        XCTAssertEqual(report.centralReferenceIndex.status, .missing)
        XCTAssertEqual(report.tracking.source, .policyFallback)
        XCTAssertFalse(report.tracking.gitTrackedPathsAvailable)
        XCTAssertTrue(report.tracking.onlyReferencesManifestTracked)
        XCTAssertEqual(report.tracking.status, .policyOnly)
        XCTAssertEqual(report.tracking.errorMessage, "not a git checkout")
    }

    private func makeWorkspace() throws -> URL {
        let temp = try ReferenceStatusTemporaryDirectory()
        temporaryDirectories.append(temp)
        let workspace = temp.url
        try makeDirectory(workspace.appendingPathComponent("references"))
        try write(
            """
            /references/*
            !/references/manifest.json
            """,
            to: workspace.appendingPathComponent(".gitignore")
        )
        try write(
            """
            {
              "repositories": [
                {
                  "name": "porymap",
                  "path": "references/porymap",
                  "modules": ["maps"]
                }
              ]
            }
            """,
            to: workspace.appendingPathComponent("references/manifest.json")
        )
        return workspace
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}

private final class ReferenceStatusTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReferenceStatusReportTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
