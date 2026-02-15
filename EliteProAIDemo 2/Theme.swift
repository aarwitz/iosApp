import SwiftUI

enum EPTheme {
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.10)   // orange-ish
    
    // Adaptive colors — automatically respond to light/dark mode
    static let card = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
    })
    
    static let cardStroke = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.08)
    })
    
    static let softText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.72)
            : UIColor.black.withAlphaComponent(0.55)
    })
    
    static let divider = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.black.withAlphaComponent(0.12)
    })
    
    static let primaryText = Color.primary
    
    // Convenience functions for cases that still pass colorScheme
    static func card(for colorScheme: ColorScheme) -> Color { card }
    static func cardStroke(for colorScheme: ColorScheme) -> Color { cardStroke }
    static func softText(for colorScheme: ColorScheme) -> Color { softText }
    static func divider(for colorScheme: ColorScheme) -> Color { divider }
    static func primaryText(for colorScheme: ColorScheme) -> Color { primaryText }
}

struct EPButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Color.primary.opacity(configuration.isPressed ? 0.7 : 1.0))
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
