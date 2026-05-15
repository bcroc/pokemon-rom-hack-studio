import XCTest
@testable import PokemonHackCore

final class PoryscriptCompatibilityTests: XCTestCase {
    func testScannerReportsPorySourcesLineMarkersAndConditionals() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write("script Route1 {}\n", to: root.appendingPathComponent("data/maps/Route1/scripts.pory"))
        try write(
            """
            #line 10 "data/maps/Route1/scripts.pory"
            #ifdef REVISION
            poryswitch(VERSION) {
            }
            #endif
            """,
            to: root.appendingPathComponent("data/maps/Route1/scripts.inc")
        )

        let report = PoryscriptCompatibilityScanner.scan(rootPath: root.path)

        XCTAssertEqual(report.porySources.map(\.relativePath), ["data/maps/Route1/scripts.pory"])
        XCTAssertTrue(report.generatedRelationships.contains { $0.kind == .lineMarker && $0.poryPath == "data/maps/Route1/scripts.pory" })
        XCTAssertTrue(report.generatedRelationships.contains { $0.kind == .poryswitch })
        XCTAssertTrue(report.generatedRelationships.contains { $0.kind == .conditional })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PORYSCRIPT_COMPILER_NOT_INVOKED" })
        XCTAssertTrue(report.blockingDiagnostics(for: "data/maps/Route1/scripts.inc").contains { $0.code == "SCRIPT_COMMAND_EDIT_PORYSCRIPT_GENERATED_BLOCKED" })
    }

    func testScannerIgnoresGeneratedWorkspaceArtifacts() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("script {}\n", to: root.appendingPathComponent(".pokemonhackstudio/exports/maps/generated.pory"))

        let report = PoryscriptCompatibilityScanner.scan(rootPath: root.path)

        XCTAssertTrue(report.porySources.isEmpty)
        XCTAssertTrue(report.generatedRelationships.isEmpty)
    }

    private func makeTemporaryProjectRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("pokemonhack-poryscript-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
