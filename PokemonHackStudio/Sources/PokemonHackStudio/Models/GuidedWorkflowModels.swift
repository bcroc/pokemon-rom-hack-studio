import Foundation

struct WorkbenchGuidedFlow: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let systemImage: String
    let status: ValidationState
    let run: GuidedWorkflowRun
    let facts: [Fact]
    let primaryAction: WorkbenchGuidedAction
    let secondaryActions: [WorkbenchGuidedAction]
}

struct WorkbenchGuidedAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let targetModule: WorkbenchModule
    let searchText: String?
    let resourceAssetPath: String?
    let resourceAssetCategory: String?
    let buildTab: BuildWorkbenchTab?

    init(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        targetModule: WorkbenchModule,
        searchText: String? = nil,
        resourceAssetPath: String? = nil,
        resourceAssetCategory: String? = nil,
        buildTab: BuildWorkbenchTab? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.targetModule = targetModule
        self.searchText = searchText
        self.resourceAssetPath = resourceAssetPath
        self.resourceAssetCategory = resourceAssetCategory
        self.buildTab = buildTab
    }
}

enum DiagnosticSummaryBucket: String, CaseIterable, Identifiable, Hashable {
    case blockingErrors
    case sourceWarnings
    case healthToolchain
    case generatedArtifacts
    case optionalAssets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blockingErrors:
            "Blocking Errors"
        case .sourceWarnings:
            "Source Warnings"
        case .healthToolchain:
            "Health & Toolchain"
        case .generatedArtifacts:
            "Generated Artifacts"
        case .optionalAssets:
            "Optional Assets"
        }
    }

    var subtitle: String {
        switch self {
        case .blockingErrors:
            "Fix these before trusting previews."
        case .sourceWarnings:
            "Source shapes or data that need review."
        case .healthToolchain:
            "Local tools, ROM headers, and readiness checks."
        case .generatedArtifacts:
            "Build outputs and generated files that are missing or stale."
        case .optionalAssets:
            "Resource and graphics findings that may not block editing."
        }
    }

    var systemImage: String {
        switch self {
        case .blockingErrors:
            "xmark.octagon"
        case .sourceWarnings:
            "doc.text.magnifyingglass"
        case .healthToolchain:
            "wrench.and.screwdriver"
        case .generatedArtifacts:
            "archivebox"
        case .optionalAssets:
            "photo.on.rectangle"
        }
    }
}

struct DiagnosticBucketSummary: Identifiable {
    let bucket: DiagnosticSummaryBucket
    let diagnostics: [IndexedDiagnosticRow]

    var id: String { bucket.id }
    var title: String { bucket.title }
    var subtitle: String { bucket.subtitle }
    var systemImage: String { bucket.systemImage }
    var count: Int { diagnostics.count }

    var status: ValidationState {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }
        if diagnostics.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .valid
    }
}

struct DiagnosticSummary {
    let buckets: [DiagnosticBucketSummary]

    init(diagnostics: [IndexedDiagnosticRow]) {
        var grouped: [DiagnosticSummaryBucket: [IndexedDiagnosticRow]] = [:]
        for bucket in DiagnosticSummaryBucket.allCases {
            grouped[bucket] = []
        }

        for diagnostic in diagnostics {
            grouped[Self.bucket(for: diagnostic), default: []].append(diagnostic)
        }

        buckets = DiagnosticSummaryBucket.allCases.map { bucket in
            DiagnosticBucketSummary(bucket: bucket, diagnostics: grouped[bucket] ?? [])
        }
    }

    var totalCount: Int {
        buckets.reduce(0) { $0 + $1.count }
    }

    var blockingErrorCount: Int {
        bucket(.blockingErrors).count
    }

    var warningCount: Int {
        buckets.flatMap(\.diagnostics).filter { $0.severity == .warning }.count
    }

    var healthCount: Int {
        bucket(.healthToolchain).count
    }

    var generatedArtifactCount: Int {
        bucket(.generatedArtifacts).count
    }

    var optionalAssetCount: Int {
        bucket(.optionalAssets).count
    }

    var sourceWarningCount: Int {
        bucket(.sourceWarnings).count
    }

    var status: ValidationState {
        if blockingErrorCount > 0 {
            return .error
        }
        if totalCount > 0 {
            return .warning
        }
        return .valid
    }

    var compactLabel: String {
        if blockingErrorCount > 0 {
            return "\(blockingErrorCount) blocking"
        }
        if warningCount > 0 {
            return "\(warningCount) warnings"
        }
        if totalCount > 0 {
            return "\(totalCount) findings"
        }
        return "Healthy"
    }

    var detail: String {
        if totalCount == 0 {
            return "No diagnostics in the current project."
        }

        let parts = [
            blockingErrorCount > 0 ? "\(blockingErrorCount) blocking" : nil,
            sourceWarningCount > 0 ? "\(sourceWarningCount) source" : nil,
            healthCount > 0 ? "\(healthCount) health" : nil,
            generatedArtifactCount > 0 ? "\(generatedArtifactCount) generated" : nil,
            optionalAssetCount > 0 ? Self.countLabel(optionalAssetCount, singular: "optional asset") : nil
        ].compactMap { $0 }

        return parts.joined(separator: ", ")
    }

    func bucket(_ bucket: DiagnosticSummaryBucket) -> DiagnosticBucketSummary {
        buckets.first { $0.bucket == bucket } ?? DiagnosticBucketSummary(bucket: bucket, diagnostics: [])
    }

    static func bucket(for diagnostic: IndexedDiagnosticRow) -> DiagnosticSummaryBucket {
        if diagnostic.severity == .error {
            return .blockingErrors
        }

        let code = diagnostic.title.uppercased()
        let blob = [
            diagnostic.title,
            diagnostic.message,
            diagnostic.source.path,
            diagnostic.source.symbol
        ]
        .joined(separator: " ")
        .uppercased()

        if code.hasPrefix("BUILD_OUTPUT_")
            || code.hasPrefix("GENERATED_ARTIFACT_")
            || code.hasPrefix("GRAPHICS_GENERATED_ARTIFACT_")
            || blob.contains("GENERATED")
            || blob.contains("BUILD OUTPUT")
        {
            return .generatedArtifacts
        }

        if code.hasPrefix("BUILD_TOOL_")
            || code.hasPrefix("TOOLCHAIN_")
            || code.hasPrefix("ROM_HEADER_")
            || code.hasPrefix("GRAPHICS_CONVERSION_")
        {
            return .healthToolchain
        }

        if blob.contains("RESOURCE")
            || blob.contains("ASSET")
            || blob.contains("GRAPHICS")
            || blob.contains("TILESET")
            || blob.contains("PALETTE")
            || blob.contains("SPRITE")
        {
            return .optionalAssets
        }

        return .sourceWarnings
    }

    private static func countLabel(_ count: Int, singular: String) -> String {
        count == 1 ? "\(count) \(singular)" : "\(count) \(singular)s"
    }
}
