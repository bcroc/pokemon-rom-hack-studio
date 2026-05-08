import SwiftUI

struct StatusPill: View {
    let state: ValidationState

    var body: some View {
        Label(state.rawValue, systemImage: state.statusSystemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(state.statusTint.opacity(0.14), in: Capsule())
            .foregroundStyle(state.statusTint)
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

struct DiagnosticStatusButton: View {
    let summary: DiagnosticSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(summary.compactLabel, systemImage: summary.status.statusSystemImage)
        }
        .buttonStyle(.plain)
        .help(summary.detail)
        .accessibilityLabel("Diagnostics status: \(summary.compactLabel)")
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(summary.status.statusTint.opacity(0.12), in: Capsule())
        .foregroundStyle(summary.status.statusTint)
    }
}

private extension ValidationState {
    var statusSystemImage: String {
        switch self {
        case .valid:
            "checkmark.circle"
        case .warning:
            "exclamationmark.triangle"
        case .error:
            "xmark.octagon"
        }
    }

    var statusTint: Color {
        switch self {
        case .valid:
            .green
        case .warning:
            .orange
        case .error:
            .red
        }
    }
}
