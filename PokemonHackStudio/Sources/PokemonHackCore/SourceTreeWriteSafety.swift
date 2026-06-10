import Foundation

enum SourceTreeWriteSafety {
    static func isContained(_ url: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    static func diagnosticsForRelativeWritePath(
        _ path: String,
        root: URL,
        fileManager: FileManager,
        codePrefix: String,
        subject: String,
        spanLine: Int = 1
    ) -> [Diagnostic] {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return [pathDiagnostic("\(codePrefix)_PATH_EMPTY", "\(subject) is missing.", path: path, line: spanLine)]
        }
        guard !(trimmed as NSString).isAbsolutePath else {
            return [pathDiagnostic("\(codePrefix)_PATH_ABSOLUTE", "\(subject) must be project-relative: \(trimmed).", path: trimmed, line: spanLine)]
        }

        let components = normalizedComponents(trimmed)
        if components.contains("..") {
            return [pathDiagnostic("\(codePrefix)_PATH_ESCAPE", "\(subject) cannot contain '..': \(trimmed).", path: trimmed, line: spanLine)]
        }

        let destination = root.appendingPathComponent(trimmed).standardizedFileURL
        guard isContained(destination, in: root) else {
            return [pathDiagnostic("\(codePrefix)_PATH_OUTSIDE_ROOT", "\(subject) resolves outside the project root: \(trimmed).", path: trimmed, line: spanLine)]
        }

        let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
        if let ancestor = nearestExistingAncestor(for: destination, root: root, fileManager: fileManager) {
            let resolvedAncestor = ancestor.resolvingSymlinksInPath().standardizedFileURL
            if !isContained(resolvedAncestor, in: resolvedRoot) {
                return [pathDiagnostic("\(codePrefix)_PATH_SYMLINK_OUTSIDE_ROOT", "\(subject) crosses a symlink outside the project root: \(trimmed).", path: trimmed, line: spanLine)]
            }
        }

        return []
    }

    private static func normalizedComponents(_ path: String) -> [String] {
        path
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
    }

    private static func nearestExistingAncestor(
        for destination: URL,
        root: URL,
        fileManager: FileManager
    ) -> URL? {
        let standardizedRoot = root.standardizedFileURL
        var current = destination.standardizedFileURL

        while isContained(current, in: standardizedRoot) {
            if fileManager.fileExists(atPath: current.path) {
                return current
            }
            let parent = current.deletingLastPathComponent().standardizedFileURL
            if parent.path == current.path {
                break
            }
            current = parent
        }
        return nil
    }

    private static func pathDiagnostic(_ code: String, _ message: String, path: String, line: Int) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: line))
    }
}
