import CoreGraphics

enum WorkbenchLayoutMode: Equatable {
    static let compactContentBreakpoint: CGFloat = 1060
    static let compactPopoverWidth: CGFloat = 360
    static let compactPopoverHeight: CGFloat = 620

    case compact
    case wide

    init(contentWidth: CGFloat) {
        self = contentWidth < Self.compactContentBreakpoint ? .compact : .wide
    }

    var isCompact: Bool {
        self == .compact
    }

    var isWide: Bool {
        self == .wide
    }

    var contentPadding: CGFloat {
        isCompact ? 14 : 20
    }

    var sectionSpacing: CGFloat {
        isCompact ? 14 : 18
    }
}

enum MapEditorLayoutMode: Equatable {
    static let compactBreakpoint: CGFloat = 1180

    case wide
    case compact

    init(width: CGFloat) {
        self = width < Self.compactBreakpoint ? .compact : .wide
    }

    var isCompact: Bool {
        self == .compact
    }

    var isWide: Bool {
        self == .wide
    }
}
