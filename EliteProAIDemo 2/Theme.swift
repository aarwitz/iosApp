import SwiftUI

enum EPTheme {
//    static let accent = Color(red: 1.0, green: 0.45, blue: 0.10)   // orange-ish
    static let accent = Color(red: 0.73, green: 0.30, blue: 0.12)
    
    // Adaptive colors — automatically respond to light/dark mode
    // Create UIColors once to avoid recreating closures on every access
    private static let _cardUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            : UIColor.white
    }
    static let card = Color(_cardUIColor)
    
    private static let _cardStrokeUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.08)
    }
    static let cardStroke = Color(_cardStrokeUIColor)

    private static let _cardShadowUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .clear : UIColor.black.withAlphaComponent(0.065)
    }
    static let cardShadow = Color(_cardShadowUIColor)

    /// Light gray grouped page background (matches iOS Settings-style)
    static let pageBackground = Color(UIColor.systemGroupedBackground)
    
    private static let _softTextUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.72)
            : UIColor.black.withAlphaComponent(0.55)
    }
    static let softText = Color(_softTextUIColor)
    
    private static let _dividerUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.black.withAlphaComponent(0.12)
    }
    static let divider = Color(_dividerUIColor)
    
    static let primaryText = Color.primary
    
    // Convenience functions for cases that still pass colorScheme
    static func card(for colorScheme: ColorScheme) -> Color { card }
    static func cardStroke(for colorScheme: ColorScheme) -> Color { cardStroke }
    static func softText(for colorScheme: ColorScheme) -> Color { softText }
    static func divider(for colorScheme: ColorScheme) -> Color { divider }
    static func primaryText(for colorScheme: ColorScheme) -> Color { primaryText }

    static let backgroundLuxury = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1)
                : UIColor.systemGroupedBackground
        }
    )
}

struct EPButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .serif))
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
            .shadow(color: EPTheme.cardShadow, radius: 5, x: 0, y: 2)
    }
}
