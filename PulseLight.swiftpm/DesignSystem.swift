import SwiftUI

// MARK: - Colors

enum PulseColors {
    // Primary brand color - vibrant red
    static let primary = Color(red: 0.95, green: 0.2, blue: 0.25)
    static let primaryDark = Color(red: 0.85, green: 0.15, blue: 0.2)
    
    // Backgrounds
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.tertiarySystemBackground)
    
    // Labels
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    
    // Waveform
    static let waveform = Color(red: 0.95, green: 0.2, blue: 0.25)
    static let waveformGradientTop = Color(red: 0.95, green: 0.2, blue: 0.25).opacity(0.4)
    static let waveformGradientBottom = Color(red: 0.95, green: 0.2, blue: 0.25).opacity(0.08)
    
    // Status colors
    static let confidence = Color(red: 0.2, green: 0.75, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let demoBanner = Color(red: 0.2, green: 0.5, blue: 0.95)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackground.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

enum PulseTypography {
    // Display fonts - SF Pro Display for headings
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 22, weight: .semibold, design: .default)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    
    // Text fonts - SF Pro Text for body
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // Specialized displays
    static let bpmDisplay = Font.system(size: 76, weight: .bold, design: .rounded)
    static let bpmUnit = Font.system(size: 20, weight: .medium, design: .rounded)
    static let countdownDisplay = Font.system(size: 56, weight: .bold, design: .rounded)
}

// MARK: - Haptics

enum PulseHaptics {
    static func pulse() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

// MARK: - Shadows & Effects

enum PulseShadows {
    static let small = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Constants

enum PulseConstants {
    static let sampleRate: Double = 30.0
    static let bufferSize: Int = 600
    static let sessionDuration: TimeInterval = 20.0
    static let minimumFramesForEstimate: Int = 90

    static let disclaimer = "PulseLight is an educational and experimental tool. It is not a medical device and should not be used for diagnosis or treatment. Always consult a healthcare professional for medical advice."
}
