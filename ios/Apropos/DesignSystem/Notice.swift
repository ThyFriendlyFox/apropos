import SwiftUI

/// A titled block of explanation. Used wherever the app has to say why
/// something will or will not happen.
struct Notice: View {
    enum Tone { case good, neutral, warning }


    let title: String
    let detail: String
    var tone: Tone = .warning

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var icon: String {
        switch tone {
        case .good: return "checkmark.circle"
        case .neutral: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        }
    }

    private var color: Color {
        switch tone {
        case .good: return Theme.accent
        case .neutral: return .white
        case .warning: return .orange
        }
    }
}

