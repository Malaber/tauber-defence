import SwiftUI

enum GameTheme {
    static let ink = Color(red: 0.09, green: 0.15, blue: 0.16)
    static let deepTeal = Color(red: 0.04, green: 0.28, blue: 0.29)
    static let teal = Color(red: 0.10, green: 0.69, blue: 0.62)
    static let cream = Color(red: 0.98, green: 0.91, blue: 0.73)
    static let yellow = Color(red: 0.98, green: 0.72, blue: 0.18)
    static let coral = Color(red: 0.92, green: 0.30, blue: 0.24)
    static let blue = Color(red: 0.20, green: 0.57, blue: 0.88)

    static let panel = LinearGradient(
        colors: [ink.opacity(0.94), deepTeal.opacity(0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GamePanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
    }
}

extension View {
    func gamePanel() -> some View {
        modifier(GamePanelModifier())
    }
}
