import SwiftUI

enum Theme {
    static let background = Color(red: 0.051, green: 0.067, blue: 0.090)
    static let surface = Color(red: 0.086, green: 0.106, blue: 0.133)
    static let border = Color.white.opacity(0.10)
    static let accent = Color(red: 0.247, green: 0.831, blue: 0.353)
    static let secondaryText = Color.white.opacity(0.62)
}

extension View {
    /// The card treatment used by every row and panel in the app.
    func cardSurface(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }
}
