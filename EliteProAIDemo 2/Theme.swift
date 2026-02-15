import SwiftUI

enum EPTheme {
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.10)   // orange-ish
    static let card = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let cardStroke = Color.white.opacity(0.12)
    static let softText = Color.white.opacity(0.72)
    static let divider = Color.white.opacity(0.10)
}

struct EPButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.85 : 0.95))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(EPTheme.card.opacity(configuration.isPressed ? 0.85 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct EPCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(EPTheme.card))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
    }
}
