import Foundation

public struct ScriptCommand: Codable, Equatable {
    public let name: String
    public let arguments: [String]
    public let comment: String?

    public init(name: String, arguments: [String] = [], comment: String? = nil) {
        self.name = name
        self.arguments = arguments
        self.comment = comment
    }
}

public enum ScriptLine: Codable, Equatable, Identifiable {
    public var id: String {
        switch self {
        case .command(let cmd, let line): return "cmd:\(line):\(cmd.name)"
        case .label(let label, let line): return "label:\(line):\(label)"
        case .macro(let name, _, let line): return "macro:\(line):\(name)"
        case .directive(let name, _, let line): return "dir:\(line):\(name)"
        case .comment(let text, let line): return "comment:\(line):\(text.prefix(10))"
        case .empty(let line): return "empty:\(line)"
        }
    }

    case command(ScriptCommand, line: Int)
    case label(String, line: Int)
    case macro(name: String, arguments: [String], line: Int)
    case directive(name: String, value: String, line: Int)
    case comment(String, line: Int)
    case empty(line: Int)

    public var line: Int {
        switch self {
        case .command(_, let line): line
        case .label(_, let line): line
        case .macro(_, _, let line): line
        case .directive(_, _, let line): line
        case .comment(_, let line): line
        case .empty(let line): line
        }
    }
}
