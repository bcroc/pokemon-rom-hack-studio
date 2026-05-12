import Foundation

public enum DecompBuildRunStatus: String, Codable, Equatable, Sendable {
    case blocked
    case succeeded
    case failed
    case cancelled
}

public enum DecompBuildLogStream: String, Codable, Equatable, Sendable {
    case stdout
    case stderr
    case system
}

public struct DecompBuildLogEvent: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let stream: DecompBuildLogStream
    public let message: String
    public let emittedAt: Date

    public init(id: String = UUID().uuidString, stream: DecompBuildLogStream, message: String, emittedAt: Date = Date()) {
        self.id = id
        self.stream = stream
        self.message = message
        self.emittedAt = emittedAt
    }
}

public enum DecompBuildArtifactKind: String, Codable, Equatable, Sendable {
    case stdout
    case stderr
    case runLog
}

public struct DecompBuildArtifact: Codable, Equatable, Identifiable, Sendable {
    public var id: String { relativePath }

    public let kind: DecompBuildArtifactKind
    public let relativePath: String
    public let absolutePath: String
    public let exists: Bool
    public let detail: String

    public init(kind: DecompBuildArtifactKind, relativePath: String, absolutePath: String, exists: Bool, detail: String) {
        self.kind = kind
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.exists = exists
        self.detail = detail
    }
}

public struct DecompBuildResult: Codable, Equatable, @unchecked Sendable {
    public let status: DecompBuildRunStatus
    public let projectRootPath: String
    public let targetID: String?
    public let targetName: String?
    public let command: [String]
    public let processID: Int32?
    public let exitCode: Int32?
    public let artifacts: [DecompBuildArtifact]
    public let output: BuildOutputValidation?
    public let diagnostics: [Diagnostic]
    public let startedAt: Date?
    public let finishedAt: Date?

    public init(
        status: DecompBuildRunStatus,
        projectRootPath: String,
        targetID: String?,
        targetName: String?,
        command: [String],
        processID: Int32? = nil,
        exitCode: Int32? = nil,
        artifacts: [DecompBuildArtifact],
        output: BuildOutputValidation? = nil,
        diagnostics: [Diagnostic],
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) {
        self.status = status
        self.projectRootPath = projectRootPath
        self.targetID = targetID
        self.targetName = targetName
        self.command = command
        self.processID = processID
        self.exitCode = exitCode
        self.artifacts = artifacts
        self.output = output
        self.diagnostics = diagnostics
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}

public typealias DecompBuildLogHandler = @Sendable (DecompBuildLogEvent) -> Void

private final class DecompBuildProcessBox: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false

    func set(_ process: Process) {
        lock.lock()
        self.process = process
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let process = process
        lock.unlock()
        process?.terminate()
    }

    var wasCancelled: Bool {
        lock.lock()
        let value = cancelled
        lock.unlock()
        return value
    }
}

public enum DecompBuildRunner {
    public static func run(
        index: ProjectIndex,
        targetID: BuildTarget.ID,
        artifactRoot: URL? = nil,
        fileManager: FileManager = .default,
        toolResolver: @escaping ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment(),
        logHandler: @escaping DecompBuildLogHandler = { _ in },
        now: @Sendable @escaping () -> Date = Date.init
    ) async -> DecompBuildResult {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let artifactRoot = (artifactRoot ?? root).standardizedFileURL
        guard let target = index.buildTargets.first(where: { $0.id == targetID }) else {
            return blocked(index: index, root: root, target: nil, artifactRoot: artifactRoot, code: "BUILD_TARGET_NOT_FOUND", message: "No declared build target matched \(targetID).")
        }
        guard target.command.first == "make" else {
            let message = target.command.isEmpty
                ? "Build target \(target.id) does not declare a command."
                : "PokemonHackStudio only runs declared decomp make targets."
            return blocked(index: index, root: root, target: target, artifactRoot: artifactRoot, code: target.command.isEmpty ? "BUILD_COMMAND_MISSING" : "BUILD_COMMAND_NOT_SUPPORTED", message: message)
        }
        let make = toolResolver("make")
        guard make.isAvailable, let executablePath = make.resolvedPath else {
            return blocked(index: index, root: root, target: target, artifactRoot: artifactRoot, code: "BUILD_TOOL_MISSING", message: "Build target \(target.id) requires make, but no executable was found.")
        }

        return await runMake(
            index: index,
            target: target,
            executablePath: executablePath,
            arguments: Array(target.command.dropFirst()),
            root: root,
            artifactRoot: artifactRoot,
            fileManager: fileManager,
            toolResolver: toolResolver,
            logHandler: logHandler,
            now: now
        )
    }

    private static func runMake(
        index: ProjectIndex,
        target: BuildTarget,
        executablePath: String,
        arguments: [String],
        root: URL,
        artifactRoot: URL,
        fileManager: FileManager,
        toolResolver: @escaping ToolAvailabilityResolver,
        logHandler: @escaping DecompBuildLogHandler,
        now: @Sendable @escaping () -> Date
    ) async -> DecompBuildResult {
        let startedAt = now()
        let artifacts = buildArtifacts(target: target, root: artifactRoot, fileManager: fileManager)
        guard
            let stdoutURL = artifactURL(kind: .stdout, artifacts: artifacts),
            let stderrURL = artifactURL(kind: .stderr, artifacts: artifacts),
            let runLogURL = artifactURL(kind: .runLog, artifacts: artifacts)
        else {
            return blocked(index: index, root: root, target: target, artifactRoot: artifactRoot, code: "BUILD_ARTIFACT_PLAN_MISSING", message: "Build run artifacts are incomplete.")
        }

        let box = DecompBuildProcessBox()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                do {
                    try fileManager.createDirectory(at: runLogURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try Data().write(to: stdoutURL)
                    try Data().write(to: stderrURL)
                    let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
                    let stderrHandle = try FileHandle(forWritingTo: stderrURL)
                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()
                    let writeQueue = DispatchQueue(label: "PokemonHackStudio.DecompBuildRunner.\(target.id)")
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: executablePath)
                    process.arguments = arguments
                    process.currentDirectoryURL = root
                    process.standardOutput = stdoutPipe
                    process.standardError = stderrPipe
                    box.set(process)

                    logHandler(DecompBuildLogEvent(stream: .system, message: "Running \(target.command.joined(separator: " ")) in \(root.path)", emittedAt: startedAt))
                    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                        append(handle.availableData, stream: .stdout, outputHandle: stdoutHandle, queue: writeQueue, logHandler: logHandler)
                    }
                    stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                        append(handle.availableData, stream: .stderr, outputHandle: stderrHandle, queue: writeQueue, logHandler: logHandler)
                    }

                    process.terminationHandler = { process in
                        stdoutPipe.fileHandleForReading.readabilityHandler = nil
                        stderrPipe.fileHandleForReading.readabilityHandler = nil
                        append(stdoutPipe.fileHandleForReading.readDataToEndOfFile(), stream: .stdout, outputHandle: stdoutHandle, queue: writeQueue, logHandler: logHandler)
                        append(stderrPipe.fileHandleForReading.readDataToEndOfFile(), stream: .stderr, outputHandle: stderrHandle, queue: writeQueue, logHandler: logHandler)
                        writeQueue.sync {
                            try? stdoutHandle.close()
                            try? stderrHandle.close()
                        }

                        let finishedAt = now()
                        let status: DecompBuildRunStatus = box.wasCancelled ? .cancelled : (process.terminationStatus == 0 ? .succeeded : .failed)
                        let finalReport = BuildValidationReportBuilder.build(index: index, fileManager: .default, toolResolver: toolResolver)
                        let targetReport = finalReport.targets.first(where: { $0.target.id == target.id })
                        let output = targetReport?.output
                        let diagnostics = targetReport?.diagnostics ?? []
                        try? runLog(
                            target: target,
                            root: root,
                            status: status,
                            processID: process.processIdentifier,
                            exitCode: process.terminationStatus,
                            startedAt: startedAt,
                            finishedAt: finishedAt,
                            output: output,
                            diagnostics: diagnostics
                        ).write(to: runLogURL, atomically: true, encoding: .utf8)
                        logHandler(DecompBuildLogEvent(stream: .system, message: "Build \(status.rawValue) with exit code \(process.terminationStatus).", emittedAt: finishedAt))
                        continuation.resume(
                            returning: DecompBuildResult(
                                status: status,
                                projectRootPath: root.path,
                                targetID: target.id,
                                targetName: target.name,
                                command: target.command,
                                processID: process.processIdentifier,
                                exitCode: process.terminationStatus,
                                artifacts: artifacts,
                                output: output,
                                diagnostics: diagnostics,
                                startedAt: startedAt,
                                finishedAt: finishedAt
                            )
                        )
                    }

                    try process.run()
                } catch {
                    continuation.resume(
                        returning: DecompBuildResult(
                            status: .failed,
                            projectRootPath: root.path,
                            targetID: target.id,
                            targetName: target.name,
                            command: target.command,
                            artifacts: buildArtifacts(target: target, root: artifactRoot, fileManager: fileManager),
                            diagnostics: [
                                Diagnostic(
                                    severity: .error,
                                    code: "BUILD_RUN_FAILED",
                                    message: "Build run failed: \(error.localizedDescription)"
                                )
                            ],
                            startedAt: startedAt,
                            finishedAt: now()
                        )
                    )
                }
            }
        } onCancel: {
            box.cancel()
        }
    }

    private static func blocked(index: ProjectIndex, root: URL, target: BuildTarget?, artifactRoot: URL, code: String, message: String) -> DecompBuildResult {
        DecompBuildResult(
            status: .blocked,
            projectRootPath: root.path,
            targetID: target?.id,
            targetName: target?.name,
            command: target?.command ?? [],
            artifacts: target.map { buildArtifacts(target: $0, root: artifactRoot, fileManager: .default) } ?? [],
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: code,
                    message: message
                )
            ]
        )
    }

    private static func buildArtifacts(target: BuildTarget, root: URL, fileManager: FileManager) -> [DecompBuildArtifact] {
        let safeTargetID = target.id.replacingOccurrences(of: "/", with: "-")
        let base = ".pokemonhackstudio/builds/\(safeTargetID)"
        return [
            artifact(kind: .stdout, relativePath: "\(base)/stdout.log", root: root, fileManager: fileManager),
            artifact(kind: .stderr, relativePath: "\(base)/stderr.log", root: root, fileManager: fileManager),
            artifact(kind: .runLog, relativePath: "\(base)/run.log", root: root, fileManager: fileManager)
        ]
    }

    private static func artifact(kind: DecompBuildArtifactKind, relativePath: String, root: URL, fileManager: FileManager) -> DecompBuildArtifact {
        let url = root.appendingPathComponent(relativePath)
        let exists = fileManager.fileExists(atPath: url.path)
        return DecompBuildArtifact(kind: kind, relativePath: relativePath, absolutePath: url.path, exists: exists, detail: exists ? "Build \(kind.rawValue) artifact exists." : "Build \(kind.rawValue) artifact is planned.")
    }

    private static func artifactURL(kind: DecompBuildArtifactKind, artifacts: [DecompBuildArtifact]) -> URL? {
        artifacts.first(where: { $0.kind == kind }).map { URL(fileURLWithPath: $0.absolutePath) }
    }

    private static func append(_ data: Data, stream: DecompBuildLogStream, outputHandle: FileHandle, queue: DispatchQueue, logHandler: @escaping DecompBuildLogHandler) {
        guard !data.isEmpty else { return }
        queue.async {
            try? outputHandle.write(contentsOf: data)
        }
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
        for line in text.components(separatedBy: .newlines).filter({ !$0.isEmpty }) {
            logHandler(DecompBuildLogEvent(stream: stream, message: line))
        }
    }

    private static func runLog(
        target: BuildTarget,
        root: URL,
        status: DecompBuildRunStatus,
        processID: Int32,
        exitCode: Int32,
        startedAt: Date,
        finishedAt: Date,
        output: BuildOutputValidation?,
        diagnostics: [Diagnostic]
    ) -> String {
        var lines = [
            "PokemonHackStudio build run",
            "Target: \(target.id) (\(target.name))",
            "Command: \(target.command.joined(separator: " "))",
            "Working directory: \(root.path)",
            "Process ID: \(processID)",
            "Status: \(status.rawValue)",
            "Exit code: \(exitCode)",
            "Started: \(startedAt)",
            "Finished: \(finishedAt)"
        ]
        if let output {
            lines.append("Output: \(output.relativePath)")
            lines.append("Output exists: \(output.exists)")
            lines.append("Checksum: \(output.checksumStatus.rawValue)")
            lines.append("Freshness: \(output.freshnessStatus.rawValue)")
            if let sha1 = output.sha1 {
                lines.append("SHA1: \(sha1)")
            }
        } else {
            lines.append("Output: not declared")
        }
        if !diagnostics.isEmpty {
            lines.append("Diagnostics:")
            lines.append(contentsOf: diagnostics.map { "- \($0.code): \($0.message)" })
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
