import Foundation

public struct NDSROMHeaderParseResult: Codable, Equatable {
    public let header: NDSROMHeader?
    public let diagnostics: [Diagnostic]

    public init(header: NDSROMHeader?, diagnostics: [Diagnostic] = []) {
        self.header = header
        self.diagnostics = diagnostics
    }
}

public struct NDSROMHeader: Codable, Equatable {
    public let path: String
    public let romSize: UInt64
    public let title: String
    public let gameCode: String
    public let makerCode: String
    public let unitCode: UInt8
    public let unitCodeDescription: String
    public let deviceCapacity: UInt8
    public let deviceCapacityBytes: UInt64?
    public let deviceCapacityDescription: String
    public let arm9Offset: UInt64
    public let arm9EntryAddress: UInt64
    public let arm9LoadAddress: UInt64
    public let arm9Size: UInt64
    public let arm7Offset: UInt64
    public let arm7EntryAddress: UInt64
    public let arm7LoadAddress: UInt64
    public let arm7Size: UInt64
    public let fntOffset: UInt64
    public let fntSize: UInt64
    public let fatOffset: UInt64
    public let fatSize: UInt64
    public let arm9OverlayOffset: UInt64
    public let arm9OverlaySize: UInt64
    public let arm7OverlayOffset: UInt64
    public let arm7OverlaySize: UInt64
    public let bannerOffset: UInt64
    public let secureAreaChecksum: UInt16
    public let headerChecksum: UInt16

    public var displayTitle: String {
        if let known = Self.knownTitle(for: gameCode), !known.isEmpty {
            return known
        }
        return title.isEmpty ? URL(fileURLWithPath: path).lastPathComponent : title
    }

    public var headerFacts: [NDSHeaderFact] {
        [
            NDSHeaderFact(label: "Title", value: title.isEmpty ? "unknown" : title),
            NDSHeaderFact(label: "Game Code", value: gameCode.isEmpty ? "unknown" : gameCode),
            NDSHeaderFact(label: "Maker Code", value: makerCode.isEmpty ? "unknown" : makerCode),
            NDSHeaderFact(label: "Unit Code", value: unitCodeDescription),
            NDSHeaderFact(label: "Device Capacity", value: deviceCapacityDescription),
            NDSHeaderFact(label: "ARM9 ROM", value: NDSROMHeader.hexRange(offset: arm9Offset, size: arm9Size)),
            NDSHeaderFact(label: "ARM7 ROM", value: NDSROMHeader.hexRange(offset: arm7Offset, size: arm7Size)),
            NDSHeaderFact(label: "FNT", value: NDSROMHeader.hexRange(offset: fntOffset, size: fntSize)),
            NDSHeaderFact(label: "FAT", value: NDSROMHeader.hexRange(offset: fatOffset, size: fatSize)),
            NDSHeaderFact(label: "ARM9 Overlays", value: NDSROMHeader.hexRange(offset: arm9OverlayOffset, size: arm9OverlaySize)),
            NDSHeaderFact(label: "ARM7 Overlays", value: NDSROMHeader.hexRange(offset: arm7OverlayOffset, size: arm7OverlaySize)),
            NDSHeaderFact(label: "Banner Offset", value: NDSROMHeader.hex(bannerOffset)),
            NDSHeaderFact(label: "Secure Area Checksum", value: String(format: "0x%04X", secureAreaChecksum)),
            NDSHeaderFact(label: "Header Checksum", value: String(format: "0x%04X", headerChecksum))
        ]
    }

    public static func knownTitle(for gameCode: String?) -> String? {
        switch gameCode?.uppercased() {
        case "ADAE", "ADAP":
            return "Pokemon Diamond"
        case "APAE", "APAP":
            return "Pokemon Pearl"
        case "CPUE", "CPUP":
            return "Pokemon Platinum"
        case "IPKE", "IPKP":
            return "Pokemon HeartGold"
        case "IPGE", "IPGP":
            return "Pokemon SoulSilver"
        case "IRBE", "IRBO":
            return "Pokemon Black"
        case "IRAE", "IRAO":
            return "Pokemon White"
        case "IREO", "IREP":
            return "Pokemon Black 2"
        case "IRDO", "IRDP":
            return "Pokemon White 2"
        default:
            return nil
        }
    }

    private static func hex(_ value: UInt64) -> String {
        "0x\(String(value, radix: 16, uppercase: true))"
    }

    private static func hexRange(offset: UInt64, size: UInt64) -> String {
        "\(hex(offset))+\(size)"
    }
}

public struct NDSHeaderFact: Codable, Equatable, Identifiable {
    public var id: String { label }

    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public enum NDSROMHeaderParser {
    private static let minimumHeaderSize = 0x160

    public static func parse(path: String, data: Data) -> NDSROMHeaderParseResult {
        var diagnostics: [Diagnostic] = []
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        guard data.count >= minimumHeaderSize else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_HEADER_TRUNCATED",
                    message: "NDS header is \(data.count) bytes; at least \(minimumHeaderSize) bytes are required.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
            return NDSROMHeaderParseResult(header: nil, diagnostics: diagnostics)
        }

        let deviceCapacity = data.ndsByte(at: 0x14) ?? 0
        let deviceCapacityBytes = deviceCapacity < 32 ? UInt64(128 * 1024) << UInt64(deviceCapacity) : nil
        let header = NDSROMHeader(
            path: path,
            romSize: UInt64(data.count),
            title: data.ndsASCII(offset: 0x00, length: 12),
            gameCode: data.ndsASCII(offset: 0x0C, length: 4),
            makerCode: data.ndsASCII(offset: 0x10, length: 2),
            unitCode: data.ndsByte(at: 0x12) ?? 0,
            unitCodeDescription: unitCodeDescription(data.ndsByte(at: 0x12) ?? 0),
            deviceCapacity: deviceCapacity,
            deviceCapacityBytes: deviceCapacityBytes,
            deviceCapacityDescription: deviceCapacityDescription(byte: deviceCapacity, bytes: deviceCapacityBytes),
            arm9Offset: UInt64(data.ndsUInt32LE(at: 0x20) ?? 0),
            arm9EntryAddress: UInt64(data.ndsUInt32LE(at: 0x24) ?? 0),
            arm9LoadAddress: UInt64(data.ndsUInt32LE(at: 0x28) ?? 0),
            arm9Size: UInt64(data.ndsUInt32LE(at: 0x2C) ?? 0),
            arm7Offset: UInt64(data.ndsUInt32LE(at: 0x30) ?? 0),
            arm7EntryAddress: UInt64(data.ndsUInt32LE(at: 0x34) ?? 0),
            arm7LoadAddress: UInt64(data.ndsUInt32LE(at: 0x38) ?? 0),
            arm7Size: UInt64(data.ndsUInt32LE(at: 0x3C) ?? 0),
            fntOffset: UInt64(data.ndsUInt32LE(at: 0x40) ?? 0),
            fntSize: UInt64(data.ndsUInt32LE(at: 0x44) ?? 0),
            fatOffset: UInt64(data.ndsUInt32LE(at: 0x48) ?? 0),
            fatSize: UInt64(data.ndsUInt32LE(at: 0x4C) ?? 0),
            arm9OverlayOffset: UInt64(data.ndsUInt32LE(at: 0x50) ?? 0),
            arm9OverlaySize: UInt64(data.ndsUInt32LE(at: 0x54) ?? 0),
            arm7OverlayOffset: UInt64(data.ndsUInt32LE(at: 0x58) ?? 0),
            arm7OverlaySize: UInt64(data.ndsUInt32LE(at: 0x5C) ?? 0),
            bannerOffset: UInt64(data.ndsUInt32LE(at: 0x68) ?? 0),
            secureAreaChecksum: data.ndsUInt16LE(at: 0x6C) ?? 0,
            headerChecksum: data.ndsUInt16LE(at: 0x15E) ?? 0
        )

        diagnostics.append(contentsOf: sectionDiagnostics(header: header, dataSize: data.count, fileName: fileName))
        if header.gameCode.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_HEADER_GAME_CODE_EMPTY",
                    message: "NDS game code is empty.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
        }
        return NDSROMHeaderParseResult(header: header, diagnostics: diagnostics)
    }

    private static func unitCodeDescription(_ byte: UInt8) -> String {
        switch byte {
        case 0x00:
            return "Nintendo DS"
        case 0x02:
            return "Nintendo DS / DSi enhanced"
        case 0x03:
            return "Nintendo DSi"
        default:
            return String(format: "Unknown 0x%02X", byte)
        }
    }

    private static func deviceCapacityDescription(byte: UInt8, bytes: UInt64?) -> String {
        guard let bytes else {
            return String(format: "0x%02X (size unavailable)", byte)
        }
        let mib = Double(bytes) / 1_048_576.0
        if mib >= 1 {
            return String(format: "0x%02X (%.0f MiB)", byte, mib)
        }
        return "\(byte) (\(bytes) bytes)"
    }

    private static func sectionDiagnostics(header: NDSROMHeader, dataSize: Int, fileName: String) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let sections: [(String, UInt64, UInt64)] = [
            ("ARM9", header.arm9Offset, header.arm9Size),
            ("ARM7", header.arm7Offset, header.arm7Size),
            ("FNT", header.fntOffset, header.fntSize),
            ("FAT", header.fatOffset, header.fatSize),
            ("ARM9 overlay table", header.arm9OverlayOffset, header.arm9OverlaySize),
            ("ARM7 overlay table", header.arm7OverlayOffset, header.arm7OverlaySize)
        ]
        let romSize = UInt64(dataSize)
        for (name, offset, size) in sections where size > 0 {
            if offset > romSize || offset + size > romSize || offset + size < offset {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_SECTION_OUT_OF_BOUNDS",
                        message: "\(name) range 0x\(String(offset, radix: 16, uppercase: true))+\(size) extends beyond ROM size \(dataSize).",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
            }
        }
        if header.bannerOffset > 0 && header.bannerOffset >= romSize {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_BANNER_OUT_OF_BOUNDS",
                    message: "Banner offset 0x\(String(header.bannerOffset, radix: 16, uppercase: true)) is outside the ROM.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
        }
        if header.fatSize % 8 != 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_FAT_SIZE_UNALIGNED",
                    message: "FAT size \(header.fatSize) is not a multiple of 8 bytes.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
        }
        return diagnostics
    }
}

public enum NitroFSFileKind: String, Codable, Equatable, CaseIterable {
    case narc
    case overlay
    case text
    case graphics
    case audio
    case model
    case binary
    case unknown
}

public struct NitroFSFolder: Codable, Equatable, Identifiable {
    public var id: String { String(format: "0x%04X", directoryID) }

    public let directoryID: UInt16
    public let path: String
    public let firstFileID: UInt16
    public let parentDirectoryID: UInt16?
}

public struct NitroFSFile: Codable, Equatable, Identifiable {
    public var id: String { "\(fileID):\(path)" }

    public let fileID: Int
    public let path: String
    public let offset: UInt64
    public let size: UInt64
    public let kind: NitroFSFileKind
}

public struct NitroFSIndex: Codable, Equatable {
    public let romPath: String
    public let folders: [NitroFSFolder]
    public let files: [NitroFSFile]
    public let folderCount: Int
    public let fileCount: Int
    public let diagnostics: [Diagnostic]

    public init(romPath: String, folders: [NitroFSFolder], files: [NitroFSFile], diagnostics: [Diagnostic]) {
        self.romPath = romPath
        self.folders = folders
        self.files = files
        folderCount = folders.count
        fileCount = files.count
        self.diagnostics = diagnostics
    }
}

public enum NitroFSIndexBuilder {
    public static func build(path: String, header: NDSROMHeader, data: Data) -> NitroFSIndex {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        var diagnostics: [Diagnostic] = []
        guard header.fntSize > 0, header.fatSize > 0 else {
            return NitroFSIndex(
                romPath: path,
                folders: [],
                files: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_NITROFS_TABLES_EMPTY",
                        message: "FNT or FAT table is empty; NitroFS files could not be listed.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                ]
            )
        }

        guard
            let fntRange = data.ndsRange(offset: header.fntOffset, size: header.fntSize),
            let fatRange = data.ndsRange(offset: header.fatOffset, size: header.fatSize)
        else {
            return NitroFSIndex(
                romPath: path,
                folders: [],
                files: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "NDS_NITROFS_TABLE_OUT_OF_BOUNDS",
                        message: "FNT or FAT table extends beyond the ROM.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                ]
            )
        }

        let fntData = data.subdata(in: fntRange)
        let fatData = data.subdata(in: fatRange)
        let fatEntries = parseFAT(data: fatData, romSize: UInt64(data.count), fileName: fileName, diagnostics: &diagnostics)
        let parsed = parseFNT(
            fntData: fntData,
            fatEntries: fatEntries,
            romData: data,
            fileName: fileName,
            diagnostics: &diagnostics
        )
        return NitroFSIndex(
            romPath: path,
            folders: parsed.folders,
            files: parsed.files,
            diagnostics: diagnostics
        )
    }

    private static func parseFAT(
        data: Data,
        romSize: UInt64,
        fileName: String,
        diagnostics: inout [Diagnostic]
    ) -> [(offset: UInt64, size: UInt64)] {
        var entries: [(offset: UInt64, size: UInt64)] = []
        let count = data.count / 8
        for index in 0..<count {
            let entryOffset = index * 8
            let start = UInt64(data.ndsUInt32LE(at: entryOffset) ?? 0)
            let end = UInt64(data.ndsUInt32LE(at: entryOffset + 4) ?? 0)
            if end < start {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_FAT_ENTRY_REVERSED",
                        message: "FAT entry \(index) has end offset before start offset.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                entries.append((start, 0))
                continue
            }
            if end > romSize {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_FAT_ENTRY_OUT_OF_BOUNDS",
                        message: "FAT entry \(index) extends beyond ROM size.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
            }
            entries.append((start, end - start))
        }
        if data.count % 8 != 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_FAT_TRAILING_BYTES",
                    message: "FAT has \(data.count % 8) trailing byte(s) after complete entries.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
        }
        return entries
    }

    private static func parseFNT(
        fntData: Data,
        fatEntries: [(offset: UInt64, size: UInt64)],
        romData: Data,
        fileName: String,
        diagnostics: inout [Diagnostic]
    ) -> (folders: [NitroFSFolder], files: [NitroFSFile]) {
        guard fntData.count >= 8 else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_FNT_TRUNCATED",
                    message: "FNT is too small to contain the root directory record.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
            return ([], [])
        }

        let directoryCount = max(1, Int(fntData.ndsUInt16LE(at: 6) ?? 1))
        var folders: [NitroFSFolder] = []
        var files: [NitroFSFile] = []
        var visited: Set<Int> = []

        func directoryRecord(_ directoryID: Int) -> (subtableOffset: Int, firstFileID: Int, parentID: UInt16)? {
            let recordIndex = directoryID & 0x0FFF
            let recordOffset = recordIndex * 8
            guard recordOffset + 8 <= fntData.count else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_FNT_DIRECTORY_RECORD_OUT_OF_BOUNDS",
                        message: "Directory record 0x\(String(directoryID, radix: 16, uppercase: true)) is outside the FNT.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                return nil
            }
            return (
                Int(fntData.ndsUInt32LE(at: recordOffset) ?? 0),
                Int(fntData.ndsUInt16LE(at: recordOffset + 4) ?? 0),
                fntData.ndsUInt16LE(at: recordOffset + 6) ?? 0
            )
        }

        func parseDirectory(_ directoryID: Int, path: String) {
            let recordIndex = directoryID & 0x0FFF
            guard recordIndex < directoryCount else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_FNT_DIRECTORY_ID_OUT_OF_RANGE",
                        message: "Directory id 0x\(String(directoryID, radix: 16, uppercase: true)) is outside the declared directory count \(directoryCount).",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                return
            }
            guard visited.insert(recordIndex).inserted else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_FNT_DIRECTORY_CYCLE",
                        message: "Directory id 0x\(String(directoryID, radix: 16, uppercase: true)) was already visited.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                return
            }
            guard let record = directoryRecord(directoryID) else { return }
            folders.append(
                NitroFSFolder(
                    directoryID: UInt16(directoryID),
                    path: path.isEmpty ? "/" : path,
                    firstFileID: UInt16(record.firstFileID),
                    parentDirectoryID: directoryID == 0xF000 ? nil : record.parentID
                )
            )
            guard record.subtableOffset < fntData.count else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_FNT_SUBTABLE_OUT_OF_BOUNDS",
                        message: "Directory \(path.isEmpty ? "/" : path) subtable is outside the FNT.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                return
            }

            var cursor = record.subtableOffset
            var fileID = record.firstFileID
            while cursor < fntData.count {
                guard let control = fntData.ndsByte(at: cursor) else { break }
                cursor += 1
                if control == 0 { break }
                let isDirectory = (control & 0x80) != 0
                let nameLength = Int(control & 0x7F)
                guard nameLength > 0, cursor + nameLength <= fntData.count else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .warning,
                            code: "NDS_FNT_NAME_OUT_OF_BOUNDS",
                            message: "Directory \(path.isEmpty ? "/" : path) contains an out-of-bounds name.",
                            span: SourceSpan(relativePath: fileName, startLine: 1)
                        )
                    )
                    return
                }
                let name = fntData.ndsASCII(offset: cursor, length: nameLength, trimPadding: false)
                cursor += nameLength
                if isDirectory {
                    guard cursor + 2 <= fntData.count, let childID = fntData.ndsUInt16LE(at: cursor) else {
                        diagnostics.append(
                            Diagnostic(
                                severity: .warning,
                                code: "NDS_FNT_CHILD_ID_OUT_OF_BOUNDS",
                                message: "Directory \(path.isEmpty ? "/" : path) has a child directory without an id.",
                                span: SourceSpan(relativePath: fileName, startLine: 1)
                            )
                        )
                        return
                    }
                    cursor += 2
                    parseDirectory(Int(childID), path: joinedPath(path, name))
                } else {
                    if fileID >= fatEntries.count {
                        diagnostics.append(
                            Diagnostic(
                                severity: .warning,
                                code: "NDS_FNT_FILE_ID_MISSING_FAT",
                                message: "FNT file \(joinedPath(path, name)) references missing FAT entry \(fileID).",
                                span: SourceSpan(relativePath: fileName, startLine: 1)
                            )
                        )
                    } else {
                        let fat = fatEntries[fileID]
                        let filePath = joinedPath(path, name)
                        files.append(
                            NitroFSFile(
                                fileID: fileID,
                                path: filePath,
                                offset: fat.offset,
                                size: fat.size,
                                kind: kind(for: filePath, offset: fat.offset, size: fat.size, romData: romData)
                            )
                        )
                    }
                    fileID += 1
                }
            }
        }

        parseDirectory(0xF000, path: "")
        return (folders, files.sorted { $0.fileID < $1.fileID })
    }

    private static func joinedPath(_ prefix: String, _ name: String) -> String {
        prefix.isEmpty ? name : "\(prefix)/\(name)"
    }

    private static func kind(for path: String, offset: UInt64, size: UInt64, romData: Data) -> NitroFSFileKind {
        let lower = path.lowercased()
        if lower.contains("overlay") {
            return .overlay
        }
        if lower.hasSuffix(".narc") || romData.ndsMagic("NARC", offset: offset) {
            return .narc
        }
        if lower.hasSuffix(".sdat") || lower.contains("/sound") || lower.contains("/snd") {
            return .audio
        }
        if lower.hasSuffix(".nclr") || lower.hasSuffix(".ncgr") || lower.hasSuffix(".nscr")
            || lower.hasSuffix(".ncer") || lower.hasSuffix(".nanr") || lower.hasSuffix(".nsbmd")
            || lower.hasSuffix(".nsbtx") || lower.contains("graphic") || lower.contains("/arc/pokegra") {
            return .graphics
        }
        if lower.hasSuffix(".bmd0") || lower.hasSuffix(".btx0") || lower.hasSuffix(".bca0") {
            return .model
        }
        if lower.contains("msg") || lower.contains("text") {
            return .text
        }
        if size > 0 {
            return .binary
        }
        return .unknown
    }
}

public enum NDSOverlayTableKind: String, Codable, Equatable, CaseIterable {
    case arm9
    case arm7
}

public struct NDSOverlayEntry: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(overlayID)" }

    public let kind: NDSOverlayTableKind
    public let overlayID: UInt32
    public let ramAddress: UInt64
    public let ramSize: UInt64
    public let bssSize: UInt64
    public let staticInitializerStart: UInt64
    public let staticInitializerEnd: UInt64
    public let fileID: UInt32
    public let compressedSize: UInt64
    public let isCompressed: Bool
}

public struct NDSOverlayTableIndex: Codable, Equatable {
    public let kind: NDSOverlayTableKind
    public let entries: [NDSOverlayEntry]
    public let entryCount: Int
    public let diagnostics: [Diagnostic]

    public init(kind: NDSOverlayTableKind, entries: [NDSOverlayEntry], diagnostics: [Diagnostic] = []) {
        self.kind = kind
        self.entries = entries
        entryCount = entries.count
        self.diagnostics = diagnostics
    }
}

public enum NDSOverlayTableIndexBuilder {
    public static func build(
        kind: NDSOverlayTableKind,
        offset: UInt64,
        size: UInt64,
        data: Data,
        path: String
    ) -> NDSOverlayTableIndex {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        guard size > 0 else {
            return NDSOverlayTableIndex(kind: kind, entries: [])
        }
        guard let range = data.ndsRange(offset: offset, size: size) else {
            return NDSOverlayTableIndex(
                kind: kind,
                entries: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_OVERLAY_TABLE_OUT_OF_BOUNDS",
                        message: "\(kind.rawValue.uppercased()) overlay table extends beyond the ROM.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                ]
            )
        }

        let table = data.subdata(in: range)
        var diagnostics: [Diagnostic] = []
        if table.count % 32 != 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_OVERLAY_TABLE_UNALIGNED",
                    message: "\(kind.rawValue.uppercased()) overlay table has \(table.count % 32) trailing byte(s).",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
        }
        let count = table.count / 32
        let entries = (0..<count).map { index in
            let entryOffset = index * 32
            let compressedFlags = table.ndsUInt32LE(at: entryOffset + 28) ?? 0
            return NDSOverlayEntry(
                kind: kind,
                overlayID: table.ndsUInt32LE(at: entryOffset) ?? 0,
                ramAddress: UInt64(table.ndsUInt32LE(at: entryOffset + 4) ?? 0),
                ramSize: UInt64(table.ndsUInt32LE(at: entryOffset + 8) ?? 0),
                bssSize: UInt64(table.ndsUInt32LE(at: entryOffset + 12) ?? 0),
                staticInitializerStart: UInt64(table.ndsUInt32LE(at: entryOffset + 16) ?? 0),
                staticInitializerEnd: UInt64(table.ndsUInt32LE(at: entryOffset + 20) ?? 0),
                fileID: table.ndsUInt32LE(at: entryOffset + 24) ?? 0,
                compressedSize: UInt64(compressedFlags & 0x00FF_FFFF),
                isCompressed: (compressedFlags & 0x0100_0000) != 0
            )
        }
        return NDSOverlayTableIndex(kind: kind, entries: entries, diagnostics: diagnostics)
    }
}

public struct NARCMember: Codable, Equatable, Identifiable {
    public var id: String { "\(fileID):\(path)" }

    public let fileID: Int
    public let path: String
    public let name: String?
    public let offset: UInt64
    public let size: UInt64
}

public struct NARCIndex: Codable, Equatable {
    public let path: String
    public let byteCount: UInt64
    public let memberCount: Int
    public let gmifDataOffset: UInt64?
    public let members: [NARCMember]
    public let diagnostics: [Diagnostic]

    public init(
        path: String,
        byteCount: UInt64,
        gmifDataOffset: UInt64?,
        members: [NARCMember],
        diagnostics: [Diagnostic] = []
    ) {
        self.path = path
        self.byteCount = byteCount
        self.gmifDataOffset = gmifDataOffset
        self.members = members
        memberCount = members.count
        self.diagnostics = diagnostics
    }
}

public enum NARCParser {
    public static func parse(path: String, data: Data) -> NARCIndex {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        var diagnostics: [Diagnostic] = []
        guard data.count >= 0x10, data.ndsMagic("NARC", offset: 0) else {
            return NARCIndex(
                path: path,
                byteCount: UInt64(data.count),
                gmifDataOffset: nil,
                members: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "NARC_MAGIC_MISSING",
                        message: "NARC magic is missing.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                ]
            )
        }

        let declaredFileSize = Int(data.ndsUInt32LE(at: 0x08) ?? UInt32(data.count))
        let headerSize = Int(data.ndsUInt16LE(at: 0x0C) ?? 0x10)
        let blockCount = Int(data.ndsUInt16LE(at: 0x0E) ?? 0)
        if declaredFileSize > data.count {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NARC_DECLARED_SIZE_OUT_OF_BOUNDS",
                    message: "NARC declares \(declaredFileSize) bytes but only \(data.count) are available.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
        }

        var blocks: [NARCBlock] = []
        var cursor = max(0x10, headerSize)
        while cursor + 8 <= data.count, blocks.count < max(blockCount, 3) {
            let tag = data.ndsASCII(offset: cursor, length: 4, trimPadding: false)
            let blockSize = Int(data.ndsUInt32LE(at: cursor + 4) ?? 0)
            guard blockSize >= 8, cursor + blockSize <= data.count else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NARC_BLOCK_OUT_OF_BOUNDS",
                        message: "NARC block \(tag) at offset \(cursor) has invalid size \(blockSize).",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                break
            }
            blocks.append(NARCBlock(tag: tag, offset: cursor, size: blockSize))
            cursor += blockSize
        }

        guard let fatBlock = blocks.first(where: { $0.isFAT }),
              let imageBlock = blocks.first(where: { $0.isImage })
        else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NARC_REQUIRED_BLOCK_MISSING",
                    message: "NARC is missing a FATB/BTAF or FIMG/GMIF block.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
            return NARCIndex(path: path, byteCount: UInt64(data.count), gmifDataOffset: nil, members: [], diagnostics: diagnostics)
        }

        let names = blocks.first(where: { $0.isFNT }).map { parseNames(data: data, block: $0, diagnostics: &diagnostics, fileName: fileName) } ?? [:]
        let entries = parseFAT(data: data, block: fatBlock, diagnostics: &diagnostics, fileName: fileName)
        let gmifDataOffset = imageBlock.offset + 8
        let gmifDataSize = imageBlock.size - 8
        let members = entries.enumerated().map { index, entry in
            let name = names[index]
            let path = name ?? String(format: "file_%04d.bin", index)
            let size = entry.end >= entry.start ? entry.end - entry.start : 0
            if Int(entry.end) > gmifDataSize {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NARC_MEMBER_OUT_OF_BOUNDS",
                        message: "NARC member \(index) extends beyond GMIF data.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
            }
            return NARCMember(
                fileID: index,
                path: path,
                name: name,
                offset: UInt64(entry.start),
                size: UInt64(size)
            )
        }
        return NARCIndex(
            path: path,
            byteCount: UInt64(data.count),
            gmifDataOffset: UInt64(gmifDataOffset),
            members: members,
            diagnostics: diagnostics
        )
    }

    private static func parseFAT(
        data: Data,
        block: NARCBlock,
        diagnostics: inout [Diagnostic],
        fileName: String
    ) -> [(start: Int, end: Int)] {
        let count = Int(data.ndsUInt16LE(at: block.offset + 8) ?? 0)
        let entriesOffset = block.offset + 12
        guard entriesOffset + count * 8 <= block.offset + block.size else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NARC_FAT_TRUNCATED",
                    message: "NARC FAT block is too small for \(count) entries.",
                    span: SourceSpan(relativePath: fileName, startLine: 1)
                )
            )
            return []
        }
        return (0..<count).map { index in
            let offset = entriesOffset + index * 8
            return (
                Int(data.ndsUInt32LE(at: offset) ?? 0),
                Int(data.ndsUInt32LE(at: offset + 4) ?? 0)
            )
        }
    }

    private static func parseNames(
        data: Data,
        block: NARCBlock,
        diagnostics: inout [Diagnostic],
        fileName: String
    ) -> [Int: String] {
        let blockDataStart = block.offset + 8
        let blockDataSize = block.size - 8
        guard blockDataSize >= 8 else { return [:] }
        let fntData = data.subdata(in: blockDataStart..<(blockDataStart + blockDataSize))
        guard let rootSubtableOffset = fntData.ndsUInt32LE(at: 0) else { return [:] }
        var names: [Int: String] = [:]
        var cursor = Int(rootSubtableOffset)
        var currentFileID = Int(fntData.ndsUInt16LE(at: 4) ?? 0)
        while cursor < fntData.count {
            guard let control = fntData.ndsByte(at: cursor) else { break }
            cursor += 1
            if control == 0 { break }
            let isDirectory = (control & 0x80) != 0
            let nameLength = Int(control & 0x7F)
            guard nameLength > 0, cursor + nameLength <= fntData.count else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NARC_FNT_NAME_OUT_OF_BOUNDS",
                        message: "NARC filename table contains an out-of-bounds name.",
                        span: SourceSpan(relativePath: fileName, startLine: 1)
                    )
                )
                return names
            }
            let name = fntData.ndsASCII(offset: cursor, length: nameLength, trimPadding: false)
            cursor += nameLength
            if isDirectory {
                cursor += 2
            } else {
                names[currentFileID] = name
                currentFileID += 1
            }
        }
        return names
    }
}

public struct NDSNARCArchive: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let fileID: Int
    public let path: String
    public let offset: UInt64
    public let size: UInt64
    public let index: NARCIndex
}

public struct NDSROMInspectorReport: Codable, Equatable {
    public let projectIndex: ProjectIndex
    public let header: NDSROMHeader
    public let fileSystem: NitroFSIndex
    public let arm9Overlays: NDSOverlayTableIndex
    public let arm7Overlays: NDSOverlayTableIndex
    public let narcArchives: [NDSNARCArchive]
    public let resourceEntry: GenIIIResourceEntry
    public let diagnostics: [Diagnostic]
    public let isReadOnly: Bool
}

public enum NDSROMInspectorReportBuilder {
    private static let maxNARCArchives = 128

    public static func build(path: String, fileManager: FileManager = .default) throws -> NDSROMInspectorReport {
        let index = try GameAdapterRegistry.index(path: path, fileManager: fileManager)
        return try build(index: index, fileManager: fileManager)
    }

    public static func build(index: ProjectIndex, fileManager: FileManager = .default) throws -> NDSROMInspectorReport {
        guard index.profile == .ndsROM else {
            throw PokemonHackCoreError.unsupportedProject(index.root.path)
        }
        let url = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let data = try Data(contentsOf: url)
        let headerResult = NDSROMHeaderParser.parse(path: url.path, data: data)
        guard let header = headerResult.header else {
            throw PokemonHackCoreError.unsupportedProject(url.path)
        }
        let fileSystem = NitroFSIndexBuilder.build(path: url.path, header: header, data: data)
        let arm9Overlays = NDSOverlayTableIndexBuilder.build(
            kind: .arm9,
            offset: header.arm9OverlayOffset,
            size: header.arm9OverlaySize,
            data: data,
            path: url.path
        )
        let arm7Overlays = NDSOverlayTableIndexBuilder.build(
            kind: .arm7,
            offset: header.arm7OverlayOffset,
            size: header.arm7OverlaySize,
            data: data,
            path: url.path
        )
        var diagnostics = index.diagnostics
            + headerResult.diagnostics
            + fileSystem.diagnostics
            + arm9Overlays.diagnostics
            + arm7Overlays.diagnostics
        let narcArchives = parseNARCs(
            files: fileSystem.files,
            data: data,
            diagnostics: &diagnostics
        )
        diagnostics.append(contentsOf: narcArchives.flatMap { $0.index.diagnostics })
        let resourceEntry = NDSResourceEntryFactory.makeEntry(
            index: index,
            header: header,
            fileSystem: fileSystem,
            arm9Overlays: arm9Overlays,
            arm7Overlays: arm7Overlays,
            narcArchives: narcArchives,
            diagnostics: diagnostics,
            fileManager: fileManager
        )
        return NDSROMInspectorReport(
            projectIndex: index,
            header: header,
            fileSystem: fileSystem,
            arm9Overlays: arm9Overlays,
            arm7Overlays: arm7Overlays,
            narcArchives: narcArchives,
            resourceEntry: resourceEntry,
            diagnostics: diagnostics,
            isReadOnly: true
        )
    }

    public static func files(path: String, fileManager: FileManager = .default) throws -> NitroFSIndex {
        let report = try build(path: path, fileManager: fileManager)
        return report.fileSystem
    }

    private static func parseNARCs(
        files: [NitroFSFile],
        data: Data,
        diagnostics: inout [Diagnostic]
    ) -> [NDSNARCArchive] {
        var archives: [NDSNARCArchive] = []
        for file in files where file.kind == .narc {
            guard data.ndsMagic("NARC", offset: file.offset) else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_NARC_UNSUPPORTED_MAGIC",
                        message: "NitroFS file \(file.path) is NARC-like but does not start with NARC magic; it may be compressed or unsupported."
                    )
                )
                continue
            }
            if archives.count >= maxNARCArchives {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_NARC_SCAN_LIMIT_REACHED",
                        message: "NARC scanning stopped after \(maxNARCArchives) archives."
                    )
                )
                break
            }
            guard let range = data.ndsRange(offset: file.offset, size: file.size) else { continue }
            let archiveData = data.subdata(in: range)
            let index = NARCParser.parse(path: file.path, data: archiveData)
            archives.append(
                NDSNARCArchive(
                    fileID: file.fileID,
                    path: file.path,
                    offset: file.offset,
                    size: file.size,
                    index: index
                )
            )
        }
        return archives
    }
}

public enum NDSResourceEntryFactory {
    public static func makeEntry(
        index: ProjectIndex,
        header: NDSROMHeader,
        fileSystem: NitroFSIndex,
        arm9Overlays: NDSOverlayTableIndex,
        arm7Overlays: NDSOverlayTableIndex,
        narcArchives: [NDSNARCArchive],
        diagnostics: [Diagnostic],
        fileManager: FileManager = .default
    ) -> GenIIIResourceEntry {
        let url = URL(fileURLWithPath: index.root.path)
        let items = resourceItems(
            url: url,
            header: header,
            fileSystem: fileSystem,
            arm9Overlays: arm9Overlays,
            arm7Overlays: arm7Overlays,
            narcArchives: narcArchives,
            fileManager: fileManager
        )
        return GenIIIResourceEntry(
            id: index.root.path,
            title: header.displayTitle,
            path: index.root.path,
            platform: .ndsROM,
            family: family(for: header.gameCode),
            profile: .ndsROM,
            variants: [
                GenIIIResourceVariant(
                    id: header.gameCode.isEmpty ? "nds-rom" : header.gameCode,
                    title: header.displayTitle
                )
            ],
            role: .localInput,
            parseStatus: diagnostics.contains { $0.severity == .error } ? .partial : .parsed,
            adapterID: index.adapterID,
            writePolicy: .readOnly,
            modules: index.editorModules,
            resourceCount: items.count,
            items: items,
            diagnostics: diagnostics
        )
    }

    public static func family(for gameCode: String) -> GenIIIGameFamily {
        switch gameCode.uppercased() {
        case "ADAE", "ADAP", "APAE", "APAP":
            return .diamondPearl
        case "CPUE", "CPUP":
            return .platinum
        case "IPKE", "IPKP", "IPGE", "IPGP":
            return .heartGoldSoulSilver
        case "IRBE", "IRBO", "IRAE", "IRAO":
            return .blackWhite
        case "IREO", "IREP", "IRDO", "IRDP":
            return .black2White2
        default:
            return .ndsUnknown
        }
    }

    private static func resourceItems(
        url: URL,
        header: NDSROMHeader,
        fileSystem: NitroFSIndex,
        arm9Overlays: NDSOverlayTableIndex,
        arm7Overlays: NDSOverlayTableIndex,
        narcArchives: [NDSNARCArchive],
        fileManager: FileManager
    ) -> [GenIIIResourceItem] {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.uint64Value
        var items: [GenIIIResourceItem] = [
            GenIIIResourceItem(
                id: url.path,
                path: url.lastPathComponent,
                kind: "rom",
                category: "NDS ROM",
                offset: 0,
                size: size
            )
        ]
        items.append(contentsOf: header.headerFacts.map { fact in
            GenIIIResourceItem(
                id: "nds-header:\(fact.label)",
                path: "\(fact.label): \(fact.value)",
                kind: fact.label,
                category: "NDS Header"
            )
        })
        items.append(contentsOf: fileSystem.folders.map { folder in
            GenIIIResourceItem(
                id: "nitrofs-folder:\(folder.id)",
                path: folder.path,
                kind: "folder",
                category: "NitroFS Folder"
            )
        })
        items.append(contentsOf: fileSystem.files.map { file in
            GenIIIResourceItem(
                id: "nitrofs-file:\(file.fileID)",
                path: file.path,
                kind: file.kind.rawValue,
                category: "NitroFS File",
                offset: file.offset,
                size: file.size
            )
        })
        items.append(contentsOf: overlayItems(table: arm9Overlays))
        items.append(contentsOf: overlayItems(table: arm7Overlays))
        for archive in narcArchives {
            items.append(
                GenIIIResourceItem(
                    id: "narc:\(archive.path)",
                    path: archive.path,
                    kind: "narc",
                    category: "NARC Archive",
                    offset: archive.offset,
                    size: archive.size
                )
            )
            let gmifDataOffset = archive.index.gmifDataOffset ?? 0
            items.append(contentsOf: archive.index.members.map { member in
                GenIIIResourceItem(
                    id: "narc-member:\(archive.path):\(member.fileID)",
                    path: "\(archive.path)#\(member.path)",
                    kind: "narcMember",
                    category: "NARC Member",
                    offset: archive.offset + gmifDataOffset + member.offset,
                    size: member.size
                )
            })
        }
        return items
    }

    private static func overlayItems(table: NDSOverlayTableIndex) -> [GenIIIResourceItem] {
        table.entries.map { entry in
            GenIIIResourceItem(
                id: "overlay:\(entry.kind.rawValue):\(entry.overlayID)",
                path: "\(entry.kind.rawValue)/overlay_\(entry.overlayID)",
                kind: "overlay",
                category: "\(entry.kind.rawValue.uppercased()) Overlay",
                offset: nil,
                size: entry.ramSize
            )
        }
    }
}

private struct NARCBlock {
    let tag: String
    let offset: Int
    let size: Int

    var isFAT: Bool { tag == "BTAF" || tag == "FATB" }
    var isFNT: Bool { tag == "BTNF" || tag == "FNTB" }
    var isImage: Bool { tag == "GMIF" || tag == "FIMG" }
}

private extension Data {
    func ndsByte(at offset: Int) -> UInt8? {
        guard offset >= 0, offset < count else { return nil }
        return self[startIndex.advanced(by: offset)]
    }

    func ndsUInt16LE(at offset: Int) -> UInt16? {
        guard
            let b0 = ndsByte(at: offset),
            let b1 = ndsByte(at: offset + 1)
        else {
            return nil
        }
        return UInt16(b0) | (UInt16(b1) << 8)
    }

    func ndsUInt32LE(at offset: Int) -> UInt32? {
        guard
            let b0 = ndsByte(at: offset),
            let b1 = ndsByte(at: offset + 1),
            let b2 = ndsByte(at: offset + 2),
            let b3 = ndsByte(at: offset + 3)
        else {
            return nil
        }
        return UInt32(b0) | (UInt32(b1) << 8) | (UInt32(b2) << 16) | (UInt32(b3) << 24)
    }

    func ndsASCII(offset: Int, length: Int, trimPadding: Bool = true) -> String {
        guard offset >= 0, length > 0, offset + length <= count else { return "" }
        let bytes = (0..<length).compactMap { ndsByte(at: offset + $0) }
        let scalarBytes = bytes.prefix { $0 != 0 }
        let string = String(bytes: scalarBytes, encoding: .ascii) ?? ""
        return trimPadding ? string.trimmingCharacters(in: .whitespacesAndNewlines) : string
    }

    func ndsMagic(_ magic: String, offset: UInt64) -> Bool {
        guard offset <= UInt64(Int.max) else { return false }
        return ndsMagic(magic, offset: Int(offset))
    }

    func ndsMagic(_ magic: String, offset: Int) -> Bool {
        guard offset >= 0, offset + magic.count <= count else { return false }
        return ndsASCII(offset: offset, length: magic.count, trimPadding: false) == magic
    }

    func ndsRange(offset: UInt64, size: UInt64) -> Range<Int>? {
        guard
            offset <= UInt64(Int.max),
            size <= UInt64(Int.max),
            offset + size >= offset,
            offset + size <= UInt64(count)
        else {
            return nil
        }
        let lower = Int(offset)
        let upper = lower + Int(size)
        return lower..<upper
    }
}
