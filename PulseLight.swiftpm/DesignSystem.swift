import SwiftUI

// MARK: - Colors

enum PulseColors {
    static let primary = Color.red
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.tertiarySystemBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let waveform = Color.red
    static let waveformGradientTop = Color.red.opacity(0.3)
    static let waveformGradientBottom = Color.red.opacity(0.05)
    static let confidence = Color.green
    static let warning = Color.orange
    static let demoBanner = Color.blue
}

// MARK: - Typography

enum PulseTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    static let bpmDisplay = Font.system(size: 72, weight: .bold, design: .rounded)
    static let bpmUnit = Font.title3.weight(.medium)
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

// MARK: - Constants

enum PulseConstants {
    static let sampleRate: Double = 30.0
    static let bufferSize: Int = 600
    static let sessionDuration: TimeInterval = 20.0
    static let minimumFramesForEstimate: Int = 90

    static let disclaimer = "PulseLight is an educational and experimental tool. It is not a medical device and should not be used for diagnosis or treatment. Always consult a healthcare professional for medical advice."
}
