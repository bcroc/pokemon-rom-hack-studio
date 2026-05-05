import SwiftUI

struct StatusPill: View {
    let state: ValidationState

    var body: some View {
        Label(state.rawValue, systemImage: imageName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
    }

    private var imageName: String {
        switch state {
        case .valid: "checkmark.circle"
        case .warning: "exclamationmark.triangle"
        case .error: "xmark.octagon"
        }
    }

    private var tint: Color {
        switch state {
        case .valid: .green
        case .warning: .orange
        case .error: .red
        }
    }
}

struct DirtyPill: View {
    let isDirty: Bool

    var body: some View {
        Label(isDirty ? "Dirty" : "Clean", systemImage: isDirty ? "circle.fill" : "circle")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isDirty ? Color.blue : Color.secondary).opacity(0.12), in: Capsule())
            .foregroundStyle(isDirty ? Color.blue : Color.secondary)
    }
}

struct IssueCountBadge: View {
    let count: Int

    var body: some View {
        Label("\(count)", systemImage: "exclamationmark.triangle")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.red.opacity(0.13), in: Capsule())
            .foregroundStyle(.red)
            .accessibilityLabel("\(count) issues")
    }
}
