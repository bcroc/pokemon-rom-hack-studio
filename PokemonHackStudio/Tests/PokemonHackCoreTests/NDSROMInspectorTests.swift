import XCTest
@testable import PokemonHackCore

final class NDSROMInspectorTests: XCTestCase {
    private var temporaryDirectories: [NDSTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testNDSHeaderParserReportsCoreFacts() throws {
        let rom = try writeSyntheticNDSROM()
        let data = try Data(contentsOf: rom)
        let result = NDSROMHeaderParser.parse(path: rom.path, data: data)
        let header = try XCTUnwrap(result.header)

        XCTAssertEqual(header.title, "POKEMON D")
        XCTAssertEqual(header.gameCode, "ADAE")
        XCTAssertEqual(header.makerCode, "01")
        XCTAssertEqual(header.unitCodeDescription, "Nintendo DS")
        XCTAssertEqual(header.deviceCapacityBytes, 64 * 1024 * 1024)
        XCTAssertEqual(header.fntOffset, 0x300)
        XCTAssertEqual(header.fatOffset, 0x380)
        XCTAssertEqual(header.arm9OverlayOffset, 0x3C0)
        XCTAssertEqual(header.displayTitle, "Pokemon Diamond")
        XCTAssertFalse(result.diagnostics.contains { $0.severity == .error })
    }

    func testNitroFSIndexesNestedFoldersOverlaysAndNARCs() throws {
        let rom = try writeSyntheticNDSROM()
        let report = try NDSROMInspectorReportBuilder.build(path: rom.path)

        XCTAssertEqual(report.projectIndex.profile, .ndsROM)
        XCTAssertEqual(report.projectIndex.writePolicy, .readOnly)
        XCTAssertEqual(report.fileSystem.folderCount, 2)
        XCTAssertTrue(report.fileSystem.files.contains { $0.fileID == 0 && $0.path == "root.bin" && $0.size == 4 })
        XCTAssertTrue(report.fileSystem.files.contains { $0.fileID == 1 && $0.path == "sub/child.narc" && $0.kind == .narc })
        XCTAssertEqual(report.arm9Overlays.entryCount, 1)
        XCTAssertEqual(report.arm9Overlays.entries.first?.overlayID, 7)
        XCTAssertEqual(report.arm9Overlays.entries.first?.fileID, 1)
        XCTAssertEqual(report.narcArchives.count, 1)
        XCTAssertEqual(report.narcArchives.first?.index.memberCount, 2)
        XCTAssertTrue(report.resourceEntry.items.contains { $0.category == "NDS Header" && $0.kind == "Game Code" })
        XCTAssertTrue(report.resourceEntry.items.contains { $0.category == "NitroFS File" && $0.path == "sub/child.narc" })
        XCTAssertTrue(report.resourceEntry.items.contains { $0.category == "NARC Member" && $0.path.contains("#first.bin") })
    }

    func testNDSAdapterAndResourceRegistryDetectReadonlyNDSROMs() throws {
        let temp = try NDSTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("Pokemon Diamond.nds")
        try syntheticNDSROM().write(to: rom)

        let profile = try ProjectInspector.detectProfile(at: rom)
        let index = try GameAdapterRegistry.index(path: rom.path)
        let resource = GenIIIResourceRegistry.resourceIndex(path: rom.path)
        let library = GenIIIResourceRegistry.load(workspaceRoot: temp.url.path)

        XCTAssertEqual(profile, .ndsROM)
        XCTAssertEqual(index.adapterID, "nds.binary-rom")
        XCTAssertTrue(index.capabilities.contains(.ndsROMInspection))
        XCTAssertTrue(index.capabilities.contains(.nitroFSIndex))
        XCTAssertEqual(resource.platform, .ndsROM)
        XCTAssertEqual(resource.family, .diamondPearl)
        XCTAssertEqual(resource.writePolicy, .readOnly)
        XCTAssertTrue(library.entries.contains { $0.platform == .ndsROM && $0.family == .diamondPearl })
    }

    func testNDSParserReportsTruncatedHeaderAndMalformedRanges() throws {
        let truncated = Data(repeating: 0, count: 0x40)
        let truncatedResult = NDSROMHeaderParser.parse(path: "broken.nds", data: truncated)
        XCTAssertNil(truncatedResult.header)
        XCTAssertTrue(truncatedResult.diagnostics.contains { $0.code == "NDS_HEADER_TRUNCATED" && $0.severity == .error })

        var malformed = syntheticNDSROM()
        writeUInt32LE(0xFFFF_F000, into: &malformed, at: 0x40)
        writeUInt32LE(0x1000, into: &malformed, at: 0x44)
        let headerResult = NDSROMHeaderParser.parse(path: "malformed.nds", data: malformed)
        XCTAssertTrue(headerResult.diagnostics.contains { $0.code == "NDS_SECTION_OUT_OF_BOUNDS" })
        let header = try XCTUnwrap(headerResult.header)
        let fileSystem = NitroFSIndexBuilder.build(path: "malformed.nds", header: header, data: malformed)
        XCTAssertTrue(fileSystem.diagnostics.contains { $0.code == "NDS_NITROFS_TABLE_OUT_OF_BOUNDS" })
    }

    func testNARCParserIndexesNamedMembersAndMalformedBlocks() throws {
        let narc = syntheticNARC()
        let index = NARCParser.parse(path: "fixture.narc", data: narc)

        XCTAssertEqual(index.memberCount, 2)
        XCTAssertEqual(index.members.map(\.path), ["first.bin", "second.bin"])
        XCTAssertEqual(index.members.first?.offset, 0)
        XCTAssertEqual(index.members.first?.size, 4)

        let malformed = Data("NARC".utf8) + Data(repeating: 0, count: 12)
        let malformedIndex = NARCParser.parse(path: "broken.narc", data: malformed)
        XCTAssertTrue(malformedIndex.diagnostics.contains { $0.code == "NARC_REQUIRED_BLOCK_MISSING" })
    }

    private func writeSyntheticNDSROM() throws -> URL {
        let temp = try NDSTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("fixture.nds")
        try syntheticNDSROM().write(to: rom)
        return rom
    }

    private func syntheticNDSROM() -> Data {
        var data = Data(repeating: 0, count: 0x900)
        writeASCII("POKEMON D", into: &data, at: 0x00, length: 12)
        writeASCII("ADAE", into: &data, at: 0x0C, length: 4)
        writeASCII("01", into: &data, at: 0x10, length: 2)
        data[0x12] = 0x00
        data[0x14] = 0x09
        writeUInt32LE(0x200, into: &data, at: 0x20)
        writeUInt32LE(0x0200_0000, into: &data, at: 0x24)
        writeUInt32LE(0x0200_0000, into: &data, at: 0x28)
        writeUInt32LE(0x20, into: &data, at: 0x2C)
        writeUInt32LE(0x220, into: &data, at: 0x30)
        writeUInt32LE(0x0238_0000, into: &data, at: 0x34)
        writeUInt32LE(0x0238_0000, into: &data, at: 0x38)
        writeUInt32LE(0x20, into: &data, at: 0x3C)

        let fnt = syntheticFNT()
        writeUInt32LE(0x300, into: &data, at: 0x40)
        writeUInt32LE(UInt32(fnt.count), into: &data, at: 0x44)
        data.replaceSubrange(0x300..<(0x300 + fnt.count), with: fnt)

        var fat = Data()
        appendUInt32LE(0x400, to: &fat)
        appendUInt32LE(0x404, to: &fat)
        let narc = syntheticNARC()
        appendUInt32LE(0x500, to: &fat)
        appendUInt32LE(UInt32(0x500 + narc.count), to: &fat)
        writeUInt32LE(0x380, into: &data, at: 0x48)
        writeUInt32LE(UInt32(fat.count), into: &data, at: 0x4C)
        data.replaceSubrange(0x380..<(0x380 + fat.count), with: fat)

        writeUInt32LE(0x3C0, into: &data, at: 0x50)
        writeUInt32LE(32, into: &data, at: 0x54)
        writeUInt32LE(0x700, into: &data, at: 0x68)
        writeUInt16LE(0x1234, into: &data, at: 0x6C)
        writeUInt16LE(0x5678, into: &data, at: 0x15E)

        writeUInt32LE(7, into: &data, at: 0x3C0)
        writeUInt32LE(0x0210_0000, into: &data, at: 0x3C4)
        writeUInt32LE(0x80, into: &data, at: 0x3C8)
        writeUInt32LE(0x10, into: &data, at: 0x3CC)
        writeUInt32LE(0x0210_0010, into: &data, at: 0x3D0)
        writeUInt32LE(0x0210_0020, into: &data, at: 0x3D4)
        writeUInt32LE(1, into: &data, at: 0x3D8)
        writeUInt32LE(0x0100_0020, into: &data, at: 0x3DC)

        data.replaceSubrange(0x400..<0x404, with: Data("ROOT".utf8))
        data.replaceSubrange(0x500..<(0x500 + narc.count), with: narc)
        return data
    }

    private func syntheticFNT() -> Data {
        var rootEntries = Data()
        appendFNTFile("root.bin", to: &rootEntries)
        appendFNTDirectory("sub", directoryID: 0xF001, to: &rootEntries)
        rootEntries.append(0)

        var childEntries = Data()
        appendFNTFile("child.narc", to: &childEntries)
        childEntries.append(0)

        var fnt = Data()
        appendUInt32LE(16, to: &fnt)
        appendUInt16LE(0, to: &fnt)
        appendUInt16LE(2, to: &fnt)
        appendUInt32LE(UInt32(16 + rootEntries.count), to: &fnt)
        appendUInt16LE(1, to: &fnt)
        appendUInt16LE(0xF000, to: &fnt)
        fnt.append(rootEntries)
        fnt.append(childEntries)
        return fnt
    }

    private func syntheticNARC() -> Data {
        let payload = Data([0xAA, 0xBB, 0xCC, 0xDD, 0x11, 0x22, 0x33])

        var fat = Data("BTAF".utf8)
        appendUInt32LE(28, to: &fat)
        appendUInt16LE(2, to: &fat)
        appendUInt16LE(0, to: &fat)
        appendUInt32LE(0, to: &fat)
        appendUInt32LE(4, to: &fat)
        appendUInt32LE(4, to: &fat)
        appendUInt32LE(UInt32(payload.count), to: &fat)

        var namesData = Data()
        appendUInt32LE(8, to: &namesData)
        appendUInt16LE(0, to: &namesData)
        appendUInt16LE(1, to: &namesData)
        appendFNTFile("first.bin", to: &namesData)
        appendFNTFile("second.bin", to: &namesData)
        namesData.append(0)
        var fnt = Data("BTNF".utf8)
        appendUInt32LE(UInt32(8 + namesData.count), to: &fnt)
        fnt.append(namesData)

        var image = Data("GMIF".utf8)
        appendUInt32LE(UInt32(8 + payload.count), to: &image)
        image.append(payload)

        let fileSize = UInt32(16 + fat.count + fnt.count + image.count)
        var header = Data("NARC".utf8)
        appendUInt16LE(0xFFFE, to: &header)
        appendUInt16LE(0x0100, to: &header)
        appendUInt32LE(fileSize, to: &header)
        appendUInt16LE(0x10, to: &header)
        appendUInt16LE(3, to: &header)
        return header + fat + fnt + image
    }

    private func appendFNTFile(_ name: String, to data: inout Data) {
        data.append(UInt8(name.utf8.count))
        data.append(Data(name.utf8))
    }

    private func appendFNTDirectory(_ name: String, directoryID: UInt16, to data: inout Data) {
        data.append(UInt8(0x80 | name.utf8.count))
        data.append(Data(name.utf8))
        appendUInt16LE(directoryID, to: &data)
    }

    private func writeASCII(_ string: String, into data: inout Data, at offset: Int, length: Int) {
        let bytes = Array(string.utf8.prefix(length))
        data.replaceSubrange(offset..<(offset + bytes.count), with: bytes)
    }

    private func writeUInt16LE(_ value: UInt16, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xff)
        data[offset + 1] = UInt8((value >> 8) & 0xff)
    }

    private func writeUInt32LE(_ value: UInt32, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xff)
        data[offset + 1] = UInt8((value >> 8) & 0xff)
        data[offset + 2] = UInt8((value >> 16) & 0xff)
        data[offset + 3] = UInt8((value >> 24) & 0xff)
    }

    private func appendUInt16LE(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
    }

    private func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 24) & 0xff))
    }
}

private final class NDSTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCoreNDSTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
